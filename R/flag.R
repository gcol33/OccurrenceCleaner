#' Flag occurrence records
#'
#' Runs a set of record tests over species occurrence records and writes one
#' flag per record per test. Nothing is removed and no threshold is baked in: a
#' cleaning rule is a set of tests, applied afterwards with [has_flag()] or
#' summarised with [tally_flags()].
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
#' its default buffers: `cap` 10 km, `cen` 1 km, `inst` 100 m, `gbif` 1 km,
#' `zero` 0.5 degrees. Proximity tests are closed balls in WGS84 geodesic
#' distance. Records failing `val` are given no spatial flag.
#'
#' Documented differences to CoordinateCleaner 3.0.1, each verified in the
#' package tests:
#' * CoordinateCleaner approximates each buffer circle by an inscribed polygon
#'   (72 vertices for `cap`, `cen`, `gbif`; 40 for `inst`), so a record between
#'   99.9 % (`cap`, `cen`, `gbif`) or 99.7 % (`inst`) of the buffer and the
#'   buffer itself is flagged here and may not be there. Everything
#'   CoordinateCleaner flags is flagged here.
#' * `cc_zero`'s 0.5 degree buffer is interpreted by terra as 0.5 metres, so
#'   CoordinateCleaner 3.0.1 flags only exact zeros; this package applies the
#'   documented 0.5 degree radius.
#' * `coun` compares the record's code with both the alpha-2 and alpha-3 codes
#'   of the Natural Earth country polygon the point falls in; CoordinateCleaner
#'   compares alpha-3 only. Records without a code, or at sea, are flagged as in
#'   CoordinateCleaner.
#' * `dupl` on streamed input is evaluated within each input file (Parquet
#'   part), not across the whole table.
#' * With the default reference the gazetteers are rebuilt from the original
#'   sources; `reference = "CoordinateCleaner"` uses that package's own tables.
#'
#' @param x A data frame, a `vectra_node`, or a path (file or directory).
#' @param tests Character vector of test names, see [flag_tests()]. Default
#'   [default_tests()]. A test whose fields are missing from `x` is an error.
#' @param columns Field names, see [occ_columns()].
#' @param reference `"natural_earth"` (own gazetteers, the default) or
#'   `"CoordinateCleaner"` (that package's tables, read at run time). See
#'   [reference_info()].
#' @param land_scale Natural Earth scale of the land layer for `sea`: 110
#'   (CoordinateCleaner's default), 50, or 10 (downloaded on first use, see
#'   [download_reference()]).
#' @param buffers Named list overriding buffer distances in metres for `cap`,
#'   `cen`, `inst`, `gbif`, or in degrees for `zero`. Unnamed entries keep the
#'   defaults.
#' @param dupl_by Additional column names a duplicate must share (as
#'   CoordinateCleaner's `additions`), for example an event date.
#' @param dupl_cell Cell size in degrees. When given, coordinates are binned to
#'   this grid before comparing duplicates, so "same cell and species" counts.
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
#'   column `flag_<test>` per test, and attributes `occ_tests`,
#'   `occ_layout_version` and `occ_reference`. For streamed input: an object of
#'   class `occ_flagged` describing the output directory, which [tally_flags()]
#'   accepts; the parts are `.vtr` files holding the `id` and `keep` columns and
#'   `flags`, readable with `vectra::tbl()`.
#' @examples
#' x <- data.frame(species = c("a", "a", "b", "c"),
#'                 decimalLongitude = c(12.58, 0, 16.37, 2.35),
#'                 decimalLatitude = c(55.67, 0, 48.21, 48.85))
#' f <- flag_occurrences(x, tests = c("val", "zero", "gbif", "cap"))
#' f[, c("species", "flags", "flag_zero", "flag_gbif", "flag_cap")]
#' @export
flag_occurrences <- function(x, tests = NULL, columns = occ_columns(),
                             reference = c("natural_earth", "CoordinateCleaner"),
                             land_scale = 110, buffers = NULL, dupl_by = NULL, dupl_cell = NULL,
                             out = NULL, keep = NULL, part_rows = 2e6, resume = TRUE,
                             verbose = TRUE) {
  tests <- check_tests(tests)
  reference <- match.arg(reference)
  if (!land_scale %in% c(110, 50, 10)) stop("`land_scale` must be 110, 50 or 10")
  cfg <- list(tests = tests, columns = columns, reference = reference, land_scale = land_scale,
              buffers = check_buffers(buffers), dupl_by = dupl_by, dupl_cell = dupl_cell,
              layout_version = .layout_version, reference_label = reference_label(reference, land_scale))
  if (is.data.frame(x)) return(flag_df(x, cfg))
  flag_stream(x, cfg, out = out, keep = keep, part_rows = part_rows, resume = resume,
              verbose = verbose)
}

.default_buffers <- list(cap = 10000, cen = 1000, inst = 100, gbif = 1000, zero = 0.5)

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
  cols <- resolve_columns(cfg$columns, names(x), fields_for(cfg$tests))
  r <- flag_chunk(x, cfg, cols)
  x$flags <- r$flags
  for (t in cfg$tests) x[[paste0("flag_", t)]] <- has_flag(r$flags, t)
  attr(x, "occ_tests") <- cfg$tests
  attr(x, "occ_layout_version") <- cfg$layout_version
  attr(x, "occ_reference") <- cfg$reference_label
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
  spatial <- intersect(tests, c("val", "zero", "equ", "cap", "cen", "inst", "gbif", "sea", "urb", "coun", "dupl"))
  if (length(spatial)) {
    lon <- to_numeric(d[[cols$lon]])
    lat <- to_numeric(d[[cols$lat]])
    bad <- !is.finite(lon) | !is.finite(lat) | lon < -180 | lon > 180 | lat < -90 | lat > 90
    if ("val" %in% tests) set_bit("val", bad)
    ok <- !bad
    lon_ok <- lon; lat_ok <- lat
    lon_ok[bad] <- NA_real_; lat_ok[bad] <- NA_real_
    if ("zero" %in% tests) {
      r <- cfg$buffers$zero
      set_bit("zero", ok & (lon == 0 | lat == 0 | sqrt(lon^2 + lat^2) <= r))
    }
    if ("equ" %in% tests) set_bit("equ", ok & abs(lon) == abs(lat))
    for (t in intersect(tests, c("cap", "cen", "inst", "gbif"))) {
      idx <- point_index(t, cfg$reference)
      set_bit(t, cpp_point_within(idx, lon_ok, lat_ok, cfg$buffers[[t]]))
    }
    if ("sea" %in% tests) {
      p <- polygon_index("sea", cfg$reference, cfg$land_scale)
      set_bit("sea", ok & cpp_polygon_locate(p$index, lon_ok, lat_ok) == 0L)
    }
    if ("urb" %in% tests) {
      p <- polygon_index("urb", cfg$reference, cfg$land_scale)
      set_bit("urb", cpp_polygon_locate(p$index, lon_ok, lat_ok) > 0L)
    }
    if ("coun" %in% tests) {
      p <- polygon_index("coun", cfg$reference, cfg$land_scale)
      f <- cpp_polygon_locate(p$index, lon_ok, lat_ok)
      code <- toupper(trimws(as.character(d[[cols$country]])))
      code[!nzchar(code) | is.na(code)] <- NA_character_
      a3 <- p$features$iso_a3[ifelse(f > 0L, f, NA_integer_)]
      a2 <- p$features$iso_a2[ifelse(f > 0L, f, NA_integer_)]
      adm <- p$features$adm0_a3[ifelse(f > 0L, f, NA_integer_)]
      match <- (!is.na(a3) & code == a3) | (!is.na(a2) & code == a2) | (!is.na(adm) & code == adm)
      match[is.na(match)] <- FALSE
      set_bit("coun", ok & !match)
    }
    if ("dupl" %in% tests) {
      kx <- lon; ky <- lat
      if (!is.null(cfg$dupl_cell)) {
        kx <- floor(lon / cfg$dupl_cell); ky <- floor(lat / cfg$dupl_cell)
      }
      key <- data.frame(kx, ky, as.character(d[[cols$species]]), stringsAsFactors = FALSE)
      for (extra in cfg$dupl_by) {
        if (!extra %in% names(d)) stop("`dupl_by` column `", extra, "` not found in the input")
        key[[extra]] <- d[[extra]]
      }
      set_bit("dupl", ok & duplicated(key))
    }
  }
  issue_tests <- intersect(tests, c("issue_geo", "issue_tax", "issue_date", "rounded"))
  if (length(issue_tests)) {
    iss <- issue_sets(d[[cols$issue]])
    for (t in issue_tests) set_bit(t, vapply(iss, function(s) any(s %in% .issue_groups[[t]]), logical(1)))
  }
  if (any(c("fossil", "living") %in% tests)) {
    b <- toupper(trimws(as.character(d[[cols$basis]])))
    if ("fossil" %in% tests) set_bit("fossil", b == "FOSSIL_SPECIMEN")
    if ("living" %in% tests) set_bit("living", b == "LIVING_SPECIMEN")
  }
  if (any(c("introduced", "managed") %in% tests)) {
    e <- toupper(trimws(as.character(d[[cols$establishment]])))
    if ("introduced" %in% tests) set_bit("introduced", e %in% c("INTRODUCED", "NATURALISED", "NATURALIZED", "INVASIVE"))
    if ("managed" %in% tests) set_bit("managed", e %in% c("MANAGED", "CULTIVATED"))
  }
  list(flags = flags)
}

to_numeric <- function(v) {
  if (is.numeric(v)) return(as.numeric(v))
  suppressWarnings(as.numeric(as.character(v)))
}

# GBIF issue names per addition test.
.issue_groups <- list(
  issue_geo = c("COORDINATE_INVALID", "COORDINATE_OUT_OF_RANGE", "COORDINATE_REPROJECTION_FAILED",
                "COORDINATE_REPROJECTION_SUSPICIOUS", "COORDINATE_UNCERTAINTY_METERS_INVALID",
                "COORDINATE_PRECISION_INVALID", "GEODETIC_DATUM_INVALID", "CONTINENT_COORDINATE_MISMATCH",
                "COUNTRY_COORDINATE_MISMATCH", "PRESUMED_SWAPPED_COORDINATE", "PRESUMED_NEGATED_LONGITUDE",
                "PRESUMED_NEGATED_LATITUDE", "ZERO_COORDINATE"),
  issue_tax = c("TAXON_MATCH_FUZZY", "TAXON_MATCH_HIGHERRANK", "TAXON_MATCH_NONE", "TAXON_MATCH_AGGREGATE"),
  issue_date = c("RECORDED_DATE_INVALID", "RECORDED_DATE_UNLIKELY", "RECORDED_DATE_MISMATCH"),
  rounded = "COORDINATE_ROUNDED"
)

# Issue column to a list of character vectors.
issue_sets <- function(v) {
  if (is.list(v)) return(lapply(v, function(s) toupper(trimws(as.character(s)))))
  v <- as.character(v)
  v[is.na(v)] <- ""
  lapply(strsplit(toupper(v), "[;,| ]+"), function(s) s[nzchar(s)])
}
