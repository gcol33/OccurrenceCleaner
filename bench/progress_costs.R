# Seconds per item of each progress step of a finished streamed run, from its
# out/progress_steps.csv, printed as the .step_cost vector of R/progress.R.
# record_bytes is the record pass's seconds per byte of the input files.
#
# Usage: Rscript progress_costs.R <flag output dir> <parquet dir> [max files]
#   the input files as gbif_snapshot_run.R chose them, for the byte count.

args <- commandArgs(TRUE)
out <- args[1]; snap <- args[2]
max_files <- if (length(args) >= 3) as.integer(args[3]) else Inf

files <- sort(list.files(snap, full.names = TRUE))
files <- files[!grepl("^[._]", basename(files))]
if (is.finite(max_files)) files <- head(files, max_files)

s <- read.csv(file.path(out, "progress_steps.csv"))
s <- s[s$session > 0, ]
cost <- stats::setNames(s$secs / s$session, s$step)
if ("record" %in% names(cost)) cost[["record_bytes"]] <- s$secs[s$step == "record"] / sum(file.size(files))
print(cbind(s, cost = signif(s$secs / s$session, 2)))
cat(sprintf("%s = %.1e", names(cost), cost), sep = ", ")
cat("\n")
