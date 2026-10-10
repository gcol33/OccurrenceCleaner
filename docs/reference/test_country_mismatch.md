# Test: country code mismatch

Flags records whose coordinates fall outside the Natural Earth 1:50m
country polygon named by their country code. The code is compared with
the polygon's ISO 3166-1 alpha-2 code, its alpha-3 code and the Natural
Earth `ADM0_A3` code, case-insensitively. Records without a code, and
records at sea, are flagged.

## Fields

`lon`, `lat`, `country`.

## CoordinateCleaner

Equivalent to `cc_coun()`, which compares alpha-3 codes only; for
alpha-3 codes present in Natural Earth the flags are identical. GBIF's
`countryCode` is alpha-2 and works here without conversion.

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md),
[`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md)

Other tests:
[`test_basis`](https://gillescolling.com/OccurrenceCleaner/reference/test_basis.md),
[`test_capital`](https://gillescolling.com/OccurrenceCleaner/reference/test_capital.md),
[`test_centroid`](https://gillescolling.com/OccurrenceCleaner/reference/test_centroid.md),
[`test_duplicate`](https://gillescolling.com/OccurrenceCleaner/reference/test_duplicate.md),
[`test_equal`](https://gillescolling.com/OccurrenceCleaner/reference/test_equal.md),
[`test_establishment`](https://gillescolling.com/OccurrenceCleaner/reference/test_establishment.md),
[`test_gbif_headquarters`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_headquarters.md),
[`test_gbif_issue`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_issue.md),
[`test_institution`](https://gillescolling.com/OccurrenceCleaner/reference/test_institution.md),
[`test_invalid`](https://gillescolling.com/OccurrenceCleaner/reference/test_invalid.md),
[`test_sea`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md),
[`test_urban`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`test_zero`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
x <- data.frame(decimalLongitude = 16.37, decimalLatitude = 48.21,
                countryCode = c("AT", "AUT", "DE", NA))
flag_occurrences(x, tests = "country_mismatch")$flag_country_mismatch
```
