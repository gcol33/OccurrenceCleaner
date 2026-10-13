# Test: biodiversity institutions

Flags records within 100 m of a biodiversity institution (WGS84 geodesic
distance, closed ball): herbaria, museums, botanic gardens, zoos and
universities holding collections, where specimens are often
georeferenced to the institution. The default gazetteer contains 23,895
points: the 6,080 institutions with coordinates in GBIF's Global
Registry of Scientific Collections (GRSciColl), less five whose
coordinates the `zero` test flags (they lie near (0, 0) or have a
longitude of exactly 0, and are geocoding errors); 7,810 points from
Wikidata (CC0), retrieved 2026-10-10: every botanical garden, natural
history museum, zoo, aquarium and herbarium with coordinates, every
museum whose subject is a natural-history field, and the museums of
Wikipedia's lists of natural history museums (English, Arabic, Dutch,
Esperanto, French, German and Portuguese editions) that have their own
Wikidata coordinates; 700 further museums of those lists placed at the
place the list gives for them, by its Wikidata coordinates or the
GeoNames populated place of that name (`source` "Wikipedia",
`master_source` says which); the three GeoNames places (CC BY 4.0) of
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)'s
table; 3,652 gardens of Botanic Gardens Conservation International
(BGCI) GardenSearch, retrieved 2026-10-10, used under the BGCI terms
(https://www.bgci.org/terms-and-conditions/); 1,062 herbaria of Index
Herbariorum that GRSciColl does not place, and 2,468 publishing
organisations of the GBIF registry, both retrieved 2026-10-13; and 2,120
points for the institutions of CoordinateCleaner's table that none of
these holds under their name (`source` "CoordinateCleaner list"), placed
from Wikidata, OpenStreetMap (through Nominatim) or the GeoNames
populated place of the institution's city, by its name, city and
country; `master_source` says which. The `source` column of
[`reference_points()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_points.md)
tells them apart.

## Usage

``` r
clean_institution(x, buffer = 100, ...)
```

## Arguments

- x:

  A data frame of occurrence records.

- buffer:

  Buffer distance of the test, in the unit of its Buffer section; the
  default is the test's default buffer.

- ...:

  Further arguments to
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md):
  `columns`, `reference`, `gazetteers`, `land_scale`.

## Value

`clean_<test>()`: the rows of `x` the test does not flag, with the
columns of `x` unchanged. See
[`keep_unflagged()`](https://gillescolling.com/OccurrenceCleaner/reference/keep_unflagged.md),
Cleaning functions.

## Details

Every institution of CoordinateCleaner's table with coordinates has a
point here except one, an expert group listed in Antarctica. Where a
source gives several candidates for an institution, the one nearest
CoordinateCleaner's point is taken; the coordinates are always the
source's. For 496 institutions no source places the institution itself,
and the point is the populated place of its country nearest
CoordinateCleaner's point.

The exception is "SCAR - Expert Group on Birds and Marine Mammals".
CoordinateCleaner places it at 45.1439 N, 0.5558 E. Its entry in the
GBIF registry was deleted on 2021-05-31 and has no coordinates. It has
no point here because no independently verified physical location of the
group could be established.

The column `extension` marks the 7,665 points from sources
CoordinateCleaner's table does not draw on: Wikidata beyond the museums
of the English list, and the lists of the other language editions. The
other 16,230 points come from the registries CoordinateCleaner's table
is compiled from (GRSciColl, which absorbed GRBio and mirrors Index
Herbariorum, Index Herbariorum itself, the GBIF registry, the English
list, GeoNames and BGCI) and from its own list of institutions. Passing
the points with `extension` FALSE as
`gazetteers = list(institution = ...)` restricts the test to those
sources (see the examples).

## Fields

`lon`, `lat`.

## Buffer

`buffers = list(institution = 100)`, in metres.

## CoordinateCleaner

Equivalent to `cc_inst()`. Its 40-gon buffer edge lies within 0.31 m of
the 100 m circle. Its `institutions` table (9,773 points with
coordinates) places nearly every institution by its own geocoding, so
its points can lie apart from the source coordinates used here: for 32
percent of its points a point of the default gazetteer lies within 100
m, for 73 percent within 1 km and for 91 percent within 5 km (28, 70 and
90 percent for the points with `extension` FALSE).
`reference = "CoordinateCleaner"` uses that table, and
[`rbind()`](https://rdrr.io/r/base/cbind.html) of
[`reference_points()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_points.md)
under both references, passed as `gazetteers = list(institution = ...)`,
flags records near either.

## Custom gazetteer

`gazetteers = list(institution = points)`, a data frame of longitude and
latitude; see
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md),
[`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md)

Other tests:
[`clean_age_equal()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md),
[`clean_age_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_outlier.md),
[`clean_age_range_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_range_outlier.md),
[`clean_aohi()`](https://gillescolling.com/OccurrenceCleaner/reference/test_aohi.md),
[`clean_basis_fossil()`](https://gillescolling.com/OccurrenceCleaner/reference/test_basis.md),
[`clean_capital()`](https://gillescolling.com/OccurrenceCleaner/reference/test_capital.md),
[`clean_centroid()`](https://gillescolling.com/OccurrenceCleaner/reference/test_centroid.md),
[`clean_country_mismatch()`](https://gillescolling.com/OccurrenceCleaner/reference/test_country_mismatch.md),
[`clean_dataset_ddmm()`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_ddmm.md),
[`clean_dataset_rounded()`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_rounded.md),
[`clean_duplicate()`](https://gillescolling.com/OccurrenceCleaner/reference/test_duplicate.md),
[`clean_equal()`](https://gillescolling.com/OccurrenceCleaner/reference/test_equal.md),
[`clean_establishment_introduced()`](https://gillescolling.com/OccurrenceCleaner/reference/test_establishment.md),
[`clean_gbif_headquarters()`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_headquarters.md),
[`clean_invalid()`](https://gillescolling.com/OccurrenceCleaner/reference/test_invalid.md),
[`clean_issue_coordinate()`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_issue.md),
[`clean_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_outlier.md),
[`clean_range()`](https://gillescolling.com/OccurrenceCleaner/reference/test_range.md),
[`clean_sea()`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md),
[`clean_sea_nonmarine()`](https://gillescolling.com/OccurrenceCleaner/reference/test_habitat.md),
[`clean_spatiotemporal_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_spatiotemporal_outlier.md),
[`clean_urban()`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`clean_zero()`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
x <- data.frame(decimalLongitude = c(16.3598, 15), decimalLatitude = c(48.2052, 47))
flag_occurrences(x, tests = "institution")$flag_institution
g <- reference_points("institution")
flag_occurrences(x, tests = "institution",
                 gazetteers = list(institution = g[!g$extension, ]))$flag_institution
clean_institution(x)
```
