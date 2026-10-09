test_that("flag layout is versioned and consistent", {
  ft <- flag_tests()
  expect_s3_class(ft, "data.frame")
  expect_identical(attr(ft, "layout_version"), 1L)
  expect_identical(ft$bit, seq_len(nrow(ft)) - 1L)
  expect_false(anyDuplicated(ft$test) > 0)
  expect_true(all(ft$source %in% c("CoordinateCleaner", "OccurrenceCleaner")))
  cc <- ft$source == "CoordinateCleaner"
  expect_true(all(startsWith(ft$equivalent[cc], "cc_")))
  expect_true(all(is.na(ft$equivalent[!cc])))
  expect_true(all(default_tests() %in% ft$test))
})

test_that("flag_mask and has_flag follow the layout", {
  expect_identical(flag_mask("val"), 1L)
  expect_identical(flag_mask(c("val", "zero")), 3L)
  expect_identical(flag_mask("cap"), bitwShiftL(1L, 3L))
  expect_identical(has_flag(c(0L, 8L, 16L, 24L, NA), c("cap", "cen")), c(FALSE, TRUE, TRUE, TRUE, NA))
  expect_error(flag_mask("nope"), "unknown test")
  expect_error(flag_mask(NA_character_), "character vector")
})

test_that("occ_columns validates names", {
  c1 <- occ_columns(lon = "x", lat = "y")
  expect_s3_class(c1, "occ_columns")
  expect_identical(c1$lon, "x")
  expect_identical(c1$species, "species")
  expect_error(occ_columns(lon = ""), "non-empty")
  expect_error(occ_columns(lat = c("a", "b")), "single")
})

test_that("column resolution is exact first, then case-insensitive", {
  cols <- occ_columns()
  r <- resolve_columns(cols, c("decimallongitude", "decimallatitude", "species"), c("lon", "lat"))
  expect_identical(r$lon, "decimallongitude")
  r <- resolve_columns(cols, c("decimalLongitude", "decimallongitude", "decimalLatitude"), c("lon", "lat"))
  expect_identical(r$lon, "decimalLongitude")
  expect_error(resolve_columns(cols, c("Species", "SPECIES"), "species"), "not found")
  expect_error(resolve_columns(cols, c("x", "y"), c("lon")), "set it with occ_columns")
  expect_identical(resolve_columns(cols, "x", "id", optional = "id"), list())
})
