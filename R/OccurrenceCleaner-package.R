#' OccurrenceCleaner: fast quality flags for species occurrence records
#'
#' Flags common errors in species occurrence records and keeps every record.
#' Each test writes one flag per record, so a cleaning rule is chosen
#' afterwards as a query over the flags. The tests and their default buffers
#' follow CoordinateCleaner (Zizka et al. 2019); see [flag_tests()] for the
#' flag layout, [flag_occurrences()] to flag a data frame or an on-disk table
#' and [tally_flags()] to summarise what each test removes.
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
