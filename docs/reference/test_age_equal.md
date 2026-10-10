# Test: fossil age range

Flags records whose minimum age is equal to or greater than their
maximum age: a zero-length or inverted stratigraphic range, which in the
Paleobiology Database usually means one age was copied into both fields
or the two were swapped. Records with a missing age are not flagged.

## Details

The width of the range (`max_age - min_age`) is a numeric field, not a
test: it stays a raw column and is cut at tally time with `bins`, as the
record year is.

## Fields

`min_age`, `max_age` (`min_ma`, `max_ma` by default; see
[`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md)).

## CoordinateCleaner

Equivalent to `cf_equal()`; identical flags. `cf_range(method = "time")`
is a threshold on the range width, here a bin in
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md);
`cf_range()` and `cf_age()` with `method = "quantile"` or `"mad"`
compare records of a taxon with each other and are not ported.

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
[`test_urban`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`test_zero`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
x <- data.frame(min_ma = c(10, 20, 30), max_ma = c(20, 20, 25))
flag_occurrences(x, tests = "age_equal")$flag_age_equal
```
