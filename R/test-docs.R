#' Test: invalid coordinates
#'
#' Flags records whose longitude or latitude is missing, not a number, or
#' outside \[-180, 180\] x \[-90, 90\]. Text columns are coerced with
#' `as.numeric(as.character())` first. A record failing this test gets no
#' other spatial flag.
#'
#' @section Fields: `lon`, `lat` (see [occ_columns()]).
#' @section CoordinateCleaner: Equivalent to `cc_val()`. Its other spatial
#'   tests return `NA` or "clean" for invalid rows; here those rows carry only
#'   the `invalid` bit.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(decimalLongitude = c("16.37", "abc", NA, "200"),
#'                 decimalLatitude = c("48.21", "10", "10", "10"))
#' flag_occurrences(x, tests = "invalid")$flag_invalid
#' @name test_invalid
NULL

#' Test: zero coordinates
#'
#' Flags records with a longitude or latitude of exactly zero, and records
#' within a planar distance of 0.5 degrees of (0, 0).
#'
#' @section Fields: `lon`, `lat`.
#' @section Buffer: `buffers = list(zero = 0.5)`, in degrees. `zero = 0`
#'   flags exact zeros only.
#' @section CoordinateCleaner: Equivalent to `cc_zero()`. CoordinateCleaner
#'   3.0.1 documents the same 0.5 degree buffer, but builds the buffer point
#'   without a CRS, so terra buffers 0.5 metres and only exact zeros are
#'   flagged. `buffers = list(zero = 0)` reproduces that behaviour.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(decimalLongitude = c(0, 0.3, 0.4), decimalLatitude = c(42, 0.3, 0.4))
#' flag_occurrences(x, tests = "zero")$flag_zero
#' flag_occurrences(x, tests = "zero", buffers = list(zero = 0))$flag_zero
#' @name test_zero
NULL

#' Test: equal coordinates
#'
#' Flags records whose absolute longitude equals their absolute latitude, the
#' result of one value being entered in both fields.
#'
#' @section Fields: `lon`, `lat`.
#' @section CoordinateCleaner: Equivalent to `cc_equ()` with its default
#'   `test = "absolute"`; identical flags.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(decimalLongitude = c(10, -10, 10.0001), decimalLatitude = 10)
#' flag_occurrences(x, tests = "equal")$flag_equal
#' @name test_equal
NULL

#' Test: country capitals
#'
#' Flags records within 10 km of a country capital, measured as WGS84
#' geodesic distance (closed ball: a record at exactly the buffer distance is
#' flagged). Candidates are found with a kd-tree on the unit sphere and
#' decided with the Vincenty inverse formula.
#'
#' The default gazetteer holds 243 Natural Earth populated places of the
#' classes admin-0 capital, alternative capital and admin-0 region capital
#' (dependent territories); see [reference_info()].
#'
#' @section Fields: `lon`, `lat`.
#' @section Buffer: `buffers = list(capital = 10000)`, in metres.
#' @section CoordinateCleaner: Equivalent to `cc_cap()`. CoordinateCleaner
#'   draws the buffer as a 72-gon with vertices on the circle, whose edge lies
#'   at 99.9 % of the buffer between vertices; records in that band (within
#'   9.5 m of the 10 km edge) are flagged here and may not be there. With
#'   `reference = "CoordinateCleaner"` its `countryref` capitals are used.
#' @section Custom gazetteer: `gazetteers = list(capital = points)`, a data frame
#'   of longitude and latitude; see [flag_occurrences()].
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()], [reference_info()]
#' @examples
#' x <- data.frame(decimalLongitude = c(16.37, 16.51), decimalLatitude = c(48.21, 48.25))
#' flag_occurrences(x, tests = "capital")$flag_capital
#' flag_occurrences(x, tests = "capital", buffers = list(capital = 20000))$flag_capital
#' @name test_capital
NULL

#' Test: country and province centroids
#'
#' Flags records within 1 km of a country or province centroid (WGS84
#' geodesic distance, closed ball). The default gazetteer holds Natural Earth
#' 5.1.1 country polygon centroids and label points and admin-1 label points.
#'
#' @section Fields: `lon`, `lat`.
#' @section Buffer: `buffers = list(centroid = 1000)`, in metres.
#' @section CoordinateCleaner: Equivalent to `cc_cen()` with `test = "both"`.
#'   Its 72-gon buffer edge lies within 0.95 m of the 1 km circle. Its country
#'   centroids come from other sources (median 30 km from the Natural Earth
#'   ones); its province centroids are the admin-1 label points of an older
#'   Natural Earth release.
#' @section Custom gazetteer: `gazetteers = list(centroid = points)`, a data frame
#'   of longitude and latitude; see [flag_occurrences()].
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()], [reference_info()]
#' @examples
#' x <- data.frame(decimalLongitude = c(14.1307, 10), decimalLatitude = c(47.5857, 50))
#' flag_occurrences(x, tests = "centroid")$flag_centroid
#' @name test_centroid
NULL

#' Test: biodiversity institutions
#'
#' Flags records within 100 m of a biodiversity institution (WGS84 geodesic
#' distance, closed ball): herbaria, museums, botanic gardens, zoos and
#' universities holding collections, where specimens are often georeferenced
#' to the institution. The default gazetteer is the 6,085 institutions with
#' coordinates in GBIF's Global Registry of Scientific Collections
#' (GRSciColl).
#'
#' @section Fields: `lon`, `lat`.
#' @section Buffer: `buffers = list(institution = 100)`, in metres.
#' @section CoordinateCleaner: Equivalent to `cc_inst()`. Its 40-gon buffer
#'   edge lies within 0.31 m of the 100 m circle. Its `institutions` table
#'   also holds botanic gardens from BGCI and points from Wikipedia and
#'   GeoNames, which `reference = "CoordinateCleaner"` uses.
#' @section Custom gazetteer: `gazetteers = list(institution = points)`, a data frame
#'   of longitude and latitude; see [flag_occurrences()].
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()], [reference_info()]
#' @examples
#' x <- data.frame(decimalLongitude = c(16.3598, 15), decimalLatitude = c(48.2052, 47))
#' flag_occurrences(x, tests = "institution")$flag_institution
#' @name test_institution
NULL

#' Test: GBIF headquarters
#'
#' Flags records within 1 km of the GBIF secretariat in Copenhagen (12.58 E,
#' 55.67 N), a location some records receive as a default.
#'
#' @section Fields: `lon`, `lat`.
#' @section Buffer: `buffers = list(gbif_headquarters = 1000)`, in metres.
#' @section CoordinateCleaner: Equivalent to `cc_gbif()`; same point, 72-gon
#'   buffer within 0.95 m of the 1 km circle. The point lies outside the
#'   1:50m Natural Earth coast, so it also fails `sea` at `land_scale = 50`
#'   and `country_mismatch` with code `"DK"`, in both packages.
#' @section Custom gazetteer: `gazetteers = list(gbif_headquarters = points)`, a data frame
#'   of longitude and latitude; see [flag_occurrences()].
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(decimalLongitude = c(12.58, 12.6), decimalLatitude = c(55.67, 55.7))
#' flag_occurrences(x, tests = "gbif_headquarters")$flag_gbif_headquarters
#' @name test_gbif_headquarters
NULL

#' Test: records at sea
#'
#' Flags records outside the Natural Earth land polygons, by a planar
#' point-in-polygon test in longitude and latitude through a grid index that
#' resolves boundary cells exactly. The land layer is chosen with
#' `land_scale`: 110 (default), 50, or 10. The 1:10m layer is downloaded once
#' by [download_reference()].
#'
#' @section Fields: `lon`, `lat`.
#' @section CoordinateCleaner: Equivalent to `cc_sea()` with its default
#'   `scale = 110` (`clean_coordinates()` uses `seas_scale = 50`, which is
#'   `land_scale = 50` here); identical flags on
#'   the same layer. CoordinateCleaner downloads the layer through
#'   rnaturalearth at run time; here it is bundled and pinned.
#' @section Custom gazetteer: `gazetteers = list(sea = polygons)`, an `sf` or
#'   `sfc` object of land polygons; see [flag_occurrences()].
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()], [reference_info()]
#' @examples
#' x <- data.frame(decimalLongitude = c(12.58, 16.37, -30), decimalLatitude = c(55.67, 48.21, 40))
#' flag_occurrences(x, tests = "sea")$flag_sea
#' flag_occurrences(x, tests = "sea", land_scale = 50)$flag_sea
#' @name test_sea
NULL

#' Test: urban areas
#'
#' Flags records inside the Natural Earth 1:50m urban-area polygons. Not in
#' [default_tests()], as urban records are often correct.
#'
#' @section Fields: `lon`, `lat`.
#' @section CoordinateCleaner: Equivalent to `cc_urb()` with its default
#'   1:50m urban areas; identical flags on the same layer. Not run by
#'   `clean_coordinates()` by default either.
#' @section Custom gazetteer: `gazetteers = list(urban = polygons)`, an `sf` or
#'   `sfc` object of urban-area polygons; see [flag_occurrences()].
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(decimalLongitude = c(16.37, 15.3), decimalLatitude = c(48.21, 47.5))
#' flag_occurrences(x, tests = "urban")$flag_urban
#' @name test_urban
NULL

#' Test: country code mismatch
#'
#' Flags records whose coordinates fall outside the Natural Earth 1:50m
#' country polygon named by their country code. The code is compared with the
#' polygon's ISO 3166-1 alpha-2 code, its alpha-3 code and the Natural Earth
#' `ADM0_A3` code, case-insensitively. Records without a code, and records at
#' sea, are flagged.
#'
#' @section Fields: `lon`, `lat`, `country`.
#' @section CoordinateCleaner: Equivalent to `cc_coun()`, which compares
#'   alpha-3 codes only; for alpha-3 codes present in Natural Earth the flags
#'   are identical. GBIF's `countryCode` is alpha-2 and works here without
#'   conversion.
#' @section Custom gazetteer: `gazetteers = list(country_mismatch = polygons)`, an `sf` or
#'   `sfc` object of country polygons with a code column; see [flag_occurrences()].
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()], [occ_columns()]
#' @examples
#' x <- data.frame(decimalLongitude = 16.37, decimalLatitude = 48.21,
#'                 countryCode = c("AT", "AUT", "DE", NA))
#' flag_occurrences(x, tests = "country_mismatch")$flag_country_mismatch
#' @name test_country_mismatch
NULL

#' Test: duplicates
#'
#' Flags every record with the same longitude, latitude and species as an
#' earlier record; the first of each set is not flagged. `duplicate_by` adds
#' columns that must also match; `duplicate_cell` bins coordinates to a grid
#' of that many degrees first. On streamed input the test runs within each
#' input file.
#'
#' @section Fields: `lon`, `lat`, `species`, and any `duplicate_by` columns.
#' @section CoordinateCleaner: Equivalent to `cc_dupl()`, with `duplicate_by`
#'   as its `additions`. Records with invalid coordinates are not flagged here;
#'   `cc_dupl()` flags the second of two such records.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(species = "a", decimalLongitude = c(16.37, 16.37, 16.3701),
#'                 decimalLatitude = 48.21, eventDate = c("2020", "2021", "2020"))
#' flag_occurrences(x, tests = "duplicate")$flag_duplicate
#' flag_occurrences(x, tests = "duplicate", duplicate_by = "eventDate")$flag_duplicate
#' flag_occurrences(x, tests = "duplicate", duplicate_cell = 0.01)$flag_duplicate
#' @name test_duplicate
NULL

#' Tests: GBIF issue flags
#'
#' Four tests read the issue names GBIF attaches to a record during
#' processing:
#' * `issue_coordinate`: COORDINATE_INVALID, COORDINATE_OUT_OF_RANGE,
#'   COORDINATE_REPROJECTION_FAILED, COORDINATE_REPROJECTION_SUSPICIOUS,
#'   COORDINATE_UNCERTAINTY_METERS_INVALID, COORDINATE_PRECISION_INVALID,
#'   GEODETIC_DATUM_INVALID, CONTINENT_COORDINATE_MISMATCH,
#'   COUNTRY_COORDINATE_MISMATCH, PRESUMED_SWAPPED_COORDINATE,
#'   PRESUMED_NEGATED_LONGITUDE, PRESUMED_NEGATED_LATITUDE, ZERO_COORDINATE;
#' * `issue_taxon`: TAXON_MATCH_FUZZY, TAXON_MATCH_HIGHERRANK,
#'   TAXON_MATCH_NONE, TAXON_MATCH_AGGREGATE;
#' * `issue_date`: RECORDED_DATE_INVALID, RECORDED_DATE_UNLIKELY,
#'   RECORDED_DATE_MISMATCH;
#' * `issue_rounded`: COORDINATE_ROUNDED, which GBIF sets when it rounds a
#'   coordinate to five decimals.
#'
#' The `issue` column is a string of names separated by `;`, `,`, `|` or
#' spaces, or a list column of character vectors; case is ignored.
#'
#' @section Fields: `issue`.
#' @section CoordinateCleaner: No equivalent; additions of this package.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(issue = c("COORDINATE_ROUNDED;GEODETIC_DATUM_ASSUMED_WGS84",
#'                           "TAXON_MATCH_FUZZY", "PRESUMED_SWAPPED_COORDINATE", ""))
#' f <- flag_occurrences(x, tests = c("issue_coordinate", "issue_taxon", "issue_rounded"))
#' f[, c("flag_issue_coordinate", "flag_issue_taxon", "flag_issue_rounded")]
#' @name test_gbif_issue
NULL

#' Tests: basis of record
#'
#' `basis_fossil` flags records with `basisOfRecord` `FOSSIL_SPECIMEN`,
#' `basis_living` those with `LIVING_SPECIMEN` (botanic garden, zoo and
#' culture-collection individuals). Matching ignores case and surrounding
#' spaces.
#'
#' @section Fields: `basis`.
#' @section CoordinateCleaner: No equivalent; additions of this package.
#'   CoordinateCleaner's fossil tests (`cf_*()`) test fossil ages and ranges,
#'   which this package does not.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(basisOfRecord = c("HUMAN_OBSERVATION", "LIVING_SPECIMEN", "FOSSIL_SPECIMEN"))
#' f <- flag_occurrences(x, tests = c("basis_fossil", "basis_living"))
#' f[, c("flag_basis_fossil", "flag_basis_living")]
#' @name test_basis
NULL

#' Tests: establishment means
#'
#' `establishment_introduced` flags records with `establishmentMeans`
#' introduced, naturalised (either spelling) or invasive;
#' `establishment_managed` flags managed or cultivated individuals. Matching
#' ignores case and surrounding spaces.
#'
#' @section Fields: `establishment`.
#' @section CoordinateCleaner: No equivalent; additions of this package.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(establishmentMeans = c(NA, "MANAGED", "native", "Naturalised"))
#' f <- flag_occurrences(x, tests = c("establishment_introduced", "establishment_managed"))
#' f[, c("flag_establishment_introduced", "flag_establishment_managed")]
#' @name test_establishment
NULL

#' Test: fossil age range
#'
#' Flags records whose minimum age is equal to or greater than their maximum
#' age: a zero-length or inverted stratigraphic range, which in the
#' Paleobiology Database usually means one age was copied into both fields or
#' the two were swapped. Records with a missing age are not flagged.
#'
#' The width of the range (`max_age - min_age`) is a numeric field, not a
#' test: it stays a raw column and is cut at tally time with `bins`, as the
#' record year is.
#'
#' @section Fields: `min_age`, `max_age` (`min_ma`, `max_ma` by default; see
#'   [occ_columns()]).
#' @section CoordinateCleaner: Equivalent to `cf_equal()`; identical flags.
#'   `cf_range(method = "time")` is a threshold on the range width, here a bin
#'   in [tally_flags()]; `cf_range()` and `cf_age()` with `method = "quantile"`
#'   or `"mad"` compare records of a taxon with each other and are not ported.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(min_ma = c(10, 20, 30), max_ma = c(20, 20, 25))
#' flag_occurrences(x, tests = "age_equal")$flag_age_equal
#' @name test_age_equal
NULL
