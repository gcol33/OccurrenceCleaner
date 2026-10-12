#' The flag layout: one bit per test
#'
#' Every record flagged by [flag_occurrences()] carries an integer flag word in
#' which bit `bit` is set when the record fails test `test`. The layout is
#' versioned: `layout_version` changes whenever a bit is added, removed or
#' redefined, and the flag output records which version produced it.
#'
#' The word is an R integer, 32 bits of which the sign bit cannot be used
#' (it carries `NA`): bits 0 to 29 hold the thirty tests and bit 30 is free.
#' A thirty-second test needs a wider word, which will come with a new layout
#' version.
#'
#' Tests marked `source = "CoordinateCleaner"` are equivalent to the test of
#' the same name in that package with its default buffer (see the `equivalent` column);
#' the documented differences are listed in [flag_occurrences()]. Tests marked
#' `source = "OccurrenceCleaner"` are additions.
#'
#' @return A data frame with columns `bit` (0-based), `test`, `definition`,
#'   `source`, `equivalent` (the [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) function, or `NA`),
#'   `spatialvalid` (the column `clean_coordinates()` or `clean_fossils()`
#'   writes for the test, used by [as_spatialvalid()], or `NA`) and `needs`
#'   (the record fields the test reads, as names of [occ_columns()]).
#'   The attribute `layout_version` holds the layout version.
#' @examples
#' flag_tests()
#' @export
flag_tests <- function() {
  x <- .flag_layout
  attr(x, "layout_version") <- .layout_version
  x
}

.layout_version <- 4L

.flag_layout <- data.frame(
  bit = 0:29,
  test = c("invalid", "zero", "equal", "capital", "centroid", "institution", "gbif_headquarters",
           "sea", "urban", "country_mismatch", "duplicate",
           "issue_coordinate", "issue_taxon", "issue_date", "issue_rounded",
           "basis_fossil", "basis_living", "establishment_introduced", "establishment_managed",
           "age_equal", "outlier", "age_outlier", "spatiotemporal_outlier", "age_range_outlier",
           "dataset_ddmm", "dataset_rounded", "range", "aohi", "sea_nonmarine", "land_marine"),
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
    "establishment means is managed or cultivated",
    "minimum age equal to or greater than the maximum age",
    "geographic outlier among the records of its species",
    "age outlier among the records of its taxon",
    "outlier in space and time among the records of its taxon",
    "age range wider than that of the other records of its taxon",
    "in a dataset with a degree-minute to decimal conversion error",
    "in a dataset whose coordinates lie on a regular grid",
    "outside the range polygons of its species",
    "within 10 km of an Artificial Hotspot Occurrence Inventory point",
    "outside the land polygons, and the genus does not live in the sea",
    "inside the land polygons, and the genus lives only in the sea"),
  source = c(rep("CoordinateCleaner", 11), rep("OccurrenceCleaner", 8), rep("CoordinateCleaner", 9),
             rep("OccurrenceCleaner", 2)),
  equivalent = c("cc_val", "cc_zero", "cc_equ", "cc_cap", "cc_cen", "cc_inst", "cc_gbif", "cc_sea",
                 "cc_urb", "cc_coun", "cc_dupl", rep(NA_character_, 8), "cf_equal",
                 "cc_outl", "cf_age", "cf_outl", "cf_range", "cd_ddmm", "cd_round", "cc_iucn", "cc_aohi",
                 NA, NA),
  spatialvalid = c(".val", ".zer", ".equ", ".cap", ".cen", ".inst", ".gbf", ".sea", ".urb", ".con",
                   ".dpl", rep(NA_character_, 8), ".aeq", ".otl", NA, ".spt", ".trg", NA, NA,
                   ".rang", ".aohi", NA, NA),
  needs = c(rep("lon,lat", 9), "lon,lat,country", "lon,lat,species", rep("issue", 4), "basis",
            "basis", "establishment", "establishment", "min_age,max_age",
            "lon,lat,species", "min_age,max_age,species", "lon,lat,min_age,max_age,species",
            "min_age,max_age,species", "lon,lat,dataset", "lon,lat,dataset", "lon,lat,species", "lon,lat",
            "lon,lat,genus", "lon,lat,genus"),
  stringsAsFactors = FALSE
)

.test_names <- .flag_layout$test

#' Default tests
#'
#' The tests [flag_occurrences()] runs when `tests` is not given: every
#' CoordinateCleaner-equivalent test that needs only coordinates and a species
#' name. `country_mismatch` needs a country code, `urban` is left out as in
#' [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)'s `clean_coordinates()`, and the GBIF-field additions need
#' GBIF columns.
#'
#' @return A character vector of test names.
#' @examples
#' default_tests()
#' @export
default_tests <- function() {
  c("invalid", "zero", "equal", "capital", "centroid", "institution", "gbif_headquarters", "sea",
    "duplicate")
}

#' Bit mask and membership for sets of tests
#'
#' `flag_mask()` turns test names into the integer with those bits set;
#' `has_flag()` tells which flag words carry at least one of the tests. A
#' cleaning rule is a set of tests, so `has_flag(flags, rule)` marks the records
#' that rule removes.
#'
#' @param tests Character vector of test names from [flag_tests()].
#' @param flags Integer flag words, or a data frame returned by
#'   [flag_occurrences()], whose `flags` column is then used.
#' @return `flag_mask()`: a single integer. `has_flag()`: a logical vector, one
#'   element per flag word (per row of a data frame); `NA` flags give `NA`, so
#'   subset with `which()` or `%in% TRUE` when flags can be missing. For a
#'   flagged data frame, a test that was not run is an error, so a rule never
#'   silently removes nothing for a test it names.
#' @examples
#' flag_mask(c("capital", "centroid"))
#' has_flag(c(0L, 8L, 16L, 24L), c("capital", "centroid"))
#' x <- data.frame(decimalLongitude = c(16.37, 0), decimalLatitude = c(48.21, 0))
#' f <- flag_occurrences(x, tests = c("zero", "capital"))
#' f[!has_flag(f, "zero"), ]
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
  if (is.data.frame(flags)) {
    if (!"flags" %in% names(flags)) stop("`flags` is a data frame without a `flags` column; run flag_occurrences() first")
    check_tests_run(tests, flagged_tests(flags))
    flags <- flags[["flags"]]
  }
  bitwAnd(as.integer(flags), flag_mask(tests)) != 0L
}

# A rule naming a test that was not run would silently remove nothing for it.
check_tests_run <- function(tests, run) {
  missing <- setdiff(check_tests(tests), run)
  if (length(missing)) stop("test(s) not run on these flags: ", paste(missing, collapse = ", "),
                            "; run flag_occurrences() with them, or drop them from the rule")
  invisible(tests)
}

check_tests <- function(tests) {
  if (is.null(tests)) return(default_tests())
  if (!is.character(tests) || anyNA(tests)) stop("`tests` must be a character vector of test names")
  bad <- setdiff(tests, .test_names)
  if (length(bad)) stop("unknown test(s): ", paste(bad, collapse = ", "), ". See flag_tests().")
  unique(tests)
}
