# Test: zero coordinates

Flags records with a longitude or latitude of exactly zero, and records
within a planar distance of 0.5 degrees of (0, 0).

## Fields

`lon`, `lat`.

## Buffer

`buffers = list(zero = 0.5)`, in degrees. `zero = 0` flags exact zeros
only.

## CoordinateCleaner

Equivalent to `cc_zero()`. CoordinateCleaner 3.0.1 documents the same
0.5 degree buffer, but builds the buffer point without a CRS, so terra
buffers 0.5 metres and only exact zeros are flagged.
`buffers = list(zero = 0)` reproduces that behaviour.

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)

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
[`test_sea`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md),
[`test_urban`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md)

## Examples

``` r
x <- data.frame(decimalLongitude = c(0, 0.3, 0.4), decimalLatitude = c(42, 0.3, 0.4))
flag_occurrences(x, tests = "zero")$flag_zero
flag_occurrences(x, tests = "zero", buffers = list(zero = 0))$flag_zero
```
