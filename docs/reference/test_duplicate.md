# Test: duplicates

Flags every record with the same longitude, latitude and species as an
earlier record; the first of each set is not flagged. `duplicate_by`
adds columns that must also match; `duplicate_cell` bins coordinates to
a grid of that many degrees first. A missing species counts as one
value, as in [`duplicated()`](https://rdrr.io/r/base/duplicated.html),
so records without a species at the same coordinates are duplicates of
each other.

## Usage

``` r
clean_duplicate(x, by = NULL, cell = NULL, ...)
```

## Arguments

- x:

  A data frame of occurrence records.

- by:

  Additional column names a duplicate must share, as `duplicate_by` in
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

- cell:

  Cell size in degrees for comparing coordinates, as `duplicate_cell` in
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

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

The test compares each record with all records before it in the input
order: the rows of a data frame, or on streamed input the files in
sorted order and the rows within each file. Streamed input therefore
gets the same flags as the same records in one data frame. It is a
grouped test: the records are bucketed by a 124-bit hash of their key in
a pass before the record tests, so it needs a path rather than a
single-run `vectra_node`. The probability that any two different keys
share a hash is about 2e-18 for ten billion records.

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
x <- data.frame(species = "a", decimalLongitude = c(16.37, 16.37, 16.3701),
                decimalLatitude = 48.21, eventDate = c("2020", "2021", "2020"))
flag_occurrences(x, tests = "duplicate")$flag_duplicate
flag_occurrences(x, tests = "duplicate", duplicate_by = "eventDate")$flag_duplicate
flag_occurrences(x, tests = "duplicate", duplicate_cell = 0.01)$flag_duplicate
clean_duplicate(x, by = "eventDate")
```
