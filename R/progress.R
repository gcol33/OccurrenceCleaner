# Progress and time to completion of a streamed run.
#
# A run is a sequence of steps (the passes of the group stage over the input,
# the bucket decisions, the record pass), each a count of items (rows, or
# bytes where the rows of the input are not counted) with a cost per item in
# seconds, measured on a reference run (.step_cost). The step in progress is
# timed from its own items once it has some; the steps ahead are estimated from
# their sizes and costs, scaled by the ratio of the seconds this session has
# taken to the reference seconds of the items it has done, so the estimate
# follows the speed of the machine. Items done before a resume are counted as
# done but not timed.
#
# Each report overwrites `file` with one line:
#   <step> <done> <total> <elapsed_s> <step_eta_s> <run_eta_s> <run_fraction>
# A file write reaches a reader of a detached run whose console output is
# buffered.

# Reference seconds per item of each step, measured on the first 12 files
# (2.1 million records) of the GBIF snapshot of 2026-10-01 with the tests of
# bench/gbif_snapshot_run.R, on one core. decide_taxon and repair were not
# measured there and take the cost of pass1, which reads the same rows.
# record_bytes is the only step of its run (no group tests, rows not counted),
# so its cost sets the estimate only until the first file is done.
.step_cost <- c(pass0 = 6.8e-7, pass1 = 9.2e-7, decide_duplicate = 5.6e-7, decide_outlier = 1.24e-4,
                decide_taxon = 9.2e-7, final = 3.8e-2, record = 1.5e-5, record_bytes = 1.5e-5,
                repair = 9.2e-7)

.step_label <- c(pass0 = "group pass (counts)", pass1 = "group pass (buckets)", decide_duplicate = "duplicate buckets",
                 decide_outlier = "outlier buckets", decide_taxon = "taxon buckets",
                 final = "large species", record = "record pass", record_bytes = "record pass",
                 repair = "rewriting parts")

.step_unit <- c(final = "species", record_bytes = "bytes")

# `steps`: the step names in run order. `file`: the heartbeat file or NULL.
# `every`: seconds between console reports.
new_progress <- function(steps, file = NULL, verbose = FALSE, every = 60,
                         clock = function() proc.time()[["elapsed"]]) {
  p <- new.env()
  p$steps <- data.frame(step = steps, total = NA_real_, done = 0, session = 0, secs = 0,
                        cost = unname(.step_cost[steps]), stringsAsFactors = FALSE)
  p$file <- file
  p$verbose <- verbose
  p$every <- every
  p$clock <- clock
  p$t0 <- clock()
  p$last <- -Inf
  p$cur <- NA_integer_
  p$step_t0 <- NA_real_
  p
}

progress_step_index <- function(p, step) {
  i <- match(step, p$steps$step)
  if (is.na(i)) stop("no progress step ", step)
  i
}

# Set or revise the size of a step.
progress_size <- function(p, step, total) {
  if (is.null(p)) return(invisible())
  p$steps$total[progress_step_index(p, step)] <- total
  invisible()
}

# Begin a step; `done` items of it were done before this session.
progress_start <- function(p, step, done = 0) {
  if (is.null(p)) return(invisible())
  i <- progress_step_index(p, step)
  if (!is.na(p$cur) && p$cur != i) progress_end(p)
  p$steps$done[i] <- done
  p$cur <- i
  p$step_t0 <- p$clock()
  progress_report(p, force = TRUE)
}

# Add items done in this session to the current step.
progress_tick <- function(p, n) {
  if (is.null(p) || is.na(p$cur)) return(invisible())
  i <- p$cur
  p$steps$done[i] <- p$steps$done[i] + n
  p$steps$session[i] <- p$steps$session[i] + n
  p$steps$secs[i] <- p$clock() - p$step_t0
  progress_report(p)
}

# Add items of the current step that were done before this session.
progress_credit <- function(p, n) {
  if (is.null(p) || is.na(p$cur)) return(invisible())
  p$steps$done[p$cur] <- p$steps$done[p$cur] + n
  invisible()
}

# Close the current step; its size becomes what was done.
progress_end <- function(p) {
  if (is.null(p) || is.na(p$cur)) return(invisible())
  i <- p$cur
  p$steps$secs[i] <- p$clock() - p$step_t0
  p$steps$total[i] <- p$steps$done[i]
  progress_report(p, force = TRUE)
  if (p$verbose) message("progress: ", .step_label[[p$steps$step[i]]], " done [",
                         format_secs(p$steps$secs[i]), "]")
  p$cur <- NA_integer_
  invisible()
}

# The estimate: seconds left in the current step and in the run, and the
# share of the run's reference seconds that is done.
progress_estimate <- function(p) {
  s <- p$steps
  total <- ifelse(is.na(s$total), s$done, pmax(s$total, s$done))
  ref_done <- sum(s$session * s$cost)
  scale <- if (ref_done > 0) sum(s$secs) / ref_done else 1
  left <- (total - s$done) * s$cost * scale
  i <- p$cur
  if (!is.na(i) && s$session[i] > 0) left[i] <- (total[i] - s$done[i]) * s$secs[i] / s$session[i]
  step_eta <- if (is.na(i)) 0 else left[i]
  list(step_eta = step_eta, run_eta = sum(left),
       fraction = sum(s$done * s$cost) / max(sum(total * s$cost), .Machine$double.eps))
}

progress_report <- function(p, force = FALSE) {
  now <- p$clock()
  if (!force && now - p$last < p$every) return(invisible())
  p$last <- now
  e <- progress_estimate(p)
  i <- p$cur
  step <- if (is.na(i)) "none" else p$steps$step[i]
  done <- if (is.na(i)) 0 else p$steps$done[i]
  total <- if (is.na(i)) 0 else p$steps$total[i]
  elapsed <- now - p$t0
  if (!is.null(p$file))
    writeLines(sprintf("%s %.0f %.0f %.1f %.1f %.1f %.4f", step, done, if (is.na(total)) -1 else total,
                       elapsed, e$step_eta, e$run_eta, e$fraction), p$file)
  if (p$verbose && !is.na(i)) {
    unit <- if (step %in% names(.step_unit)) .step_unit[[step]] else "rows"
    message(sprintf("progress: %s, %s of %s %s | step ETA %s | run %.0f%%, ETA ~%s | elapsed %s",
                    .step_label[[step]], format_count(done), format_count(total), unit,
                    format_secs(e$step_eta), 100 * e$fraction, format_secs(e$run_eta),
                    format_secs(elapsed)))
  }
  invisible()
}

format_secs <- function(s) {
  if (!is.finite(s) || s < 0) return("?")
  if (s < 90) return(sprintf("%.0f s", s))
  if (s < 5400) return(sprintf("%.1f min", s / 60))
  sprintf("%.1f h", s / 3600)
}

format_count <- function(n) {
  if (is.na(n)) return("?")
  format(n, big.mark = ",", scientific = FALSE, trim = TRUE)
}
