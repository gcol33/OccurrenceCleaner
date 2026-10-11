# Build the Natural Earth reference layers shipped in R/sysdata.rda.
#
# Natural Earth (https://www.naturalearthdata.com) is public domain: "All
# versions of Natural Earth raster + vector map data found on this website are
# in the public domain." (terms of use, read 2026-10-09). Each layer is pinned
# by file, version stamp (the VERSION.txt inside the zip) and sha256 of the zip.
#
# Run from the package root:  Rscript data-raw/natural_earth.R
# Needs sf and digest only here; neither is a package dependency.

suppressMessages({library(sf)})
source("data-raw/utils.R")
sf_use_s2(FALSE)
cache <- "data-raw/cache"
dir.create(cache, showWarnings = FALSE, recursive = TRUE)
retrieved <- "2026-10-09"

layers <- data.frame(
  key    = c("land_110", "land_50", "land_10", "countries_50", "admin0_10", "admin1_10", "places_10", "urban_50"),
  path   = c("110m/physical/ne_110m_land", "50m/physical/ne_50m_land", "10m/physical/ne_10m_land",
             "50m/cultural/ne_50m_admin_0_countries", "10m/cultural/ne_10m_admin_0_countries",
             "10m/cultural/ne_10m_admin_1_states_provinces", "10m/cultural/ne_10m_populated_places_simple",
             "50m/cultural/ne_50m_urban_areas"),
  stringsAsFactors = FALSE
)
layers$file <- paste0(basename(layers$path), ".zip")
layers$url <- paste0("https://naciscdn.org/naturalearth/", layers$path, ".zip")

fetch <-function(i) {
  z <- file.path(cache, layers$file[i])
  if (!file.exists(z)) download.file(layers$url[i], z, mode = "wb", quiet = TRUE)
  d <- file.path(tempdir(), sub(".zip", "", layers$file[i], fixed = TRUE))
  unzip(z, exdir = d)
  ver <- trimws(readLines(list.files(d, "VERSION[.]txt$", full.names = TRUE), warn = FALSE))
  list(sf = st_read(list.files(d, "[.]shp$", full.names = TRUE), quiet = TRUE),
       meta = data.frame(layer = layers$key[i], source = "Natural Earth", file = layers$file[i],
                         version = ver, url = layers$url[i], sha256 = sha256(z),
                         retrieved = retrieved, licence = "public domain", stringsAsFactors = FALSE))
}

# Coordinates are stored as integer 1e-7 degrees (about 1 cm), exact for the
# 6-7 decimals Natural Earth ships.
to_int <- function(v) as.integer(round(v * 1e7))

# Polygons -> compact ring table. One ring per exterior or hole ring; feature
# is the 1-based row of `features`.
compact_polygons <- function(x, features) {
  g <- st_geometry(x)
  xs <- list(); ys <- list(); starts <- integer(); feats <- integer(); off <- 0L
  for (f in seq_along(g)) {
    geom <- g[[f]]
    polys <- if (inherits(geom, "POLYGON")) list(geom) else geom
    for (poly in polys) for (ring in poly) {
      m <- unclass(ring)
      n <- nrow(m)
      if (n >= 4 && m[1, 1] == m[n, 1] && m[1, 2] == m[n, 2]) n <- n - 1L
      if (n < 3) next
      xs[[length(xs) + 1]] <- m[seq_len(n), 1]
      ys[[length(ys) + 1]] <- m[seq_len(n), 2]
      starts <- c(starts, off)
      feats <- c(feats, f)
      off <- off + n
    }
  }
  list(x = to_int(unlist(xs)), y = to_int(unlist(ys)), ring_start = c(starts, off),
       ring_feature = feats, features = features)
}

out <- list(); meta <- list()

for (key in c("land_110", "land_50", "land_10")) {
  L <- fetch(which(layers$key == key)); meta[[key]] <- L$meta
  out[[key]] <- compact_polygons(L$sf, data.frame(id = seq_len(nrow(L$sf))))
  cat(key, ": features", nrow(L$sf), " vertices", length(out[[key]]$x), "\n")
}

L <- fetch(which(layers$key == "countries_50")); meta$countries_50 <- L$meta
d <- as.data.frame(L$sf)
countries <- data.frame(name = d$ADMIN, adm0_a3 = d$ADM0_A3, iso_a3 = d$ISO_A3_EH, iso_a2 = d$ISO_A2_EH,
                        type = d$TYPE, stringsAsFactors = FALSE)
countries$iso_a3[countries$iso_a3 == "-99"] <- NA
countries$iso_a2[countries$iso_a2 == "-99"] <- NA
out$countries_50 <- compact_polygons(L$sf, countries)
cat("countries_50: features", nrow(countries), " vertices", length(out$countries_50$x), "\n")

L <- fetch(which(layers$key == "urban_50")); meta$urban_50 <- L$meta
out$urban_50 <- compact_polygons(L$sf, data.frame(id = seq_len(nrow(L$sf))))
cat("urban_50: features", nrow(L$sf), " vertices", length(out$urban_50$x), "\n")

# Capitals: Natural Earth admin-0 capitals, alternative capitals and capitals
# of dependent territories ("Admin-0 region capital").
L <- fetch(which(layers$key == "places_10")); meta$places_10 <- L$meta
d <- as.data.frame(L$sf)
keep <- d$featurecla %in% c("Admin-0 capital", "Admin-0 capital alt", "Admin-0 region capital")
capitals <- data.frame(name = d$name[keep], country = d$adm0name[keep], adm0_a3 = d$adm0_a3[keep],
                       iso_a2 = d$iso_a2[keep], class = d$featurecla[keep],
                       lon = d$longitude[keep], lat = d$latitude[keep], stringsAsFactors = FALSE)
capitals <- capitals[order(capitals$adm0_a3, capitals$name), ]
rownames(capitals) <- NULL
out$capitals <- capitals
cat("capitals:", nrow(capitals), "\n")

# Centroids: admin-0 polygon centroids and label points, admin-1 label points
# (the latter are what CoordinateCleaner's countryref provinces hold).
L <- fetch(which(layers$key == "admin0_10")); meta$admin0_10 <- L$meta
d <- as.data.frame(L$sf)
# Centroids on the sphere (s2): a planar centroid of a country spanning the
# antimeridian (Fiji, Kiribati) falls on the far side of the globe.
sf_use_s2(TRUE)
ctr <- suppressWarnings(st_coordinates(st_centroid(st_make_valid(st_geometry(L$sf)))))
sf_use_s2(FALSE)
cen0 <- rbind(
  data.frame(name = d$ADMIN, adm0_a3 = d$ADM0_A3, code = d$ADM0_A3, type = "country", method = "polygon centroid",
             lon = ctr[, 1], lat = ctr[, 2], stringsAsFactors = FALSE),
  data.frame(name = d$ADMIN, adm0_a3 = d$ADM0_A3, code = d$ADM0_A3, type = "country", method = "label point",
             lon = d$LABEL_X, lat = d$LABEL_Y, stringsAsFactors = FALSE))
L <- fetch(which(layers$key == "admin1_10")); meta$admin1_10 <- L$meta
d <- as.data.frame(L$sf)
cen1 <- data.frame(name = d$name, adm0_a3 = d$adm0_a3, code = d$adm1_code, type = "province", method = "label point",
                   lon = d$longitude, lat = d$latitude, stringsAsFactors = FALSE)
centroids <- rbind(cen0, cen1)
centroids <- centroids[is.finite(centroids$lon) & is.finite(centroids$lat), ]
centroids <- centroids[order(centroids$type, centroids$adm0_a3, centroids$code, centroids$method), ]
rownames(centroids) <- NULL
out$centroids <- centroids
cat("centroids:", nrow(centroids), " (", sum(centroids$type == "country"), "country,", sum(centroids$type == "province"), "province )\n")

out$meta <- do.call(rbind, meta)
rownames(out$meta) <- NULL
saveRDS(out, file.path(cache, "natural_earth_layers.rds"), compress = "xz")
for (k in names(out)) { f <- tempfile(); saveRDS(out[[k]], f, compress = "xz"); cat(sprintf("%-14s %7.0f KB xz\n", k, file.size(f) / 1024)) }
print(out$meta[, c("layer", "version", "sha256")])
