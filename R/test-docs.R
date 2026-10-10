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
#'   flagged. `buffers = list(zero = 0)` reproduces that behaviour. Reported
#'   as \href{https://github.com/ropensci/CoordinateCleaner/issues/114}{CoordinateCleaner issue 114}.
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
#' to the institution. The default gazetteer holds 13,696 points: the 6,080
#' institutions with coordinates in GBIF's Global Registry of Scientific
#' Collections (GRSciColl), less five whose coordinates the `zero` test flags
#' (they lie near (0, 0) or have a longitude of exactly 0, and are geocoding
#' errors); 7,613 points from Wikidata (CC0), retrieved 2026-10-10: every
#' botanical garden, natural history museum, zoo, aquarium and herbarium with
#' coordinates, and the institutions of Wikipedia's list of natural history
#' museums; and the three GeoNames places (CC BY 4.0) of CoordinateCleaner's
#' table. The `source` column of [reference_points()] tells them apart.
#'
#' @section Fields: `lon`, `lat`.
#' @section Buffer: `buffers = list(institution = 100)`, in metres.
#' @section CoordinateCleaner: Equivalent to `cc_inst()`. Its 40-gon buffer
#'   edge lies within 0.31 m of the 100 m circle. Its `institutions` table
#'   (9,773 points with coordinates) also holds 712 botanic gardens from
#'   Botanic Gardens Conservation International (BGCI), whose terms do not
#'   allow the data to be redistributed in its original form, so they are not
#'   shipped here. `reference = "CoordinateCleaner"` uses that table, and
#'   `rbind()` of [reference_points()] under both references, passed as
#'   `gazetteers = list(institution = ...)`, flags records near either.
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
#'   in [tally_flags()]. The per-taxon tests `cf_age()`, `cf_outl()` and
#'   `cf_range()` with `method = "quantile"` or `"mad"` are [test_age_outlier],
#'   [test_spatiotemporal_outlier] and [test_age_range_outlier].
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(min_ma = c(10, 20, 30), max_ma = c(20, 20, 25))
#' flag_occurrences(x, tests = "age_equal")$flag_age_equal
#' @name test_age_equal
NULL

#' Test: geographic outliers
#'
#' Flags records far from the other records of their species. For each record
#' the haversine distances (km) to the species' other records are computed,
#' leaving out zero distances (the record itself and records at the same
#' point); a record is flagged when its mean distance lies above the upper
#' fence of the species' mean distances: Q75 + `mltpl` x IQR (`method =
#' "quantile"`) or median + `mltpl` x MAD (`"mad"`). With `method =
#' "distance"` a record is flagged when its nearest other record is more than
#' `tdi` km away. Species with fewer than `min_occs` distinct points are not
#' tested.
#'
#' Species with 10,000 records or more, and every species when `thinning =
#' TRUE`, are tested on a raster approximation: records are counted on a grid
#' of `thinning_res` degrees spanning all valid records (widened by two cells),
#' distances are taken between cell centres, and the records of the outlier
#' cells are flagged. Without thinning, distances are weighted by the product
#' of the cell counts and a cell's distance to itself counts as 100 x
#' `thinning_res` / 2 km, as in CoordinateCleaner.
#'
#' The test needs every record of a species, so it runs in a group pass over
#' the whole input before the record tests; on streamed input that pass reads
#' all files, and a species spread over several files is tested as one.
#'
#' @section Fields: `lon`, `lat`, `species`. Records with invalid coordinates
#'   are left out.
#' @section Settings: `settings = list(outlier = list(...))` with `method`
#'   (`"quantile"`), `mltpl` (5), `tdi` (1000 km), `min_occs` (7), `thinning`
#'   (`FALSE`), `thinning_res` (0.5 degrees) and `sampling_thresh` (0).
#' @section Sampling correction: With `sampling_thresh` above 0, an outlier
#'   stays flagged only in a country whose record density (log records per
#'   100 km2) lies above that quantile of the densities of all countries, so
#'   that isolated records in poorly sampled countries are kept. The records
#'   per country come from `gazetteers = list(sampling = <data frame>)`, with
#'   an ISO alpha-2 `country` column and a `records` column, for example from
#'   `rgbif::occ_count()` or a tally of the input itself; country areas are
#'   computed from the country polygons of the reference.
#' @section CoordinateCleaner: Equivalent to `cc_outl()`; identical flags for
#'   species below 10,000 records. In CoordinateCleaner 3.0.1 the raster
#'   approximation computes the cell statistics but its mapping from outlier
#'   cells back to records returns none, so it never flags a record; here the
#'   records of the outlier cells are flagged. CoordinateCleaner's sampling
#'   correction queries GBIF record counts online at run time; here the counts
#'   are a table given with the call, so the flags can be reproduced.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' set.seed(1)
#' x <- data.frame(species = "a", decimalLongitude = c(rnorm(50, 10, 1), 60),
#'                 decimalLatitude = c(rnorm(50, 50, 1), 10))
#' which(flag_occurrences(x, tests = "outlier")$flag_outlier)
#' @name test_outlier
NULL

#' Test: fossil age outliers
#'
#' Flags fossil records whose age is far from the ages of the other records of
#' their taxon. One age is drawn uniformly from each record's range (the
#' minimum age when the range has zero width), each record gets its mean
#' absolute age difference to all records of the taxon, and records above the
#' upper fence (Q75 + `mltpl` x IQR, or median + `mltpl` x MAD) are outliers.
#' The draw is repeated `replicates` times and a record is flagged when it is
#' an outlier in more than `1 - flag_thresh` of them. Taxa with fewer than
#' `size_thresh` records are not tested.
#'
#' The draws are seeded per taxon from `seed` and the taxon name, and taken in
#' an order fixed by the records' ages, coordinates and identifier, so the
#' flags are reproducible and do not depend on the order or the splitting of
#' the input. The caller's random-number stream is left unchanged.
#'
#' @section Fields: `min_age`, `max_age`, `species` (the taxon), and `lon`,
#'   `lat` for `uniq_loc`.
#' @section Settings: `settings = list(age_outlier = list(...))` with `method`
#'   (`"quantile"`), `mltpl` (5), `size_thresh` (7), `replicates` (5),
#'   `flag_thresh` (0.5), `uniq_loc` (`FALSE`: when `TRUE`, records sharing
#'   taxon, coordinates rounded to 0.1 degrees and ages are tested once) and
#'   `seed` (1).
#' @section CoordinateCleaner: Equivalent to `cf_age()` at taxon level;
#'   identical flags when no age has to be drawn (every range of zero width).
#'   Otherwise both draw ages at random and the flags agree in distribution,
#'   not record by record: CoordinateCleaner draws from the session's random
#'   stream in input order.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(accepted_name = "A", min_ma = c(rep(20, 20), 90), max_ma = c(rep(22, 20), 92))
#' flag_occurrences(x, tests = "age_outlier",
#'                  columns = occ_columns(species = "accepted_name"))$flag_age_outlier
#' @name test_age_outlier
NULL

#' Test: fossil outliers in space and time
#'
#' Flags fossil records that are far from the other records of their taxon in
#' space and time together. Ages are drawn as in [test_age_outlier]; for each
#' pair of records the age difference is rescaled so that the largest age
#' difference equals the largest geographic distance, added to the haversine
#' distance in km between coordinates rounded to 0.1 degrees (Euclidean
#' degrees for taxa of 10,000 records or more) and rounded; each record's mean
#' over all records of its taxon is compared with the upper fence. Replicates,
#' majority and seeding are as in [test_age_outlier].
#'
#' @section Fields: `lon`, `lat`, `min_age`, `max_age`, `species`.
#' @section Settings: `settings = list(spatiotemporal_outlier = list(...))`
#'   with the same options and defaults as `age_outlier`.
#' @section CoordinateCleaner: Equivalent to `cf_outl()` at taxon level, the
#'   `spatiotemp` test of `clean_fossils()`; identical flags when every range
#'   has zero width, agreement in distribution otherwise.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' set.seed(1)
#' x <- data.frame(accepted_name = "A", lng = c(runif(20, 0, 5), 120), lat = c(runif(20, 40, 45), -30),
#'                 min_ma = 20, max_ma = 20)
#' cols <- occ_columns(lon = "lng", lat = "lat", species = "accepted_name")
#' flag_occurrences(x, tests = "spatiotemporal_outlier", columns = cols)$flag_spatiotemporal_outlier
#' @name test_spatiotemporal_outlier
NULL

#' Test: fossil age-range outliers
#'
#' Flags fossil records whose age range (`max_age - min_age`) lies above the
#' upper fence of the ranges of the other records of their taxon (Q75 +
#' `mltpl` x IQR, or median + `mltpl` x MAD). A record dated only to a long
#' period among records dated to stages is the typical case. With `level =
#' "all"` the fence is taken over the whole input instead of per taxon, as in
#' CoordinateCleaner's dataset-level `cf_range(taxon = "")`. A fixed limit in
#' million years needs no test: the range stays a raw column and is cut in
#' [tally_flags()].
#'
#' @section Fields: `min_age`, `max_age`, `species`.
#' @section Settings: `settings = list(age_range_outlier = list(...))` with
#'   `method` (`"quantile"`), `mltpl` (5), `size_thresh` (7), `uniq_loc`
#'   (`FALSE`) and `level` (`"taxon"`).
#' @section CoordinateCleaner: Equivalent to `cf_range()` with `method =
#'   "quantile"` or `"mad"`; identical flags. With `uniq_loc = TRUE`,
#'   CoordinateCleaner also flags records of other taxa that happen to share a
#'   flagged range width; here the flag goes to the records with the same
#'   taxon, coordinates and ages.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()], [test_age_equal]
#' @examples
#' x <- data.frame(accepted_name = "A", min_ma = 20, max_ma = c(rep(21, 20), 60))
#' flag_occurrences(x, tests = "age_range_outlier",
#'                  columns = occ_columns(species = "accepted_name"))$flag_age_range_outlier
#' @name test_age_range_outlier
NULL

#' Test: degree-minute conversion errors in a dataset
#'
#' Flags every record of a dataset whose coordinates look converted from
#' degrees and minutes as if they were decimal degrees, which leaves no decimal
#' part above .59. The decimal parts of each dataset's distinct coordinates are
#' placed on a `mat_size` x `mat_size` grid; a binomial test compares the share
#' of filled cells with both decimals below .6 with its expected share, and
#' the dataset fails when the excess is significant (p < `pvalue`) and larger
#' than `diff` times the expected share. Datasets spanning less than
#' `min_span` degrees in longitude or latitude are not tested.
#'
#' @section Fields: `lon`, `lat`, `dataset` (`datasetKey` by default).
#' @section Settings: `settings = list(dataset_ddmm = list(...))` with
#'   `pvalue` (0.025), `diff` (1), `mat_size` (1000) and `min_span` (2).
#' @section CoordinateCleaner: Equivalent to `cd_ddmm()`; identical flags.
#'   Records without a dataset key are not flagged here; `cd_ddmm()` flags
#'   them.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' set.seed(2)
#' ddmm <- function(n) floor(runif(n, 0, 20)) + sample(0:59, n, TRUE) / 100
#' x <- data.frame(datasetKey = rep(c("ok", "ddmm"), each = 300),
#'                 decimalLongitude = c(runif(300, 0, 20), ddmm(300)),
#'                 decimalLatitude = c(runif(300, 0, 20), ddmm(300)))
#' tapply(flag_occurrences(x, tests = "dataset_ddmm")$flag_dataset_ddmm, x$datasetKey, all)
#' @name test_dataset_ddmm
NULL

#' Test: rasterised datasets
#'
#' Flags every record of a dataset whose coordinates lie on a regular grid, as
#' when records were collected or published per grid cell. For each axis the
#' absolute coordinates are binned into about 3000 classes, the
#' autocorrelation of the bin counts is computed, and its outliers (values
#' above Q75 + `T1` x IQR in sliding windows) are located; regularly spaced
#' outliers, at a common distance between `reg_dist_min` and `reg_dist_max`
#' degrees found at least `reg_out_thresh` times, mark the axis as periodic.
#' A dataset fails when both axes are periodic (`axis = "both"`) or the chosen
#' one is. Datasets with fewer than `min_unique_ds_size` distinct coordinates
#' are not tested.
#'
#' @section Fields: `lon`, `lat`, `dataset`.
#' @section Settings: `settings = list(dataset_rounded = list(...))` with
#'   `T1` (7), `reg_out_thresh` (2), `reg_dist_min` (0.1), `reg_dist_max` (2),
#'   `min_unique_ds_size` (4) and `axis` (`"both"`).
#' @section CoordinateCleaner: Equivalent to `cd_round()`; identical flags. In
#'   CoordinateCleaner 3.0.1 an input with several datasets of which one is
#'   below `min_unique_ds_size` stops with an error; here that dataset is not
#'   tested. Records without a dataset key are not flagged.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' set.seed(2)
#' x <- data.frame(datasetKey = rep(c("ok", "grid"), each = 400),
#'                 decimalLongitude = c(runif(400, 0, 20), round(runif(400, 0, 20) * 2) / 2 + 0.01),
#'                 decimalLatitude = c(runif(400, 0, 20), round(runif(400, 30, 50) * 2) / 2 + 0.01))
#' tapply(flag_occurrences(x, tests = "dataset_rounded")$flag_dataset_rounded, x$datasetKey, all)
#' @name test_dataset_rounded
NULL

#' Test: outside the species range
#'
#' Flags records that fall outside every range polygon of their species, for
#' example an IUCN range map. The polygons come from `gazetteers = list(range =
#' <sf>)`: an `sf` object with a species column (named like the record's
#' species column, `species`, `binomial` or `sci_name`). Species without a
#' polygon are not tested. With `buffers = list(range = m)`, records within
#' `m` metres of a polygon edge count as inside.
#'
#' @section Fields: `lon`, `lat`, `species`.
#' @section Buffer: `buffers = list(range = 0)`, in metres. The distance to an
#'   edge is measured on the ellipsoid from the closest point of the edge in a
#'   local equirectangular projection.
#' @section Custom gazetteer: required; there is no shipped range layer.
#' @section CoordinateCleaner: Equivalent to `cc_iucn()`; identical flags
#'   without a buffer. With a buffer CoordinateCleaner buffers the polygons
#'   with terra, so records very close to the buffer edge may differ.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   rg <- sf::st_sf(species = "a", geometry = sf::st_sfc(sf::st_polygon(list(
#'     rbind(c(0, 40), c(20, 40), c(20, 55), c(0, 55), c(0, 40)))), crs = 4326))
#'   x <- data.frame(species = c("a", "a", "b"), decimalLongitude = c(10, 30, 30),
#'                   decimalLatitude = 50)
#'   flag_occurrences(x, tests = "range", gazetteers = list(range = rg))$flag_range
#' }
#' @name test_range
NULL

#' Test: artificial hotspots
#'
#' Flags records within 10 km of a point of the Artificial Hotspot Occurrence
#' Inventory (AHOI; Park et al. 2023): the coordinates that recur most often in
#' GBIF plant, bird, insect and mammal records, each with the reason it
#' recurs (a georeferencing default, a gazetteer centroid, a popular
#' observation site). WGS84 geodesic distance, closed ball.
#'
#' The shipped inventory is built from the original deposit (Dryad,
#' doi:10.5061/dryad.v41ns1s0p, CC0); [reference_points()] returns it with the
#' taxon group, the record count at each point and whether the point marks a
#' real observation site (`determination`), so it can be filtered and passed
#' back through `gazetteers`.
#'
#' @section Fields: `lon`, `lat`.
#' @section Buffer: `buffers = list(aohi = 10000)`, in metres.
#' @section Custom gazetteer: `gazetteers = list(aohi = points)`, a data frame
#'   of longitude and latitude; see [flag_occurrences()].
#' @section CoordinateCleaner: Equivalent to `cc_aohi()` with its default four
#'   taxa; with `reference = "CoordinateCleaner"` its bundled table is used.
#'   Its 72-gon buffer edge lies within 9.5 m of the 10 km circle. Its table
#'   differs from the Dryad deposit at a few points.
#' @references Park, D. S., Xie, Y., Thammavong, H. T., Tulaiha, R. and Feng,
#'   X. (2023). Artificial Hotspot Occurrence Inventory (AHOI). Journal of
#'   Biogeography 50:441-449. \doi{10.1111/jbi.14543}
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()], [reference_points()]
#' @examples
#' a <- reference_points("aohi")
#' x <- data.frame(decimalLongitude = a$lon[1] + 0.01, decimalLatitude = a$lat[1])
#' flag_occurrences(x, tests = "aohi")$flag_aohi
#' @name test_aohi
NULL

#' Tests: habitat at sea and on land
#'
#' Two tests set the land test against the habitat of the record's genus:
#' * `sea_nonmarine` flags records outside the land polygons whose genus does
#'   not live in the sea (a tree or a toad in open water);
#' * `land_marine` flags records inside the land polygons whose genus lives
#'   only in the sea (a starfish or a coral inland).
#'
#' The genus habitats come from the Interim Register of Marine and Nonmarine
#' Genera (IRMNG; Rees, T. (compiler) (2026). The Interim Register of Marine
#' and Nonmarine Genera. Available from https://www.irmng.org at VLIZ; CC BY
#' 4.0), see [reference_habitat()] for how a genus is classed. Records of a
#' genus IRMNG does not class (missing flags, or both habitats, as for gulls,
#' seals, salmon or mangroves) are not tested. The genus is the first word of
#' the `genus` field, so a binomial species column works too; a `kingdom`
#' column, when present, resolves genus names used in two kingdoms. The land
#' is the layer of `sea`: `land_scale`, or `gazetteers$sea`.
#'
#' A coarse coast puts coastal records on the wrong side: at the default
#' `land_scale = 110` the coastline is generalised by kilometres. The buffers
#' leave records within that distance of the coast untested.
#'
#' Marine fossils of a living marine genus lie on land too; combine with
#' `basis_fossil` in a rule to keep them.
#'
#' @section Fields: `lon`, `lat`, `genus`; `kingdom` when present.
#' @section Buffer: `buffers = list(sea_nonmarine = 0, land_marine = 0)`, in
#'   metres from the land polygon edge.
#' @section Custom gazetteer: `gazetteers = list(habitat = <data frame>)` with
#'   columns `genus`, `marine` (logical: `TRUE` only marine, `FALSE` not
#'   marine) and optionally `kingdom`; `gazetteers = list(sea = <sf>)` replaces
#'   the land.
#' @section CoordinateCleaner: Not in CoordinateCleaner, whose `cc_sea()`
#'   flags every record off the land, marine or not.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()], [reference_habitat()], [test_sea]
#' @examples
#' x <- data.frame(kingdom = c("Plantae", "Animalia", "Animalia", "Plantae"),
#'                 genus = c("Quercus", "Asterias", "Asterias", "Quercus"),
#'                 decimalLongitude = c(-30, 16.37, -30, 16.37),
#'                 decimalLatitude = c(40, 48.21, 40, 48.21))
#' f <- flag_occurrences(x, tests = c("sea", "sea_nonmarine", "land_marine"))
#' f[, c("genus", "flag_sea", "flag_sea_nonmarine", "flag_land_marine")]
#' @name test_habitat
NULL
