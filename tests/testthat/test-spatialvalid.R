recs <- function() {
  data.frame(species = c("a", "a", "b", "b"),
             decimalLongitude = c(0, 16.37, 10, 10),
             decimalLatitude = c(0, 48.21, 50, 50))
}

test_that("as_spatialvalid writes CoordinateCleaner's column names, TRUE for pass", {
  x <- recs()
  f <- flag_occurrences(x, tests = cc_default)
  sv <- as_spatialvalid(f)
  expect_s3_class(sv, c("spatialvalid", "data.frame"), exact = TRUE)
  expect_identical(names(sv), c(names(x), ".val", ".zer", ".equ", ".cap", ".cen", ".inst", ".gbf",
                                ".sea", ".dpl", ".summary"))
  expect_identical(sv$.cap, !f$flag_capital)
  expect_identical(sv$.dpl, !f$flag_duplicate)
  expect_identical(sv$.summary, !has_flag(f$flags, cc_default))
  expect_identical(attr(sv, "occ_reference"), attr(f, "occ_reference"))
})

test_that("as_spatialvalid takes a subset of the tests and names additions by test", {
  x <- recs()
  x$issue <- c("ZERO_COORDINATE", "", "", "")
  f <- flag_occurrences(x, tests = c("zero", "capital", "issue_coordinate"))
  sv <- as_spatialvalid(f, tests = c("capital", "issue_coordinate"))
  expect_identical(names(sv), c(names(x), ".cap", ".issue_coordinate", ".summary"))
  expect_identical(sv$.summary, !has_flag(f$flags, c("capital", "issue_coordinate")))
  expect_error(as_spatialvalid(f, tests = "sea"), "not flagged with: sea")
  expect_error(as_spatialvalid(x), "flagged records")
})

test_that("as_spatialvalid reads flags written to disk", {
  src <- tempfile("src")
  dir.create(src)
  out <- tempfile("flags")
  on.exit(unlink(c(src, out), recursive = TRUE), add = TRUE)
  x <- recs()
  vectra::write_vtr(x, file.path(src, "a.vtr"))
  m <- flag_occurrences(src, tests = c("zero", "capital"), out = out, keep = "species", verbose = FALSE)
  sv <- as_spatialvalid(out)
  expect_identical(names(sv), c("species", ".zer", ".cap", ".summary"))
  expect_identical(sv$.summary, !has_flag(flag_occurrences(x, tests = c("zero", "capital"))$flags,
                                          c("zero", "capital")))
})

test_that("as_spatialvalid matches clean_coordinates(value = 'spatialvalid')", {
  skip_if_not_installed("CoordinateCleaner")
  set.seed(4)
  n <- 500
  x <- data.frame(species = sample(c("a", "b"), n, TRUE),
                  decimalLongitude = c(runif(n - 4, -170, 170), 0, 10, -10, 5),
                  decimalLatitude = c(runif(n - 4, -80, 80), 0, 10, 10, 5))
  x[sample(n, 50), ] <- x[sample(n, 50), ]
  row.names(x) <- NULL
  theirs <- suppressWarnings(suppressMessages(
    CoordinateCleaner::clean_coordinates(x, tests = c("equal", "duplicates"), verbose = FALSE)))
  ours <- as_spatialvalid(flag_occurrences(x, tests = c("invalid", "equal", "duplicate")))
  expect_setequal(names(ours), names(theirs))
  for (v in names(theirs)) expect_identical(ours[[v]], theirs[[v]], info = v)
  expect_identical(CoordinateCleaner:::summary.spatialvalid(ours)[names(theirs)[grepl("^\\.", names(theirs))]],
                   CoordinateCleaner:::summary.spatialvalid(theirs))
  skip_if_not_installed("ggplot2")
  for (details in c(FALSE, TRUE)) {
    p_ours <- suppressWarnings(CoordinateCleaner:::plot.spatialvalid(ours, details = details))
    p_theirs <- suppressWarnings(CoordinateCleaner:::plot.spatialvalid(theirs, details = details))
    expect_identical(ggplot2::layer_data(p_ours, 2), ggplot2::layer_data(p_theirs, 2), info = details)
  }
})

test_that("CoordinateCleaner's plot method draws a converted result with additions", {
  skip_if_not_installed("CoordinateCleaner")
  skip_if_not_installed("ggplot2")
  x <- recs()
  x$issue <- c("ZERO_COORDINATE", "", "", "")
  sv <- as_spatialvalid(flag_occurrences(x, tests = c("zero", "capital", "issue_coordinate")),
                        tests = c("capital", "issue_coordinate"))
  p <- suppressWarnings(CoordinateCleaner:::plot.spatialvalid(sv, details = TRUE))
  expect_identical(nrow(ggplot2::layer_data(p, 2)), nrow(x))
  expect_identical(sort(unique(p$layers[[2]]$data$flag)), c("AAAclean", "cap", "issue_coordinate"))
})
