#' Share of records flagged, per test and rule
#'
#' Turns flag counts into percentages: for every rule, how many records each of
#' its tests flags, how many it is the only reason the rule removes, and how
#' many the rule removes in total. A record can fail several tests, so the
#' per-test shares of a rule can add up to more than the rule's total; the
#' `only` shares add up to at most that total, and the rest is records removed
#' for more than one reason.
#'
#' `summary()` on a flagged data frame or on on-disk flag output first calls
#' [tally_flags()] with the arguments in `...`, so `rules`, `by` and `bins`
#' work as there; on an `occ_tally` it reshapes the counts already made.
#'
#' @param object A data frame returned by [flag_occurrences()] (class
#'   `occ_flags`), an `occ_flagged` object, or a table from [tally_flags()].
#' @param ... Passed to [tally_flags()]: `rules`, `by`, `bins`, `tests`.
#' @return A data frame of class `occ_summary`, one row per group, rule and
#'   test of the rule, plus one row per group and rule with `test = "(any)"`
#'   for the rule as a whole. Columns: the grouping columns, `rule`, `test`,
#'   `n` (records in the group), `flagged` (records carrying the test, or
#'   removed by the rule), `pct` (`flagged` as a percentage of `n`), `only`
#'   (records whose sole flag among the rule's tests is this one) and
#'   `pct_only`.
#' @seealso [plot.occ_summary()] to draw it.
#' @examples
#' x <- data.frame(species = c("a", "a", "b", "c", "c"),
#'                 kingdom = c("P", "P", "A", "A", "A"),
#'                 decimalLongitude = c(12.58, 0, 16.37, 2.35, 2.35),
#'                 decimalLatitude = c(55.67, 0, 48.21, 48.85, 48.85))
#' f <- flag_occurrences(x)
#' summary(f)
#' summary(f, rules = list(strict = c("zero", "capital", "duplicate")), by = "kingdom")
#' @export
summary.occ_flags <- function(object, ...) {
  if (!"flags" %in% names(object)) return(NextMethod())
  summary(tally_flags(object, ...))
}

#' @rdname summary.occ_flags
#' @export
summary.occ_flagged <- function(object, ...) {
  summary(tally_flags(object, ...))
}

#' @rdname summary.occ_flags
#' @export
summary.occ_tally <- function(object, ...) {
  rules <- attr(object, "occ_rules")
  by <- attr(object, "occ_by") %||% character()
  n <- object$n
  share <- function(k) ifelse(n > 0, 100 * k / n, NA_real_)
  rows <- list()
  for (ri in seq_along(rules)) {
    r <- names(rules)[ri]
    items <- c(rules[[r]], "(any)")
    for (ti in seq_along(items)) {
      t <- items[ti]
      any_row <- t == "(any)"
      flagged <- if (any_row) object[[paste0("removed_", r)]] else object[[paste0("flagged_", t)]]
      only <- if (any_row) rep(NA_integer_, length(n)) else object[[only_column(r, t)]]
      d <- data.frame(object[by], rule = r, test = t, n = n, flagged = flagged, pct = share(flagged),
                      only = only, pct_only = share(only), stringsAsFactors = FALSE)
      d$.g <- seq_along(n); d$.r <- ri; d$.t <- ti
      rows[[length(rows) + 1L]] <- d
    }
  }
  out <- do.call(rbind, rows)
  out <- out[order(out$.g, out$.r, out$.t), setdiff(names(out), c(".g", ".r", ".t")), drop = FALSE]
  rownames(out) <- NULL
  attr(out, "occ_by") <- by
  class(out) <- c("occ_summary", "data.frame")
  out
}

.occ_flag_attrs <- c("occ_tests", "occ_test_plan", "occ_layout_version", "occ_reference",
                     "occ_columns")

#' @export
`[.occ_flags` <- function(x, ...) {
  out <- NextMethod()
  if (!is.data.frame(out)) return(out)
  if (!"flags" %in% names(out)) {
    class(out) <- setdiff(class(out), "occ_flags")
    return(out)
  }
  for (a in .occ_flag_attrs) attr(out, a) <- attr(x, a)
  out
}

#' @export
print.occ_flags <- function(x, n = 10L, ...) {
  if (!"flags" %in% names(x)) return(NextMethod())
  tests <- flagged_tests(x)
  cat("<occ_flags> ", format(nrow(x), big.mark = ","), " records, ", length(tests), " tests", sep = "")
  ref <- reference_short(attr(x, "occ_reference"))
  if (!is.null(ref)) cat(", reference ", ref, sep = "")
  cat("\n")
  absent <- unavailable_summary(attr(x, "occ_test_plan"))
  if (!is.null(absent)) cat("# not run, missing input: ", absent, "; test_plan() lists them\n", sep = "")
  d <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
  d <- utils::head(d[setdiff(names(d), paste0("flag_", tests))], n)
  attributes(d)[.occ_flag_attrs] <- NULL
  d$flagged_by <- vapply(d$flags, function(f) {
    paste(tests[vapply(tests, function(t) isTRUE(has_flag(f, t)), logical(1))], collapse = ",")
  }, "")
  print(d, ...)
  if (nrow(x) > n)
    cat("# ... ", format(nrow(x) - n, big.mark = ","), " more records; summary() for the share each test flags\n", sep = "")
  invisible(x)
}

#' @export
print.occ_tally <- function(x, ...) {
  rules <- attr(x, "occ_rules")
  if (is.null(rules) || !all(paste0("removed_", names(rules)) %in% names(x))) return(NextMethod())
  by <- attr(x, "occ_by") %||% character()
  cat("<occ_tally> ", format(sum(x$n), big.mark = ","), " records", sep = "")
  if (length(by)) cat(" in ", nrow(x), " groups of ", paste(by, collapse = ", "), sep = "")
  cat(", rules: ", paste(names(rules), collapse = ", "), "\n", sep = "")
  keep <- c(by, "n", paste0(c("removed_", "kept_"), rep(names(rules), each = 2L)))
  print(as.data.frame(unclass(x)[intersect(keep, names(x))], stringsAsFactors = FALSE), row.names = FALSE, ...)
  cat("# summary() for the share each test flags\n")
  invisible(x)
}

#' @export
print.occ_summary <- function(x, digits = 2, ...) {
  by <- attr(x, "occ_by") %||% character()
  total <- if (all(c("rule", "test", "n", "flagged", "pct") %in% names(x))) x[x$test == "(any)", , drop = FALSE]
  if (!is.null(total) && nrow(total)) {
    n_all <- sum(total$n[total$rule == total$rule[1]])
    cat("<occ_summary> ", format(n_all, big.mark = ","), " records", sep = "")
    if (length(by)) cat(", grouped by ", paste(by, collapse = ", "), sep = "")
    cat("\n")
    if (!length(by)) {
      for (i in seq_len(nrow(total)))
        cat("  rule ", total$rule[i], ": removes ", format(total$flagged[i], big.mark = ","), " (",
            format(round(total$pct[i], digits), nsmall = digits), " %)\n", sep = "")
    }
  }
  d <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
  for (k in intersect(c("pct", "pct_only"), names(d)))
    d[[k]] <- ifelse(is.na(d[[k]]), "", format(round(d[[k]], digits), nsmall = digits))
  if ("only" %in% names(d)) d$only <- ifelse(is.na(d$only), "", format(d$only))
  print(d, row.names = FALSE, ...)
  invisible(x)
}

#' Plot flag percentages, or map flagged records
#'
#' Without grouping, one horizontal bar per test of a rule: the full bar is the
#' share of records the test flags, the dark part the share it is the only
#' reason for. With grouping (`by` or `bins` in [tally_flags()]), a grid of
#' tests by groups shaded and labelled with the share each test flags in each
#' group. `type = "map"` on a flagged data frame draws the records over the
#' Natural Earth land, coloured by whether the rule removes them.
#'
#' @param x A flagged data frame (`occ_flags`), an `occ_flagged` object, an
#'   `occ_tally` or an `occ_summary`.
#' @param rule Name of the rule to draw. Default: the first rule.
#' @param type For a flagged data frame: `"tests"` (the shares, as for an
#'   `occ_summary`) or `"map"`.
#' @param rules Named list of rules, as in [tally_flags()]. For `type = "map"`
#'   the first rule decides which records are drawn as removed. Default: one
#'   rule holding every test run.
#' @param xlim,ylim For `type = "map"`: longitude and latitude limits of the
#'   map. Default: the extent of the records. The title counts the records
#'   inside the limits.
#' @param ... For `occ_flags` and `occ_flagged`: passed to [tally_flags()]
#'   (`by`, `bins`, `tests`). Otherwise unused.
#' @return `x`, invisibly.
#' @examples
#' x <- data.frame(species = c("a", "a", "b", "c", "c"),
#'                 kingdom = c("P", "P", "A", "A", "A"),
#'                 decimalLongitude = c(12.58, 0, 16.37, 2.35, 2.35),
#'                 decimalLatitude = c(55.67, 0, 48.21, 48.85, 48.85))
#' f <- flag_occurrences(x)
#' plot(f)
#' plot(f, by = "kingdom")
#' plot(f, type = "map")
#' plot(f, type = "map", xlim = c(0, 20), ylim = c(45, 60))
#' @export
plot.occ_summary <- function(x, rule = NULL, ...) {
  rule <- rule %||% x$rule[1]
  if (!rule %in% x$rule) stop("no rule `", rule, "` in the summary")
  d <- x[x$rule == rule & x$test != "(any)", , drop = FALSE]
  total <- x[x$rule == rule & x$test == "(any)", , drop = FALSE]
  by <- attr(x, "occ_by") %||% character()
  if (length(by) && nrow(total) > 1L) plot_share_grid(d, total, by, rule)
  else plot_share_bars(d, total, rule)
  invisible(x)
}

#' @rdname plot.occ_summary
#' @export
plot.occ_tally <- function(x, rule = NULL, ...) {
  plot(summary(x), rule = rule)
  invisible(x)
}

#' @rdname plot.occ_summary
#' @export
plot.occ_flags <- function(x, type = c("tests", "map"), rules = NULL, xlim = NULL, ylim = NULL, ...) {
  type <- match.arg(type)
  if (type == "tests") {
    plot(summary(x, rules = rules, ...))
    return(invisible(x))
  }
  rules <- check_rules(rules, flagged_tests(x))
  cols <- resolve_columns(attr(x, "occ_columns") %||% occ_columns(), names(x), c("lon", "lat"))
  plot_flag_map(to_numeric(x[[cols$lon]]), to_numeric(x[[cols$lat]]),
                has_flag(x$flags, rules[[1]]), names(rules)[1], xlim, ylim)
  invisible(x)
}

#' @rdname plot.occ_summary
#' @export
plot.occ_flagged <- function(x, rules = NULL, ...) {
  plot(summary(x, rules = rules, ...))
  invisible(x)
}

.col_flagged <- "#9DB4C0"
.col_only <- "#2C5D73"
.col_removed <- "#B5442F"

share_label <- function(p) ifelse(is.na(p), "", sprintf(if (any(p > 0 & p < 0.1, na.rm = TRUE)) "%.2f" else "%.1f", p))

plot_share_bars <- function(d, total, rule) {
  d <- d[order(d$pct, na.last = FALSE), , drop = FALSE]
  op <- graphics::par(mar = c(4.5, max(4, max(nchar(d$test)) * 0.55 + 1), 3, 1))
  on.exit(graphics::par(op))
  lim <- c(0, max(c(d$pct, 1), na.rm = TRUE) * 1.15)
  mid <- graphics::barplot(d$pct, horiz = TRUE, names.arg = FALSE, col = .col_flagged,
                           border = NA, xlim = lim, xlab = "% of records")
  graphics::barplot(d$pct_only, horiz = TRUE, col = .col_only, border = NA, add = TRUE, axes = FALSE)
  graphics::axis(2, at = mid, labels = d$test, las = 1, tick = FALSE, gap.axis = -1, line = -0.6)
  graphics::text(d$pct, mid, share_label(d$pct), pos = 4, xpd = TRUE)
  graphics::title(main = sprintf("rule %s removes %s %% of %s records", rule, share_label(total$pct[1]),
                                 format(total$n[1], big.mark = ",")), font.main = 1, cex.main = 1)
  graphics::legend("bottomright", c("flagged", "only reason"), fill = c(.col_flagged, .col_only),
                   border = NA, bty = "n")
}

plot_share_grid <- function(d, total, by, rule) {
  group <- do.call(paste, c(unname(as.list(total[by])), sep = " / "))
  tests <- unique(d$test)
  m <- matrix(d$pct, nrow = length(tests), ncol = length(group))
  m <- rbind(m, total$pct)
  rows <- c(tests, paste0("rule ", rule))
  op <- graphics::par(mar = c(max(4, max(nchar(group)) * 0.5 + 1), max(4, max(nchar(rows)) * 0.55 + 1), 3, 1))
  on.exit(graphics::par(op))
  # The ramp ends at a light shade so dark cell labels stay readable on every cell.
  pal <- grDevices::colorRampPalette(c("#F4F7F8", .col_flagged))(100)
  z <- as.vector(t(m)[, rev(seq_along(rows)), drop = FALSE])
  zmax <- max(c(m, 1), na.rm = TRUE)
  fill <- pal[pmax(1L, ceiling(ifelse(is.na(z), 0, z) / zmax * 100))]
  graphics::plot.new()
  graphics::plot.window(c(0.5, length(group) + 0.5), c(0.5, length(rows) + 0.5), xaxs = "i", yaxs = "i")
  xy <- expand.grid(x = seq_along(group), y = seq_along(rows))
  graphics::rect(xy$x - 0.5, xy$y - 0.5, xy$x + 0.5, xy$y + 0.5, col = fill, border = NA)
  graphics::axis(1, seq_along(group), group, las = 2, tick = FALSE, gap.axis = -1)
  graphics::axis(2, seq_along(rows), rev(rows), las = 1, tick = FALSE, gap.axis = -1)
  graphics::abline(h = 1.5, col = "white", lwd = 3)
  graphics::text(xy$x, xy$y, share_label(z))
  graphics::title(main = "% of records flagged", font.main = 1, cex.main = 1)
}

plot_flag_map <- function(lon, lat, removed, rule, xlim = NULL, ylim = NULL) {
  ok <- is.finite(lon) & is.finite(lat) & abs(lon) <= 180 & abs(lat) <= 90
  removed[is.na(removed)] <- FALSE
  if (any(ok)) {
    xr <- range(lon[ok]); yr <- range(lat[ok])
    pad <- max(1, 0.1 * max(diff(xr), diff(yr)))
    xr <- pmin(pmax(xr + c(-pad, pad), -180), 180); yr <- pmin(pmax(yr + c(-pad, pad), -90), 90)
  } else {
    xr <- c(-180, 180); yr <- c(-90, 90)
  }
  xr <- xlim %||% xr; yr <- ylim %||% yr
  ok <- ok & lon >= xr[1] & lon <= xr[2] & lat >= yr[1] & lat <= yr[2]
  op <- graphics::par(mar = c(3, 3.5, 3, 1))
  on.exit(graphics::par(op))
  graphics::plot.new()
  graphics::plot.window(xr, yr, asp = 1 / cos(mean(yr) * pi / 180))
  usr <- graphics::par("usr")
  graphics::rect(usr[1], usr[3], usr[2], usr[4], col = "#EEF3F6", border = NA)
  land <- ref_land_110
  starts <- land$ring_start
  idx <- unlist(lapply(seq_len(length(starts) - 1L), function(i) c(NA, seq.int(starts[i] + 1L, starts[i + 1L]))))[-1L]
  graphics::polypath(land$x[idx] / 1e7, land$y[idx] / 1e7, col = "#E3E1DA", border = "#B9B6AC",
                     rule = "evenodd")
  graphics::points(lon[ok & !removed], lat[ok & !removed], pch = 16, cex = 0.6,
                   col = grDevices::adjustcolor("#4D4D4D", 0.6))
  graphics::points(lon[ok & removed], lat[ok & removed], pch = 16, cex = 0.7,
                   col = grDevices::adjustcolor(.col_removed, 0.6))
  ticks <- function(r, lim) { p <- pretty(r); p[p >= -lim & p <= lim] }
  graphics::axis(1, ticks(xr, 180))
  graphics::axis(2, ticks(yr, 90), las = 1)
  graphics::box(col = "grey70")
  graphics::title(main = sprintf("rule %s: %s of %s records removed", rule,
                                 format(sum(removed & ok), big.mark = ","), format(sum(ok), big.mark = ",")),
                  font.main = 1, cex.main = 1)
  graphics::legend("bottomleft", c("kept", "removed"), pch = 16, col = c("#4D4D4D", .col_removed),
                   bty = "n", bg = "white")
}
