# Test: duplicates

Flags every record with the same longitude, latitude and species as an
earlier record; the first of each set is not flagged. `duplicate_by`
adds columns that must also match; `duplicate_cell` bins coordinates to
a grid of that many degrees first. On streamed input the test runs
within each input file.

## Fields

`lon`, `lat`, `species`, and any `duplicate_by` columns.

## CoordinateCleaner

Equivalent to `cc_dupl()`, with `duplicate_by` as its `additions`.
Records with invalid coordinates are not flagged here; `cc_dupl()` flags
the second of two such records.

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)

Other tests:
[`test_age_equal`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md),
[`test_basis`](https://gillescolling.com/OccurrenceCleaner/reference/test_basis.md),
[`test_capital`](https://gillescolling.com/OccurrenceCleaner/reference/test_capital.md),
[`test_centroid`](https://gillescolling.com/OccurrenceCleaner/reference/test_centroid.md),
[`test_country_mismatch`](https://gillescolling.com/OccurrenceCleaner/reference/test_country_mismatch.md),
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
x <- data.frame(species = "a", decimalLongitude = c(16.37, 16.37, 16.3701),
                decimalLatitude = 48.21, eventDate = c("2020", "2021", "2020"))
flag_occurrences(x, tests = "duplicate")$flag_duplicate
flag_occurrences(x, tests = "duplicate", duplicate_by = "eventDate")$flag_duplicate
flag_occurrences(x, tests = "duplicate", duplicate_cell = 0.01)$flag_duplicate
```
