test_that("flags do not depend on the number of threads", {
  set.seed(3)
  n <- 6000
  x <- data.frame(species = sample(sprintf("sp%02d", 1:40), n, TRUE),
                  decimallongitude = c(runif(n - 3, -20, 40), 0, 12.58, 2.35),
                  decimallatitude = c(runif(n - 3, 30, 60), 0, 55.67, 48.85),
                  countrycode = sample(c("AT", "DE", "FR", ""), n, TRUE),
                  issue = sample(c("", "ZERO_COORDINATE;TAXON_MATCH_FUZZY", "COORDINATE_ROUNDED"), n, TRUE))
  tests <- c("invalid", "zero", "capital", "centroid", "institution", "sea", "country_mismatch",
             "issue_coordinate", "issue_taxon", "issue_rounded", "outlier")
  one <- flag_occurrences(x, tests = tests, n_threads = 1)
  four <- flag_occurrences(x, tests = tests, n_threads = 4)
  expect_identical(four$flags, one$flags)
  expect_true(any(one$flag_outlier))
  expect_true(any(one$flag_issue_taxon))
})

test_that("the grouped outlier distances equal one call per species", {
  set.seed(4)
  key <- sample(c("a", "b", "c"), 300, TRUE)
  lon <- runif(300, -10, 10); lat <- runif(300, -10, 10)
  lon[c(5, 9)] <- lon[1]; lat[c(5, 9)] <- lat[1]
  s <- .default_settings$outlier
  got <- outlier_exact(key, lon, lat, s, n_threads = 3)
  want <- logical(300)
  for (k in unique(key)) {
    i <- which(key == k)
    d <- cpp_outlier_dist(lon[i], lat[i], c(0L, length(i)))
    want[i] <- fence_flags(d$mean, s$method, s$mltpl)
  }
  expect_identical(got, want)
  expect_identical(outlier_exact(character(), numeric(), numeric(), s), logical())
})

test_that("a thread request above the OpenMP limit is reduced with a message", {
  cap <- cpp_max_threads()
  expect_identical(resolve_threads(0), cap)
  expect_message(expect_identical(resolve_threads(cap + 1), cap), "requested")
  expect_error(resolve_threads("a"), "single number")
})

test_that("a large species spread over threads by rows gives the same distances", {
  set.seed(5)
  lon <- runif(500, -30, 30); lat <- runif(500, -30, 30)
  lon[10:12] <- lon[1]; lat[10:12] <- lat[1]
  start <- c(0L, 3L, 400L, 500L)
  one <- cpp_outlier_dist(lon, lat, start, n_threads = 1)
  rows <- cpp_outlier_dist(lon, lat, start, n_threads = 4, split_n = 2)
  expect_identical(rows, one)
})
