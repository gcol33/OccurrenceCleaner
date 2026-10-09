#' The flag layout: one bit per test
#'
#' Every record flagged by [flag_occurrences()] carries an integer flag word in
#' which bit `bit` is set when the record fails test `test`. The layout is
#' versioned: `layout_version` changes whenever a bit is added, removed or
#' redefined, and the flag output records which version produced it.
#'
#' Tests marked `source = "CoordinateCleaner"` reproduce the test of the same
#' name in that package with its default buffer (see the `equivalent` column);
#' the documented differences are listed in [flag_occurrences()]. Tests marked
#' `source = "OccurrenceCleaner"` are additions.
#'
#' @return A data frame with columns `bit` (0-based), `test`, `definition`,
#'   `source`, `equivalent` (the CoordinateCleaner function, or `NA`) and
#'   `needs` (the record fields the test reads, as names of [occ_columns()]).
#'   The attribute `layout_version` holds the layout version.
#' @examples
#' flag_tests()
#' @export
flag_tests <- function() {
  x <- .flag_layout
  attr(x, "layout_version") <- .layout_version
  x
}

.layout_version <- 1L

.flag_layout <- data.frame(
  bit = 0:18,
  test = c("val", "zero", "equ", "cap", "cen", "inst", "gbif", "sea", "urb", "coun", "dupl",
           "issue_geo", "issue_tax", "issue_date", "rounded", "fossil", "living", "introduced",
           "managed"),
  definition = c(
    "coordinate missing, not numeric or outside [-180, 180] x [-90, 90]",
    "longitude or latitude exactly zero, or within 0.5 degrees of (0, 0)",
    "absolute longitude equal to absolute latitude",
    "within 10 km of a country capital",
    "within 1 km of a country or province centroid",
    "within 100 m of a biodiversity institution",
    "within 1 km of the GBIF headquarters (12.58 E, 55.67 N)",
    "outside the land polygons",
    "inside an urban-area polygon",
    "coordinates fall outside the country given by the record's country code",
    "same coordinates and species as an earlier record",
    "a GBIF georeferencing issue is present",
    "GBIF matched the taxon fuzzily or to a higher rank",
    "GBIF found the recorded date invalid or unlikely",
    "GBIF rounded the coordinates (COORDINATE_ROUNDED)",
    "basis of record is a fossil specimen",
    "basis of record is a living specimen",
    "establishment means is introduced, naturalised or invasive",
    "establishment means is managed or cultivated"),
  source = c(rep("CoordinateCleaner", 11), rep("OccurrenceCleaner", 8)),
  equivalent = c("cc_val", "cc_zero", "cc_equ", "cc_cap", "cc_cen", "cc_inst", "cc_gbif", "cc_sea",
                 "cc_urb", "cc_coun", "cc_dupl", rep(NA_character_, 8)),
  needs = c(rep("lon,lat", 9), "lon,lat,country", "lon,lat,species", rep("issue", 4), "basis",
            "basis", "establishment", "establishment"),
  stringsAsFactors = FALSE
)

.test_names <- .flag_layout$test

#' Default tests
#'
#' The tests [flag_occurrences()] runs when `tests` is not given: every
#' CoordinateCleaner-equivalent test that needs only coordinates and a species
#' name. `coun` needs a country code, `urb` is left out as in CoordinateCleaner's
#' `clean_coordinates()`, and the GBIF-field additions need GBIF columns.
#'
#' @return A character vector of test names.
#' @examples
#' default_tests()
#' @export
default_tests <- function() {
  c("val", "zero", "equ", "cap", "cen", "inst", "gbif", "sea", "dupl")
}

#' Bit mask and membership for sets of tests
#'
#' `flag_mask()` turns test names into the integer with those bits set;
#' `has_flag()` tells which flag words carry at least one of the tests. A
#' cleaning rule is a set of tests, so `has_flag(flags, rule)` marks the records
#' that rule removes.
#'
#' @param tests Character vector of test names from [flag_tests()].
#' @param flags Integer flag words as returned by [flag_occurrences()].
#' @return `flag_mask()`: a single integer. `has_flag()`: a logical vector the
#'   length of `flags`; `NA` flags give `NA`.
#' @examples
#' flag_mask(c("cap", "cen"))
#' has_flag(c(0L, 8L, 16L, 24L), c("cap", "cen"))
#' @export
flag_mask <- function(tests) {
  tests <- check_tests(tests)
  bits <- .flag_layout$bit[match(tests, .flag_layout$test)]
  m <- 0L
  for (b in bits) m <- bitwOr(m, bitwShiftL(1L, b))
  m
}

#' @rdname flag_mask
#' @export
has_flag <- function(flags, tests) {
  bitwAnd(as.integer(flags), flag_mask(tests)) != 0L
}

check_tests <- function(tests) {
  if (is.null(tests)) return(default_tests())
  if (!is.character(tests) || anyNA(tests)) stop("`tests` must be a character vector of test names")
  bad <- setdiff(tests, .test_names)
  if (length(bad)) stop("unknown test(s): ", paste(bad, collapse = ", "), ". See flag_tests().")
  unique(tests)
}
