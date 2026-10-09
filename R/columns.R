#' Name the record fields
#'
#' Tells [flag_occurrences()] which columns of the input hold each field. The
#' defaults are the Darwin Core terms GBIF uses; matching is case-insensitive,
#' so GBIF's lower-case snapshot columns (`decimallongitude`, ...) are found by
#' the defaults too. Fields are resolved only when a requested test needs them.
#'
#' @param lon,lat Longitude and latitude in decimal degrees.
#' @param species Taxon name or key used by the duplicate test.
#' @param country Country code of the record (ISO 3166-1 alpha-2 or alpha-3),
#'   used by the `coun` test.
#' @param issue GBIF issue flags, either a character column with the issue
#'   names separated by `;` (as the GBIF snapshot read through vectra gives) or
#'   a list column of character vectors.
#' @param basis Basis of record (`basisOfRecord`).
#' @param establishment Establishment means (`establishmentMeans`).
#' @param id Record identifier, copied into on-disk flag output when present.
#' @return A named list of column names with class `occ_columns`.
#' @examples
#' occ_columns(lon = "x", lat = "y")
#' @export
occ_columns <- function(lon = "decimalLongitude", lat = "decimalLatitude", species = "species",
                        country = "countryCode", issue = "issue", basis = "basisOfRecord",
                        establishment = "establishmentMeans", id = "gbifID") {
  cols <- list(lon = lon, lat = lat, species = species, country = country, issue = issue,
               basis = basis, establishment = establishment, id = id)
  for (nm in names(cols)) {
    v <- cols[[nm]]
    if (!is.character(v) || length(v) != 1L || is.na(v) || !nzchar(v))
      stop("column name for `", nm, "` must be a single non-empty string")
  }
  structure(cols, class = "occ_columns")
}

# Resolve the field names a set of tests needs against the available column
# names. Exact match first, then a unique case-insensitive match.
resolve_columns <- function(columns, available, fields, optional = character()) {
  if (!inherits(columns, "occ_columns")) stop("`columns` must come from occ_columns()")
  out <- list()
  for (f in fields) {
    want <- columns[[f]]
    hit <- if (want %in% available) want else {
      m <- available[tolower(available) == tolower(want)]
      if (length(m) == 1L) m else NA_character_
    }
    if (is.na(hit)) {
      if (f %in% optional) next
      stop("column `", want, "` (field `", f, "`) not found in the input; set it with occ_columns()")
    }
    out[[f]] <- hit
  }
  out
}

# Fields needed by a set of tests.
fields_for <- function(tests) {
  needs <- .flag_layout$needs[match(tests, .flag_layout$test)]
  unique(unlist(strsplit(needs, ",", fixed = TRUE)))
}
