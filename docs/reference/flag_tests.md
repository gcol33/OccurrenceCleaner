# The flag layout: one bit per test

Every record flagged by
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
carries an integer flag word in which bit `bit` is set when the record
fails test `test`. The layout is versioned: `layout_version` changes
whenever a bit is added, removed or redefined, and the flag output
records which version produced it.

## Usage

``` r
flag_tests()
```

## Value

A data frame with columns `bit` (0-based), `test`, `definition`,
`source`, `equivalent` (the CoordinateCleaner function, or `NA`),
`spatialvalid` (the column `clean_coordinates()` or `clean_fossils()`
writes for the test, used by
[`as_spatialvalid()`](https://gillescolling.com/OccurrenceCleaner/reference/as_spatialvalid.md),
or `NA`) and `needs` (the record fields the test reads, as names of
[`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md)).
The attribute `layout_version` holds the layout version.

## Details

Tests marked `source = "CoordinateCleaner"` are equivalent to the test
of the same name in that package with its default buffer (see the
`equivalent` column); the documented differences are listed in
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).
Tests marked `source = "OccurrenceCleaner"` are additions.

## Examples

``` r
flag_tests()
```
