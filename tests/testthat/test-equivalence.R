# Equivalence to CoordinateCleaner 3.0.1, test by test, with
# reference = "CoordinateCleaner" so both read the same gazetteers. Every
# mismatch must be one of the documented differences (see ?flag_occurrences):
#
#  * proximity tests: CoordinateCleaner buffers are inscribed polygons (72
#    vertices for cap/cen/gbif, 40 for inst), so it may miss records between
#    r*cos(pi/n) and r from the reference point; it never flags more.
#  * zero: CoordinateCleaner 3.0.1 applies 0.5 m instead of 0.5 degrees.

skip_if_not_installed("CoordinateCleaner")
skip_if_not_installed("geosphere")

cc <- function(fn, x, ...) !suppressWarnings(suppressMessages(fn(x, value = "flagged", verbose = FALSE, ...)))

# Records around a gazetteer: random points in the annulus 0.5 r .. 1.5 r
# around sampled reference points, plus points far away.
around <- function(ref, r, n, seed) {
  set.seed(seed)
  i <- sample(nrow(ref), n, TRUE)
  p <- geosphere::destPoint(as.matrix(ref[i, c("lon", "lat")]), runif(n, 0, 360), runif(n, 0.5 * r, 1.5 * r))
  far <- cbind(runif(n / 4, -180, 180), runif(n / 4, -60, 70))
  data.frame(species = "sp", decimalLongitude = c(p[, 1], far[, 1]), decimalLatitude = c(p[, 2], far[, 2]))
}

check_proximity <- function(test, fn, r, sides, n = 3000, seed = 1, ...) {
  ref <- OccurrenceCleaner:::point_gazetteer(test, "CoordinateCleaner")
  ref <- ref[is.finite(ref$lon) & is.finite(ref$lat), ]
  x <- around(ref, r, n, seed)
  ours <- flag_occurrences(x, tests = test, reference = "CoordinateCleaner")[[paste0("flag_", test)]]
  theirs <- cc(fn, x, ...)
  # everything CoordinateCleaner flags, we flag
  expect_true(all(ours[theirs]), info = test)
  # our extra flags lie in the inscribed-polygon band
  extra <- which(ours & !theirs)
  if (length(extra)) {
    nn <- OccurrenceCleaner:::cpp_point_nearest(OccurrenceCleaner:::point_index(test, "CoordinateCleaner"),
                                                x$decimalLongitude[extra], x$decimalLatitude[extra])
    d <- nn$distance_m
    expect_true(all(d >= r * cos(pi / sides) * (1 - 1e-6) & d <= r * (1 + 1e-9)), info = test)
  }
  c(n = nrow(x), flagged_cc = sum(theirs), flagged_ours = sum(ours), band = length(extra))
}

test_that("cap matches cc_cap up to the 72-gon band", {
  s <- check_proximity("cap", CoordinateCleaner::cc_cap, 10000, 72)
  expect_gt(s[["flagged_cc"]], 0)
})

test_that("cen matches cc_cen up to the 72-gon band", {
  s <- check_proximity("cen", CoordinateCleaner::cc_cen, 1000, 72)
  expect_gt(s[["flagged_cc"]], 0)
})

test_that("inst matches cc_inst up to the 40-gon band", {
  s <- check_proximity("inst", CoordinateCleaner::cc_inst, 100, 40)
  expect_gt(s[["flagged_cc"]], 0)
})

test_that("gbif matches cc_gbif up to the 72-gon band", {
  s <- check_proximity("gbif", CoordinateCleaner::cc_gbif, 1000, 72, n = 400)
  expect_gt(s[["flagged_cc"]], 0)
})

test_that("val, equ and dupl match exactly", {
  set.seed(4)
  n <- 2000
  x <- data.frame(species = sample(c("a", "b"), n, TRUE),
                  decimalLongitude = c(runif(n - 6, -200, 200), NA, 0, 10, -10, 180, 5),
                  decimalLatitude = c(runif(n - 6, -100, 100), 1, 0, 10, 10, -90, 5))
  x[sample(n, 200), c("decimalLongitude", "decimalLatitude", "species")] <- x[sample(n, 200), c("decimalLongitude", "decimalLatitude", "species")]
  f <- flag_occurrences(x, tests = c("val", "equ", "dupl"))
  expect_identical(f$flag_val, cc(CoordinateCleaner::cc_val, x))
  ok <- !f$flag_val
  expect_identical(f$flag_equ[ok], cc(CoordinateCleaner::cc_equ, x[ok, ]))
  expect_identical(f$flag_dupl[ok], cc(CoordinateCleaner::cc_dupl, x[ok, ]))
  expect_identical(flag_occurrences(x[ok, ], tests = "dupl", dupl_by = "species")$flag_dupl,
                   cc(CoordinateCleaner::cc_dupl, x[ok, ], additions = "species"))
})

test_that("zero matches cc_zero outside the 0.5 degree disc", {
  set.seed(6)
  x <- data.frame(species = "a", decimalLongitude = c(runif(500, -2, 2), 0, 0, 3, 0.2),
                  decimalLatitude = c(runif(500, -2, 2), 0, 7, 0, 0.1))
  f <- flag_occurrences(x, tests = "zero")
  theirs <- cc(CoordinateCleaner::cc_zero, x)
  disc <- sqrt(x$decimalLongitude^2 + x$decimalLatitude^2) <= 0.5
  expect_identical(f$flag_zero[!disc], theirs[!disc])
  expect_true(all(f$flag_zero[disc]))
  expect_true(all(f$flag_zero[theirs]))
})

test_that("sea, urb and coun match CoordinateCleaner on its Natural Earth layers", {
  skip_if_not_installed("rnaturalearth")
  skip_if_offline()
  set.seed(7)
  n <- 1500
  x <- data.frame(species = "a", decimalLongitude = runif(n, -180, 180), decimalLatitude = runif(n, -60, 75))
  # coastal emphasis: points near the 1:110m land vertices
  L <- OccurrenceCleaner:::ref_land_110
  i <- sample(length(L$x), 1500)
  near <- geosphere::destPoint(cbind(L$x[i] / 1e7, L$y[i] / 1e7), runif(1500, 0, 360), runif(1500, 10, 20000))
  x <- rbind(x, data.frame(species = "a", decimalLongitude = near[, 1], decimalLatitude = near[, 2]))
  x$countrycode <- sample(c("FRA", "DEU", "BRA", "USA", NA), nrow(x), TRUE)

  f <- flag_occurrences(x, tests = c("sea", "urb"), reference = "CoordinateCleaner")
  sea <- cc(CoordinateCleaner::cc_sea, x)
  expect_identical(f$flag_sea, sea)
  urb <- cc(CoordinateCleaner::cc_urb, x)
  expect_identical(f$flag_urb, urb)

  f <- flag_occurrences(x, tests = "coun", reference = "CoordinateCleaner", columns = occ_columns(country = "countrycode"))
  coun <- cc(CoordinateCleaner::cc_coun, x, iso3 = "countrycode")
  expect_identical(f$flag_coun, coun)
})

test_that("own gazetteers flag the same records as CoordinateCleaner's at the same points", {
  # Not an equivalence claim (the gazetteers differ, see dev_notes); a smoke
  # check that the default reference runs and flags capitals and GBIF HQ.
  x <- data.frame(species = "a", decimalLongitude = c(2.3522, 12.58, 16.3738), decimalLatitude = c(48.8566, 55.67, 48.2082))
  f <- flag_occurrences(x, tests = c("cap", "gbif"))
  expect_identical(f$flag_cap, c(TRUE, TRUE, TRUE))
  expect_identical(f$flag_gbif, c(FALSE, TRUE, FALSE))
})
