#' Convert flags to CoordinateCleaner's spatialvalid format
#'
#' Returns flagged records in the layout that [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)'s
#' `clean_coordinates()` and `clean_fossils()` return with
#' `value = "spatialvalid"`, so code written for that object (its `summary()`
#' and `plot()` methods, filters on `.summary`) runs unchanged. The record
#' columns come first, then one logical column per test, `TRUE` when the
#' record passes, then `.summary`, `TRUE` when it passes every test given.
#'
#' Each test takes the column name CoordinateCleaner uses for it (`.cap` for
#' `capital`, `.otl` for `outlier`, see the `spatialvalid` column of
#' [flag_tests()]); a test without one there is written as `.<test>`, for
#' example `.issue_coordinate`. The columns are decoded from the `flags` word,
#' so a record whose flag word is `NA` is `NA` in every column.
#'
#' @param x A flagged data frame (`occ_flags`) from [flag_occurrences()], or
#'   flags written to disk (an `occ_flagged` object or its directory). Flags on
#'   disk are read into memory with their `keep` columns as the record
#'   columns.
#' @param tests Tests to include, from those `x` was flagged with; default all
#'   of them. `.summary` is then the complement of the rule made of these
#'   tests.
#' @return A data frame of class `c("spatialvalid", "data.frame")`, carrying
#'   the reference and layout version of the flags as attributes
#'   `occ_reference` and `occ_layout_version`.
#' @seealso [flag_occurrences()], [has_flag()]
#' @examples
#' x <- data.frame(species = c("a", "a", "b"),
#'                 decimalLongitude = c(0, 16.37, 10),
#'                 decimalLatitude = c(0, 48.21, 50))
#' sv <- as_spatialvalid(flag_occurrences(x))
#' sv
#' sv[sv$.summary, ]
#' @export
as_spatialvalid <- function(x, tests = NULL) {
  if (inherits(x, "occ_flags")) {
    run <- attr(x, "occ_tests")
    stamp <- list(reference = attr(x, "occ_reference"), layout = attr(x, "occ_layout_version"))
    records <- as.data.frame(unclass(x), stringsAsFactors = FALSE, optional = TRUE)
    row.names(records) <- row.names(x)
  } else if (inherits(x, "occ_flagged") || is.character(x)) {
    m <- read_flagged(x)
    run <- m$tests
    stamp <- list(reference = m$reference, layout = m$layout_version)
    records <- as.data.frame(vectra::collect(flagged_table(m)), stringsAsFactors = FALSE,
                             optional = TRUE)
  } else {
    stop("`x` must be flagged records from flag_occurrences(): a data frame, an occ_flagged object or its directory")
  }
  tests <- if (is.null(tests)) run else check_tests(tests)
  missing <- setdiff(tests, run)
  if (length(missing)) stop("`x` was not flagged with: ", paste(missing, collapse = ", "))
  layout <- .flag_layout[.flag_layout$test %in% tests, ]
  cols <- ifelse(is.na(layout$spatialvalid), paste0(".", layout$test), layout$spatialvalid)
  flags <- records$flags
  out <- records[setdiff(names(records), c("flags", paste0("flag_", .test_names)))]
  pass <- lapply(layout$test, function(t) !has_flag(flags, t))
  names(pass) <- cols
  out[cols] <- pass
  out$.summary <- if (length(tests)) !has_flag(flags, tests) else rep(TRUE, nrow(out))
  attr(out, "occ_reference") <- stamp$reference
  attr(out, "occ_layout_version") <- stamp$layout
  class(out) <- c("spatialvalid", "data.frame")
  out
}
