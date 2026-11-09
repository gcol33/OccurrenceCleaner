# Test: biodiversity institutions

Flags records within 100 m of a biodiversity institution (WGS84 geodesic
distance, closed ball): herbaria, museums, botanic gardens, zoos and
universities holding collections, where specimens are often
georeferenced to the institution.

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

The default gazetteer has 24,342 points. Of these, 9,773 are the
institutions with coordinates in the table of
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) 3.0.1
(`source` "CoordinateCleaner", `status` "cc"), and 14,569 are further
points that a check beyond their own source confirms (`status`
"confirmed").

Of CoordinateCleaner's points, 9,200 are used as that package has them.
The other 573 are moved (`status` "override", `source` the source of the
new coordinates). For 565 of them, a Google Maps place of the
institution's name lies within 25 km of the city of CoordinateCleaner's
record, while CoordinateCleaner's point lies more than 25 km from both;
they are moved to that place (`source` "Google Maps"). The SCAR Expert
Group on Birds and Marine Mammals has no site of its own and is moved to
the SCAR secretariat in Cambridge (`source` "Wikipedia"). Seven whose
Google Maps search gave no place are moved to the site Wikipedia or
OpenStreetMap gives (`source` "Wikipedia" or "OpenStreetMap"). `cc_lon`
and `cc_lat` keep CoordinateCleaner's coordinates, and `evidence` gives
the place's name, the distances and the URL the coordinates were read
from.

A further point is confirmed when a Google Maps place of the
institution's name lies within 300 m of it, or when it lies within 200 m
of the OpenStreetMap feature of that name; `evidence` says which. The
Google Maps search used the institution's name with its city and
country. When the two names share only words of place names, they must
also name the same kind of institution (university, museum, garden, zoo,
herbarium, institute), so Durban Botanic Gardens does not confirm the
Durban Museum. These checks covered every point of the package's table,
retrieved 2026-10-13 to 2026-10-27. In a hand reading of 100 points
confirmed by Google Maps, 97 were at the named institution, 2 were
unclear and 1 was another institution, which was left out. In a hand
reading of 99 points confirmed by OpenStreetMap alone, 95 were at the
named institution, 2 at another institution, 1 at another site of the
same organisation and 1 unclear. Points no check confirmed were then
read on satellite imagery with the map provider's place labels, together
with the named OpenStreetMap features within 1 km, by a language model
(Claude Opus 5.5); the 2,317 it placed on the named institution are
confirmed (`evidence` "satellite imagery with place labels"). Of 100
such points read by hand, it placed none of the 33 found elsewhere on
the institution. For the points it placed within about 200 m of the
institution, it then read the position of the institution's building or
grounds off the image; the 240 points moved there and read again as on
the institution are confirmed at the new place, and `evidence` keeps the
source's coordinates. Of 30 of these read by hand, 26 were on the
institution, 4 could not be judged from the image and none was
elsewhere. Points that a later reading showed are not on the institution
stay unconfirmed.

[`reference_points()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_points.md)
also returns 10,233 unconfirmed points, which the test leaves out. They
come from GBIF's Global Registry of Scientific Collections (GRSciColl),
Wikidata, Wikipedia's lists of natural history museums, GeoNames,
Botanic Gardens Conservation International (BGCI) GardenSearch, Index
Herbariorum, the GBIF registry of publishing organisations and
OpenStreetMap, and from searches for CoordinateCleaner's institutions by
name. `source` and `master_source` say which, and
[`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md)
gives the versions and retrieval dates. No check placed them on the
institution. Passing the whole table as
`gazetteers = list(institution = ...)` uses them too (see the examples).

## Fields

`lon`, `lat`.

## Buffer

`buffers = list(institution = 100)`, in metres.

## CoordinateCleaner

Equivalent to `cc_inst()`. Its 40-gon buffer edge lies within 0.31 m of
the 100 m circle. The default gazetteer differs from its `institutions`
table by the 573 moved points and the 14,569 confirmed points.
`reference = "CoordinateCleaner"` uses its table as it is.

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
table(g$status)
flag_occurrences(x, tests = "institution",
                 gazetteers = list(institution = g))$flag_institution
clean_institution(x)
```
