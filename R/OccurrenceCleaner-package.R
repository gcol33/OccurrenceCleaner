#' OccurrenceCleaner: fast quality flags for species occurrence records
#'
#' An extension of CoordinateCleaner (Zizka et al. 2019) tailored to
#' large-scale occurrence data: it runs that package's record tests with the
#' same definitions and default buffers, and keeps every record. Each test
#' writes one flag per record, so a cleaning rule is chosen afterwards as a
#' query over the flags. See [flag_occurrences()] to flag a data frame or an
#' on-disk table, [flag_tests()] for which bit holds which test, and
#' [tally_flags()] to count what each test and rule removes.
#'
#' The tests, their default buffers and the options of the outlier and
#' dataset tests come from CoordinateCleaner by Alexander Zizka and
#' co-authors; please cite Zizka et al. (2019) together with this package
#' (`citation("OccurrenceCleaner")` gives both).
#'
#' @references Zizka A, Silvestro D, Andermann T, et al. (2019)
#'   CoordinateCleaner: standardized cleaning of occurrence records from
#'   biological collection databases. Methods in Ecology and Evolution
#'   10:744-751. \doi{10.1111/2041-210X.13152}
#' @keywords internal
#' @useDynLib OccurrenceCleaner, .registration = TRUE
#' @importFrom Rcpp evalCpp
#' @importFrom vectra collect_chunked
"_PACKAGE"

# Session cache for compiled reference indices (external pointers).
.occ_cache <- new.env(parent = emptyenv())
