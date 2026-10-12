x0 <- data.frame(species = "sp", decimalLongitude = c(16.37, 0, 10, 16.51, 2.35),
          decimalLatitude = c(48.21, 0, 10, 48.25, 48.86))

test_that("keep_unflagged() keeps the records no test of the rule flagged", {
  f <- flag_occurrences(x0, tests = c("zero", "equal", "capital"))
  k <- keep_unflagged(f)
  expect_identical(k$decimalLongitude, 16.51)
  expect_identical(nrow(keep_unflagged(f, tests = "zero")), 4L)
  expect_identical(keep_unflagged(f, tests = c("zero", "equal"))$decimalLongitude, c(16.37, 16.51, 2.35))
  # flag columns and attributes survive
  expect_s3_class(k, "occ_flags")
  expect_true(all(c("flags", "flag_zero", "flag_capital") %in% names(k)))
  for (a in c("occ_tests", "occ_reference", "occ_layout_version", "occ_columns"))
    expect_identical(attr(k, a), attr(f, a))
  # the same selection as has_flag()
  expect_identical(keep_unflagged(f, "capital"), f[!has_flag(f, "capital"), ])
})

test_that("keep_unflagged() refuses tests that were not run and input without flags", {
  f <- flag_occurrences(x0, tests = "zero")
  expect_error(keep_unflagged(f, tests = "capital"), "not run")
  expect_error(keep_unflagged(f, tests = "nonsense"), "unknown test")
  expect_error(keep_unflagged(x0), "flag_occurrences")
})

test_that("each test has a cleaning function", {
  ns <- getNamespaceExports("OccurrenceCleaner")
  expect_setequal(grep("^clean_", ns, value = TRUE), paste0("clean_", flag_tests()$test))
})

test_that("cleaning functions take the registry defaults as arguments", {
  expect_identical(formals(clean_capital)$buffer, 10000)
  expect_identical(formals(clean_zero)$buffer, 0.5)
  expect_identical(formals(clean_institution)$buffer, 100)
  expect_identical(formals(clean_outlier)$mltpl, 5)
  expect_identical(formals(clean_outlier)$method, "quantile")
  expect_identical(formals(clean_dataset_rounded)$T1, 7)
  expect_true(all(c("by", "cell") %in% names(formals(clean_duplicate))))
  expect_true(all(c("ranges", "buffer") %in% names(formals(clean_range))))
  expect_identical(names(formals(clean_invalid)), c("x", "..."))
})

test_that("a cleaning function returns the rows of x the test does not flag", {
  k <- clean_capital(x0)
  expect_identical(k, x0[!flag_occurrences(x0, tests = "capital")$flag_capital, ])
  expect_false(inherits(k, "occ_flags"))
  expect_identical(names(k), names(x0))
  # its buffer reaches the test
  expect_identical(nrow(clean_capital(x0, buffer = 20000)), 2L)
  expect_identical(clean_zero(x0, buffer = 0), clean_zero(x0))
  expect_error(clean_capital(x0, tests = "zero"), "runs one test")
})

test_that("a chain of record tests keeps what one flagging call and keep_unflagged() keep", {
  tests <- c("invalid", "zero", "equal", "capital", "centroid", "institution", "gbif_headquarters", "sea")
  chain <- x0 |> clean_invalid() |> clean_zero() |> clean_equal() |> clean_capital() |>
    clean_centroid() |> clean_institution() |> clean_gbif_headquarters() |> clean_sea()
  once <- keep_unflagged(flag_occurrences(x0, tests = tests))
  expect_identical(rownames(chain), rownames(once))
})

test_that("options of a grouped test reach its settings", {
  set.seed(1)
  x <- data.frame(species = "a", decimalLongitude = c(rnorm(50, 10, 1), 13),
                  decimalLatitude = c(rnorm(50, 50, 1), 50))
  for (m in c(5, 1)) {
    f <- flag_occurrences(x, tests = "outlier", settings = list(outlier = list(mltpl = m)))
    expect_identical(clean_outlier(x, mltpl = m), x[!f$flag_outlier, ])
  }
  d <- data.frame(species = "sp", decimalLongitude = c(16.37, 16.37, 16.37), decimalLatitude = 48.21, eventDate = c("a", "b", "a"))
  expect_identical(nrow(clean_duplicate(d)), 1L)
  expect_identical(nrow(clean_duplicate(d, by = "eventDate")), 2L)
})

test_that("cleaning functions take a data frame only", {
  expect_error(clean_zero(tempfile()), "takes a data frame")
})
