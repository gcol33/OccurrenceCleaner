# Test: artificial hotspots

Flags records within 10 km of a point of the Artificial Hotspot
Occurrence Inventory (AHOI; Park et al. 2023): the coordinates that
recur most often in GBIF plant, bird, insect and mammal records, each
with the reason it recurs (a georeferencing default, a gazetteer
centroid, a popular observation site). WGS84 geodesic distance, closed
ball.

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
[`test_age_equal`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md),
[`test_age_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_outlier.md),
[`test_age_range_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_range_outlier.md),
[`test_basis`](https://gillescolling.com/OccurrenceCleaner/reference/test_basis.md),
[`test_capital`](https://gillescolling.com/OccurrenceCleaner/reference/test_capital.md),
[`test_centroid`](https://gillescolling.com/OccurrenceCleaner/reference/test_centroid.md),
[`test_country_mismatch`](https://gillescolling.com/OccurrenceCleaner/reference/test_country_mismatch.md),
[`test_dataset_ddmm`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_ddmm.md),
[`test_dataset_rounded`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_rounded.md),
[`test_duplicate`](https://gillescolling.com/OccurrenceCleaner/reference/test_duplicate.md),
[`test_equal`](https://gillescolling.com/OccurrenceCleaner/reference/test_equal.md),
[`test_establishment`](https://gillescolling.com/OccurrenceCleaner/reference/test_establishment.md),
[`test_gbif_headquarters`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_headquarters.md),
[`test_gbif_issue`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_issue.md),
[`test_institution`](https://gillescolling.com/OccurrenceCleaner/reference/test_institution.md),
[`test_invalid`](https://gillescolling.com/OccurrenceCleaner/reference/test_invalid.md),
[`test_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_outlier.md),
[`test_range`](https://gillescolling.com/OccurrenceCleaner/reference/test_range.md),
[`test_sea`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md),
[`test_spatiotemporal_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_spatiotemporal_outlier.md),
[`test_urban`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`test_zero`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
a <- reference_points("aohi")
x <- data.frame(decimalLongitude = a$lon[1] + 0.01, decimalLatitude = a$lat[1])
flag_occurrences(x, tests = "aohi")$flag_aohi
```
