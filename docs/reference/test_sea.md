# Test: records at sea

Flags records outside the Natural Earth land polygons, by a planar
point-in-polygon test in longitude and latitude through a grid index
that resolves boundary cells exactly. The land layer is chosen with
`land_scale`: 110 (default), 50, or 10. The 1:10m layer is downloaded
once by
[`download_reference()`](https://gillescolling.com/OccurrenceCleaner/reference/download_reference.md).

## Fields

`lon`, `lat`.

## CoordinateCleaner

Equivalent to `cc_sea()` with its default `scale = 110` (`seas_scale` in
`clean_coordinates()`); identical flags on the same layer.
CoordinateCleaner downloads the layer through rnaturalearth at run time;
here it is bundled and pinned.

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md),
[`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md)

Other tests:
[`test_basis`](https://gillescolling.com/OccurrenceCleaner/reference/test_basis.md),
[`test_capital`](https://gillescolling.com/OccurrenceCleaner/reference/test_capital.md),
[`test_centroid`](https://gillescolling.com/OccurrenceCleaner/reference/test_centroid.md),
[`test_country_mismatch`](https://gillescolling.com/OccurrenceCleaner/reference/test_country_mismatch.md),
[`test_duplicate`](https://gillescolling.com/OccurrenceCleaner/reference/test_duplicate.md),
[`test_equal`](https://gillescolling.com/OccurrenceCleaner/reference/test_equal.md),
[`test_establishment`](https://gillescolling.com/OccurrenceCleaner/reference/test_establishment.md),
[`test_gbif_headquarters`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_headquarters.md),
[`test_gbif_issue`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_issue.md),
[`test_institution`](https://gillescolling.com/OccurrenceCleaner/reference/test_institution.md),
[`test_invalid`](https://gillescolling.com/OccurrenceCleaner/reference/test_invalid.md),
[`test_urban`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`test_zero`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
x <- data.frame(decimalLongitude = c(12.58, 16.37, -30), decimalLatitude = c(55.67, 48.21, 40))
flag_occurrences(x, tests = "sea")$flag_sea
flag_occurrences(x, tests = "sea", land_scale = 50)$flag_sea
```
