test_that("age_equal flags equal and inverted age ranges", {
  x <- data.frame(min_ma = c(10, 20, 30, NA, "5"), max_ma = c(20, 20, 25, 10, "7"))
  f <- flag_occurrences(x, tests = "age_equal")
  expect_identical(f$flag_age_equal, c(FALSE, TRUE, TRUE, FALSE, FALSE))
  g <- flag_occurrences(data.frame(lo = 3, hi = 3), tests = "age_equal",
                        columns = occ_columns(min_age = "lo", max_age = "hi"))
  expect_true(g$flag_age_equal)
  expect_error(flag_occurrences(data.frame(a = 1), tests = "age_equal"), "min_ma")
})

test_that("age_equal matches cf_equal", {
  skip_if_not_installed("CoordinateCleaner")
  set.seed(9)
  lo <- round(runif(1000, 0, 100))
  x <- data.frame(min_ma = lo, max_ma = lo + sample(c(-5, 0, 0, 3, 20), 1000, TRUE))
  theirs <- !suppressMessages(CoordinateCleaner::cf_equal(x, value = "flagged", verbose = FALSE))
  expect_identical(flag_occurrences(x, tests = "age_equal")$flag_age_equal, theirs)
})
