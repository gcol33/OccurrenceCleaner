.habitat_tests <- c("sea_nonmarine", "land_marine")

#' Genus habitats of the habitat tests
#'
#' Returns the genera the habitat tests `sea_nonmarine` and `land_marine` know,
#' built from the Interim Register of Marine and Nonmarine Genera (IRMNG; Rees,
#' T. (compiler) (2026). The Interim Register of Marine and Nonmarine Genera.
#' Available from https://www.irmng.org at VLIZ; CC BY 4.0), Darwin Core
#' archive of 2026-10-06. A name that is not accepted takes the habitat flags
#' of its accepted name. A genus is
#' * not marine (`marine = FALSE`) when IRMNG sets `isMarine` to 0 and does
#'   not set `isBrackish` to 1;
#' * only marine (`marine = TRUE`) when IRMNG sets `isMarine` to 1 and both
#'   `isTerrestrial` and `isFreshwater` to 0, and the genus is not extinct
#'   (fossils of extinct marine genera lie on land).
#'
#' Genera with missing flags or with both habitats are not listed, and records
#' of them are not tested. Several genera share a name across kingdoms; when
#' they disagree the name is resolved only through the record's kingdom.
#'
#' The table can be filtered or extended and passed back with
#' `gazetteers = list(habitat = <data frame>)` in [flag_occurrences()].
#'
#' @return A data frame with columns `kingdom`, `genus` and `marine`.
#' @examples
#' h <- reference_habitat()
#' table(h$kingdom, h$marine)
#' h[h$genus %in% c("Quercus", "Asterias", "Gadus"), ]
#' @export
reference_habitat <- function() {
  ref_habitat
}

# Lookup tables for a genus habitat table: by kingdom and genus, and by genus
# alone for genera whose class is the same in every kingdom listed.
habitat_lookup <- function(h) {
  by_kingdom <- stats::setNames(h$marine, paste(h$kingdom, h$genus, sep = "\t"))
  agree <- tapply(h$marine, h$genus, function(m) if (all(m == m[1])) m[1] else NA)
  agree <- agree[!is.na(agree)]
  list(by_kingdom = by_kingdom, by_genus = stats::setNames(as.logical(agree), names(agree)))
}

habitat_index <- function() {
  key <- "habitat/IRMNG"
  if (!is.null(.occ_cache[[key]])) return(.occ_cache[[key]])
  .occ_cache[[key]] <- habitat_lookup(ref_habitat)
  .occ_cache[[key]]
}

# Habitat class per record: TRUE only marine, FALSE not marine, NA unknown.
# The genus is the first word of the genus field. When the table names
# kingdoms, a record with a kingdom is looked up by kingdom and genus, so a
# genus listed only in another kingdom is unknown for it.
habitat_of <- function(idx, genus, kingdom = NULL) {
  g <- trimws(as.character(genus))
  g <- sub("[[:space:]].*$", "", g)
  g[!nzchar(g)] <- NA_character_
  out <- unname(idx$by_genus[g])
  if (!is.null(kingdom) && !is.null(idx$by_kingdom)) {
    k <- trimws(as.character(kingdom))
    has_k <- !is.na(k) & nzchar(k) & !is.na(g)
    out[has_k] <- unname(idx$by_kingdom[paste(k[has_k], g[has_k], sep = "\t")])
  }
  out
}

# A user habitat table: a data frame with a genus column and a logical marine
# column, and optionally a kingdom column.
gazetteer_habitat <- function(g) {
  if (!is.data.frame(g)) stop("`gazetteers$habitat` must be a data frame with genus and marine columns")
  nm <- tolower(names(g))
  gi <- match("genus", nm); mi <- match("marine", nm); ki <- match("kingdom", nm)
  if (is.na(gi) || is.na(mi)) stop("`gazetteers$habitat` needs a genus column and a logical marine column")
  marine <- g[[mi]]
  if (!is.logical(marine)) stop("`gazetteers$habitat$marine` must be logical (TRUE only marine, FALSE not marine)")
  h <- data.frame(kingdom = if (is.na(ki)) NA_character_ else trimws(as.character(g[[ki]])),
                  genus = trimws(as.character(g[[gi]])), marine = marine, stringsAsFactors = FALSE)
  h <- h[!is.na(h$genus) & nzchar(h$genus) & !is.na(h$marine), , drop = FALSE]
  if (!nrow(h)) stop("`gazetteers$habitat` has no genus with a habitat")
  h
}
