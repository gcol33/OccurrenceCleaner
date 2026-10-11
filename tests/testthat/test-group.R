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

test_that("outlier matches cc_outl on the exact path for every method", {
  skip_if_not_installed("CoordinateCleaner")
  x <- species_data()
  for (m in c("quantile", "mad", "distance")) {
    ours <- flag_occurrences(x, tests = "outlier", settings = list(outlier = list(method = m)))$flag_outlier
    expect_identical(ours, cc(CoordinateCleaner::cc_outl, x, method = m), info = m)
  }
  # species with fewer than min_occs distinct points are not tested
  expect_false(any(flag_occurrences(x, tests = "outlier")$flag_outlier[x$species == "c"]))
})

test_that("the raster approximation flags the records of outlier cells", {
  set.seed(1)
  n <- 12000
  x <- data.frame(species = "a", decimalLongitude = c(runif(n - 20, 10, 20), runif(20, 120, 130)),
                  decimalLatitude = c(runif(n - 20, 40, 50), runif(20, -30, -20)))
  f <- flag_occurrences(x, tests = "outlier")$flag_outlier
  expect_identical(which(f), (n - 19):n)
  # CoordinateCleaner 3.0.1 computes the same cell statistics but its mapping
  # from flagged cells back to records returns no records.
  skip_if_not_installed("CoordinateCleaner")
  skip_on_cran()
  expect_false(any(cc(CoordinateCleaner::cc_outl, x)))
})

test_that("raster cell statistics follow the terra grid and geosphere distances", {
  skip_if_not_installed("terra")
  skip_if_not_installed("geosphere")
  x <- species_data()
  x <- x[x$species == "a", ]
  s <- check_settings(list(outlier = list(thinning = TRUE)))$outlier
  ext <- c(range(x$decimalLongitude), range(x$decimalLatitude))
  grid <- OccurrenceCleaner:::outlier_grid(ext, s$thinning_res)
  ras <- terra::rast(terra::ext(ext[1], ext[2], ext[3], ext[4]) + 2 * s$thinning_res, resolution = s$thinning_res)
  expect_equal(c(grid$nrow, grid$ncol), c(terra::nrow(ras), terra::ncol(ras)))
  cid <- OccurrenceCleaner:::grid_cell(grid, x$decimalLongitude, x$decimalLatitude)
  expect_identical(as.numeric(cid), as.numeric(terra::cellFromXY(ras, cbind(x$decimalLongitude, x$decimalLatitude))))
  tb <- table(cid)
  cells <- as.numeric(names(tb))
  xy <- terra::xyFromCell(ras, cells)
  d <- geosphere::distm(xy, fun = geosphere::distHaversine) / 1000
  d[d == 0] <- NA
  expect_equal(OccurrenceCleaner:::cpp_cell_dist(xy[, 1], xy[, 2], as.numeric(tb), FALSE, 25)$mean,
               rowMeans(d, na.rm = TRUE))
  w <- outer(as.numeric(tb), as.numeric(tb))
  dw <- geosphere::distm(xy, fun = geosphere::distHaversine) / 1000
  dw[dw == 0] <- 100 * mean(terra::res(ras)) / 2
  expect_equal(OccurrenceCleaner:::cpp_cell_dist(xy[, 1], xy[, 2], as.numeric(tb), TRUE,
                                                 100 * mean(terra::res(ras)) / 2)$mean,
               rowSums(round(dw * w)) / rowSums(w))
})

test_that("age_range_outlier matches cf_range at taxon level", {
  skip_if_not_installed("CoordinateCleaner")
  f <- fossil_data()
  for (m in c("quantile", "mad")) {
    ours <- flag_occurrences(f, tests = "age_range_outlier", columns = fossil_cols,
                             settings = list(age_range_outlier = list(method = m)))$flag_age_range_outlier
    expect_identical(ours, cc(CoordinateCleaner::cf_range, f, lon = "lng", lat = "lat", method = m), info = m)
  }
})

test_that("age_outlier and spatiotemporal_outlier match cf_age and cf_outl when no age is drawn", {
  skip_if_not_installed("CoordinateCleaner")
  f <- fossil_data()
  f$max_ma <- f$min_ma
  f$min_ma[1:3] <- f$max_ma[1:3] <- c(200, 210, 190)
  f$lng[4:5] <- 150
  expect_identical(flag_occurrences(f, tests = "age_outlier", columns = fossil_cols)$flag_age_outlier,
                   cc(CoordinateCleaner::cf_age, f, lon = "lng", lat = "lat"))
  expect_identical(flag_occurrences(f, tests = "spatiotemporal_outlier", columns = fossil_cols)$flag_spatiotemporal_outlier,
                   cc(CoordinateCleaner::cf_outl, f, lon = "lng", lat = "lat"))
})

test_that("random age draws are seeded per taxon and do not depend on the input order", {
  f <- fossil_data()
  f$occurrence_no <- seq_len(nrow(f))
  cols <- occ_columns(lon = "lng", lat = "lat", species = "accepted_name", id = "occurrence_no")
  tests <- c("age_outlier", "spatiotemporal_outlier")
  a <- flag_occurrences(f, tests = tests, columns = cols)
  b <- flag_occurrences(f, tests = tests, columns = cols)
  expect_identical(a$flags, b$flags)
  sh <- sample(nrow(f))
  c2 <- flag_occurrences(f[sh, ], tests = tests, columns = cols)
  expect_identical(c2$flags[order(c2$occurrence_no)], a$flags)
  set.seed(99); r1 <- runif(1)
  set.seed(99); invisible(flag_occurrences(f, tests = tests, columns = cols)); r2 <- runif(1)
  expect_identical(r1, r2)
  expect_true(any(a$flag_age_outlier))
})

test_that("dataset_ddmm and dataset_rounded match cd_ddmm and cd_round", {
  skip_if_not_installed("CoordinateCleaner")
  set.seed(2)
  y <- data.frame(datasetKey = rep(c("big", "ddmm", "grid"), c(400, 400, 400)),
                  decimalLongitude = c(runif(400, 0, 20), floor(runif(400, 0, 20)) + sample(0:59, 400, TRUE) / 100,
                                       round(runif(400, 0, 20) * 2) / 2 + 0.01),
                  decimalLatitude = c(runif(400, 0, 20), floor(runif(400, 0, 20)) + sample(0:59, 400, TRUE) / 100,
                                      round(runif(400, 30, 50) * 2) / 2 + 0.01))
  f <- flag_occurrences(y, tests = c("dataset_ddmm", "dataset_rounded"))
  expect_identical(f$flag_dataset_ddmm, cc(CoordinateCleaner::cd_ddmm, y, ds = "datasetKey"))
  expect_identical(f$flag_dataset_rounded, cc(CoordinateCleaner::cd_round, y, ds = "datasetKey", graphs = FALSE))
  expect_identical(c(tapply(f$flag_dataset_ddmm, y$datasetKey, all)), c(big = FALSE, ddmm = TRUE, grid = TRUE))
})

test_that("histogram counts equal graphics::hist", {
  set.seed(5)
  v <- abs(c(runif(500, 0, 30), round(runif(300, 0, 30), 1)))
  b <- OccurrenceCleaner:::act_breaks(range(v))
  expect_identical(OccurrenceCleaner:::bin_counts(v, b), graphics::hist(v, breaks = 3000, plot = FALSE)$counts)
})

test_that("rounding kernels equal stats::cov and the windowed quantile fence", {
  set.seed(6)
  f <- c(rpois(400, 3), rep(c(0L, 0L, 9L), 300))
  mr <- round(length(f) * 0.9)
  gam <- vapply(seq_len(mr), function(k) stats::cov(f[-(1:k)], f[-((length(f) - k + 1):length(f))]), 0)
  expect_identical(OccurrenceCleaner:::cpp_lag_cov(as.numeric(f), mr), gam)
  gam <- gam / stats::var(f[1:mr])
  hits <- numeric(0); at <- integer(0)
  for (k in seq_len(mr - 10)) {
    sub <- gam[k:(k + 10)]
    hits <- c(hits, sub > stats::quantile(sub, 0.75, names = FALSE) + stats::IQR(sub) * 3)
    at <- c(at, k:(k + 10))
  }
  expect_identical(OccurrenceCleaner:::cpp_window_outlier_counts(gam, 10L, 3),
                   as.integer(tapply(hits, at, sum)))
})

test_that("small datasets and records without a dataset are not flagged", {
  y <- data.frame(datasetKey = c(rep("small", 3), rep(NA, 5)), decimalLongitude = c(1.1, 2.2, 3.3, 1:5),
                  decimalLatitude = c(1.1, 2.2, 3.3, 1:5))
  f <- flag_occurrences(y, tests = c("dataset_ddmm", "dataset_rounded"))
  expect_false(any(f$flag_dataset_rounded))
  expect_false(any(f$flag_dataset_ddmm[is.na(y$datasetKey)]))
})

test_that("range matches cc_iucn, with and without a buffer", {
  skip_if_not_installed("CoordinateCleaner")
  skip_if_not_installed("sf")
  x <- species_data()
  rg <- sf::st_sf(species = c("a", "b"), geometry = sf::st_sfc(
    sf::st_polygon(list(rbind(c(5, 45), c(15, 45), c(15, 55), c(5, 55), c(5, 45)))),
    sf::st_polygon(list(rbind(c(-70, -20), c(-50, -20), c(-50, 0), c(-70, 0), c(-70, -20)))), crs = 4326))
  expect_identical(flag_occurrences(x, tests = "range", gazetteers = list(range = rg))$flag_range,
                   cc(CoordinateCleaner::cc_iucn, x, range = rg))
  expect_identical(flag_occurrences(x, tests = "range", gazetteers = list(range = rg),
                                    buffers = list(range = 100000))$flag_range,
                   cc(CoordinateCleaner::cc_iucn, x, range = rg, buffer = 100000))
  # species without a range polygon are not flagged
  expect_false(any(flag_occurrences(x, tests = "range", gazetteers = list(range = rg))$flag_range[x$species == "c"]))
  expect_error(flag_occurrences(x, tests = "range"), "range polygons")
})

test_that("aohi matches cc_aohi up to the 72-gon band", {
  skip_if_not_installed("CoordinateCleaner")
  skip_if_not_installed("geosphere")
  set.seed(6)
  a <- reference_points("aohi", "CoordinateCleaner")
  p <- geosphere::destPoint(as.matrix(a[sample(nrow(a), 400, TRUE), ]), runif(400, 0, 360), runif(400, 5000, 15000))
  z <- data.frame(species = "a", decimalLongitude = p[, 1], decimalLatitude = p[, 2])
  ours <- flag_occurrences(z, tests = "aohi", reference = "CoordinateCleaner")$flag_aohi
  theirs <- cc(CoordinateCleaner::cc_aohi, z)
  expect_true(all(ours[theirs]))
  extra <- which(ours & !theirs)
  if (length(extra)) {
    d <- apply(geosphere::distm(cbind(z$decimalLongitude[extra], z$decimalLatitude[extra]), as.matrix(a)), 1, min)
    expect_true(all(d >= 10000 * cos(pi / 72) * (1 - 1e-3)))
  }
  expect_gt(nrow(reference_points("aohi")), 300)
})

test_that("group tests give the same flags on streamed input as on a data frame", {
  x <- species_data()
  x$datasetKey <- sample(c("d1", "d2"), nrow(x), TRUE)
  x$min_ma <- round(runif(nrow(x), 10, 30))
  x$max_ma <- x$min_ma + sample(c(1, 2, 40), nrow(x), TRUE, c(.5, .45, .05))
  x$gbifID <- as.character(seq_len(nrow(x)))
  x <- x[sample(nrow(x)), ]
  tests <- c("invalid", "outlier", "age_outlier", "spatiotemporal_outlier", "age_range_outlier",
             "dataset_ddmm", "dataset_rounded")
  df <- flag_occurrences(x, tests = tests)
  src <- tempfile(); dir.create(src)
  for (i in 1:3) vectra::write_vtr(x[seq(i, nrow(x), 3), ], file.path(src, sprintf("p%d.vtr", i)))
  out <- tempfile()
  o <- flag_occurrences(src, tests = tests, out = out, verbose = FALSE)
  s <- as.data.frame(vectra::collect(flagged_table(o)))
  expect_identical(s$flags[match(df$gbifID, s$gbifID)], df$flags)
  expect_true(file.exists(file.path(out, "group_result.rds")))
  expect_false(dir.exists(file.path(out, ".group")))
})

test_that("settings are validated", {
  x <- species_data()
  expect_error(flag_occurrences(x, tests = "outlier", settings = list(nope = list())), "no entry")
  expect_error(flag_occurrences(x, tests = "outlier", settings = list(outlier = list(meth = "mad"))), "no entry")
  expect_error(flag_occurrences(x, tests = "outlier", settings = list(outlier = list(method = "x"))), "must be one of")
  expect_error(flag_occurrences(x, tests = "outlier", settings = list(outlier = list(mltpl = "a"))), "single number")
})

test_that("the sampling correction keeps outliers only in well-sampled countries", {
  set.seed(1)
  x <- rbind(data.frame(species = "a", decimalLongitude = rnorm(200, 10, 1), decimalLatitude = rnorm(200, 50, 1)),
             data.frame(species = "a", decimalLongitude = c(2.35, 37.6), decimalLatitude = c(48.86, 55.75)))
  expect_identical(which(flag_occurrences(x, tests = "outlier")$flag_outlier), 201:202)
  tab <- data.frame(country = c("FR", "RU", "DE", "AT"), records = c(5e7, 1e5, 6e7, 1e7))
  f <- flag_occurrences(x, tests = "outlier", gazetteers = list(sampling = tab),
                        settings = list(outlier = list(sampling_thresh = 0.25)))
  expect_identical(which(f$flag_outlier), 201L)
  expect_match(attr(f, "occ_reference"), "sampling 4 countries")
  expect_error(flag_occurrences(x, tests = "outlier", settings = list(outlier = list(sampling_thresh = 0.25))),
               "records per country")
})

test_that("country areas are close to the surveyed areas", {
  a <- OccurrenceCleaner:::country_areas_km2(OccurrenceCleaner:::polygon_layer("country_mismatch", "OccurrenceCleaner", 110))
  expect_equal(unname(a["AT"]), 83879, tolerance = 0.01)
  expect_equal(unname(a["DE"]), 357022, tolerance = 0.01)
  expect_lt(unname(a["ZA"]), 1221037 * 1.01)
})
