# Extracted from test-group.R:210

# prequel ----------------------------------------------------------------------
cc <- function(fn, x, ...) !suppressWarnings(suppressMessages(fn(x, value = "flagged", verbose = FALSE, ...)))
species_data <- function(seed = 3) {
  set.seed(seed)
  mk <- function(sp, n, lon, lat, sd) data.frame(species = sp, decimalLongitude = rnorm(n, lon, sd),
                                                 decimalLatitude = rnorm(n, lat, sd))
  rbind(mk("a", 300, 10, 50, 2), mk("b", 200, -60, -10, 3), mk("c", 5, 0, 0, 1),
        data.frame(species = c("a", "a", "b"), decimalLongitude = c(80, 100, 20), decimalLatitude = c(-20, 30, 40)))
}
fossil_data <- function(seed = 4) {
  set.seed(seed)
  f <- data.frame(accepted_name = rep(c("A", "B"), c(60, 40)), lng = runif(100, -10, 10), lat = runif(100, 40, 50))
  f$min_ma <- round(runif(100, 10, 30))
  f$max_ma <- f$min_ma + sample(c(1, 2, 3, 40), 100, TRUE, c(.4, .3, .25, .05))
  f
}
fossil_cols <- occ_columns(lon = "lng", lat = "lat", species = "accepted_name")

# test -------------------------------------------------------------------------
x <- species_data()
x$datasetKey <- sample(c("d1", "d2"), nrow(x), TRUE)
x$min_ma <- round(runif(nrow(x), 10, 30))
x$max_ma <- x$min_ma + sample(c(1, 2, 40), nrow(x), TRUE, c(.5, .45, .05))
x$gbifID <- as.character(seq_len(nrow(x)))
x <- x[sample(nrow(x)), ]
tests <- c("invalid", "outlier", "age_outlier", "spatiotemporal_outlier", "age_range_outlier",
             "dataset_ddmm", "dataset_rounded")
df <- flag_occurrences(x, tests = tests)
src <- tempfile()
dir.create(src)
for (i in 1:3) vectra::write_vtr(x[seq(i, nrow(x), 3), ], file.path(src, sprintf("p%d.vtr", i)))
out <- tempfile()
o <- flag_occurrences(src, tests = tests, out = out, verbose = FALSE)
s <- as.data.frame(vectra::collect(flagged_table(o)))
expect_identical(s$flags[match(df$gbifID, s$gbifID)], df$flags)
expect_true(file.exists(file.path(out, "group_result.rds")))
expect_false(dir.exists(file.path(out, ".group")))
