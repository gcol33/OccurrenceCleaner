# Grouped tests: a record is compared with the other records of its species,
# its taxon or its dataset, so every record of a group has to be seen before
# any record of it can be flagged. They run in a group pass ahead of the
# record tests; the pass returns a lookup that the record pass ORs into the
# flag word of each chunk.

.group_tests <- c("duplicate", "outlier", "age_outlier", "spatiotemporal_outlier", "age_range_outlier",
                  "dataset_ddmm", "dataset_rounded")
.taxon_tests <- c("age_outlier", "spatiotemporal_outlier", "age_range_outlier")
.dataset_tests <- c("dataset_ddmm", "dataset_rounded")

# ---- settings ------------------------------------------------------------------

.default_settings <- list(
  outlier = list(method = "quantile", mltpl = 5, tdi = 1000, min_occs = 7, thinning = FALSE,
                 thinning_res = 0.5, sampling_thresh = 0),
  age_outlier = list(method = "quantile", mltpl = 5, size_thresh = 7, replicates = 5,
                     flag_thresh = 0.5, uniq_loc = FALSE, seed = 1L),
  spatiotemporal_outlier = list(method = "quantile", mltpl = 5, size_thresh = 7, replicates = 5,
                                flag_thresh = 0.5, uniq_loc = FALSE, seed = 1L),
  age_range_outlier = list(method = "quantile", mltpl = 5, size_thresh = 7, uniq_loc = FALSE,
                           level = "taxon"),
  dataset_ddmm = list(pvalue = 0.025, diff = 1, mat_size = 1000, min_span = 2),
  dataset_rounded = list(T1 = 7, reg_out_thresh = 2, reg_dist_min = 0.1, reg_dist_max = 2,
                         min_unique_ds_size = 4, axis = "both")
)

check_settings <- function(settings) {
  s <- .default_settings
  if (is.null(settings)) return(s)
  if (!is.list(settings) || is.null(names(settings))) stop("`settings` must be a named list")
  bad <- setdiff(names(settings), names(s))
  if (length(bad)) stop("`settings` has no entry for: ", paste(bad, collapse = ", "))
  for (t in names(settings)) {
    v <- settings[[t]]
    if (!is.list(v) || (length(v) && is.null(names(v)))) stop("`settings$", t, "` must be a named list")
    unknown <- setdiff(names(v), names(s[[t]]))
    if (length(unknown)) stop("`settings$", t, "` has no entry for: ", paste(unknown, collapse = ", "))
    for (k in names(v)) {
      old <- s[[t]][[k]]
      new <- v[[k]]
      if (length(new) != 1L || is.na(new) || (is.character(old) != is.character(new)) ||
          (is.logical(old) && !is.logical(new)))
        stop("`settings$", t, "$", k, "` must be a single ", if (is.character(old)) "string" else
             if (is.logical(old)) "TRUE or FALSE" else "number")
      s[[t]][[k]] <- new
    }
  }
  methods <- list(outlier = c("quantile", "mad", "distance"), age_outlier = c("quantile", "mad"),
                  spatiotemporal_outlier = c("quantile", "mad"), age_range_outlier = c("quantile", "mad"))
  for (t in names(methods))
    if (!s[[t]]$method %in% methods[[t]])
      stop("`settings$", t, "$method` must be one of: ", paste(methods[[t]], collapse = ", "))
  if (!s$age_range_outlier$level %in% c("taxon", "all")) stop("`settings$age_range_outlier$level` must be \"taxon\" or \"all\"")
  if (!s$dataset_rounded$axis %in% c("both", "lon", "lat")) stop("`settings$dataset_rounded$axis` must be \"both\", \"lon\" or \"lat\"")
  s
}

# ---- shared statistics ---------------------------------------------------------

# The upper fence: Q75 + mltpl * IQR, or median + mltpl * MAD; NA when every
# value is missing.
fence_limit <- function(v, method, mltpl) {
  if (all(is.na(v))) return(NA_real_)
  if (method == "mad") stats::median(v, na.rm = TRUE) + stats::mad(v, na.rm = TRUE) * mltpl
  else stats::quantile(v, 0.75, na.rm = TRUE, names = FALSE) + stats::IQR(v, na.rm = TRUE) * mltpl
}

# Values above the upper fence.
fence_flags <- function(v, method, mltpl) {
  out <- v > fence_limit(v, method, mltpl)
  out[is.na(out)] <- FALSE
  out
}

# Run fun() with the RNG seeded for one group, leaving the caller's stream as
# it was. The seed mixes the user seed with a hash of the group key, so a
# group's draws do not depend on the other groups or on the input order.
with_group_seed <- function(seed, key, fun) {
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had) old <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
  on.exit(if (had) assign(".Random.seed", old, envir = globalenv())
          else rm(".Random.seed", envir = globalenv()))
  set.seed(bitwXor(as.integer(seed), cpp_hash_strings(as.character(key))))
  fun()
}

# Sum of absolute differences of each value to all values, missing values
# counting as zero difference, in O(n log n).
abs_diff_sums <- function(v) {
  out <- numeric(length(v))
  ok <- which(!is.na(v))
  if (length(ok) < 2) return(out)
  o <- ok[order(v[ok])]
  s <- v[o]
  m <- length(s)
  cs <- cumsum(s)
  k <- seq_len(m)
  out[o] <- s * (k - 1) - c(0, cs[-m]) + (cs[m] - cs) - s * (m - k)
  out
}

# Representatives of rows sharing taxon, coordinates rounded to 0.1 degrees
# and ages; flagged representatives pass the flag to every row with the same
# taxon, raw coordinates and ages.
uniq_rows <- function(g) {
  key <- paste(round(g$lon, 1), round(g$lat, 1), g$lo, g$hi, sep = "\r")
  !duplicated(key)
}
spread_flags <- function(g, rep_rows, flagged_rep) {
  hit <- rep_rows[flagged_rep]
  if (!length(hit)) return(rep(FALSE, nrow(g)))
  full <- paste(g$lon, g$lat, g$lo, g$hi, sep = "\r")
  full %in% full[hit]
}

# ---- species: geographic outliers ---------------------------------------------

# Exact test on the records of the species in `key` (each < 10000 records,
# no thinning). A species is tested when it has at least min_occs distinct
# coordinates; its records keep their input order, so the distance sums are
# added in the same order whatever the other species or the threads.
outlier_exact <- function(key, lon, lat, s, n_threads = 1L) {
  hit <- logical(length(key))
  if (!length(key)) return(hit)
  o <- order(key, method = "radix")
  k <- key[o]
  grp <- cumsum(c(TRUE, k[-1L] != k[-length(k)]))
  n_uniq <- tabulate(grp[!duplicated(data.frame(grp, lon[o], lat[o]))], grp[length(grp)])
  sel <- n_uniq[grp] >= s$min_occs
  if (!any(sel)) return(hit)
  idx <- o[sel]
  g <- grp[sel]
  start <- c(0L, cumsum(rle(g)$lengths))
  d <- cpp_outlier_dist(lon[idx], lat[idx], as.integer(start), n_threads)
  h <- if (s$method == "distance") d$min > s$tdi else {
    lim <- vapply(split(d$mean, g), fence_limit, 0, method = s$method, mltpl = s$mltpl)
    d$mean > lim[match(g, as.integer(names(lim)))]
  }
  h[is.na(h)] <- FALSE
  hit[idx] <- h
  hit
}

# Raster grid of the approximation: the extent of all valid records widened by
# two cells, clamped to the globe, with as many cells of the requested size as
# fit after rounding and the cell size stretched to fill the extent.
outlier_grid <- function(ext, res) {
  e <- c(max(-180, ext[1] - 2 * res), min(180, ext[2] + 2 * res),
         max(-90, ext[3] - 2 * res), min(90, ext[4] + 2 * res))
  nc <- max(1L, as.integer(round((e[2] - e[1]) / res)))
  nr <- max(1L, as.integer(round((e[4] - e[3]) / res)))
  list(xmin = e[1], xmax = e[2], ymin = e[3], ymax = e[4], ncol = nc, nrow = nr,
       xres = (e[2] - e[1]) / nc, yres = (e[4] - e[3]) / nr)
}

grid_cell <- function(grid, lon, lat) {
  col <- pmin(grid$ncol, floor((lon - grid$xmin) / grid$xres) + 1)
  row <- pmin(grid$nrow, floor((grid$ymax - lat) / grid$yres) + 1)
  (row - 1) * grid$ncol + col
}

# Flagged cells of one species from its per-cell record counts.
outlier_cells <- function(cells, counts, grid, s) {
  col <- (cells - 1) %% grid$ncol + 1
  row <- (cells - 1) %/% grid$ncol + 1
  cx <- grid$xmin + (col - 0.5) * grid$xres
  cy <- grid$ymax - (row - 0.5) * grid$yres
  d <- cpp_cell_dist(cx, cy, as.numeric(counts), weighted = !s$thinning,
                     same_km = 100 * mean(c(grid$xres, grid$yres)) / 2)
  hit <- if (s$method == "distance") d$min > s$tdi else fence_flags(d$mean, s$method, s$mltpl)
  cells[hit]
}

# ---- taxa: fossil ages ----------------------------------------------------------

draw_ages <- function(lo, hi, point_ages) {
  out <- rep(NA_real_, length(lo))
  ok <- !is.na(lo)
  fixed <- ok & !is.na(hi) & lo == hi & point_ages
  out[fixed] <- lo[fixed]
  rnd <- which(ok & !fixed)
  if (length(rnd)) out[rnd] <- round(suppressWarnings(stats::runif(length(rnd), lo[rnd], hi[rnd])), 2)
  out
}

# Majority over replicates: flagged when the share of replicates that pass is
# below flag_thresh.
replicate_flags <- function(n, s, one) {
  pass <- matrix(TRUE, n, s$replicates)
  for (r in seq_len(s$replicates)) pass[, r] <- !one()
  rowMeans(pass) < s$flag_thresh
}

taxon_age_outlier <- function(g, s) {
  rows <- if (s$uniq_loc) which(uniq_rows(g)) else seq_len(nrow(g))
  if (length(rows) < s$size_thresh) return(rep(FALSE, nrow(g)))
  lo <- g$lo[rows]; hi <- g$hi[rows]
  hit <- with_group_seed(s$seed, g$key[1], function()
    replicate_flags(length(rows), s, function() {
      a <- draw_ages(lo, hi, point_ages = TRUE)
      fence_flags(abs_diff_sums(a) / length(a), s$method, s$mltpl)
    }))
  if (s$uniq_loc) spread_flags(g, rows, hit) else hit
}

taxon_spatiotemporal_outlier <- function(g, s) {
  rows <- if (s$uniq_loc) which(uniq_rows(g)) else seq_len(nrow(g))
  if (length(rows) < s$size_thresh) return(rep(FALSE, nrow(g)))
  lon <- round(g$lon[rows], 1); lat <- round(g$lat[rows], 1)
  lo <- g$lo[rows]; hi <- g$hi[rows]
  euclid <- length(rows) >= 10000
  hit <- with_group_seed(s$seed, g$key[1], function()
    replicate_flags(length(rows), s, function() {
      a <- draw_ages(lo, hi, point_ages = FALSE)
      fence_flags(cpp_spatiotemporal_mean(lon, lat, a, euclid), s$method, s$mltpl)
    }))
  if (s$uniq_loc) spread_flags(g, rows, hit) else hit
}

taxon_age_range_outlier <- function(g, s, sized = TRUE) {
  rows <- if (s$uniq_loc) which(uniq_rows(g)) else seq_len(nrow(g))
  if (sized && length(rows) < s$size_thresh) return(rep(FALSE, nrow(g)))
  r <- g$hi[rows] - g$lo[rows]
  hit <- if (s$method == "mad" && anyNA(r)) rep(FALSE, length(r)) else fence_flags(r, s$method, s$mltpl)
  if (s$uniq_loc) spread_flags(g, rows, hit) else hit
}

# ---- datasets: ddmm conversion and rasterised coordinates -----------------------

# Histogram counts as graphics::hist() makes them: pretty breaks for about
# 3000 classes, right-closed bins with a small fuzz, the lowest value in the
# first bin.
act_breaks <- function(range_abs) pretty(range_abs, n = 3000, min.n = 1)
bin_counts <- function(v, breaks) {
  nb <- length(breaks)
  diddle <- 1e-7 * if (nb > 5) stats::median(diff(breaks)) else if (nb <= 3) diff(range(v)) else min(diff(breaks)[diff(breaks) > 0])
  fb <- breaks + c(-diddle, rep.int(diddle, nb - 1))
  idx <- findInterval(v, fb, left.open = TRUE)
  idx[v == fb[1]] <- 1L
  tabulate(idx[idx >= 1 & idx < nb], nb - 1)
}

# Periodicity of one axis from its histogram counts f and bin midpoints:
# TRUE when the autocorrelation shows regularly spaced outliers (a grid).
axis_periodic <- function(f, mids, s) {
  mr <- round(length(f) * 0.9)
  if (mr < 12) return(FALSE)
  g0 <- stats::var(f[1:mr])
  if (!is.finite(g0) || g0 == 0) return(FALSE)
  gam <- cpp_lag_cov(as.numeric(f), mr) / g0
  tot <- cpp_window_outlier_counts(gam, 10L, s$T1)
  # Positions as CoordinateCleaner reads them back from table labels: 15 significant digits.
  outl <- as.numeric(as.character(mids[1:mr][tot >= 6]))
  if (length(outl) < 2) return(FALSE)
  dm <- round(stats::dist(round(outl, 2)), 2)
  dm[dm > 2] <- NA
  if (all(is.na(dm))) return(FALSE)
  dm[dm < 0.01] <- NA
  tab <- table(c(dm))
  if (!length(tab)) return(FALSE)
  com <- as.numeric(names(tab)[tab == max(tab)])[1]
  n_reg <- sum(c(dm) %in% com)
  isTRUE(com >= s$reg_dist_min && com <= s$reg_dist_max && n_reg >= s$reg_out_thresh)
}

# Degree-minute test of one dataset from its set of filled cells on the
# mat_size x mat_size grid of coordinate decimals.
ddmm_fails <- function(cells, span_ok, s) {
  if (!span_ok || !length(cells)) return(FALSE)
  ms <- s$mat_size
  k <- floor(0.599 * ms)
  p_small <- k * k / ms^2
  row <- (cells - 1) %/% ms + 1
  col <- (cells - 1) %% ms + 1
  n06 <- sum(row >= ms - k & col <= k)
  n <- length(cells)
  p <- stats::pbinom(n06 - 1, n, p_small, lower.tail = FALSE)
  p < s$pvalue && (n06 / n - p_small) / p_small > s$diff
}

ddmm_cells <- function(lon, lat, ms) {
  cl <- ceiling((abs(lon) - floor(abs(lon))) * ms)
  rl <- ms - ceiling((abs(lat) - floor(abs(lat))) * ms)
  ok <- cl >= 1 & rl >= 1
  unique((rl[ok] - 1) * ms + cl[ok])
}

# ---- the group pass --------------------------------------------------------------

# Iterate over every chunk of the units in `which`; f(chunk, unit index, first
# row). On-disk units are read with the columns in `cols` only.
each_chunk <- function(units, f, cols, which = seq_along(units)) {
  for (u in which) {
    src <- units[[u]]$open()
    if (is.data.frame(src)) {
      f(src, u, 1L)
    } else {
      if (isTRUE(units[[u]]$reopen)) src <- project(src, unlist(cols))
      vectra::collect_chunked(src, function(acc, chunk) {
        f(chunk, u, acc)
        acc + nrow(chunk)
      }, .init = 1L)
    }
  }
  invisible(NULL)
}

# Rows of each unit: counted from the table metadata where the format keeps
# it, otherwise by a scan.
unit_rows <- function(u) {
  src <- u$open()
  if (is.data.frame(src)) return(nrow(src))
  vectra::collect(vectra::tally(src))$n
}

group_columns <- function(chunk, cols, field) {
  if (is.null(cols[[field]])) return(NULL)
  chunk[[cols[[field]]]]
}

# Sum a list of named count vectors by name.
sum_counts <- function(parts) {
  v <- unlist(parts)
  if (!length(v)) return(stats::setNames(numeric(), character()))
  r <- rowsum(unname(v), names(v), reorder = FALSE)
  stats::setNames(r[, 1], rownames(r))
}

# The key columns of the duplicate test: coordinates (binned to
# duplicate_cell when given), species and the duplicate_by columns.
duplicate_key <- function(chunk, cols, cfg, lon, lat) {
  if (!is.null(cfg$duplicate_cell)) {
    lon <- floor(lon / cfg$duplicate_cell); lat <- floor(lat / cfg$duplicate_cell)
  }
  key <- list(as.double(lon), as.double(lat), as.character(chunk[[cols$species]]))
  for (extra in cfg$duplicate_by) {
    if (!extra %in% names(chunk)) stop("`duplicate_by` column `", extra, "` not found in the input")
    v <- chunk[[extra]]
    key[[length(key) + 1L]] <- if (is.numeric(v)) as.double(v) else if (is.logical(v)) v else as.character(v)
  }
  key
}

# Call f(g) for each key group of one partition of a store.
each_group <- function(p, k, f) each_part(p, k, function(d) for (g in split(d, d$key)) f(g))

# Call f(d) on the rows of one partition of a store, all rows of a key
# together. A partition of more than `cap` rows on disk is split further by a
# salted hash of the key, so only one piece has to fit in memory.
each_part <- function(p, k, f, cap = 5e6, depth = 0L) {
  n <- p$rows[[k]]
  if (is.null(p$dir) || n <= cap || depth >= 4L) {
    f(parts_read(p, k))
    return(invisible())
  }
  sub <- new_parts(if (!is.null(p$dir)) file.path(p$dir, paste0("sub-", k)), "b", p$flush_rows)
  m <- max(2, ceiling(n / cap) * 2)
  parts_each(p, k, function(d) parts_add(sub, d, cpp_hash_strings(paste0(d$key, "\r", depth)) %% m))
  for (kk in parts_keys(sub)) each_part(sub, kk, f, cap, depth + 1L)
  parts_drop(sub)
  invisible()
}

# Run every requested group test over all units. Returns the lookup used by
# the record pass: the flagged rows by (unit, row), flagged cells of
# raster-approximated species, and failed datasets.
#
# With `dir`, rows are bucketed on disk and the stage is checkpointed to
# dir/state.rds after a unit or a bucket whenever `checkpoint_secs` have
# passed, and at the end of each step; a call with the same `dir` resumes from
# the last checkpoint. The steps: count the rows of each unit, pass 0 (extent,
# records per species, dataset ranges), pass 1 (rows into buckets, raster
# cell counts, dataset histograms), the decision over each store's buckets,
# and the final per-species and per-dataset decisions. `rows` are the rows of
# each unit when the caller has counted them; `progress` (from new_progress()
# over group_steps(cfg)) is advanced through the steps.
group_pass <- function(units, cfg, cols, dir = NULL, checkpoint_secs = 300, verbose = FALSE,
                       flush_rows = NULL, rows = NULL, progress = NULL) {
  tests <- intersect(cfg$tests, .group_tests)
  s <- cfg$settings
  want_outlier <- "outlier" %in% tests
  want_taxon <- intersect(tests, .taxon_tests)
  want_ds <- intersect(tests, .dataset_tests)
  want_dup <- "duplicate" %in% tests
  read_cols <- c(unlist(cols), if (want_dup) cfg$duplicate_by)
  disk <- !is.null(dir)
  state_path <- if (disk) file.path(dir, "state.rds")
  if (disk) dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  st <- if (disk && file.exists(state_path)) readRDS(state_path) else
    list(stage = "count", unit = 1L, unit_rows = NULL, ext = c(Inf, -Inf, Inf, -Inf),
         sp_parts = list(), sp_len = 0, ds = list(), cells = list(), stores = list(), decided = 0L,
         datasets = NULL, raster = list(), grid = NULL, sampling = NULL)
  if (st$stage == "done") return(group_result(st, dir))
  if (!length(tests)) {
    st$stage <- "done"
    return(group_result(st, dir))
  }
  say <- function(...) if (verbose) message("group tests: ", ...)

  if (st$stage == "count") {
    st$unit_rows <- rows %||% vapply(units, unit_rows, 0)
    # In memory one bucket holds everything; on disk a bucket holds about
    # four million records.
    st$n_buckets <- if (disk) max(64, ceiling(sum(st$unit_rows) / 4e6)) else 1
    st$stage <- if (want_outlier || length(want_ds)) "pass0" else "pass1"
    if (disk) save_atomic(st, state_path)
  }
  flush_rows <- flush_rows %||% max(2e6, 2000 * st$n_buckets)
  subdir <- function(name) if (disk) file.path(dir, name)
  stores <- list(hits = new_parts(subdir("hits"), "h", flush_rows))
  if (want_outlier) stores$sp <- new_parts(subdir("species"), "b", flush_rows)
  if (length(want_taxon)) stores$tx <- new_parts(subdir("taxa"), "b", flush_rows)
  if (want_dup) stores$dup <- new_parts(subdir("duplicate"), "b", flush_rows)
  # Files written after the last checkpoint (or before the first) are cut back.
  for (k in names(stores)) parts_restore(stores[[k]], st$stores[[k]] %||% stats::setNames(numeric(), character()))
  ds <- list2env(st$ds)
  cells <- list2env(st$cells)
  steps <- group_steps(cfg)
  n_rows <- sum(st$unit_rows)
  for (k in intersect(c("pass0", "pass1"), steps)) progress_size(progress, k, n_rows)
  store_step <- c(decide_duplicate = "dup", decide_outlier = "sp", decide_taxon = "tx")
  for (k in intersect(names(store_step), steps))
    progress_size(progress, k, if (st$stage %in% c("count", "pass0", "pass1")) n_rows else
      sum(stores[[store_step[[k]]]]$rows))
  last <- Sys.time()
  checkpoint <- function(force = FALSE) {
    if (!disk || (!force && difftime(Sys.time(), last, units = "secs") < checkpoint_secs)) return(invisible())
    st$stores <<- lapply(stores, parts_state)
    st$ds <<- as.list(ds, all.names = TRUE)
    st$cells <<- as.list(cells, all.names = TRUE)
    save_atomic(st, state_path)
    last <<- Sys.time()
  }
  # One pass over the units, from the first unit not yet done.
  run_pass <- function(stage, next_stage, f) {
    if (st$stage != stage) return(invisible())
    say("reading ", length(units) - st$unit + 1L, " file(s)",
        if (want_outlier || length(want_ds)) paste0(" (pass ", if (stage == "pass0") 1 else 2, " of 2)"))
    progress_start(progress, stage, done = sum(st$unit_rows[seq_len(st$unit - 1L)]))
    while (st$unit <= length(units)) {
      each_chunk(units, function(chunk, u, first) {
        f(chunk, u, first)
        progress_tick(progress, NROW(chunk))
      }, read_cols, which = st$unit)
      st$unit <<- st$unit + 1L
      checkpoint()
    }
    st$stage <<- next_stage
    st$unit <<- 1L
    checkpoint(force = TRUE)
  }
  # The buckets of one store, from the first bucket not yet decided.
  run_buckets <- function(stage, next_stage, store, f, resumable = TRUE) {
    if (st$stage != stage) return(invisible())
    keys <- if (is.null(store)) character() else as.character(sort(as.numeric(parts_keys(store))))
    if (!is.null(store)) {
      say(sub("decide_", "", stage), ": ", length(keys) - st$decided, " bucket(s)")
      progress_size(progress, stage, sum(store$rows))
      progress_start(progress, stage, done = sum(store$rows[keys[seq_len(st$decided)]]))
    }
    for (i in seq_along(keys)) {
      if (i <= st$decided) next
      f(keys[i])
      progress_tick(progress, store$rows[[keys[i]]])
      if (resumable) {
        st$decided <<- i
        checkpoint()
      }
    }
    st$stage <<- next_stage
    st$decided <<- 0L
    checkpoint(force = TRUE)
  }

  # Pass 0: extent of valid records, records per species, per-dataset ranges.
  run_pass("pass0", "pass1", function(chunk, u, first) {
    lon <- to_numeric(chunk[[cols$lon]]); lat <- to_numeric(chunk[[cols$lat]])
    ok <- valid_coords(lon, lat)
    if (any(ok)) st$ext <<- c(min(st$ext[1], lon[ok]), max(st$ext[2], lon[ok]),
                               min(st$ext[3], lat[ok]), max(st$ext[4], lat[ok]))
    if (want_outlier) {
      sp <- as.character(chunk[[cols$species]])[ok]
      sp <- sp[!is.na(sp)]
      if (length(sp)) {
        tb <- table(sp)
        st$sp_parts[[length(st$sp_parts) + 1L]] <<- stats::setNames(as.numeric(tb), names(tb))
        st$sp_len <<- st$sp_len + length(tb)
        if (st$sp_len > 5e6) {
          st$sp_parts <<- list(sum_counts(st$sp_parts))
          st$sp_len <<- length(st$sp_parts[[1]])
        }
      }
    }
    if (length(want_ds)) ds_pass0(ds, as.character(chunk[[cols$dataset]]), lon, lat, ok)
  })

  # Pass 1: rows of small species, of taxa and duplicate keys into buckets;
  # cell counts of large species; ddmm cells and histograms of datasets.
  so <- s$outlier
  if (want_outlier && is.null(st$raster_sp)) {
    sp_n <- sum_counts(st$sp_parts)
    st$raster_sp <- names(sp_n)[sp_n >= 10000 | so$thinning]
    st$grid <- if (length(st$raster_sp)) outlier_grid(st$ext, so$thinning_res)
    st$sp_parts <- list()
  }
  nb <- st$n_buckets
  run_pass("pass1", "decide_duplicate", function(chunk, u, first) {
    rows <- first + seq_len(nrow(chunk)) - 1L
    if (is.null(cols$lon) || is.null(cols$lat)) {
      lon <- lat <- rep(NA_real_, nrow(chunk))
      ok <- rep(FALSE, nrow(chunk))
    } else {
      lon <- to_numeric(chunk[[cols$lon]]); lat <- to_numeric(chunk[[cols$lat]])
      ok <- valid_coords(lon, lat)
    }
    if (want_dup) {
      h <- cpp_key_hash(duplicate_key(chunk, cols, cfg, lon, lat))
      d <- data.frame(unit = u, row = rows, h1 = h$h1, h2 = h$h2, h3 = h$h3, h4 = h$h4)[ok, , drop = FALSE]
      parts_add(stores$dup, d, d$h1 %% nb)
    }
    if (want_outlier) {
      sp <- as.character(chunk[[cols$species]])
      keep <- ok & !is.na(sp)
      big <- keep & sp %in% st$raster_sp
      small <- keep & !big
      d <- data.frame(key = sp[small], unit = rep(u, sum(small)), row = rows[small],
                      lon = lon[small], lat = lat[small], stringsAsFactors = FALSE)
      parts_add(stores$sp, d, cpp_hash_strings(d$key) %% nb)
      if (any(big)) {
        cid <- grid_cell(st$grid, lon[big], lat[big])
        lon_b <- lon[big]; lat_b <- lat[big]
        by_sp <- split(seq_along(cid), sp[big])
        for (k in names(by_sp)) {
          i <- by_sp[[k]]
          e <- cells[[k]]
          tb <- table(cid[i])
          cur <- if (is.null(e)) integer() else e$counts
          add <- stats::setNames(as.integer(tb), names(tb))
          all <- union(names(cur), names(add))
          v <- stats::setNames(integer(length(all)), all)
          v[names(cur)] <- v[names(cur)] + cur
          v[names(add)] <- v[names(add)] + add
          pts <- first_unique(if (!is.null(e)) e$pts, cbind(lon_b[i], lat_b[i]), so$min_occs)
          cells[[k]] <- list(counts = v, pts = pts)
        }
      }
    }
    if (length(want_taxon)) {
      sp <- as.character(chunk[[cols$species]])
      keep <- !is.na(sp)
      lo <- to_numeric(chunk[[cols$min_age]]); hi <- to_numeric(chunk[[cols$max_age]])
      id <- if (is.null(cols$id)) rep(NA_character_, nrow(chunk)) else as.character(chunk[[cols$id]])
      d <- data.frame(key = sp[keep], unit = rep(u, sum(keep)), row = rows[keep],
                      lon = lon[keep], lat = lat[keep], lo = lo[keep], hi = hi[keep],
                      id = id[keep], stringsAsFactors = FALSE)
      parts_add(stores$tx, d, cpp_hash_strings(d$key) %% nb)
    }
    if (length(want_ds)) ds_pass1(ds, as.character(chunk[[cols$dataset]]), lon, lat, ok, s)
  })

  # Duplicates: the rows of a bucket are in input order, so a row whose key
  # is already in the bucket's seen-set is a later copy.
  run_buckets("decide_duplicate", "decide_outlier", stores$dup, function(k) {
    seen <- cpp_seen_new()
    parts_each(stores$dup, k, function(d) {
      hit <- cpp_seen_mark(seen, d$h1, d$h2, d$h3, d$h4)
      hits_add(stores$hits, d$unit[hit], d$row[hit], "duplicate")
    })
  })

  run_buckets("decide_outlier", "decide_taxon", stores$sp, function(k) {
    each_part(stores$sp, k, function(d) {
      hit <- outlier_exact(d$key, d$lon, d$lat, so, cfg$n_threads %||% 1L)
      hits_add(stores$hits, d$unit[hit], d$row[hit], "outlier")
    })
  })

  # With age_range_outlier at level "all", every taxon is held until the end,
  # so that step restarts from its first bucket after an interruption.
  all_level <- "age_range_outlier" %in% want_taxon && s$age_range_outlier$level == "all"
  all_rows <- list()
  run_buckets("decide_taxon", "final", stores$tx, resumable = !all_level, function(k) {
    each_group(stores$tx, k, function(g) {
      g <- g[canonical_order(g), , drop = FALSE]
      add <- function(hit, test) hits_add(stores$hits, g$unit[hit], g$row[hit], test)
      if ("age_outlier" %in% want_taxon) add(taxon_age_outlier(g, s$age_outlier), "age_outlier")
      if ("spatiotemporal_outlier" %in% want_taxon)
        add(taxon_spatiotemporal_outlier(g, s$spatiotemporal_outlier), "spatiotemporal_outlier")
      if ("age_range_outlier" %in% want_taxon) {
        if (!all_level) add(taxon_age_range_outlier(g, s$age_range_outlier), "age_range_outlier")
        else all_rows[[length(all_rows) + 1L]] <<- g
      }
    })
  })

  if (st$stage == "final") {
    if (length(all_rows)) {
      g <- do.call(rbind, all_rows)
      g <- g[canonical_order(g), , drop = FALSE]
      hit <- taxon_age_range_outlier(g, s$age_range_outlier, sized = FALSE)
      hits_add(stores$hits, g$unit[hit], g$row[hit], "age_range_outlier")
    }
    if (want_outlier) {
      progress_size(progress, "final", length(st$raster_sp))
      progress_start(progress, "final")
      for (k in st$raster_sp) {
        progress_tick(progress, 1)
        e <- cells[[k]]
        if (is.null(e) || nrow(e$pts) < so$min_occs) next
        fc <- outlier_cells(as.numeric(names(e$counts)), e$counts, st$grid, so)
        if (length(fc)) st$raster[[k]] <- fc
      }
    }
    st$datasets <- if (length(want_ds)) ds_decide(ds, want_ds, s)
    if (want_outlier && so$sampling_thresh > 0) st$sampling <- sampling_keep(cfg)
    st$stage <- "done"
    for (k in setdiff(names(stores), "hits")) parts_drop(stores[[k]])
    stores <- stores["hits"]
    ds <- new.env()
    cells <- new.env()
    checkpoint(force = TRUE)
  }
  progress_end(progress)
  group_result(st, dir, stores$hits)
}

# The progress steps of the group stage for the tests of `cfg`, in run order.
group_steps <- function(cfg) {
  tests <- intersect(cfg$tests, .group_tests)
  if (!length(tests)) return(character())
  outlier <- "outlier" %in% tests
  c(if (outlier || any(tests %in% .dataset_tests)) "pass0", "pass1",
    if ("duplicate" %in% tests) "decide_duplicate", if (outlier) "decide_outlier",
    if (any(tests %in% .taxon_tests)) "decide_taxon", if (outlier) "final")
}

# The lookup of a finished group stage.
group_result <- function(st, dir, hits = NULL) {
  if (is.null(hits) && !is.null(dir)) {
    hits <- new_parts(file.path(dir, "hits"), "h")
    hits$rows <- st$stores$hits %||% hits$rows
  }
  list(hits = hits, raster = st$raster, grid = st$grid,
       datasets = st$datasets %||% list(dataset_ddmm = character(), dataset_rounded = character()),
       sampling = st$sampling)
}

# Records of a taxon in an order fixed by their content (ages, coordinates,
# identifier), so the random age draws do not depend on the input order.
canonical_order <- function(g) order(g$lo, g$hi, g$lon, g$lat, g$id, g$unit, g$row)

# Sampling correction of the outlier test: outliers are kept only in countries
# whose record density (records per 100 km2, from the user's table of
# records per country) lies above the sampling_thresh quantile of the
# densities of all countries in the table.
sampling_keep <- function(cfg) {
  tab <- cfg$custom$sampling
  if (is.null(tab))
    stop("the outlier sampling correction needs records per country: gazetteers = list(sampling = <data frame>)")
  layer <- polygon_layer("country_mismatch", cfg$reference, 110)
  area <- country_areas_km2(layer)
  dens <- log(tab$records / (area[match(tab$country, names(area))] / 100))
  ok <- is.finite(dens)
  if (!any(ok)) stop("no country of the sampling table matches a country polygon (ISO alpha-2 codes)")
  thresh <- stats::quantile(dens[ok], cfg$settings$outlier$sampling_thresh, names = FALSE)
  list(keep = tab$country[ok][dens[ok] > thresh], reference = cfg$reference)
}

# Area in km2 of each country polygon, by ISO alpha-2 code, on the sphere of
# the WGS84 authalic radius. Rings are signed by orientation, so holes
# subtract from the shells that contain them.
country_areas_km2 <- function(layer) {
  r <- 6371.0072
  x <- layer$x / 1e7 * pi / 180
  y <- layer$y / 1e7 * pi / 180
  ring_area <- vapply(seq_along(layer$ring_feature), function(k) {
    i <- seq.int(layer$ring_start[k] + 1L, layer$ring_start[k + 1L])
    l <- x[i]; p <- y[i]
    j <- c(i[-1], i[1]) - i[1] + 1L
    sum((l[j] - l) * (2 + sin(p) + sin(p[j]))) * r^2 / 2
  }, 0)
  feat <- abs(tapply(ring_area, layer$ring_feature, sum))
  code <- layer$features$iso_a2[as.integer(names(feat))]
  ok <- !is.na(code)
  tapply(as.numeric(feat)[ok], code[ok], sum)
}

# The first k distinct rows of rbind(prev, m), reading m in growing prefixes so
# that a large m is not deduplicated in full once k rows are found.
first_unique <- function(prev, m, k) {
  take <- 1024L
  repeat {
    n <- min(take, nrow(m))
    u <- unique(rbind(prev, m[seq_len(n), , drop = FALSE]))
    if (nrow(u) >= k || n == nrow(m)) break
    take <- take * 8L
  }
  if (nrow(u) > k) u[seq_len(k), , drop = FALSE] else u
}

valid_coords <- function(lon, lat) cpp_valid_coords(lon, lat)

# Dataset accumulators. Pass 0: coordinate ranges and up to min_unique_ds_size
# distinct coordinates; pass 1: filled ddmm cells and histogram counts.
ds_pass0 <- function(ds, key, lon, lat, ok) {
  ok <- ok & !is.na(key)
  if (!any(ok)) return(invisible())
  rows <- split(which(ok), key[ok])
  for (k in names(rows)) {
    i <- rows[[k]]
    e <- ds[[k]]
    x <- lon[i]; y <- lat[i]
    r <- c(min(x), max(x), min(y), max(y), min(abs(x)), max(abs(x)), min(abs(y)), max(abs(y)))
    if (!is.null(e)) r <- c(min(e$r[1], r[1]), max(e$r[2], r[2]), min(e$r[3], r[3]), max(e$r[4], r[4]),
                            min(e$r[5], r[5]), max(e$r[6], r[6]), min(e$r[7], r[7]), max(e$r[8], r[8]))
    pts <- first_unique(if (!is.null(e)) e$pts, cbind(x, y), 4L)
    ds[[k]] <-list(r = r, pts = pts, cells = integer(), flon = NULL, flat = NULL)
  }
  invisible()
}

ds_pass1 <- function(ds, key, lon, lat, ok, s) {
  ok <- ok & !is.na(key)
  if (!any(ok)) return(invisible())
  rows <- split(which(ok), key[ok])
  for (k in names(rows)) {
    i <- rows[[k]]
    e <- ds[[k]]
    x <- lon[i]; y <- lat[i]
    e$cells <- unique(c(e$cells, ddmm_cells(x, y, s$dataset_ddmm$mat_size)))
    if (is.null(e$blon)) {
      e$blon <- act_breaks(e$r[5:6]); e$blat <- act_breaks(e$r[7:8])
      e$flon <- integer(length(e$blon) - 1); e$flat <- integer(length(e$blat) - 1)
    }
    e$flon <- e$flon + bin_counts(abs(x), e$blon)
    e$flat <- e$flat + bin_counts(abs(y), e$blat)
    ds[[k]] <- e
  }
  invisible()
}

ds_decide <- function(ds, tests, s) {
  out <- list(dataset_ddmm = character(), dataset_rounded = character())
  for (k in ls(ds, all.names = TRUE)) {
    e <- ds[[k]]
    if ("dataset_ddmm" %in% tests) {
      span_ok <- (e$r[2] - e$r[1]) >= s$dataset_ddmm$min_span && (e$r[4] - e$r[3]) >= s$dataset_ddmm$min_span
      if (ddmm_fails(e$cells, span_ok, s$dataset_ddmm)) out$dataset_ddmm <- c(out$dataset_ddmm, k)
    }
    if ("dataset_rounded" %in% tests && nrow(e$pts) >= s$dataset_rounded$min_unique_ds_size) {
      mids <- function(b) (b[-1] + b[-length(b)]) / 2
      sr <- s$dataset_rounded
      plon <- sr$axis %in% c("both", "lon") && axis_periodic(e$flon, mids(e$blon), sr)
      plat <- sr$axis %in% c("both", "lat") && axis_periodic(e$flat, mids(e$blat), sr)
      fail <- switch(sr$axis, both = plon && plat, lon = plon, lat = plat)
      if (fail) out$dataset_rounded <- c(out$dataset_rounded, k)
    }
  }
  out
}

# Bits of the group tests for the rows first..first+n-1 of unit u; `reader`
# comes from hits_reader(res$hits).
group_bits <- function(res, chunk, u, first, cols, reader) {
  n <- nrow(chunk)
  bits <- hits_lookup(reader, u, first, n)
  if (length(res$raster)) {
    sp <- as.character(chunk[[cols$species]])
    lon <- to_numeric(chunk[[cols$lon]]); lat <- to_numeric(chunk[[cols$lat]])
    cand <- which(sp %in% names(res$raster) & valid_coords(lon, lat))
    if (length(cand)) {
      cid <- grid_cell(res$grid, lon[cand], lat[cand])
      hit <- vapply(seq_along(cand), function(i) cid[i] %in% res$raster[[sp[cand[i]]]], logical(1))
      bits[cand[hit]] <- bitwOr(bits[cand[hit]], flag_mask("outlier"))
    }
  }
  if (!is.null(res$sampling)) {
    o <- which(has_flag(bits, "outlier"))
    if (length(o)) {
      p <- polygon_index("country_mismatch", res$sampling$reference, 110)
      f <- cpp_polygon_locate(p$index, to_numeric(chunk[[cols$lon]])[o], to_numeric(chunk[[cols$lat]])[o])
      cc <- p$features$iso_a2[ifelse(f > 0L, f, NA_integer_)]
      drop <- o[is.na(cc) | !cc %in% res$sampling$keep]
      bits[drop] <- bitwAnd(bits[drop], bitwNot(flag_mask("outlier")))
    }
  }
  for (t in names(res$datasets)) {
    if (!length(res$datasets[[t]])) next
    hit <- as.character(chunk[[cols$dataset]]) %in% res$datasets[[t]]
    bits[hit] <- bitwOr(bits[hit], flag_mask(t))
  }
  bits
}
