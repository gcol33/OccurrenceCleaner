# Compares the whole-snapshot tallies of several runs: records flagged per test
# and removed per rule, side by side, with the difference to the first run.
# Usage: Rscript bench/compare_snapshot_tallies.R <dir> <dir> ...
#   each <dir> holds a tally.rds written by gbif_snapshot_run.R.
# Writes compare_<names>.csv next to bench/results.

dirs <- commandArgs(trailingOnly = TRUE)
if (length(dirs) < 2) stop("give at least two result directories")
runs <- basename(normalizePath(dirs))
totals <- lapply(dirs, function(d) readRDS(file.path(d, "tally.rds"))$total)
n <- vapply(totals, function(t) as.numeric(t$n), 1)
if (length(unique(n)) != 1) warning("runs cover different record counts: ", paste(n, collapse = ", "))

cols <- Reduce(intersect, lapply(totals, names))
cols <- cols[vapply(cols, function(k) all(vapply(totals, function(t) is.numeric(t[[k]]), TRUE)), TRUE)]
tab <- data.frame(column = cols)
for (i in seq_along(runs)) {
  tab[[runs[i]]] <- vapply(cols, function(k) as.numeric(totals[[i]][[k]]), 1)
  tab[[paste0("pct_", runs[i])]] <- round(100 * tab[[runs[i]]] / n[i], 3)
  if (i > 1) tab[[paste0("diff_", runs[i])]] <- tab[[runs[i]]] - tab[[runs[1]]]
}

out <- file.path("bench/results", paste0("compare_", paste(runs, collapse = "_vs_"), ".csv"))
write.csv(tab, out, row.names = FALSE)
options(width = 200)
print(tab, row.names = FALSE)
message("written ", out)
