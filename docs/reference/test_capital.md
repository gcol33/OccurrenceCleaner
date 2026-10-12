# Test: country capitals

Flags records within 10 km of a country capital, measured as WGS84
geodesic distance (closed ball: a record at exactly the buffer distance
is flagged). Candidates are found with a kd-tree on the unit sphere and
decided with the Vincenty inverse formula.

## Usage

``` r
clean_capital(x, buffer = 10000, ...)
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

The default gazetteer contains the capital "geographic coordinates" of
the CIA World Factbook (public domain; 232 points, one per country
profile, through the factbook.json mirror retrieved 2026-10-11), the
source
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)'s
capitals are taken from. The column `extension` marks the 243 Natural
Earth populated places of the classes admin-0 capital, alternative
capital and admin-0 region capital (dependent territories), which add
the second capitals of countries that have several (Cape Town, Sucre,
Naypyidaw); passing the points with `extension` FALSE as
`gazetteers = list(capital = ...)` leaves them out. See
[`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md).

## Fields

`lon`, `lat`.

## Buffer

`buffers = list(capital = 10000)`, in metres.

## CoordinateCleaner

Equivalent to `cc_cap()`. CoordinateCleaner draws the buffer as a 72-gon
with vertices on the circle, whose edge lies at 99.9 % of the buffer
between vertices; records in that band (within 9.5 m of the 10 km edge)
are flagged here and may not be there. Of its 225 capital points, 221
are Factbook points of the default gazetteer rounded to 0.01 degree,
which moves them by up to 523 m. The other four hold values the Factbook
has since revised: Bujumbura for Burundi, whose capital it now gives as
Gitega; Buenos Aires at 58 40 W, 27 km west of the city, now 58 22 W;
Melekeok for Palau, now Ngerulmud; and Rangoon, 1.8 km from its present
coordinates. With `reference = "CoordinateCleaner"` its `countryref`
capitals are used.

## Custom gazetteer

`gazetteers = list(capital = points)`, a data frame of longitude and
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
[`clean_centroid()`](https://gillescolling.com/OccurrenceCleaner/reference/test_centroid.md),
[`clean_country_mismatch()`](https://gillescolling.com/OccurrenceCleaner/reference/test_country_mismatch.md),
[`clean_dataset_ddmm()`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_ddmm.md),
[`clean_dataset_rounded()`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_rounded.md),
[`clean_duplicate()`](https://gillescolling.com/OccurrenceCleaner/reference/test_duplicate.md),
[`clean_equal()`](https://gillescolling.com/OccurrenceCleaner/reference/test_equal.md),
[`clean_establishment_introduced()`](https://gillescolling.com/OccurrenceCleaner/reference/test_establishment.md),
[`clean_gbif_headquarters()`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_headquarters.md),
[`clean_institution()`](https://gillescolling.com/OccurrenceCleaner/reference/test_institution.md),
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
x <- data.frame(decimalLongitude = c(16.37, 16.51), decimalLatitude = c(48.21, 48.25))
flag_occurrences(x, tests = "capital")$flag_capital
flag_occurrences(x, tests = "capital", buffers = list(capital = 20000))$flag_capital
g <- reference_points("capital")
flag_occurrences(x, tests = "capital",
                 gazetteers = list(capital = g[!g$extension, ]))$flag_capital
clean_capital(x, buffer = 20000)
```
