#' Export fossil records as PyRate input
#'
#' Writes fossil occurrences in the input format of PyRate (Silvestro et al.
#' 2014), the Bayesian estimator of speciation and extinction rates from
#' fossil occurrences: a Python file holding, per replicate, one array of
#' occurrence ages per taxon, and a tab-separated list of the taxa with their
#' status. An extant taxon gets an extra age of 0. Each record's age is drawn
#' uniformly from its range (`random = TRUE`) or set to the range's midpoint;
#' a minimum age of 0 is set to 0.001.
#'
#' The records are exported as given, so the cleaning rule is applied first:
#' `x[!has_flag(x$flags, rule), ]`.
#'
#' @param x A data frame of fossil records, for example the kept records of a
#'   flagged table.
#' @param file Path prefix of the output: `<file>_PyRate.py` and
#'   `<file>_TaxonList.txt` are written.
#' @param status `"extinct"` or `"extant"`: one value for all records, one per
#'   record, or the name of a column of `x` holding them. A taxon must have a
#'   single status.
#' @param columns Field names, see [occ_columns()]; the taxon is read from
#'   `species` and the ages from `min_age` and `max_age`.
#' @param trait Optional numeric trait, one value per record or the name of a
#'   column; the taxon mean is written as a continuous trait.
#' @param replicates Number of age replicates (data sets) in the file.
#' @param random Draw ages from the ranges (`TRUE`) or use the midpoints.
#'   Replicates of midpoint ages are identical.
#' @param seed Seed for the age draws; the caller's random-number stream is
#'   left unchanged. `NULL` draws from the current stream.
#' @return The paths of the two files, invisibly.
#' @references Silvestro, D., Schnitzler, J., Liow, L. H., Antonelli, A. and
#'   Salamin, N. (2014). Bayesian estimation of speciation and extinction from
#'   incomplete fossil occurrence data. Systematic Biology 63:349-367.
#'   \doi{10.1093/sysbio/syu006}
#' @seealso [flag_occurrences()], [test_age_equal]
#' @examples
#' x <- data.frame(accepted_name = c("Equus caballus", "Equus caballus", "Hipparion sp"),
#'                 min_ma = c(0.5, 1.2, 5), max_ma = c(1, 2.6, 11))
#' paths <- export_pyrate(x, file.path(tempdir(), "horses"), status = c("extant", "extant", "extinct"),
#'                        columns = occ_columns(species = "accepted_name"), random = FALSE)
#' cat(readLines(paths[1]), sep = "\n")
#' @export
export_pyrate <- function(x, file, status, columns = occ_columns(), trait = NULL,
                          replicates = 1, random = TRUE, seed = NULL) {
  if (!is.data.frame(x)) stop("`x` must be a data frame")
  cols <- resolve_columns(columns, names(x), c("species", "min_age", "max_age"))
  pick <- function(v, what) {
    if (is.character(v) && length(v) == 1L && v %in% names(x)) return(x[[v]])
    if (length(v) == 1L) return(rep(v, nrow(x)))
    if (length(v) != nrow(x)) stop("`", what, "` must have one value or one per record")
    v
  }
  status <- tolower(as.character(pick(status, "status")))
  if (!all(status %in% c("extinct", "extant"))) stop("`status` must be \"extinct\" or \"extant\"")
  taxon <- gsub("[[:blank:]]+", "_", as.character(x[[cols$species]]))
  lo <- to_numeric(x[[cols$min_age]])
  hi <- to_numeric(x[[cols$max_age]])
  if (anyNA(taxon) || anyNA(lo) || anyNA(hi)) stop("taxon names and ages must not be missing")
  tr <- if (is.null(trait)) NULL else to_numeric(pick(trait, "trait"))
  st <- tapply(status, taxon, function(s) unique(s))
  if (any(lengths(st) > 1)) stop("taxa listed as both extinct and extant: ", paste(names(st)[lengths(st) > 1], collapse = ", "))
  taxa <- sort(unique(taxon))
  lo[lo == 0] <- 0.001
  a <- pmin(lo, hi); b <- pmax(lo, hi)
  draw <- function() {
    if (random) round(stats::runif(length(a), a, b), 6) else (a + b) / 2
  }
  ages <- if (is.null(seed)) replicate(replicates, draw(), simplify = FALSE)
          else with_group_seed(seed, "pyrate", function() replicate(replicates, draw(), simplify = FALSE))
  num <- function(v) as.character(v)
  out <- c("#!/usr/bin/env python", "from numpy import * ", "")
  for (j in seq_len(replicates)) {
    arrays <- vapply(taxa, function(t) {
      v <- num(ages[[j]][taxon == t])
      if (st[[t]] == "extant") v <- c(v, "0")
      sprintf("array([%s])", paste(v, collapse = ","))
    }, "")
    out <- c(out, sprintf("data_%d=[%s", j, paste(arrays, collapse = ",\n")), "]", "")
  }
  out <- c(out,
           sprintf("d=[%s]", paste(sprintf("data_%d", seq_len(replicates)), collapse = ",")),
           sprintf("names=[%s]", paste(sprintf("'%s_%d'", basename(file), seq_len(replicates)), collapse = ",")),
           "def get_data(i): return d[i]",
           "def get_out_name(i): return  names[i]",
           sprintf("taxa_names=['%s']", paste(taxa, collapse = "','")),
           "def get_taxa_names(): return taxa_names")
  if (!is.null(tr)) {
    m <- tapply(tr, taxon, mean, na.rm = TRUE)[taxa]
    out <- c(out, sprintf("trait1=array([%s])", gsub("NaN|NA", "nan", paste(num(m), collapse = ", "))),
             "traits=[trait1]", "def get_continuous(i): return traits[i]")
  }
  py <- paste0(file, "_PyRate.py")
  tl <- paste0(file, "_TaxonList.txt")
  writeLines(out, py)
  utils::write.table(data.frame(Species = taxa, Status = unname(unlist(st[taxa]))), tl, sep = "\t",
                     row.names = FALSE, quote = FALSE)
  invisible(c(py, tl))
}
