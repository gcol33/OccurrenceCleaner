test_that("reference selects a coastline and explicit scale overrides it", {
  own <- OccurrenceCleaner:::flag_config(tests = "sea")
  cc <- OccurrenceCleaner:::flag_config(tests = "sea", reference = "CoordinateCleaner")
  expect_identical(own$land_scale, 10)
  expect_identical(cc$land_scale, 110)
  for (ref in c("OccurrenceCleaner", "CoordinateCleaner")) {
    for (scale in c(10, 50, 110))
      expect_identical(OccurrenceCleaner:::flag_config(tests = "sea", reference = ref,
                                                       land_scale = scale)$land_scale, scale)
  }
  for (bad in list(numeric(), c(10, 50), NA_real_, "10", 20))
    expect_error(OccurrenceCleaner:::flag_config(tests = "sea", land_scale = bad), "land_scale")
})

test_that("the default coast retains Azores and Reunion land points", {
  x <- data.frame(decimalLongitude = c(-25.5, 55.5, -30), decimalLatitude = c(37.8, -21.1, 40))
  expect_identical(flag_occurrences(x, tests = "sea")$flag_sea, c(FALSE, FALSE, TRUE))
  expect_identical(flag_occurrences(x, tests = "sea", land_scale = 110)$flag_sea, rep(TRUE, 3))
  expect_identical(clean_sea(x), x[1:2, ])
})

test_that("the zero test detects Natural Earth's fictitious Null Island", {
  x <- data.frame(decimalLongitude = c(0, 0.01), decimalLatitude = c(0, 0.01))
  f <- flag_occurrences(x, tests = c("sea", "zero"))
  expect_identical(f$flag_sea, c(FALSE, TRUE))
  expect_true(all(f$flag_zero))
})
