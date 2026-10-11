#' Flag occurrence records
#'
#' Runs a set of record tests over species occurrence records and writes one
#' flag per record per test. Nothing is removed and no threshold is baked in: a
#' cleaning rule is a set of tests, applied afterwards with [has_flag()] or
#' summarised with [tally_flags()].
#'
#' The grouped tests (`outlier`, the three fossil outlier tests and the two
#' dataset tests) compare a record with the other records of its species,
#' taxon or dataset; they run in a pass over the whole input before the record
#' tests, which on streamed input reads every file once or twice more.
#'
#' The input is either a data frame, or an on-disk table streamed in chunks: a
#' `vectra_node` (from `vectra::tbl_parquet()`, `vectra::tbl_csv()`,
#' `vectra::tbl()`), a path to a Parquet file or directory of Parquet parts
#' (such as a GBIF snapshot), or a path to a `.vtr` or delimited text file. For
#' a directory each file is one resumable unit of work; the return follows the
#' input, see Value.
#'
#' @section Tests:
#' See [flag_tests()] for the layout. Tests equivalent to CoordinateCleaner use
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
#' * `cc_zero`'s 0.5 degree buffer is interpreted by terra as 0.5 metres, so
#'   CoordinateCleaner 3.0.1 flags only exact zeros; this package applies the
#'   documented 0.5 degree radius.
#' * `country_mismatch` compares the record's code with the ISO alpha-2 code,
#'   the ISO alpha-3 code and the Natural Earth `ADM0_A3` code of the country
#'   polygon the point falls in, taking the ISO codes from Natural Earth's
#'   `ISO_A2_EH` and `ISO_A3_EH` columns, which are filled where `ISO_A2` and
#'   `ISO_A3` hold `-99` (France, Norway, Kosovo); CoordinateCleaner compares
#'   `ISO_A3` only, so it flags every record in France and Norway.
#'   Records without a code, or at sea, are flagged as in CoordinateCleaner.
#' * `duplicate` on streamed input is evaluated within each input file (Parquet
#'   part), not across the whole table.
#' * `outlier` flags the records of outlier cells in the raster approximation
#'   (species of 10,000 records or more, or `thinning = TRUE`); in
#'   CoordinateCleaner 3.0.1 that path never flags a record.
#' * `age_outlier` and `spatiotemporal_outlier` draw ages from a stream seeded
#'   per taxon, so they agree with `cf_age()` and `cf_outl()` in distribution;
#'   when every age range has zero width the flags are identical.
#' * `dataset_rounded` leaves datasets below `min_unique_ds_size` untested,
#'   where `cd_round()` stops with an error; the dataset tests do not flag
#'   records without a dataset key.
#' * With the default reference the gazetteers are rebuilt from the original
#'   sources; `reference = "CoordinateCleaner"` uses that package's own tables,
#'   and `gazetteers` replaces the layer of single tests, as the `ref`
#'   arguments of CoordinateCleaner's functions do.
#'
#' @param x A data frame, a `vectra_node`, or a path (file or directory).
#' @param tests Character vector of test names, see [flag_tests()]. Default
#'   [default_tests()]. A test whose fields are missing from `x` is an error.
#' @param columns Field names, see [occ_columns()].
#' @param reference `"natural_earth"` (own gazetteers, the default) or
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
#' @param resume Skip input units whose output already exists.
#' @param verbose Report progress for streamed input.
#' @return For a data frame: `x` with an integer column `flags` and one logical
#'   column `flag_<test>` per test, class `occ_flags` added in front, and
#'   attributes `occ_tests`, `occ_layout_version`, `occ_reference` and
#'   `occ_columns`. [summary()][summary.occ_flags] reports the share of records
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
                             reference = c("natural_earth", "CoordinateCleaner"),
                             gazetteers = NULL, land_scale = 110, buffers = NULL,
                             settings = NULL, duplicate_by = NULL,
                             duplicate_cell = NULL,
                             out = NULL, keep = NULL, part_rows = 2e6, resume = TRUE,
                             verbose = TRUE) {
  tests <- check_tests(tests)
  reference <- match.arg(reference)
  if (!land_scale %in% c(110, 50, 10)) stop("`land_scale` must be 110, 50 or 10")
  if ("range" %in% tests && is.null(gazetteers$range))
    stop("the range test needs species range polygons: gazetteers = list(range = <sf>)")
  custom <- prepare_gazetteers(gazetteers, columns)
  cfg <- list(tests = tests, columns = columns, reference = reference, land_scale = land_scale,
              buffers = check_buffers(buffers), settings = check_settings(settings),
              duplicate_by = duplicate_by,
              duplicate_cell = duplicate_cell, custom = custom$index,
              layout_version = .layout_version,
              reference_label = reference_label(reference, land_scale, custom$label))
  if (is.data.frame(x)) return(flag_df(x, cfg))
  flag_stream(x, cfg, out = out, keep = keep, part_rows = part_rows, resume = resume,
              verbose = verbose)
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
    r$flags <- bitwOr(r$flags, group_bits(g, x, 1L, 1L, cols))
  }
  x$flags <- r$flags
  for (t in cfg$tests) x[[paste0("flag_", t)]] <- has_flag(r$flags, t)
  attr(x, "occ_tests") <- cfg$tests
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
  set_bit <- function(test, hit) {
    hit[is.na(hit)] <- FALSE
    flags[hit] <<- bitwOr(flags[hit], flag_mask(test))
  }
  spatial <- intersect(tests, c("invalid", "zero", "equal", "capital", "centroid", "institution",
                                "gbif_headquarters", "sea", "urban", "country_mismatch",
                                "duplicate", "range", "aohi", .habitat_tests))
  if (length(spatial)) {
    lon <- to_numeric(d[[cols$lon]])
    lat <- to_numeric(d[[cols$lat]])
    bad <- !is.finite(lon) | !is.finite(lat) | lon < -180 | lon > 180 | lat < -90 | lat > 90
    if ("invalid" %in% tests) set_bit("invalid", bad)
    ok <- !bad
    lon_ok <- lon; lat_ok <- lat
    lon_ok[bad] <- NA_real_; lat_ok[bad] <- NA_real_
    if ("zero" %in% tests) {
      r <- cfg$buffers$zero
      set_bit("zero", ok & (lon == 0 | lat == 0 | sqrt(lon^2 + lat^2) <= r))
    }
    if ("equal" %in% tests) set_bit("equal", ok & abs(lon) == abs(lat))
    for (t in intersect(tests, c("capital", "centroid", "institution", "gbif_headquarters", "aohi"))) {
      idx <- cfg$custom[[t]] %||% point_index(t, cfg$reference)
      set_bit(t, cpp_point_within(idx, lon_ok, lat_ok, cfg$buffers[[t]]))
    }
    if (any(c("sea", .habitat_tests) %in% tests)) {
      land <- cfg$custom$sea %||% polygon_index("sea", cfg$reference, cfg$land_scale)
      on_land <- cpp_polygon_locate(land$index, lon_ok, lat_ok) > 0L
      if ("sea" %in% tests) set_bit("sea", ok & !on_land)
    }
    if (any(.habitat_tests %in% tests)) {
      marine <- habitat_of(cfg$custom$habitat %||% habitat_index(), d[[cols$genus]],
                           if (!is.null(cols$kingdom)) d[[cols$kingdom]])
      off_coast <- function(hit, buffer) {
        if (buffer > 0 && any(hit))
          hit[hit] <- !cpp_polygon_near(land$index, lon_ok[hit], lat_ok[hit], buffer)
        hit
      }
      if ("sea_nonmarine" %in% tests)
        set_bit("sea_nonmarine", off_coast(ok & !on_land & marine %in% FALSE, cfg$buffers$sea_nonmarine))
      if ("land_marine" %in% tests)
        set_bit("land_marine", off_coast(ok & on_land & marine %in% TRUE, cfg$buffers$land_marine))
    }
    if ("urban" %in% tests) {
      p <- cfg$custom$urban %||% polygon_index("urban", cfg$reference, cfg$land_scale)
      set_bit("urban", cpp_polygon_locate(p$index, lon_ok, lat_ok) > 0L)
    }
    if ("country_mismatch" %in% tests) {
      p <- cfg$custom$country_mismatch %||%
        polygon_index("country_mismatch", cfg$reference, cfg$land_scale)
      f <- cpp_polygon_locate(p$index, lon_ok, lat_ok)
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
        inside <- cpp_polygon_locate(rg[[k]], lon_ok[i], lat_ok[i]) > 0L
        if (cfg$buffers$range > 0 && any(!inside))
          inside[!inside] <- cpp_polygon_near(rg[[k]], lon_ok[i][!inside], lat_ok[i][!inside], cfg$buffers$range)
        hit[i] <- !inside
      }
      set_bit("range", hit)
    }
    if ("duplicate" %in% tests) {
      kx <- lon; ky <- lat
      if (!is.null(cfg$duplicate_cell)) {
        kx <- floor(lon / cfg$duplicate_cell); ky <- floor(lat / cfg$duplicate_cell)
      }
      key <- data.frame(kx, ky, as.character(d[[cols$species]]), stringsAsFactors = FALSE)
      for (extra in cfg$duplicate_by) {
        if (!extra %in% names(d)) stop("`duplicate_by` column `", extra, "` not found in the input")
        key[[extra]] <- d[[extra]]
      }
      set_bit("duplicate", ok & duplicated(key))
    }
  }
  issue_tests <- intersect(tests, c("issue_coordinate", "issue_taxon", "issue_date", "issue_rounded"))
  if (length(issue_tests)) {
    iss <- issue_sets(d[[cols$issue]])
    for (t in issue_tests) set_bit(t, vapply(iss, function(s) any(s %in% .issue_groups[[t]]), logical(1)))
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
