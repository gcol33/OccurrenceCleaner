#' OccurrenceCleaner: fast quality flags for species occurrence records
#'
#' An extension of [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) (Zizka et al. 2019) tailored to
#' large-scale occurrence data: it runs that package's record tests with the
#' same definitions and default buffers, up to the differences listed in
#' `vignette("coordinatecleaner", package = "OccurrenceCleaner")`, and keeps
#' every record. Each test
#' writes one flag per record, so a cleaning rule is chosen afterwards as a
#' query over the flags. See [flag_occurrences()] to flag a data frame or an
#' on-disk table, [flag_tests()] for the bit each test sets, and
#' [tally_flags()] to count what each test and rule removes.
#'
#' CoordinateCleaner by Alexander Zizka and co-authors supplies the record
#' tests and what each one looks for, their default buffers, the outlier
#' statistics and the raster approximation for species with many records, the
#' dataset tests, the fossil tests, the choice of reference sources behind the
#' gazetteers and the `spatialvalid` output layout; please cite Zizka et al. (2019) together with this package
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
