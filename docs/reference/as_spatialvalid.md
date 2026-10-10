# Convert flags to CoordinateCleaner's spatialvalid format

Returns flagged records in the layout that CoordinateCleaner's
`clean_coordinates()` and `clean_fossils()` return with
`value = "spatialvalid"`, so code written for that object (its
[`summary()`](https://rdrr.io/r/base/summary.html) and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods,
filters on `.summary`) runs unchanged. The record columns come first,
then one logical column per test, `TRUE` when the record passes, then
`.summary`, `TRUE` when it passes every test given.

## Usage

``` r
as_spatialvalid(x, tests = NULL)
```

## Arguments

- x:

  A flagged data frame (`occ_flags`) from
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
  or flags written to disk (an `occ_flagged` object or its directory).
  Flags on disk are read into memory with their `keep` columns as the
  record columns.

- tests:

  Tests to include, from those `x` was flagged with; default all of
  them. `.summary` is then the complement of the rule made of these
  tests.

## Value

A data frame of class `c("spatialvalid", "data.frame")`, carrying the
reference and layout version of the flags as attributes `occ_reference`
and `occ_layout_version`.

## Details

Each test takes the column name CoordinateCleaner uses for it (`.cap`
for `capital`, `.otl` for `outlier`, see the `spatialvalid` column of
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md));
a test without one there is written as `.<test>`, for example
`.issue_coordinate`. The columns are decoded from the `flags` word, so a
record whose flag word is `NA` is `NA` in every column.

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md)

## Examples

``` r
x <- data.frame(species = c("a", "a", "b"),
                decimalLongitude = c(0, 16.37, 10),
                decimalLatitude = c(0, 48.21, 50))
sv <- as_spatialvalid(flag_occurrences(x))
sv
sv[sv$.summary, ]
```
