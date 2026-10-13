# Timing of flag_occurrences() against the number of threads.
#
# Rscript data-raw/threads.R [n_records] [n_species] [threads] [reps]
#   threads: comma-separated, e.g. 1,2,4,8
# Writes inst/extdata/thread_timings.csv (read by vignettes/parallel.Rmd).
# Run on a machine with no other heavy jobs; OpenMP must be available
# (OccurrenceCleaner:::cpp_max_threads() above 1).

args <- commandArgs(trailingOnly = TRUE)
n        <- as.numeric(if (length(args) >= 1) args[1] else 5e6)
n_sp     <- as.integer(if (length(args) >= 2) args[2] else 2000)
threads  <- as.integer(strsplit(if (length(args) >= 3) args[3] else "1,2,4,8", ",")[[1]])
reps     <- as.integer(if (length(args) >= 4) args[4] else 3)

library(OccurrenceCleaner)
cap <- OccurrenceCleaner:::cpp_max_threads()
stopifnot(cap > 1L, max(threads) <= cap)

set.seed(1)
records <- function(n, n_sp) {
  data.frame(species = sprintf("sp%04d", sample.int(n_sp, n, TRUE)),
             decimallongitude = runif(n, -180, 180),
             decimallatitude = runif(n, -55, 70))
}

workloads <- list(
  list(name = "Proximity and polygon tests",
       tests = c("capital", "centroid", "institution", "sea", "urban"),
       n = n, n_sp = n_sp),
  list(name = "Outlier test",
       tests = "outlier", n = n / 5, n_sp = n_sp / 2)
)

median_time <- function(x, tests, nt) {
  t <- vapply(seq_len(reps), function(i) {
    unname(system.time(flag_occurrences(x, tests = tests, n_threads = nt,
                                        verbose = FALSE))["elapsed"])
  }, numeric(1))
  median(t)
}

cpu <- if (.Platform$OS.type == "windows") {
  system2("powershell", c("-NoProfile", "-Command",
          shQuote("(Get-CimInstance Win32_Processor).Name")), stdout = TRUE)
} else "unknown"

rows <- list()
for (w in workloads) {
  x <- records(w$n, w$n_sp)
  invisible(flag_occurrences(x[seq_len(1e4), ], tests = w$tests, verbose = FALSE))
  for (nt in threads) {
    s <- median_time(x, w$tests, nt)
    cat(sprintf("%-30s n = %.0f  threads = %2d  %.2f s\n", w$name, w$n, nt, s))
    rows[[length(rows) + 1]] <- data.frame(
      workload = w$name, n = w$n, species = w$n_sp, threads = nt, seconds = s,
      cpu = trimws(cpu[1]), r_version = as.character(getRversion()))
  }
}
out <- do.call(rbind, rows)
dir.create("inst/extdata", recursive = TRUE, showWarnings = FALSE)
write.csv(out, "inst/extdata/thread_timings.csv", row.names = FALSE)
