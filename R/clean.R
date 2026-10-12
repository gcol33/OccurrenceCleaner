#' @include flag.R group.R
NULL

#' Keep the records no test flagged
#'
#' Removes the records flagged by a cleaning rule from the output of
#' [flag_occurrences()]. Without `tests`, the rule is every test that ran; with
#' `tests`, only those tests exclude a record, so records flagged by other
#' tests stay. The flag columns and the attributes of `x` are kept, so the
#' result can be tallied, summarised or subset again.
#'
#' @section Cleaning functions:
#' Each test also has a cleaning function, `clean_<test>()`, documented on the
#' test's help page ([test_capital], [test_outlier], ...). It runs that one
#' test with [flag_occurrences()] and returns the rows of `x` the test does not
#' flag, with the columns of `x` unchanged. Its arguments are the test's
#' buffer or options, with the defaults in the usage line; further arguments
#' (`columns`, `reference`, `gazetteers`, `land_scale`) go to
#' [flag_occurrences()].
#'
#' A chain of cleaning functions runs each test on the records the previous
#' steps kept. For record tests this gives the same records as flagging all
#' tests once and calling `keep_unflagged()`. A grouped test (`duplicate`,
#' `outlier`, the fossil outlier tests, the dataset tests) compares a record
#' with the other records of its group, so its result depends on which records
#' earlier steps removed; [flag_occurrences()] runs every test on the full
#' input. The cleaning functions take a data frame; a table on disk is
#' flagged with [flag_occurrences()] and counted with [tally_flags()].
#'
#' @param x A data frame returned by [flag_occurrences()].
#' @param tests Character vector of test names, see [flag_tests()]; `NULL`
#'   (the default) uses every test that ran. A test that was not run is an
#'   error.
#' @return The rows of `x` with no flag from `tests`, with the columns and
#'   attributes of `x`.
#' @seealso [has_flag()] for the logical vector behind the selection,
#'   [tally_flags()] to compare several rules.
#' @examples
#' x <- data.frame(species = c("a", "a", "b", "c"),
#'                 decimalLongitude = c(12.58, 0, 16.37, 2.35),
#'                 decimalLatitude = c(55.67, 0, 48.21, 48.85))
#' f <- flag_occurrences(x, tests = c("zero", "capital"))
#' keep_unflagged(f)
#' keep_unflagged(f, tests = "zero")
#' @export
keep_unflagged <- function(x, tests = NULL) {
  if (!is.data.frame(x) || !"flags" %in% names(x))
    stop("`x` must be a data frame returned by flag_occurrences(); ",
         "for flags written to disk, select rows of flagged_table() with flag_mask()")
  x[unflagged(x, tests %||% flagged_tests(x)), , drop = FALSE]
}

# Rows with no flag from `tests`; a test that was not run is an error.
unflagged <- function(f, tests) !(has_flag(f, tests) %in% TRUE)

#' Arguments shared by the cleaning functions
#'
#' @param x A data frame of occurrence records.
#' @param buffer Buffer distance of the test, in the unit of its Buffer section;
#'   the default is the test's default buffer.
#' @param ... Further arguments to [flag_occurrences()]: `columns`,
#'   `reference`, `gazetteers`, `land_scale`.
#' @return `clean_<test>()`: the rows of `x` the test does not flag, with the
#'   columns of `x` unchanged. See [keep_unflagged()], Cleaning functions.
#' @keywords internal
#' @name clean_params
NULL

# The cleaning function of one test. Its formals after `x` are the test's
# own arguments with their registry defaults: `buffer` for a buffered test,
# the options of a grouped test, `by` and `cell` for `duplicate`, `ranges`
# for `range`.
clean_fun <- function(test) {
  own <- clean_formals(test)
  f <- function(x, ...) {
    args <- mget(as.character(names(own)), envir = environment())
    clean_records(x, test, args, ...)
  }
  formals(f) <- c(alist(x = ), own, alist(... = ))
  f
}

clean_formals <- function(test) {
  own <- switch(test,
                range = c(alist(ranges = ), list(buffer = .default_buffers$range)),
                duplicate = list(by = NULL, cell = NULL),
                NULL)
  if (is.null(own) && test %in% names(.default_buffers)) own <- list(buffer = .default_buffers[[test]])
  if (test %in% names(.default_settings)) own <- .default_settings[[test]]
  own
}

clean_records <- function(x, test, args, ...) {
  if (!is.data.frame(x))
    stop("clean_", test, "() takes a data frame; flag a table on disk with ",
         "flag_occurrences(out = ...) and count it with tally_flags()")
  dots <- list(...)
  if ("tests" %in% names(dots)) stop("clean_", test, "() runs one test; use flag_occurrences() for several")
  if (!is.null(args$buffer)) {
    dots$buffers <- dots$buffers %||% list()
    dots$buffers[[test]] <- args$buffer
  }
  if (test %in% names(.default_settings)) {
    dots$settings <- dots$settings %||% list()
    dots$settings[[test]] <- args
  }
  if (test == "duplicate") {
    dots$duplicate_by <- args$by
    dots$duplicate_cell <- args$cell
  }
  if (test == "range") {
    dots$gazetteers <- dots$gazetteers %||% list()
    dots$gazetteers$range <- args$ranges
  }
  f <- do.call(flag_occurrences, c(list(x, tests = test), dots))
  x[unflagged(f, test), , drop = FALSE]
}

#' @rdname test_invalid
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_invalid <- clean_fun("invalid")

#' @rdname test_zero
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_zero <- clean_fun("zero")

#' @rdname test_equal
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_equal <- clean_fun("equal")

#' @rdname test_capital
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_capital <- clean_fun("capital")

#' @rdname test_centroid
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_centroid <- clean_fun("centroid")

#' @rdname test_institution
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_institution <- clean_fun("institution")

#' @rdname test_gbif_headquarters
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_gbif_headquarters <- clean_fun("gbif_headquarters")

#' @rdname test_sea
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_sea <- clean_fun("sea")

#' @rdname test_urban
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_urban <- clean_fun("urban")

#' @rdname test_country_mismatch
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_country_mismatch <- clean_fun("country_mismatch")

#' @rdname test_duplicate
#' @inheritParams clean_params
#' @inherit clean_params return
#' @param by Additional column names a duplicate must share, as
#'   `duplicate_by` in [flag_occurrences()].
#' @param cell Cell size in degrees for comparing coordinates, as
#'   `duplicate_cell` in [flag_occurrences()].
#' @export
clean_duplicate <- clean_fun("duplicate")

#' @rdname test_gbif_issue
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_issue_coordinate <- clean_fun("issue_coordinate")

#' @rdname test_gbif_issue
#' @export
clean_issue_taxon <- clean_fun("issue_taxon")

#' @rdname test_gbif_issue
#' @export
clean_issue_date <- clean_fun("issue_date")

#' @rdname test_gbif_issue
#' @export
clean_issue_rounded <- clean_fun("issue_rounded")

#' @rdname test_basis
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_basis_fossil <- clean_fun("basis_fossil")

#' @rdname test_basis
#' @export
clean_basis_living <- clean_fun("basis_living")

#' @rdname test_establishment
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_establishment_introduced <- clean_fun("establishment_introduced")

#' @rdname test_establishment
#' @export
clean_establishment_managed <- clean_fun("establishment_managed")

#' @rdname test_age_equal
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_age_equal <- clean_fun("age_equal")

#' @rdname test_outlier
#' @inheritParams clean_params
#' @inherit clean_params return
#' @param method,mltpl,tdi,min_occs,thinning,thinning_res,sampling_thresh
#'   Options of the test, as in Settings; the defaults are in the usage line.
#' @export
clean_outlier <- clean_fun("outlier")

#' @rdname test_age_outlier
#' @inheritParams clean_params
#' @inherit clean_params return
#' @param method,mltpl,size_thresh,replicates,flag_thresh,uniq_loc,seed
#'   Options of the test, as in Settings; the defaults are in the usage line.
#' @export
clean_age_outlier <- clean_fun("age_outlier")

#' @rdname test_spatiotemporal_outlier
#' @inheritParams clean_params
#' @inherit clean_params return
#' @param method,mltpl,size_thresh,replicates,flag_thresh,uniq_loc,seed
#'   Options of the test, as in Settings; the defaults are in the usage line.
#' @export
clean_spatiotemporal_outlier <- clean_fun("spatiotemporal_outlier")

#' @rdname test_age_range_outlier
#' @inheritParams clean_params
#' @inherit clean_params return
#' @param method,mltpl,size_thresh,uniq_loc,level
#'   Options of the test, as in Settings; the defaults are in the usage line.
#' @export
clean_age_range_outlier <- clean_fun("age_range_outlier")

#' @rdname test_dataset_ddmm
#' @inheritParams clean_params
#' @inherit clean_params return
#' @param pvalue,diff,mat_size,min_span
#'   Options of the test, as in Settings; the defaults are in the usage line.
#' @export
clean_dataset_ddmm <- clean_fun("dataset_ddmm")

#' @rdname test_dataset_rounded
#' @inheritParams clean_params
#' @inherit clean_params return
#' @param T1,reg_out_thresh,reg_dist_min,reg_dist_max,min_unique_ds_size,axis
#'   Options of the test, as in Settings; the defaults are in the usage line.
#' @export
clean_dataset_rounded <- clean_fun("dataset_rounded")

#' @rdname test_range
#' @inheritParams clean_params
#' @inherit clean_params return
#' @param ranges Species range polygons, as `gazetteers = list(range = ...)`
#'   in [flag_occurrences()].
#' @export
clean_range <- clean_fun("range")

#' @rdname test_aohi
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_aohi <- clean_fun("aohi")

#' @rdname test_habitat
#' @inheritParams clean_params
#' @inherit clean_params return
#' @export
clean_sea_nonmarine <- clean_fun("sea_nonmarine")

#' @rdname test_habitat
#' @export
clean_land_marine <- clean_fun("land_marine")
