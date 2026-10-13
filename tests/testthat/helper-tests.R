# The tests clean_coordinates() runs by default in CoordinateCleaner 3.0.1
# that need only coordinates and a species name.
cc_default <- c("invalid", "zero", "equal", "capital", "centroid", "institution",
                "gbif_headquarters", "sea", "duplicate")

# flag_occurrences() on a data frame with one and with two threads: the flags
# must agree, and the one-thread result is returned.
flag_threads <- function(...) {
  one <- flag_occurrences(..., n_threads = 1)
  two <- flag_occurrences(..., n_threads = 2)
  testthat::expect_identical(two$flags, one$flags)
  one
}
