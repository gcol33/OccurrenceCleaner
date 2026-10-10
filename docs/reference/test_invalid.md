# Test: invalid coordinates

Flags records whose longitude or latitude is missing, not a number, or
outside \[-180, 180\] x \[-90, 90\]. Text columns are coerced with
`as.numeric(as.character())` first. A record failing this test gets no
other spatial flag.

## Fields

`lon`, `lat` (see
[`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md)).

## CoordinateCleaner

Equivalent to `cc_val()`. Its other spatial tests return `NA` or "clean"
for invalid rows; here those rows carry only the `invalid` bit.

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
[`test_sea`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md),
[`test_urban`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`test_zero`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
x <- data.frame(decimalLongitude = c("16.37", "abc", NA, "200"),
                decimalLatitude = c("48.21", "10", "10", "10"))
flag_occurrences(x, tests = "invalid")$flag_invalid
```
