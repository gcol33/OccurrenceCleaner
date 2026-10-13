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
#' clean_invalid(x)
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
#' @section CoordinateCleaner: Equivalent to `cc_zero()`. [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)
#'   3.0.1 documents the same 0.5 degree buffer but applies a radius of 0.5
#'   metres, so it flags only exact zeros. `buffers = list(zero = 0)` gives
#'   the same flags.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(decimalLongitude = c(0, 0.3, 0.4), decimalLatitude = c(42, 0.3, 0.4))
#' flag_occurrences(x, tests = "zero")$flag_zero
#' flag_occurrences(x, tests = "zero", buffers = list(zero = 0))$flag_zero
#' clean_zero(x, buffer = 0)
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
#' clean_equal(x)
#' @name test_equal
NULL

#' Test: country capitals
#'
#' Flags records within 10 km of a country capital, measured as WGS84
#' geodesic distance (closed ball: a record at exactly the buffer distance is
#' flagged). Candidates are found with a kd-tree on the unit sphere and
#' decided with the Vincenty inverse formula.
#'
#' The default gazetteer contains the capital "geographic coordinates" of the
#' CIA World Factbook (public domain; 232 points, one per country profile,
#' through the factbook.json mirror retrieved 2026-10-11), the source
#' [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)'s capitals are taken from. The column `extension` marks
#' the 243 Natural Earth populated places of the classes admin-0 capital,
#' alternative capital and admin-0 region capital (dependent territories),
#' which add the second capitals of countries that have several (Cape Town,
#' Sucre, Naypyidaw); passing the points with `extension` FALSE as
#' `gazetteers = list(capital = ...)` leaves them out. See [reference_info()].
#'
#' @section Fields: `lon`, `lat`.
#' @section Buffer: `buffers = list(capital = 10000)`, in metres.
#' @section CoordinateCleaner: Equivalent to `cc_cap()`. CoordinateCleaner
#'   draws the buffer as a 72-gon with vertices on the circle, whose edge lies
#'   at 99.9 % of the buffer between vertices; records in that band (within
#'   9.5 m of the 10 km edge) are flagged here and may not be there. Of its
#'   225 capital points, 221 are Factbook points of the default gazetteer
#'   rounded to 0.01 degree, which moves them by up to 523 m. The other four
#'   hold values the Factbook has since revised: Bujumbura for Burundi, whose
#'   capital it now gives as Gitega; Buenos Aires at 58 40 W, 27 km west of
#'   the city, now 58 22 W; Melekeok for Palau, now Ngerulmud; and Rangoon,
#'   1.8 km from its present coordinates. With `reference = "CoordinateCleaner"`
#'   its `countryref` capitals are used.
#' @section Custom gazetteer: `gazetteers = list(capital = points)`, a data frame
#'   of longitude and latitude; see [flag_occurrences()].
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()], [reference_info()]
#' @examples
#' x <- data.frame(decimalLongitude = c(16.37, 16.51), decimalLatitude = c(48.21, 48.25))
#' flag_occurrences(x, tests = "capital")$flag_capital
#' flag_occurrences(x, tests = "capital", buffers = list(capital = 20000))$flag_capital
#' g <- reference_points("capital")
#' flag_occurrences(x, tests = "capital",
#'                  gazetteers = list(capital = g[!g$extension, ]))$flag_capital
#' clean_capital(x, buffer = 20000)
#' @name test_capital
NULL

#' Test: country and province centroids
#'
#' Flags records within 1 km of a country or province centroid (WGS84
#' geodesic distance, closed ball), where records georeferenced to a country
#' or province name end up. The default gazetteer contains the country points of
#' the three sources [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)'s table is compiled from, each taken
#' from the source: the "Geographic coordinates" of the CIA World Factbook
#' (public domain; 275 points, through the factbook.json mirror retrieved
#' 2026-10-11), the label points of the thematicmapping.org World Borders
#' Dataset 0.3 (Bjorn Sandvik, CC BY-SA; 246 points), and every point the
#' GEOLocate georeferencing service (geo-locate.org) returns for a country
#' name, queried 2026-10-11 (548 points; a place of that name more than 100 km
#' away inside another country is left out). Province centroids are the
#' Natural Earth 5.1.1 admin-1 label points (4,594), the current release of
#' the layer CoordinateCleaner's province centroids come from. The column `extension`
#' marks the 516 Natural Earth country polygon centroids and label points,
#' which CoordinateCleaner's table does not hold; passing the points with
#' `extension` FALSE as `gazetteers = list(centroid = ...)` leaves them out.
#'
#' @section Fields: `lon`, `lat`.
#' @section Buffer: `buffers = list(centroid = 1000)`, in metres.
#' @section CoordinateCleaner: Equivalent to `cc_cen()` with `test = "both"`.
#'   Its 72-gon buffer edge lies within 0.95 m of the 1 km circle. Of its 660
#'   country centroids, 645 are points of the default gazetteer at distance 0.
#'   Of the other 15, India, Italy and the United Kingdom hold World Borders
#'   values that version 0.3 of the dataset changed; three GEOLocate points
#'   for Macedonia and one for Guinea, at sea at 10 W 5 N, are not returned by
#'   GEOLocate today; eight (Aland, Caribbean Netherlands, DR Congo, Kuwait,
#'   Martinique, Monaco, Saint Martin, San Marino) lie 5 m to 68 km from a
#'   default point. Its province centroids are the admin-1 label points of
#'   older Natural Earth releases (4,566 of 4,645 rows match release 3.3.0,
#'   4.0.0 or 4.1.0 exactly); 4,591 are default points at distance 0, and 50
#'   lie more than 10 km from any, where Natural Earth has since changed the
#'   unit or the row matches no tagged release.
#' @section Custom gazetteer: `gazetteers = list(centroid = points)`, a data frame
#'   of longitude and latitude; see [flag_occurrences()].
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()], [reference_info()]
#' @examples
#' x <- data.frame(decimalLongitude = c(14.1307, 10), decimalLatitude = c(47.5857, 50))
#' flag_occurrences(x, tests = "centroid")$flag_centroid
#' g <- reference_points("centroid")
#' flag_occurrences(x, tests = "centroid",
#'                  gazetteers = list(centroid = g[!g$extension, ]))$flag_centroid
#' clean_centroid(x)
#' @name test_centroid
NULL

#' Test: biodiversity institutions
#'
#' Flags records within 100 m of a biodiversity institution (WGS84 geodesic
#' distance, closed ball): herbaria, museums, botanic gardens, zoos and
#' universities holding collections, where specimens are often georeferenced
#' to the institution. The default gazetteer contains 23,895 points: the 6,080
#' institutions with coordinates in GBIF's Global Registry of Scientific
#' Collections (GRSciColl), less five whose coordinates the `zero` test flags
#' (they lie near (0, 0) or have a longitude of exactly 0, and are geocoding
#' errors); 7,810 points from Wikidata (CC0), retrieved 2026-10-10: every
#' botanical garden, natural history museum, zoo, aquarium and herbarium with
#' coordinates, every museum whose subject is a natural-history field, and
#' the museums of Wikipedia's lists of natural history museums (English,
#' Arabic, Dutch, Esperanto, French, German and Portuguese editions) that
#' have their own Wikidata coordinates; 700 further museums of those lists
#' placed at the place the list gives for them, by its Wikidata coordinates
#' or the GeoNames populated place of that name (`source` "Wikipedia",
#' `master_source` says which); the three GeoNames places (CC BY 4.0) of
#' [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)'s table; 3,652 gardens of Botanic Gardens
#' Conservation International (BGCI) GardenSearch, retrieved 2026-10-10, used
#' under the BGCI terms (https://www.bgci.org/terms-and-conditions/); 1,062
#' herbaria of Index Herbariorum that GRSciColl does not place, and 2,468
#' publishing organisations of the GBIF registry, both retrieved 2026-10-13;
#' and 2,120 points for the institutions of CoordinateCleaner's table that
#' none of these holds under their name (`source` "CoordinateCleaner list"),
#' placed from Wikidata, OpenStreetMap (through Nominatim) or the GeoNames
#' populated place of the institution's city, by its name, city and country;
#' `master_source` says which. The `source` column of [reference_points()]
#' tells them apart.
#'
#' Every institution of CoordinateCleaner's table with coordinates has a
#' point here except one, an expert group listed in Antarctica. Where a source
#' gives several candidates for an institution, the one nearest
#' CoordinateCleaner's point is taken; the coordinates are always the
#' source's. For 496 institutions no source places the institution itself,
#' and the point is the populated place of its country nearest
#' CoordinateCleaner's point.
#'
#' The exception is "SCAR - Expert Group on Birds and Marine Mammals".
#' CoordinateCleaner places it at 45.1439 N, 0.5558 E. Its entry in the GBIF
#' registry was deleted on 2021-05-31 and has no coordinates. It has no point
#' here because no independently verified physical location of the group could
#' be established.
#'
#' The column `extension` marks the 7,665 points from sources
#' CoordinateCleaner's table does not draw on: Wikidata beyond the museums of
#' the English list, and the lists of the other language editions. The other
#' 16,230 points come from the registries CoordinateCleaner's table is
#' compiled from (GRSciColl, which absorbed GRBio and mirrors Index
#' Herbariorum, Index Herbariorum itself, the GBIF registry, the English list,
#' GeoNames and BGCI) and from its own list of institutions. Passing the points
#' with `extension` FALSE as `gazetteers = list(institution = ...)` restricts
#' the test to those sources (see the examples).
#'
#' @section Fields: `lon`, `lat`.
#' @section Buffer: `buffers = list(institution = 100)`, in metres.
#' @section CoordinateCleaner: Equivalent to `cc_inst()`. Its 40-gon buffer
#'   edge lies within 0.31 m of the 100 m circle. Its `institutions` table
#'   (9,773 points with coordinates) places nearly every institution by its
#'   own geocoding, so its points can lie apart from the source coordinates
#'   used here: for 32 percent of its points a point of the default gazetteer
#'   lies within 100 m, for 73 percent within 1 km and for 91 percent within
#'   5 km (28, 70 and 90 percent for the points with `extension` FALSE).
#'   `reference = "CoordinateCleaner"` uses that table, and
#'   `rbind()` of [reference_points()] under both references, passed as
#'   `gazetteers = list(institution = ...)`, flags records near either.
#' @section Custom gazetteer: `gazetteers = list(institution = points)`, a data frame
#'   of longitude and latitude; see [flag_occurrences()].
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()], [reference_info()]
#' @examples
#' x <- data.frame(decimalLongitude = c(16.3598, 15), decimalLatitude = c(48.2052, 47))
#' flag_occurrences(x, tests = "institution")$flag_institution
#' g <- reference_points("institution")
#' flag_occurrences(x, tests = "institution",
#'                  gazetteers = list(institution = g[!g$extension, ]))$flag_institution
#' clean_institution(x)
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
#'   1:50 million Natural Earth coast, so it also fails `sea` at `land_scale = 50`
#'   and `country_mismatch` with code `"DK"`, in both packages.
#' @section Custom gazetteer: `gazetteers = list(gbif_headquarters = points)`, a data frame
#'   of longitude and latitude; see [flag_occurrences()].
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(decimalLongitude = c(12.58, 12.6), decimalLatitude = c(55.67, 55.7))
#' flag_occurrences(x, tests = "gbif_headquarters")$flag_gbif_headquarters
#' clean_gbif_headquarters(x)
#' @name test_gbif_headquarters
NULL

#' Test: records at sea
#'
#' Flags records outside the Natural Earth land polygons, by a planar
#' point-in-polygon test in longitude and latitude through a grid index that
#' resolves boundary cells exactly. The land layer is chosen with
#' `land_scale`: 110 (default), 50, or 10. The 1:10 million layer is downloaded once
#' by [download_reference()].
#'
#' @section Fields: `lon`, `lat`.
#' @section CoordinateCleaner: Equivalent to `cc_sea()` with its default
#'   `scale = 110` (`clean_coordinates()` uses `seas_scale = 50`, which is
#'   `land_scale = 50` here); identical flags on
#'   the same layer. [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) downloads the layer through
#'   [rnaturalearth](https://docs.ropensci.org/rnaturalearth/) at run time; here it is bundled and pinned.
#' @section Custom gazetteer: `gazetteers = list(sea = polygons)`, an `sf` or
#'   `sfc` object of land polygons; see [flag_occurrences()].
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()], [reference_info()]
#' @examples
#' x <- data.frame(decimalLongitude = c(12.58, 16.37, -30), decimalLatitude = c(55.67, 48.21, 40))
#' flag_occurrences(x, tests = "sea")$flag_sea
#' flag_occurrences(x, tests = "sea", land_scale = 50)$flag_sea
#' clean_sea(x, land_scale = 50)
#' @name test_sea
NULL

#' Test: urban areas
#'
#' Flags records inside the Natural Earth 1:50 million urban-area polygons.
#' CoordinateCleaner's `clean_coordinates()` leaves this test out by default,
#' as urban records are often correct; here it runs whenever coordinates are
#' present, and a cleaning rule can leave it out.
#'
#' @section Fields: `lon`, `lat`.
#' @section CoordinateCleaner: Equivalent to `cc_urb()` with its default
#'   1:50 million urban areas; identical flags on the same layer. Not run by
#'   `clean_coordinates()` by default either.
#' @section Custom gazetteer: `gazetteers = list(urban = polygons)`, an `sf` or
#'   `sfc` object of urban-area polygons; see [flag_occurrences()].
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(decimalLongitude = c(16.37, 15.3), decimalLatitude = c(48.21, 47.5))
#' flag_occurrences(x, tests = "urban")$flag_urban
#' clean_urban(x)
#' @name test_urban
NULL

#' Test: country code mismatch
#'
#' Flags records whose coordinates fall outside the Natural Earth 1:50 million
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
#' clean_country_mismatch(x)
#' @name test_country_mismatch
NULL

#' Test: duplicates
#'
#' Flags every record with the same longitude, latitude and species as an
#' earlier record; the first of each set is not flagged. `duplicate_by` adds
#' columns that must also match; `duplicate_cell` bins coordinates to a grid
#' of that many degrees first. A missing species counts as one value, as in
#' `duplicated()`, so records without a species at the same coordinates are
#' duplicates of each other.
#'
#' The test compares each record with all records before it in the input
#' order: the rows of a data frame, or on streamed input the files in sorted
#' order and the rows within each file. Streamed input therefore gets the same
#' flags as the same records in one data frame. It is a grouped test: the
#' records are bucketed by a 124-bit hash of their key in a pass before the
#' record tests, so it needs a path rather than a single-run `vectra_node`.
#' The probability that any two different keys share a hash is about 2e-18
#' for ten billion records.
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
#' clean_duplicate(x, by = "eventDate")
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
#' x |> clean_issue_coordinate() |> clean_issue_taxon()
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
#'   [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)'s fossil tests (`cf_*()`) test fossil ages and ranges,
#'   which this package does not.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(basisOfRecord = c("HUMAN_OBSERVATION", "LIVING_SPECIMEN", "FOSSIL_SPECIMEN"))
#' f <- flag_occurrences(x, tests = c("basis_fossil", "basis_living"))
#' f[, c("flag_basis_fossil", "flag_basis_living")]
#' clean_basis_living(x)
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
#' x |> clean_establishment_introduced() |> clean_establishment_managed()
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
#' clean_age_equal(x)
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
#' `thinning_res` / 2 km, as in [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/).
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
#'   approximation (10,000 records or more, or `thinning = TRUE`) flags no
#'   records; here the records of the outlier cells are flagged. CoordinateCleaner's sampling
#'   correction queries GBIF record counts online at run time; here the counts
#'   are a table given with the call, so the flags can be reproduced.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' set.seed(1)
#' x <- data.frame(species = "a", decimalLongitude = c(rnorm(50, 10, 1), 60),
#'                 decimalLatitude = c(rnorm(50, 50, 1), 10))
#' which(flag_occurrences(x, tests = "outlier")$flag_outlier)
#' nrow(clean_outlier(x, mltpl = 3))
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
#' @section CoordinateCleaner: Equivalent to `cf_age()` at taxon level: the
#'   same draw, replicates and majority rule. The flags are identical when no
#'   age has to be drawn (every range of zero width). Otherwise the flags of a
#'   single run can differ record by record, because
#'   [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) draws
#'   from the session's random stream in input order and this test from a
#'   stream seeded per taxon.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' x <- data.frame(accepted_name = "A", min_ma = c(rep(20, 20), 90), max_ma = c(rep(22, 20), 92))
#' flag_occurrences(x, tests = "age_outlier",
#'                  columns = occ_columns(species = "accepted_name"))$flag_age_outlier
#' clean_age_outlier(x, columns = occ_columns(species = "accepted_name"))
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
#'   has zero width, and otherwise a single run can differ record by record,
#'   as for `age_outlier`.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' set.seed(1)
#' x <- data.frame(accepted_name = "A", lng = c(runif(20, 0, 5), 120), lat = c(runif(20, 40, 45), -30),
#'                 min_ma = 20, max_ma = 20)
#' cols <- occ_columns(lon = "lng", lat = "lat", species = "accepted_name")
#' flag_occurrences(x, tests = "spatiotemporal_outlier", columns = cols)$flag_spatiotemporal_outlier
#' clean_spatiotemporal_outlier(x, columns = cols)
#' @name test_spatiotemporal_outlier
NULL

#' Test: fossil age-range outliers
#'
#' Flags fossil records whose age range (`max_age - min_age`) lies above the
#' upper fence of the ranges of the other records of their taxon (Q75 +
#' `mltpl` x IQR, or median + `mltpl` x MAD). A record dated only to a long
#' period among records dated to stages is the typical case. With `level =
#' "all"` the fence is taken over the whole input instead of per taxon, as in
#' [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)'s dataset-level `cf_range(taxon = "")`. A fixed limit in
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
#' clean_age_range_outlier(x, columns = occ_columns(species = "accepted_name"))
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
#' table(clean_dataset_ddmm(x)$datasetKey)
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
#'   [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) 3.0.1 an input with several datasets of which one is
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
#' table(clean_dataset_rounded(x)$datasetKey)
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
#'   without a buffer. With a buffer [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) buffers the polygons
#'   with [terra](https://rspatial.github.io/terra/), so records very close to the buffer edge may differ.
#' @family tests
#' @seealso [flag_occurrences()], [flag_tests()]
#' @examples
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   rg <- sf::st_sf(species = "a", geometry = sf::st_sfc(sf::st_polygon(list(
#'     rbind(c(0, 40), c(20, 40), c(20, 55), c(0, 55), c(0, 40)))), crs = 4326))
#'   x <- data.frame(species = c("a", "a", "b"), decimalLongitude = c(10, 30, 30),
#'                   decimalLatitude = 50)
#'   flag_occurrences(x, tests = "range", gazetteers = list(range = rg))$flag_range
#'   clean_range(x, ranges = rg)
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
#' clean_aohi(x)
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
#' @section CoordinateCleaner: Not in [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/), whose `cc_sea()`
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
#' clean_sea_nonmarine(x)
#' @name test_habitat
NULL
