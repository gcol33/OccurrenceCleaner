# Grouped tests: a record is compared with the other records of its species,
# its taxon or its dataset, so every record of a group has to be seen before
# any record of it can be flagged. They run in a group pass ahead of the
# record tests; the pass returns a lookup that the record pass ORs into the
# flag word of each chunk.

.group_tests <- c("outlier", "age_outlier", "spatiotemporal_outlier", "age_range_outlier",
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

# Values above the upper fence: Q75 + mltpl * IQR, or median + mltpl * MAD.
fence_flags <- function(v, method, mltpl) {
  if (!length(v) || all(is.na(v))) return(rep(FALSE, length(v)))
  limit <- if (method == "mad") stats::median(v, na.rm = TRUE) + stats::mad(v, na.rm = TRUE) * mltpl
           else stats::quantile(v, 0.75, na.rm = TRUE, names = FALSE) + stats::IQR(v, na.rm = TRUE) * mltpl
  out <- v > limit
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

# Exact test on one species' records (< 10000 records, no thinning).
outlier_exact <- function(lon, lat, s) {
  d <- cpp_outlier_dist(lon, lat)
  if (s$method == "distance") return(d$min > s$tdi)
  fence_flags(d$mean, s$method, s$mltpl)
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

# Iterate over every chunk of every unit; f(chunk, unit index, first row).
# On-disk units are read with the columns in `cols` only.
each_chunk <- function(units, f, cols) {
  for (u in seq_along(units)) {
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

# Bucket store: rows of grouped records, kept in memory for a data frame and
# written to .vtr parts for streamed input. Streamed rows are held in memory
# per bucket and written once `flush_rows` rows have accumulated in all.
new_store <- function(dir, n_buckets, flush_rows = 2e6) {
  env <- new.env()
  env$dir <- dir
  env$n <- n_buckets
  env$mem <- vector("list", n_buckets)
  env$held <- 0
  env$flush_rows <- flush_rows
  if (!is.null(dir)) dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  env
}
store_add <- function(store, d) {
  if (!nrow(d)) return(invisible())
  b <- cpp_hash_strings(d$key) %% store$n + 1L
  for (rows in split(seq_len(nrow(d)), b)) {
    k <- b[rows[1]]
    store$mem[[k]] <- c(store$mem[[k]], list(d[rows, , drop = FALSE]))
  }
  store$held <- store$held + nrow(d)
  if (!is.null(store$dir) && store$held >= store$flush_rows) store_flush(store)
  invisible()
}
store_flush <- function(store) {
  for (k in seq_len(store$n)) {
    if (!length(store$mem[[k]])) next
    part <- do.call(rbind, store$mem[[k]])
    path <- file.path(store$dir, sprintf("bucket-%04d.vtr", k))
    if (file.exists(path)) vectra::append_vtr(part, path) else vectra::write_vtr(part, path)
    store$mem[k] <- list(NULL)
  }
  store$held <- 0
  invisible()
}
store_buckets <- function(store) {
  if (is.null(store$dir)) {
    mem <- Filter(length, store$mem)
    return(lapply(mem, function(parts) do.call(rbind, parts)))
  }
  store_flush(store)
  files <- list.files(store$dir, "^bucket-.*[.]vtr$", full.names = TRUE)
  lapply(files, function(f) function() as.data.frame(vectra::collect(vectra::tbl(f))))
}
bucket_data <- function(b) if (is.function(b)) b() else b

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

# Run every requested group test over all units. Returns the lookup used by
# the record pass: flagged rows by (unit, row) with their bits, flagged cells
# of raster-approximated species, and failed datasets.
group_pass <- function(units, cfg, cols, store_dir = NULL, n_buckets = 64L) {
  tests <- intersect(cfg$tests, .group_tests)
  s <- cfg$settings
  res <- list(rows = data.frame(unit = integer(), row = integer(), bits = integer()),
              raster = list(), grid = NULL, datasets = list(dataset_ddmm = character(), dataset_rounded = character()))
  if (!length(tests)) return(res)
  want_outlier <- "outlier" %in% tests
  want_taxon <- intersect(tests, .taxon_tests)
  want_ds <- intersect(tests, .dataset_tests)

  # Pass 0: extent of valid records, records per species, per-dataset ranges.
  ext <- c(Inf, -Inf, Inf, -Inf)
  # Per-chunk species counts, summed whenever they hold many names.
  sp_parts <- list()
  sp_len <- 0
  ds <- new.env()
  if (want_outlier || length(want_ds)) {
    each_chunk(units, function(chunk, u, first) {
      lon <- to_numeric(chunk[[cols$lon]]); lat <- to_numeric(chunk[[cols$lat]])
      ok <- valid_coords(lon, lat)
      if (any(ok)) ext <<- c(min(ext[1], lon[ok]), max(ext[2], lon[ok]), min(ext[3], lat[ok]), max(ext[4], lat[ok]))
      if (want_outlier) {
        sp <- as.character(chunk[[cols$species]])[ok]
        sp <- sp[!is.na(sp)]
        if (length(sp)) {
          tb <- table(sp)
          sp_parts[[length(sp_parts) + 1L]] <<- stats::setNames(as.numeric(tb), names(tb))
          sp_len <<- sp_len + length(tb)
          if (sp_len > 5e6) {
            sp_parts <<- list(sum_counts(sp_parts))
            sp_len <<- length(sp_parts[[1]])
          }
        }
      }
      if (length(want_ds)) ds_pass0(ds, as.character(chunk[[cols$dataset]]), lon, lat, ok)
    }, cols)
  }
  sp_n <- sum_counts(sp_parts)

  # Pass 1: rows of small species and of taxa into buckets; cell counts of
  # large species; ddmm cells and histograms of datasets.
  sp_store <- if (want_outlier) new_store(if (is.null(store_dir)) NULL else file.path(store_dir, "species"), n_buckets)
  tx_store <- if (length(want_taxon)) new_store(if (is.null(store_dir)) NULL else file.path(store_dir, "taxa"), n_buckets)
  so <- s$outlier
  raster_sp <- if (want_outlier) names(sp_n)[sp_n >= 10000 | so$thinning] else character()
  grid <- if (length(raster_sp)) outlier_grid(ext, so$thinning_res)
  cells <- new.env()
  if (want_outlier || length(want_taxon) || length(want_ds)) {
    each_chunk(units, function(chunk, u, first) {
      rows <- first + seq_len(nrow(chunk)) - 1L
      if (is.null(cols$lon) || is.null(cols$lat)) {
        lon <- lat <- rep(NA_real_, nrow(chunk))
        ok <- rep(FALSE, nrow(chunk))
      } else {
        lon <- to_numeric(chunk[[cols$lon]]); lat <- to_numeric(chunk[[cols$lat]])
        ok <- valid_coords(lon, lat)
      }
      if (want_outlier) {
        sp <- as.character(chunk[[cols$species]])
        keep <- ok & !is.na(sp)
        big <- keep & sp %in% raster_sp
        small <- keep & !big
        store_add(sp_store, data.frame(key = sp[small], unit = rep(u, sum(small)), row = rows[small],
                                       lon = lon[small], lat = lat[small], stringsAsFactors = FALSE))
        if (any(big)) {
          cid <- grid_cell(grid, lon[big], lat[big])
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
        store_add(tx_store, data.frame(key = sp[keep], unit = rep(u, sum(keep)), row = rows[keep],
                                       lon = lon[keep], lat = lat[keep], lo = lo[keep], hi = hi[keep],
                                       id = id[keep], stringsAsFactors = FALSE))
      }
      if (length(want_ds)) ds_pass1(ds, as.character(chunk[[cols$dataset]]), lon, lat, ok, s)
    }, cols)
  }

  hits <- list()
  add_hits <- function(g, flagged, test) {
    if (any(flagged)) hits[[length(hits) + 1L]] <<- data.frame(unit = g$unit[flagged], row = g$row[flagged],
                                                                bits = flag_mask(test))
  }
  if (want_outlier) {
    for (b in store_buckets(sp_store)) {
      d <- bucket_data(b)
      for (g in split(d, d$key)) {
        if (sum(!duplicated(g[, c("lon", "lat")])) < so$min_occs) next
        add_hits(g, outlier_exact(g$lon, g$lat, so), "outlier")
      }
    }
    for (k in raster_sp) {
      e <- cells[[k]]
      if (is.null(e) || nrow(e$pts) < so$min_occs) next
      fc <- outlier_cells(as.numeric(names(e$counts)), e$counts, grid, so)
      if (length(fc)) res$raster[[k]] <- fc
    }
    res$grid <- grid
  }
  if (length(want_taxon)) {
    all_rows <- if ("age_range_outlier" %in% want_taxon && s$age_range_outlier$level == "all") list()
    for (b in store_buckets(tx_store)) {
      d <- bucket_data(b)
      for (g in split(d, d$key)) {
        g <- g[canonical_order(g), , drop = FALSE]
        if ("age_outlier" %in% want_taxon) add_hits(g, taxon_age_outlier(g, s$age_outlier), "age_outlier")
        if ("spatiotemporal_outlier" %in% want_taxon)
          add_hits(g, taxon_spatiotemporal_outlier(g, s$spatiotemporal_outlier), "spatiotemporal_outlier")
        if ("age_range_outlier" %in% want_taxon) {
          if (s$age_range_outlier$level == "taxon") add_hits(g, taxon_age_range_outlier(g, s$age_range_outlier), "age_range_outlier")
          else all_rows[[length(all_rows) + 1L]] <- g
        }
      }
    }
    if (!is.null(all_rows) && length(all_rows)) {
      g <- do.call(rbind, all_rows)
      g <- g[canonical_order(g), , drop = FALSE]
      add_hits(g, taxon_age_range_outlier(g, s$age_range_outlier, sized = FALSE), "age_range_outlier")
    }
  }
  if (length(want_ds)) res$datasets <- ds_decide(ds, want_ds, s)
  if (want_outlier && so$sampling_thresh > 0) res$sampling <- sampling_keep(cfg)
  if (length(hits)) {
    h <- do.call(rbind, hits)
    key <- paste(h$unit, h$row)
    bits <- tapply(h$bits, key, function(b) Reduce(bitwOr, b))
    first <- !duplicated(key)
    res$rows <- data.frame(unit = h$unit[first], row = h$row[first], bits = as.integer(bits[key[first]]))
  }
  res
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

valid_coords <- function(lon, lat) {
  is.finite(lon) & is.finite(lat) & lon >= -180 & lon <= 180 & lat >= -90 & lat <= 90
}

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

# Bits of the group tests for the rows first..first+n-1 of unit u.
group_bits <- function(res, chunk, u, first, cols) {
  n <- nrow(chunk)
  bits <- integer(n)
  if (nrow(res$rows)) {
    r <- res$rows[res$rows$unit == u, , drop = FALSE]
    if (nrow(r)) {
      m <- match(first + seq_len(n) - 1L, r$row)
      bits[!is.na(m)] <- r$bits[m[!is.na(m)]]
    }
  }
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
