# Benchmark OccurrenceCleaner against CoordinateCleaner on random records near
# the gazetteers, at 1e5, 1e6 and 1e7 records. Writes dev_notes/benchmark.md.
#
#   Rscript bench/benchmark.R [max_n]
#
# CoordinateCleaner is run only while a single test takes under `cc_budget`
# seconds at the previous size; larger sizes are reported as not run.

suppressMessages({library(OccurrenceCleaner); library(CoordinateCleaner)})
args <- commandArgs(trailingOnly = TRUE)
max_n <- if (length(args)) as.numeric(args[1]) else 1e7
cc_budget <- 600
sizes <- c(1e5, 1e6, 1e7)
sizes <- sizes[sizes <= max_n]

make_records <- function(n, seed = 1) {
  set.seed(seed)
  cap <- OccurrenceCleaner:::ref_capitals
  k <- n %/% 10
  near <- geosphere::destPoint(as.matrix(cap[sample(nrow(cap), k, TRUE), c("lon", "lat")]), runif(k, 0, 360), runif(k, 0, 30000))
  data.frame(species = sample(sprintf("sp%04d", 1:2000), n, TRUE),
             decimalLongitude = c(near[, 1], runif(n - k, -180, 180)),
             decimalLatitude = c(near[, 2], runif(n - k, -60, 75)))
}

tests <- c(capital = "cc_cap", centroid = "cc_cen", institution = "cc_inst",
           gbif_headquarters = "cc_gbif", sea = "cc_sea",
           zero = "cc_zero", equal = "cc_equ", invalid = "cc_val", duplicate = "cc_dupl")
rows <- list()
cc_ok <- setNames(rep(TRUE, length(tests)), names(tests))
for (n in sizes) {
  x <- make_records(n)
  for (t in names(tests)) {
    t_occ <- system.time(f <- flag_occurrences(x, tests = t, reference = "CoordinateCleaner"))[["elapsed"]]
    t_cc <- NA_real_; agree <- NA_real_
    if (cc_ok[[t]]) {
      fn <- get(tests[[t]], asNamespace("CoordinateCleaner"))
      t_cc <- system.time(theirs <- !suppressWarnings(suppressMessages(fn(x, value = "flagged", verbose = FALSE))))[["elapsed"]]
      agree <- mean(theirs == f[[paste0("flag_", t)]], na.rm = TRUE)
      if (t_cc > cc_budget) cc_ok[[t]] <- FALSE
    }
    rows[[length(rows) + 1]] <- data.frame(n = n, test = t, occurrencecleaner_s = round(t_occ, 2),
                                           coordinatecleaner_s = round(t_cc, 1), agreement = round(agree, 6))
    cat(sprintf("n=%.0e %-5s occ %7.2f s   cc %7.1f s   agree %s\n", n, t, t_occ, t_cc, format(agree)))
  }
  t_all <- system.time(flag_occurrences(x, tests = default_tests()))[["elapsed"]]
  rows[[length(rows) + 1]] <- data.frame(n = n, test = "default_tests (own reference)", occurrencecleaner_s = round(t_all, 2),
                                         coordinatecleaner_s = NA_real_, agreement = NA_real_)
  cat(sprintf("n=%.0e all default tests %.2f s\n", n, t_all))
}
res <- do.call(rbind, rows)
dir.create("dev_notes", showWarnings = FALSE)
md <- c("# Benchmark against CoordinateCleaner", "",
        sprintf("Run %s on %s, R %s, OccurrenceCleaner %s, CoordinateCleaner %s. Records: 10 %% within 30 km of a capital, the rest uniform over land latitudes; both packages read CoordinateCleaner's gazetteers (`reference = \"CoordinateCleaner\"`). Seconds elapsed, single process. `agreement` is the share of records with identical flags; the proximity differences are the inscribed-polygon band documented in `equivalence.md`.",
                Sys.Date(), paste(Sys.info()[c("sysname", "release")], collapse = " "), getRversion(),
                packageVersion("OccurrenceCleaner"), packageVersion("CoordinateCleaner")), "",
        "| n | test | OccurrenceCleaner (s) | CoordinateCleaner (s) | agreement |", "|---|---|---|---|---|",
        sprintf("| %s | %s | %s | %s | %s |", format(res$n, scientific = TRUE, digits = 1), res$test, res$occurrencecleaner_s,
                ifelse(is.na(res$coordinatecleaner_s), "not run", res$coordinatecleaner_s),
                ifelse(is.na(res$agreement), "", res$agreement)))
writeLines(md, "dev_notes/benchmark.md")
cat("wrote dev_notes/benchmark.md\n")
