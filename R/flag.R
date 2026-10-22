#' Flag occurrence records
#'
#' Runs record tests over species occurrence records and writes one flag per
#' record per test. Nothing is removed and no threshold is baked in.
#'
#' Two choices are kept apart. Which tests run: by default every test whose
#' inputs are available, so a screening sees every potential problem the
#' columns allow; [test_plan()] lists the tests that ran and the reason each
#' other test did not. Which records are excluded: a cleaning rule, a set of
#' tests chosen afterwards and applied with [has_flag()] or compared with
#' [tally_flags()]. A rule for species distribution modelling might exclude
#' fossil and living specimens along with the coordinate problems; a study of
#' fossil ranges would keep the fossils and exclude other flags.
#'
#' The grouped tests (`duplicate`, `outlier`, the three fossil outlier tests
#' and the two dataset tests) compare a record with the other records of its
#' key, species, taxon or dataset; they run in a group stage before the record
#' tests, which on streamed input reads every file once or twice more and
#' keeps its buckets and results in `out/.group`.
#'
#' The input is either a data frame, or an on-disk table streamed in chunks: a
#' `vectra_node` (from `vectra::tbl_parquet()`, `vectra::tbl_csv()`,
#' `vectra::tbl()`), a path to a Parquet file or directory of Parquet parts
#' (such as a GBIF snapshot), or a path to a `.vtr` or delimited text file. For
#' a directory each file is one resumable unit of work; the return follows the
#' input, see Value.
#'
#' @section Streamed runs:
#' Before writing any output, a run records its configuration in
#' `out/flags_config.rds`: the tests, columns, `keep`, reference, buffers,
#' settings, duplicate options, package version, and each input file with its
#' size and modification time. A later call into the same `out` must match the
#' record, or it stops and names what differs; `resume = FALSE` clears the
#' directory instead. Sizes and modification times detect a replaced, grown or
#' touched file; they are not a hash of the contents.
#'
#' The group stage checkpoints its state after a file or a bucket whenever
#' five minutes have passed, and at the end of each pass, so an interruption
#' repeats at most the work since the last checkpoint. The record pass writes
#' a `.done` marker per input file; an interruption there repeats the file in
#' progress.
#'
#' A streamed run writes its progress to `out/progress.txt`, one line
#' overwritten on every report: the step, items done and total, seconds
#' elapsed, and the estimated seconds left in the step and in the run, and the
#' share of the run done. The estimate for the steps ahead uses per-record
#' costs measured on a part of the GBIF snapshot, scaled to the speed of the
#' run so far, so it is rough until the slower steps have started. With
#' `verbose`, the same is reported on the console every minute.
#'
#' @section Threads and workers:
#' `n_threads` spreads the exact outlier test over species and the
#' proximity and point-in-polygon queries of the record tests over records.
#' The distances of a species are summed as integers of 2^-32 km, which gives
#' the same sum in any order, and each record is computed on one thread, so
#' the flags do not depend on the number of threads. Reading the input, the other tests and the
#' bookkeeping of the group stage run on one thread. Without OpenMP support in
#' the compiler every query runs on one thread.
#'
#' `workers` runs the record pass of a streamed run over several input files
#' at once, one file per R process, so reading the input and every record
#' test run in parallel. Each file is flagged by the same code as in a single
#' process and writes its own parts and `.done` marker, so the output does not
#' depend on the number of workers. The `n_threads` of the run are shared out,
#' each worker using `n_threads %/% workers` threads (at least one). Each
#' worker holds the memory of one record pass, so `workers` times the memory
#' of a single-process record pass has to fit. The group stage runs in the
#' main process with all `n_threads`. Workers load the
#' installed package, so `workers` above 1 stops with an error under
#' `pkgload::load_all()`.
#'
#' Memory in the record pass is one input chunk, up to `part_rows` buffered
#' output rows and the group-test hits of the current block of 2^20 rows. The
#' group stage holds two million bucketed rows before writing them (more
#' above four billion records), the per-species record counts, per-dataset
#' histograms and raster cell counts of large species, the duplicate keys of
#' one bucket (at most four million records on average when the input has more
#' than 256 million), and the records of one species (fewer
#' than 10,000 for the exact outlier test) or one fossil taxon. Its disk use is
#' at most 24 bytes per record for `duplicate`, plus the coordinates of the
#' records of the outlier and fossil tests.
#'
#' @section Tests:
#' See [flag_tests()] for the layout. Tests equivalent to [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) use
#' its default buffers: `capital` 10 km, `centroid` 1 km, `institution` 100 m,
#' `gbif_headquarters` 1 km, `zero` 0.5 degrees. Proximity tests are closed
#' balls in WGS84 geodesic distance. Records failing `invalid` are given no
#' spatial flag.
#'
#' Documented differences to CoordinateCleaner 3.0.1, each verified in the
#' package tests:
#' * CoordinateCleaner approximates each buffer circle by an inscribed polygon
#'   (72 vertices for `capital`, `centroid`, `gbif_headquarters`; 40 for
#'   `institution`), so a record between 99.9 % (`capital`, `centroid`,
#'   `gbif_headquarters`) or 99.7 % (`institution`) of the buffer and the
#'   buffer itself is flagged here and may not be there. Everything
#'   CoordinateCleaner flags is flagged here.
#' * `cc_zero`'s 0.5 degree buffer is interpreted by [terra](https://rspatial.github.io/terra/) as 0.5 metres, so
#'   CoordinateCleaner 3.0.1 flags only exact zeros; this package applies the
#'   documented 0.5 degree radius.
#' * `country_mismatch` compares the record's code with the ISO alpha-2 code,
#'   the ISO alpha-3 code and the Natural Earth `ADM0_A3` code of the country
#'   polygon the point falls in, taking the ISO codes from Natural Earth's
#'   `ISO_A2_EH` and `ISO_A3_EH` columns, which are filled where `ISO_A2` and
#'   `ISO_A3` hold `-99` (France, Norway, Kosovo); CoordinateCleaner compares
#'   `ISO_A3` only, so it flags every record in France and Norway.
#'   Records without a code, or at sea, are flagged as in CoordinateCleaner.
#' * `outlier` flags the records of outlier cells in the raster approximation
#'   (species of 10,000 records or more, or `thinning = TRUE`); in
#'   CoordinateCleaner 3.0.1 that path never flags a record.
#' * `age_outlier` and `spatiotemporal_outlier` draw ages by the same
#'   procedure as `cf_age()` and `cf_outl()` but from a stream seeded per
#'   taxon, so a single run can differ record by record; when every age range
#'   has zero width the flags are identical.
#' * `dataset_rounded` leaves datasets below `min_unique_ds_size` untested,
#'   where `cd_round()` stops with an error; the dataset tests do not flag
#'   records without a dataset key.
#' * With the default reference the gazetteers are rebuilt from the original
#'   sources; `reference = "CoordinateCleaner"` uses that package's own tables,
#'   and `gazetteers` replaces the layer of single tests, as the `ref`
#'   arguments of CoordinateCleaner's functions do.
#'
#' @param x A data frame, a `vectra_node`, or a path (file or directory).
#' @param tests Character vector of test names, see [flag_tests()]. `NULL`
#'   (the default) runs every test whose columns are in `x` (and `range` when
#'   `gazetteers` has range polygons); see [test_plan()]. A named test whose
#'   columns are missing from `x` is an error.
#' @param columns Field names, see [occ_columns()].
#' @param reference `"OccurrenceCleaner"` (own gazetteers, the default) or
#'   `"CoordinateCleaner"` (that package's tables, read at run time). See
#'   [reference_info()].
#' @param gazetteers Named list of user-supplied reference layers, each
#'   replacing the reference layer of one test. Point tests (`capital`,
#'   `centroid`, `institution`, `gbif_headquarters`) take a data frame with
#'   longitude and latitude columns (named `lon`/`lat`, `longitude`/`latitude`
#'   or `decimalLongitude`/`decimalLatitude`, any case). Polygon tests (`sea`,
#'   `urban`, `country_mismatch`) take an `sf` or `sfc` object of POLYGON or
#'   MULTIPOLYGON geometries in longitude and latitude; for `sea` they are the
#'   land, and for `country_mismatch` the features need at least one code
#'   column (`iso_a2`, `iso_a3`, `adm0_a3` or `code`, any case). Each layer is
#'   indexed once per call, and its size and MD5 checksum are recorded in the
#'   reference label of the output. `range` takes species range polygons (see
#'   [test_range]), `sampling` a table of records per country for the
#'   sampling correction of [test_outlier], and `habitat` a table of genus
#'   habitats for [test_habitat] (see [reference_habitat()]). The land layer
#'   given for `sea` is also the land of the habitat tests.
#' @param land_scale Natural Earth scale of the land layer for `sea` and the
#'   habitat tests: 110
#'   (the default of CoordinateCleaner's `cc_sea()`; its `clean_coordinates()`
#'   uses `seas_scale = 50`), 50, or 10 (downloaded on first use, see
#'   [download_reference()]).
#' @param buffers Named list overriding buffer distances in metres for
#'   `capital` (10000), `centroid` (1000), `institution` (100),
#'   `gbif_headquarters` (1000), `range` (0), `aohi` (10000),
#'   `sea_nonmarine` (0) and `land_marine` (0), or in degrees for `zero`
#'   (0.5). Unnamed entries keep the defaults.
#' @param settings Named list overriding the options of the grouped tests,
#'   one entry per test, each a named list; unnamed options keep their
#'   defaults, which are CoordinateCleaner's. See [test_outlier],
#'   [test_age_outlier], [test_spatiotemporal_outlier],
#'   [test_age_range_outlier], [test_dataset_ddmm] and [test_dataset_rounded].
#' @param duplicate_by Additional column names a duplicate must share (as
#'   CoordinateCleaner's `additions`), for example an event date.
#' @param duplicate_cell Cell size in degrees. When given, coordinates are
#'   binned to this grid before comparing duplicates, so "same cell and
#'   species" counts.
#' @param out Output directory for streamed input (required then, ignored for a
#'   data frame).
#' @param keep Column names copied next to the flags in streamed output, for
#'   grouping in [tally_flags()] (taxon, year, uncertainty, ...). The `id`
#'   column of `columns` is kept when present.
#' @param part_rows Target rows per output part file for streamed input: a
#'   part is written once at least this many rows have accumulated, and at the
#'   end of each input unit.
#' @param resume Continue a run in `out`: skip input files whose `.done`
#'   marker exists and resume the group stage from its checkpoint. `FALSE`
#'   deletes the earlier output in `out` and starts over.
#' @param verbose Report progress for streamed input.
#' @param n_threads Number of threads for the outlier test and the spatial
#'   queries. `0` uses every thread OpenMP hands out; a request above that is
#'   reduced to it, with a message.
#' @param workers Number of R processes for the record pass of streamed
#'   input with more than one file; `1` flags the files one after another in
#'   this session. Ignored for a data frame and a `vectra_node`.
#' @return For a data frame: `x` with an integer column `flags` and one logical
#'   column `flag_<test>` per test, class `occ_flags` added in front, and
#'   attributes `occ_tests`, `occ_test_plan`, `occ_layout_version`,
#'   `occ_reference` and `occ_columns`. [summary()][summary.occ_flags] reports the share of records
#'   each test flags, [plot()][plot.occ_flags] draws it or maps the records. For streamed input: an object of
#'   class `occ_flagged` describing the output directory, which [tally_flags()]
#'   accepts; the parts are `.vtr` files holding the `id` and `keep` columns and
#'   `flags`, readable with `vectra::tbl()`.
#' @examples
#' x <- data.frame(species = c("a", "a", "b", "c"),
#'                 decimalLongitude = c(12.58, 0, 16.37, 2.35),
#'                 decimalLatitude = c(55.67, 0, 48.21, 48.85))
#' f <- flag_occurrences(x, tests = c("invalid", "zero", "gbif_headquarters", "capital"))
#' f[, c("species", "flags", "flag_zero", "flag_gbif_headquarters", "flag_capital")]
#' @export
flag_occurrences <- function(x, tests = NULL, columns = occ_columns(),
                             reference = c("OccurrenceCleaner", "CoordinateCleaner"),
                             gazetteers = NULL, land_scale = 110, buffers = NULL,
                             settings = NULL, duplicate_by = NULL,
                             duplicate_cell = NULL,
                             out = NULL, keep = NULL, part_rows = 2e6, resume = TRUE,
                             verbose = TRUE, n_threads = 1L, workers = 1L) {
  cfg <- flag_config(tests, columns, match.arg(reference), gazetteers, land_scale, buffers, settings,
                     duplicate_by, duplicate_cell, n_threads)
  if (is.data.frame(x)) {
    if (is.null(tests)) cfg <- apply_plan(cfg, plan_tests(names(x), columns, cfg$has_range))
    return(flag_df(x, cfg))
  }
  if (!is.numeric(workers) || length(workers) != 1L || is.na(workers) || workers < 1)
    stop("`workers` must be a single number of at least 1")
  flag_stream(x, cfg, out = out, keep = keep, part_rows = part_rows, resume = resume,
              verbose = verbose, workers = as.integer(workers))
}

# The validated configuration of a call: tests, columns, reference layers and
# the settings of the tests.
flag_config <- function(tests = NULL, columns = occ_columns(), reference = "OccurrenceCleaner",
                        gazetteers = NULL, land_scale = 110, buffers = NULL, settings = NULL,
                        duplicate_by = NULL, duplicate_cell = NULL, n_threads = 1L) {
  if (!is.null(tests)) {
    tests <- check_tests(tests)
    if ("range" %in% tests && is.null(gazetteers$range))
      stop("the range test needs species range polygons: gazetteers = list(range = <sf>)")
  }
  if (!land_scale %in% c(110, 50, 10)) stop("`land_scale` must be 110, 50 or 10")
  if (!inherits(columns, "occ_columns")) stop("`columns` must come from occ_columns()")
  custom <- prepare_gazetteers(gazetteers, columns)
  list(tests = tests, plan = if (!is.null(tests)) requested_plan(tests),
       has_range = !is.null(gazetteers$range),
       columns = columns, reference = reference, land_scale = land_scale,
       buffers = check_buffers(buffers), settings = check_settings(settings),
       duplicate_by = duplicate_by,
       duplicate_cell = duplicate_cell, gazetteers = gazetteers, custom = custom$index,
       layout_version = .layout_version, n_threads = resolve_threads(n_threads),
       reference_label = reference_label(reference, land_scale, custom$label))
}

.default_buffers <- list(capital = 10000, centroid = 1000, institution = 100,
                         gbif_headquarters = 1000, zero = 0.5, range = 0, aohi = 10000,
                         sea_nonmarine = 0, land_marine = 0)

check_buffers <- function(buffers) {
  b <- .default_buffers
  if (is.null(buffers)) return(b)
  if (!is.list(buffers) || is.null(names(buffers))) stop("`buffers` must be a named list")
  bad <- setdiff(names(buffers), names(b))
  if (length(bad)) stop("`buffers` has no entry for: ", paste(bad, collapse = ", "))
  for (nm in names(buffers)) {
    v <- buffers[[nm]]
    if (!is.numeric(v) || length(v) != 1L || !is.finite(v) || v < 0) stop("buffer `", nm, "` must be a single non-negative number")
    b[[nm]] <- v
  }
  b
}

# Flag a data frame in memory: the chunk function plus the attached columns.
flag_df <- function(x, cfg) {
  cols <- resolve_test_columns(cfg$columns, names(x), cfg$tests)
  r <- flag_chunk(x, cfg, cols)
  if (any(cfg$tests %in% .group_tests)) {
    g <- group_pass(list(list(name = "data", open = function() x)), cfg, cols)
    r$flags <- bitwOr(r$flags, group_bits(g, x, 1L, 1L, cols, hits_reader(g$hits)))
  }
  x$flags <- r$flags
  for (t in cfg$tests) x[[paste0("flag_", t)]] <- has_flag(r$flags, t)
  attr(x, "occ_tests") <- cfg$tests
  attr(x, "occ_test_plan") <- cfg$plan
  attr(x, "occ_layout_version") <- cfg$layout_version
  attr(x, "occ_reference") <- cfg$reference_label
  attr(x, "occ_columns") <- cfg$columns
  class(x) <- c("occ_flags", setdiff(class(x), "occ_flags"))
  x
}

# The engine: one chunk (data frame) to integer flag words.
flag_chunk <- function(d, cfg, cols) {
  n <- nrow(d)
  flags <- integer(n)
  tests <- cfg$tests
  nt <- cfg$n_threads %||% 1L
  set_bit <- function(test, hit) {
    hit[is.na(hit)] <- FALSE
    flags[hit] <<- bitwOr(flags[hit], flag_mask(test))
  }
  spatial <- intersect(tests, c("invalid", "zero", "equal", "capital", "centroid", "institution",
                                "gbif_headquarters", "sea", "urban", "country_mismatch",
                                "range", "aohi", .habitat_tests))
  if (length(spatial)) {
    lon <- to_numeric(d[[cols$lon]])
    lat <- to_numeric(d[[cols$lat]])
    ok <- valid_coords(lon, lat)
    bad <- !ok
    if ("invalid" %in% tests) set_bit("invalid", bad)
    lon_ok <- lon; lat_ok <- lat
    lon_ok[bad] <- NA_real_; lat_ok[bad] <- NA_real_
    if ("zero" %in% tests) {
      r <- cfg$buffers$zero
      set_bit("zero", ok & (lon == 0 | lat == 0 | sqrt(lon^2 + lat^2) <= r))
    }
    if ("equal" %in% tests) set_bit("equal", ok & abs(lon) == abs(lat))
    for (t in intersect(tests, c("capital", "centroid", "institution", "gbif_headquarters", "aohi"))) {
      idx <- cfg$custom[[t]] %||% point_index(t, cfg$reference)
      set_bit(t, cpp_point_within(idx, lon_ok, lat_ok, cfg$buffers[[t]], nt))
    }
    if (any(c("sea", .habitat_tests) %in% tests)) {
      land <- cfg$custom$sea %||% polygon_index("sea", cfg$reference, cfg$land_scale)
      on_land <- cpp_polygon_locate(land$index, lon_ok, lat_ok, nt) > 0L
      if ("sea" %in% tests) set_bit("sea", ok & !on_land)
    }
    if (any(.habitat_tests %in% tests)) {
      marine <- habitat_of(cfg$custom$habitat %||% habitat_index(), d[[cols$genus]],
                           if (!is.null(cols$kingdom)) d[[cols$kingdom]])
      off_coast <- function(hit, buffer) {
        if (buffer > 0 && any(hit))
          hit[hit] <- !cpp_polygon_near(land$index, lon_ok[hit], lat_ok[hit], buffer, nt)
        hit
      }
      if ("sea_nonmarine" %in% tests)
        set_bit("sea_nonmarine", off_coast(ok & !on_land & marine %in% FALSE, cfg$buffers$sea_nonmarine))
      if ("land_marine" %in% tests)
        set_bit("land_marine", off_coast(ok & on_land & marine %in% TRUE, cfg$buffers$land_marine))
    }
    if ("urban" %in% tests) {
      p <- cfg$custom$urban %||% polygon_index("urban", cfg$reference, cfg$land_scale)
      set_bit("urban", cpp_polygon_locate(p$index, lon_ok, lat_ok, nt) > 0L)
    }
    if ("country_mismatch" %in% tests) {
      p <- cfg$custom$country_mismatch %||%
        polygon_index("country_mismatch", cfg$reference, cfg$land_scale)
      f <- cpp_polygon_locate(p$index, lon_ok, lat_ok, nt)
      code <- toupper(trimws(as.character(d[[cols$country]])))
      code[!nzchar(code) | is.na(code)] <- NA_character_
      a3 <- p$features$iso_a3[ifelse(f > 0L, f, NA_integer_)]
      a2 <- p$features$iso_a2[ifelse(f > 0L, f, NA_integer_)]
      adm <- p$features$adm0_a3[ifelse(f > 0L, f, NA_integer_)]
      match <- (!is.na(a3) & code == a3) | (!is.na(a2) & code == a2) | (!is.na(adm) & code == adm)
      match[is.na(match)] <- FALSE
      set_bit("country_mismatch", ok & !match)
    }
    if ("range" %in% tests) {
      sp <- as.character(d[[cols$species]])
      rg <- cfg$custom$range
      hit <- logical(n)
      for (k in intersect(unique(sp[ok]), names(rg))) {
        i <- which(ok & sp == k)
        inside <- cpp_polygon_locate(rg[[k]], lon_ok[i], lat_ok[i], nt) > 0L
        if (cfg$buffers$range > 0 && any(!inside))
          inside[!inside] <- cpp_polygon_near(rg[[k]], lon_ok[i][!inside], lat_ok[i][!inside], cfg$buffers$range, nt)
        hit[i] <- !inside
      }
      set_bit("range", hit)
    }
  }
  issue_tests <- intersect(tests, c("issue_coordinate", "issue_taxon", "issue_date", "issue_rounded"))
  if (length(issue_tests)) {
    iss <- issue_sets(d[[cols$issue]])
    rec <- rep.int(seq_along(iss), lengths(iss))
    names_all <- unlist(iss, use.names = FALSE)
    for (t in issue_tests) set_bit(t, seq_len(n) %in% rec[names_all %in% .issue_groups[[t]]])
  }
  if (any(c("basis_fossil", "basis_living") %in% tests)) {
    b <- toupper(trimws(as.character(d[[cols$basis]])))
    if ("basis_fossil" %in% tests) set_bit("basis_fossil", b == "FOSSIL_SPECIMEN")
    if ("basis_living" %in% tests) set_bit("basis_living", b == "LIVING_SPECIMEN")
  }
  if (any(c("establishment_introduced", "establishment_managed") %in% tests)) {
    e <- toupper(trimws(as.character(d[[cols$establishment]])))
    if ("establishment_introduced" %in% tests)
      set_bit("establishment_introduced", e %in% c("INTRODUCED", "NATURALISED", "NATURALIZED", "INVASIVE"))
    if ("establishment_managed" %in% tests)
      set_bit("establishment_managed", e %in% c("MANAGED", "CULTIVATED"))
  }
  if ("age_equal" %in% tests) {
    lo <- to_numeric(d[[cols$min_age]])
    hi <- to_numeric(d[[cols$max_age]])
    set_bit("age_equal", lo >= hi)
  }
  list(flags = flags)
}

# Threads granted for a request: `0` or less is every thread OpenMP hands
# out, a larger request is reduced to that, with a message.
resolve_threads <- function(n_threads) {
  if (!is.numeric(n_threads) || length(n_threads) != 1L || is.na(n_threads))
    stop("`n_threads` must be a single number")
  cap <- cpp_max_threads()
  req <- as.integer(n_threads)
  if (req <= 0L) return(cap)
  if (req > cap) message("n_threads: ", req, " requested, running ", cap, " (the OpenMP limit)")
  min(req, cap)
}

to_numeric <- function(v) {
  if (is.numeric(v)) return(as.numeric(v))
  suppressWarnings(as.numeric(as.character(v)))
}

# GBIF issue names per addition test.
.issue_groups <- list(
  issue_coordinate = c("COORDINATE_INVALID", "COORDINATE_OUT_OF_RANGE", "COORDINATE_REPROJECTION_FAILED",
                       "COORDINATE_REPROJECTION_SUSPICIOUS", "COORDINATE_UNCERTAINTY_METERS_INVALID",
                       "COORDINATE_PRECISION_INVALID", "GEODETIC_DATUM_INVALID",
                       "CONTINENT_COORDINATE_MISMATCH", "COUNTRY_COORDINATE_MISMATCH",
                       "PRESUMED_SWAPPED_COORDINATE", "PRESUMED_NEGATED_LONGITUDE",
                       "PRESUMED_NEGATED_LATITUDE", "ZERO_COORDINATE"),
  issue_taxon = c("TAXON_MATCH_FUZZY", "TAXON_MATCH_HIGHERRANK", "TAXON_MATCH_NONE",
                  "TAXON_MATCH_AGGREGATE"),
  issue_date = c("RECORDED_DATE_INVALID", "RECORDED_DATE_UNLIKELY", "RECORDED_DATE_MISMATCH"),
  issue_rounded = "COORDINATE_ROUNDED"
)

# Issue column to a list of character vectors.
issue_sets <- function(v) {
  if (is.list(v)) return(lapply(v, function(s) toupper(trimws(as.character(s)))))
  v <- as.character(v)
  v[is.na(v)] <- ""
  lapply(strsplit(toupper(v), "[;,| ]+"), function(s) s[nzchar(s)])
}
