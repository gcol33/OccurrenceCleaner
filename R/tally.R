#' Tally flags into a loss table
#'
#' Counts, per group, how many records each test flags and how many a cleaning
#' rule removes. A rule is a set of tests: a record is removed when it carries
#' any of them. Works on a flagged data frame or on the on-disk output of
#' [flag_occurrences()], which is streamed part by part.
#'
#' @param x A data frame returned by [flag_occurrences()] (or any data frame
#'   with an integer `flags` column), an `occ_flagged` object, or its output
#'   directory.
#' @param by Character vector of grouping columns. For on-disk output these must
#'   have been passed as `keep` when flagging. Missing values form the group
#'   `"missing"`.
#' @param rules Named list of character vectors of test names. Default: one
#'   rule, `"all"`, holding every test present in the flags.
#' @param bins Named list of numeric break points. Each named column is cut at
#'   those breaks into a factor-like character column `<name>_bin` (closed on
#'   the left, missing values labelled `"missing"`) and added to `by`.
#' @param tests Tests to count individually. Default: those recorded with the
#'   flags, or every test with a set bit.
#' @return A data frame of class `occ_tally` with the `by` columns, `n`
#'   (records), `n_valid` (records without the `invalid` flag, when `invalid`
#'   was run), one column `flagged_<test>` per test, per rule `removed_<rule>`
#'   and `kept_<rule>`, and per rule and test of the rule `only_<rule>_<test>`:
#'   the records that test is the sole reason the rule removes. The attribute
#'   `occ_rules` holds the rules and `occ_by` the grouping columns.
#'   [summary()][summary.occ_tally] turns the counts into percentages and
#'   [plot()][plot.occ_tally] draws them.
#' @examples
#' x <- data.frame(species = c("a", "a", "b", "c"), kingdom = c("P", "P", "A", "A"),
#'                 decimalLongitude = c(12.58, 0, 16.37, 2.35),
#'                 decimalLatitude = c(55.67, 0, 48.21, 48.85))
#' f <- flag_occurrences(x, tests = c("invalid", "zero", "gbif_headquarters", "capital"))
#' tally_flags(f, by = "kingdom",
#'             rules = list(strict = c("zero", "gbif_headquarters", "capital"), mild = "zero"))
#' @export
tally_flags <- function(x, by = NULL, rules = NULL, bins = NULL, tests = NULL) {
  if (is.data.frame(x)) {
    if (!"flags" %in% names(x)) stop("`x` has no `flags` column; run flag_occurrences() first")
    tests <- tests %||% flagged_tests(x)
    rules <- check_rules(rules, tests)
    return(finish_tally(tally_chunk(x, by, rules, bins, tests), by, bins, rules))
  }
  m <- read_flagged(x)
  tests <- tests %||% m$tests
  rules <- check_rules(rules, tests)
  missing <- setdiff(by, c(m$keep, m$columns$id, names(bins)))
  if (length(missing)) stop("grouping column(s) not kept in the flag output: ", paste(missing, collapse = ", "))
  acc <- NULL
  for (p in m$parts) {
    acc <- vectra::collect_chunked(vectra::tbl(file.path(m$out, p)), function(acc, chunk) {
      merge_tally(acc, tally_chunk(chunk, by, rules, bins, tests))
    }, .init = acc)
  }
  finish_tally(acc, by, bins, rules)
}

`%||%` <- function(a, b) if (is.null(a)) b else a

tests_present <- function(flags) {
  .test_names[vapply(.test_names, function(t) any(has_flag(flags, t), na.rm = TRUE), logical(1))]
}

# Tests run on a flagged data frame: the recorded attribute, else the
# flag_<test> columns (row subsets drop the attribute), else the set bits.
flagged_tests <- function(x) {
  if (!is.null(attr(x, "occ_tests"))) return(attr(x, "occ_tests"))
  cols <- intersect(paste0("flag_", .test_names), names(x))
  if (length(cols)) return(sub("^flag_", "", cols))
  tests_present(x$flags)
}

check_rules <- function(rules, tests) {
  if (is.null(rules)) rules <- list(all = tests)
  if (!is.list(rules) || is.null(names(rules)) || any(!nzchar(names(rules)))) stop("`rules` must be a named list of test-name vectors")
  lapply(rules, check_tests)
}

# Bin labels in break order, lowest first.
bin_labels <- function(breaks) {
  breaks <- sort(unique(breaks))
  c(paste0("<", breaks[1]),
    if (length(breaks) > 1) paste0(breaks[-length(breaks)], "-", breaks[-1]),
    paste0(">=", breaks[length(breaks)]))
}

bin_column <- function(v, breaks) {
  v <- suppressWarnings(as.numeric(v))
  labels <- bin_labels(breaks)
  out <- labels[findInterval(v, sort(unique(breaks))) + 1L]
  out[is.na(v)] <- "missing"
  out
}

group_keys <- function(d, by, bins) {
  keys <- list()
  for (b in by) {
    if (!b %in% names(d) && !b %in% paste0(names(bins), "_bin")) stop("grouping column `", b, "` not found")
    if (b %in% names(d)) {
      k <- as.character(d[[b]])
      k[is.na(k)] <- "missing"
      keys[[b]] <- k
    }
  }
  for (nm in names(bins)) {
    if (!nm %in% names(d)) stop("`bins` column `", nm, "` not found")
    keys[[paste0(nm, "_bin")]] <- bin_column(d[[nm]], bins[[nm]])
  }
  keys
}

# Per-chunk tally: a data frame of group keys plus count columns.
tally_chunk <- function(d, by, rules, bins, tests) {
  keys <- group_keys(d, by, bins)
  f <- as.integer(d$flags)
  g <- if (length(keys)) interaction(keys, drop = TRUE, lex.order = TRUE) else factor(rep("all", length(f)))
  counts <- list(n = tabulate(g, nbins = nlevels(g)))
  if ("invalid" %in% tests) counts$n_valid <- tabulate(g[!has_flag(f, "invalid")], nbins = nlevels(g))
  for (t in tests) counts[[paste0("flagged_", t)]] <- tabulate(g[has_flag(f, t)], nbins = nlevels(g))
  for (r in names(rules)) {
    rem <- has_flag(f, rules[[r]])
    counts[[paste0("removed_", r)]] <- tabulate(g[rem], nbins = nlevels(g))
    in_rule <- bitwAnd(f, flag_mask(rules[[r]]))
    for (t in rules[[r]])
      counts[[only_column(r, t)]] <- tabulate(g[!is.na(in_rule) & in_rule == flag_mask(t)], nbins = nlevels(g))
  }
  out <- if (length(keys)) {
    first <- !duplicated(g)
    kd <- as.data.frame(lapply(keys, function(k) k[first]), stringsAsFactors = FALSE)
    kd[order(g[first]), , drop = FALSE]
  } else data.frame(row.names = seq_len(nlevels(g)))
  rownames(out) <- NULL
  cbind(out, as.data.frame(counts))
}

merge_tally <- function(a, b) {
  if (is.null(a)) return(b)
  both <- rbind(a, b)
  cnt <- intersect(names(both), c("n", "n_valid", grep("^(flagged|removed|only)_", names(both), value = TRUE)))
  key_cols <- setdiff(names(both), cnt)
  if (!length(key_cols)) return(as.data.frame(lapply(both, sum)))
  g <- interaction(both[key_cols], drop = TRUE, lex.order = TRUE)
  out <- both[!duplicated(g), key_cols, drop = FALSE]
  sums <- rowsum(as.matrix(both[cnt]), g, reorder = FALSE)
  out <- cbind(out, as.data.frame(sums))
  rownames(out) <- NULL
  out
}

finish_tally <- function(t, by, bins, rules) {
  if (is.null(t)) t <- data.frame(n = 0L)
  for (r in names(rules)) t[[paste0("kept_", r)]] <- t$n - t[[paste0("removed_", r)]]
  key_cols <- c(by[by %in% names(t)], paste0(names(bins), "_bin"))
  key_cols <- intersect(key_cols, names(t))
  if (length(key_cols)) {
    # Groups sort by value with "missing" last; bins sort in break order.
    sort_keys <- lapply(key_cols, function(k) {
      v <- t[[k]]
      bin <- sub("_bin$", "", k)
      if (k != bin && bin %in% names(bins)) return(list(match(v, c(bin_labels(bins[[bin]]), "missing"))))
      list(v == "missing", v)
    })
    t <- t[do.call(order, unlist(sort_keys, recursive = FALSE)), , drop = FALSE]
  }
  rownames(t) <- NULL
  attr(t, "occ_rules") <- rules
  attr(t, "occ_by") <- key_cols
  class(t) <- c("occ_tally", "data.frame")
  t
}

only_column <- function(rule, test) paste0("only_", rule, "_", test)
