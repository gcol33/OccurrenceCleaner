# Benchmark OccurrenceCleaner against CoordinateCleaner on random records near
# the gazetteers. Each test runs `reps` times per size on the same records; the
# fastest repetition is kept. Writes <out>/bench-cc.csv and <out>/ENVIRONMENT.txt.
#
#   Rscript bench/benchmark.R [out dir] [max n] [reps]
#
# CoordinateCleaner is run only while a single test takes under `cc_budget`
# seconds at the previous size; larger sizes are reported as not run (NA).

suppressMessages({library("OccurrenceCleaner"); library("CoordinateCleaner")})
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args) >= 1) args[1] else "bench/results"
max_n <- if (length(args) >= 2) as.numeric(args[2]) else 1e7
reps <- if (length(args) >= 3) as.integer(args[3]) else 3L
cc_budget <- 600
sizes <- c(1e5, 1e6, 1e7)
sizes <- sizes[sizes <= max_n]
dir.create(out, showWarnings = FALSE, recursive = TRUE)

# 10 % of the records within 30 km of a capital, the rest uniform in longitude
# and in latitude between 60 S and 75 N; species drawn from 2,000 names.
make_records <- function(n, seed = 1) {
  set.seed(seed)
  cap <- reference_points("capital")
  k <- n %/% 10
  near <- geosphere::destPoint(as.matrix(cap[sample(nrow(cap), k, TRUE), c("lon", "lat")]),
                               runif(k, 0, 360), runif(k, 0, 30000))
  data.frame(species = sample(sprintf("sp%04d", 1:2000), n, TRUE),
             decimalLongitude = c(near[, 1], runif(n - k, -180, 180)),
             decimalLatitude = c(near[, 2], runif(n - k, -60, 75)))
}

best_of <- function(expr, reps) {
  expr <- substitute(expr)
  env <- parent.frame()
  min(vapply(seq_len(reps), function(i) system.time(eval(expr, env))[["elapsed"]], numeric(1)))
}

tests <- c(capital = "cc_cap", centroid = "cc_cen", institution = "cc_inst",
           gbif_headquarters = "cc_gbif", sea = "cc_sea",
           zero = "cc_zero", equal = "cc_equ", invalid = "cc_val", duplicate = "cc_dupl")
# Build the land index and fetch CoordinateCleaner's land layer once, outside the timings.
invisible(flag_occurrences(make_records(1000), tests = "sea", reference = "CoordinateCleaner"))
invisible(suppressWarnings(suppressMessages(cc_sea(make_records(1000), value = "flagged", verbose = FALSE))))

rows <- list()
cc_ok <- setNames(rep(TRUE, length(tests)), names(tests))
for (n in sizes) {
  x <- make_records(n)
  for (t in names(tests)) {
    f <- flag_occurrences(x, tests = t, reference = "CoordinateCleaner")
    t_occ <- best_of(flag_occurrences(x, tests = t, reference = "CoordinateCleaner"), reps)
    t_cc <- NA_real_; agree <- NA_real_
    if (cc_ok[[t]]) {
      fn <- get(tests[[t]], asNamespace("CoordinateCleaner"))
      run_cc <- function() !suppressWarnings(suppressMessages(fn(x, value = "flagged", verbose = FALSE)))
      t_first <- system.time(theirs <- run_cc())[["elapsed"]]
      t_cc <- if (t_first * reps > cc_budget) t_first else min(t_first, best_of(run_cc(), reps - 1L))
      agree <- mean(theirs == f[[paste0("flag_", t)]], na.rm = TRUE)
      if (t_cc > cc_budget) cc_ok[[t]] <- FALSE
    }
    rows[[length(rows) + 1]] <- data.frame(n = n, test = t, occurrencecleaner_s = t_occ,
                                           coordinatecleaner_s = t_cc, agreement = agree)
    cat(sprintf("n=%.0e %-18s occ %8.3f s   cc %8.1f s   agree %s\n", n, t, t_occ, t_cc, format(agree)))
  }
  t_all <- best_of(flag_occurrences(x, tests = default_tests()), reps)
  rows[[length(rows) + 1]] <- data.frame(n = n, test = "default_tests", occurrencecleaner_s = t_all,
                                         coordinatecleaner_s = NA_real_, agreement = NA_real_)
  cat(sprintf("n=%.0e all default tests %.2f s\n", n, t_all))
}
res <- do.call(rbind, rows)
write.csv(res, file.path(out, "bench-cc.csv"), row.names = FALSE)
cpu <- tryCatch(trimws(system("wmic cpu get name", intern = TRUE)[2]), error = function(e) NA)
writeLines(c(paste("date:", Sys.time()), paste("cpu:", cpu),
             paste("platform:", R.version$platform), paste("os:", utils::osVersion),
             paste("R:", R.version.string), paste("BLAS:", extSoftVersion()[["BLAS"]]),
             paste("OccurrenceCleaner:", packageVersion("OccurrenceCleaner")),
             paste("CoordinateCleaner:", packageVersion("CoordinateCleaner")),
             paste("terra:", packageVersion("terra")), paste("vectra:", packageVersion("vectra")),
             paste("repetitions:", reps, "(fastest kept; CoordinateCleaner once when one run exceeds",
                   cc_budget / reps, "s)")),
           file.path(out, "ENVIRONMENT.txt"))
cat("wrote", file.path(out, "bench-cc.csv"), "\n")
