# Test: artificial hotspots

Flags records within 10 km of a point of the Artificial Hotspot
Occurrence Inventory (AHOI; Park et al. 2023): the coordinates that
recur most often in GBIF plant, bird, insect and mammal records, each
with the reason it recurs (a georeferencing default, a gazetteer
centroid, a popular observation site). WGS84 geodesic distance, closed
ball.

## Usage

``` r
clean_aohi(x, buffer = 10000, ...)
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

The shipped inventory is built from the original deposit (Dryad,
doi:10.5061/dryad.v41ns1s0p, CC0);
[`reference_points()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_points.md)
returns it with the taxon group, the record count at each point and
whether the point marks a real observation site (`determination`), so it
can be filtered and passed back through `gazetteers`.

## Fields

`lon`, `lat`.

## Buffer

`buffers = list(aohi = 10000)`, in metres.

## Custom gazetteer

`gazetteers = list(aohi = points)`, a data frame of longitude and
latitude; see
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

## CoordinateCleaner

Equivalent to `cc_aohi()` with its default four taxa; with
`reference = "CoordinateCleaner"` its bundled table is used. Its 72-gon
buffer edge lies within 9.5 m of the 10 km circle. Its table differs
from the Dryad deposit at a few points.

## References

Park, D. S., Xie, Y., Thammavong, H. T., Tulaiha, R. and Feng, X.
(2023). Artificial Hotspot Occurrence Inventory (AHOI). Journal of
Biogeography 50:441-449.
[doi:10.1111/jbi.14543](https://doi.org/10.1111/jbi.14543)

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md),
[`reference_points()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_points.md)

Other tests:
[`clean_age_equal()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md),
[`clean_age_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_outlier.md),
[`clean_age_range_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_range_outlier.md),
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
a <- reference_points("aohi")
x <- data.frame(decimalLongitude = a$lon[1] + 0.01, decimalLatitude = a$lat[1])
flag_occurrences(x, tests = "aohi")$flag_aohi
clean_aohi(x)
```
