# Build the animated hex logo man/figures/logo.svg.
#
# A Winkel tripel world map (Natural Earth 1:110m land, public domain) inside a
# hex, with occurrence records on it; the flagged ones are red. Two quiet
# motions, both looping: the meridians drift eastwards, one graticule step
# (30 degrees) every six seconds, as in the sf logo, and the red dots pulse
# slowly, out of step with each other. Under prefers-reduced-motion a still
# graticule replaces the moving one and the red dots stay still.
#
# Run from the package root:  Rscript data-raw/logo.R
# Needs sf only here; it is not a package dependency.

suppressMessages(library(sf))
sf_use_s2(FALSE)

out <- "man/figures/logo.svg"
land_zip <- "data-raw/cache/ne_110m_land.zip"
if (!file.exists(land_zip)) {
  download.file("https://naciscdn.org/naturalearth/110m/physical/ne_110m_land.zip",
                land_zip, mode = "wb", quiet = TRUE)
}

col <- c(border = "#2B3A4A", paper = "#FFFFFF", grat = "#BCC2C9", land = "#AEB4BB",
         record = "#2B3A4A", flag = "#B5342B", name = "#2E6F9E", name_edge = "#1B3F5C")

# Hex geometry: pointy top, circumradius R, centred in a 520 x 600 viewBox.
W <- 520; H <- 600; R <- 300; cx <- W / 2; cy <- H / 2
hex_pts <- function(r) {
  a <- pi / 2 + (0:5) * pi / 3
  cbind(cx + r * cos(a), cy - r * sin(a))
}
pts_attr <- function(m) paste(sprintf("%.1f,%.1f", m[, 1], m[, 2]), collapse = " ")

# Map projection and placement in viewBox units. The globe is turned so that
# lon0 faces the viewer and tilted by `tilt` degrees towards the viewer, so
# the north pole is a point inside the hex and the land sits lower. The
# projection's own pole line (the far side of the globe) sits just above the
# hex's inner top vertex (y = 12), so the graticule reaches the top of the
# hex without a visible map edge.
lon0 <- 25
tilt <- 20
crs <- "+proj=wintri +lon_0=0 +datum=WGS84 +units=m +no_defs"
map_width <- 1.6 * W

rad <- pi / 180
rotate <- function(lonlat) {
  lam <- (lonlat[, 1] - lon0) * rad; phi <- lonlat[, 2] * rad; t <- tilt * rad
  x <- cos(phi) * cos(lam); y <- cos(phi) * sin(lam); z <- sin(phi)
  xr <- x * cos(t) + z * sin(t); zr <- -x * sin(t) + z * cos(t)
  cbind(atan2(y, xr) / rad, asin(pmin(pmax(zr, -1), 1)) / rad)
}
world_m <- sf_project("EPSG:4326", crs, cbind(c(-179.999, 179.999), c(0, 0)))
k <- map_width / diff(world_m[, 1])
pole_m <- sf_project("EPSG:4326", crs, cbind(0, 90))
map_cy <- 6 + k * pole_m[1, 2]
project <- function(rot) {
  m <- sf_project("EPSG:4326", crs, rot)
  cbind(cx + k * m[, 1], map_cy - k * m[, 2])
}
to_view <- function(lonlat) project(rotate(lonlat))
path_d <- function(m, close = FALSE) {
  d <- paste0("M", paste(sprintf("%.1f,%.1f", m[, 1], m[, 2]), collapse = "L"))
  if (close) paste0(d, "Z") else d
}
# A static line in rotated coordinates, split where it crosses the far-side
# antimeridian.
split_d <- function(rot) {
  brk <- which(abs(diff(rot[, 1])) > 180)
  seg <- split(seq_len(nrow(rot)), findInterval(seq_len(nrow(rot)), brk + 1))
  paste(vapply(seg, function(i) if (length(i) > 1) path_d(project(rot[i, , drop = FALSE])) else "", ""),
        collapse = "")
}

# Land within 115 degrees of lon0 (the near side, which also covers the hex)
# and above 60 S (Antarctica sits under the name), turned into rotated
# coordinates. Nothing reaches the far-side antimeridian, so no ring is split.
land <- st_read(paste0("/vsizip/", land_zip), quiet = TRUE)
land <- suppressWarnings(st_crop(st_geometry(land), xmin = lon0 - 115, xmax = lon0 + 115,
                                 ymin = -58, ymax = 84))
land <- st_cast(st_cast(land, "MULTIPOLYGON"), "POLYGON")
land <- lapply(land, function(poly) {
  st_polygon(lapply(poly, function(ring) rotate(unclass(ring)[, 1:2, drop = FALSE])))
})
land_d <- character()
for (g in land) {
  for (ring in g) {
    m <- unclass(ring)[, 1:2, drop = FALSE]
    if (nrow(m) < 4) next
    land_d <- c(land_d, path_d(project(m), close = TRUE))
  }
}

# Graticule every 30 degrees. Parallels do not move when the globe turns
# about its axis; meridians are drawn at offsets 0..30 degrees from their
# rest position, one path per frame, interpolated by SMIL (CSS cannot animate
# a path shape in every browser). The offset is linear in time and the last
# frame equals the first, so the drift loops without a jump.
step <- 30
seq_dense <- function(a, b, n = 181) seq(a, b, length.out = n)
par_d <- vapply(seq(-60, 60, by = step), function(lat) {
  split_d(rotate(cbind(seq_dense(-180, 180, 361), lat)))
}, "")

# Every frame of a meridian keeps the same number of points; points on the
# far side (outside the hex) collapse onto their nearest near-side neighbour
# so the path never jumps across the map.
meridian <- function(rel) {
  rot <- rotate(cbind(lon0 + rel, seq_dense(-90, 90, 37)))
  far <- abs(rot[, 1]) > 150
  if (all(far)) rot[] <- rep(rot[1, ], each = nrow(rot)) else {
    near <- which(!far)
    nearest <- near[vapply(seq_len(nrow(rot)), function(i) which.min(abs(near - i)), 1L)]
    rot[far, ] <- rot[nearest[far], ]
  }
  path_d(project(rot))
}
t_drift <- 6
n_frames <- 16
shift <- seq(0, step, length.out = n_frames)
rest <- seq(-180, 180 - step, by = step)
moving <- vapply(rest, function(r) {
  frames <- vapply(shift, function(s) meridian(r + s), "")
  sprintf('<path d="%s"><animate attributeName="d" dur="%gs" repeatCount="indefinite" calcMode="linear" values="%s"/></path>',
          frames[1], t_drift, paste(frames, collapse = ";"))
}, "")
still <- vapply(rest, meridian, "")

# Records. Flagged ones: zero coordinates, open sea, the GBIF headquarters
# (an institution) and the centroid of Brazil.
records <- data.frame(
  lon = c(-50, 22, 28, 78, 80, 40, 118,
          0, -35, 12.58, -53.1),
  lat = c(-28, 8, -24, 22, 56, 58, 46,
          0, 28, 55.68, -10.8),
  flag = c(rep(FALSE, 7), rep(TRUE, 4))
)
xy <- to_view(cbind(records$lon, records$lat))
records$x <- xy[, 1]; records$y <- xy[, 2]

delay <- ifelse(records$flag, sprintf(' style="animation-delay:-%.1fs"', 1 * cumsum(records$flag)), "")
rec_svg <- sprintf('<circle class="rec%s" cx="%.1f" cy="%.1f" r="11"%s/>',
                   ifelse(records$flag, " flagged", ""), records$x, records$y, delay)

css <- sprintf('
.rec { fill: %1$s; }
.rec.flagged { fill: %2$s; transform-box: fill-box; transform-origin: center;
  animation: pulse 4s ease-in-out infinite; }
@keyframes pulse { 0%%, 100%% { transform: scale(1); opacity: 1; } 50%% { transform: scale(1.12); opacity: 0.7; } }
.grat { fill: none; stroke: %3$s; stroke-width: 2; }
.still { display: none; }
@media (prefers-reduced-motion: reduce) {
  .moving { display: none; }
  .still { display: inline; }
  .rec.flagged { animation: none; } }
', col[["record"]], col[["flag"]], col[["grat"]])

name_y <- 428
svg <- c(
  sprintf('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d" role="img" aria-label="OccurrenceCleaner logo">', W, H, W, H),
  "<title>OccurrenceCleaner logo</title>",
  sprintf("<style>%s</style>", css),
  "<defs>",
  sprintf('<clipPath id="inner"><polygon points="%s"/></clipPath>', pts_attr(hex_pts(R - 12))),
  "</defs>",
  sprintf('<polygon points="%s" fill="%s"/>', pts_attr(hex_pts(R - 12)), col[["paper"]]),
  '<g clip-path="url(#inner)">',
  sprintf('<path class="grat" d="%s"/>', paste(par_d, collapse = "")),
  '<g class="grat moving">', moving, "</g>",
  sprintf('<path class="grat still" d="%s"/>', paste(still, collapse = "")),
  sprintf('<path d="%s" fill="%s" fill-rule="evenodd"/>', paste(land_d, collapse = ""), col[["land"]]),
  rec_svg,
  sprintf('<text x="%.1f" y="%d" text-anchor="middle" font-family="Georgia, \'Times New Roman\', serif" font-style="italic" font-weight="bold" font-size="62" fill="%s" stroke="%s" stroke-width="7" stroke-linejoin="round" paint-order="stroke">Occurrence</text>',
          cx, name_y, col[["name"]], col[["paper"]]),
  sprintf('<text x="%.1f" y="%d" text-anchor="middle" font-family="Georgia, \'Times New Roman\', serif" font-style="italic" font-weight="bold" font-size="62" fill="%s" stroke="%s" stroke-width="7" stroke-linejoin="round" paint-order="stroke">Cleaner</text>',
          cx, name_y + 60, col[["name"]], col[["paper"]]),
  "</g>",
  sprintf('<polygon points="%s" fill="none" stroke="%s" stroke-width="18" stroke-linejoin="round"/>', pts_attr(hex_pts(R - 9)), col[["border"]]),
  "</svg>"
)

dir.create(dirname(out), showWarnings = FALSE, recursive = TRUE)
writeLines(svg, out, useBytes = TRUE)
message(sprintf("%s: %.0f KB", out, file.size(out) / 1024))
