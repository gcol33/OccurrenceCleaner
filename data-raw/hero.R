# Build the README banner man/figures/OccurrenceCleaner-hero.png.
#
# A sample of the GBIF snapshot of 2026-10-01 (every k-th of its Parquet files)
# flagged with the tests for coordinates that pile up at one point or line. All
# records are drawn as a grey density on the Equal Earth projection; the
# flagged records are drawn over them in three colours by test group, with the
# share of sampled records each group flags written beside it.
#
# Run from the package root:  Rscript data-raw/hero.R [number of files]
# The per-file counts are cached in data-raw/cache/hero_grid.rds; delete it to
# resample. Needs sf, ggplot2 and ragg only here; they are not package
# dependencies.

suppressMessages({
  library(sf)
  library(ggplot2)
})
pkgload::load_all(quiet = TRUE)

snapshot <- "E:/research/raw/occurrences/gbif_snapshot/2026-10-01/occurrence.parquet"
args <- commandArgs(TRUE)
n_files <- if (length(args)) as.integer(args[1]) else 250L
cache <- "data-raw/cache/hero_grid.rds"

crs_ee <- "+proj=eqearth +lon_0=0 +datum=WGS84"
lat_lim <- c(-60, 84)

# Test groups in drawing order; a record flagged by several groups counts in
# the last of them.
groups <- list(
  institution = list(tests = c("institution", "gbif_headquarters"), label = "institutions",
                     colour = "#0072B2"),
  centroid    = list(tests = c("centroid", "capital"),               label = "centroids, capitals",
                     colour = "#D55E00"),
  zero        = list(tests = c("zero", "equal"),                     label = "zero, equal",
                     colour = "#8E3B9E")
)
tests <- c("invalid", unlist(lapply(groups, `[[`, "tests"), use.names = FALSE))

# Frame in projected metres and the pixel grid the records are counted on.
corner <- sf_project("EPSG:4326", crs_ee, rbind(c(-180, 0), c(180, 0), c(0, lat_lim[1]), c(0, lat_lim[2])))
xlim <- corner[1:2, 1]; ylim <- corner[3:4, 2]
nx <- 1500L
ny <- as.integer(round(nx * diff(ylim) / diff(xlim)))
cell_of <- function(xy) {
  i <- floor((xy[, 1] - xlim[1]) / diff(xlim) * nx)
  j <- floor((xy[, 2] - ylim[1]) / diff(ylim) * ny)
  ifelse(i >= 0 & i < nx & j >= 0 & j < ny, j * nx + i + 1L, NA_integer_)
}

if (!file.exists(cache)) {
  files <- sort(list.files(snapshot, full.names = TRUE))
  files <- files[round(seq(1, length(files), length.out = n_files))]
  grid <- matrix(0, nx * ny, length(groups) + 1L, dimnames = list(NULL, c("all", names(groups))))
  n_records <- 0
  for (k in seq_along(files)) {
    x <- vectra::collect(vectra::select(vectra::tbl_parquet(files[k]), species,
                                        decimallongitude, decimallatitude))
    f <- flag_occurrences(x, tests = tests)
    f <- f[!f$flag_invalid, , drop = FALSE]
    n_records <- n_records + nrow(f)
    cell <- cell_of(sf_project("EPSG:4326", crs_ee,
                               cbind(f$decimallongitude, f$decimallatitude), keep = TRUE))
    grid[, "all"] <- grid[, "all"] + tabulate(cell, nx * ny)
    group <- rep(NA_integer_, nrow(f))
    for (g in seq_along(groups))
      group[has_flag(f, groups[[g]]$tests)] <- g
    for (g in seq_along(groups))
      grid[, g + 1L] <- grid[, g + 1L] + tabulate(cell[group %in% g], nx * ny)
    cat(sprintf("%d/%d %s: %s records\n", k, length(files), basename(files[k]),
                format(nrow(f), big.mark = ",")))
  }
  dir.create(dirname(cache), showWarnings = FALSE)
  saveRDS(list(grid = grid, n_records = n_records, files = basename(files),
               reference = reference_info()), cache)
}
hero <- readRDS(cache)
grid <- hero$grid

share <- colSums(grid[, names(groups)]) / hero$n_records * 100
cat(sprintf("%s records from %d files\n", format(hero$n_records, big.mark = ","), length(hero$files)))
print(round(share, 2))

# Drawn in pixel units of the counting grid, so the raster is regular.
px <- expand.grid(x = seq_len(nx) - 0.5, y = seq_len(ny) - 0.5)

# All records as one image: grey by log count, white where there are none.
# Grid row 1 is the bottom of the frame, image row 1 the top.
v <- log10(grid[, "all"])
ramp <- grDevices::colorRampPalette(c("#e4e4e4", "#5a5a5a"))(100)
shade <- ifelse(is.finite(v), ramp[pmax(1L, ceiling(v / max(v[is.finite(v)]) * 100))], "#ffffff")
density <- matrix(shade, ny, nx, byrow = TRUE)[ny:1, ]

# Flagged records as dots sized by count, so a pile at one capital stays
# visible at phone width.
flagged <- do.call(rbind, lapply(names(groups), function(g) {
  n <- grid[, g]
  d <- px[n > 0, c("x", "y")]
  d$n <- n[n > 0]
  d$group <- g
  d
}))
flagged$group <- factor(flagged$group, names(groups))
flagged <- flagged[order(flagged$group, flagged$n), ]

# Shares written in open ocean on two short lines, placed as fractions of the
# frame (x from the left, y from the bottom), large enough for phone width.
label_at <- rbind(institution = c(0.098, 0.665), zero = c(0.115, 0.30), centroid = c(0.67, 0.10))
key <- data.frame(
  x = label_at[names(groups), 1] * nx,
  y = label_at[names(groups), 2] * ny,
  group = factor(names(groups), names(groups)),
  label = sprintf("%s
%s %%", vapply(groups, `[[`, "", "label"),
                  sprintf(ifelse(share[names(groups)] < 1, "%.2f", "%.1f"), share[names(groups)]))
)

cols <- vapply(groups, `[[`, "", "colour")
p <- ggplot() +
  annotation_raster(density, 0, nx, 0, ny, interpolate = FALSE) +
  geom_point(data = flagged, aes(x, y, colour = group, size = n), alpha = 0.75) +
  scale_size_area(max_size = 2.6, trans = "sqrt", guide = "none") +
  geom_text(data = key, aes(x, y, label = label, colour = group), size = 11,
            fontface = "bold", hjust = 0.5, lineheight = 0.85) +
  scale_colour_manual(values = cols, guide = "none") +
  coord_equal(xlim = c(0, nx), ylim = c(0, ny), expand = FALSE) +
  theme_void() +
  theme(plot.background = element_rect(fill = "white", colour = NA),
        plot.margin = margin(8, 8, 8, 8))

height <- 6
width <- height * nx / ny
ggsave("man/figures/OccurrenceCleaner-hero.png", p, width = width, height = height, dpi = 120,
       bg = "white", device = ragg::agg_png)
