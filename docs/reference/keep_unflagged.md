# Keep the records no test flagged

Removes the records flagged by a cleaning rule from the output of
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).
Without `tests`, the rule is every test that ran; with `tests`, only
those tests exclude a record, so records flagged by other tests stay.
The flag columns and the attributes of `x` are kept, so the result can
be tallied, summarised or subset again.

## Usage

``` r
keep_unflagged(x, tests = NULL)
```

## Arguments

- x:

  A data frame returned by
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

- tests:

  Character vector of test names, see
  [`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md);
  `NULL` (the default) uses every test that ran. A test that was not run
  is an error.

## Value

The rows of `x` with no flag from `tests`, with the columns and
attributes of `x`.

## Cleaning functions

Each test also has a cleaning function, `clean_<test>()`, documented on
the test's help page
([test_capital](https://gillescolling.com/OccurrenceCleaner/reference/test_capital.md),
[test_outlier](https://gillescolling.com/OccurrenceCleaner/reference/test_outlier.md),
...). It runs that one test with
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
and returns the rows of `x` the test does not flag, with the columns of
`x` unchanged. Its arguments are the test's buffer or options, with the
defaults in the usage line; further arguments (`columns`, `reference`,
`gazetteers`, `land_scale`) go to
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

A chain of cleaning functions runs each test on the records the previous
steps kept. For record tests this gives the same records as flagging all
tests once and calling `keep_unflagged()`. A grouped test (`duplicate`,
`outlier`, the fossil outlier tests, the dataset tests) compares a
record with the other records of its group, so its result depends on
which records earlier steps removed;
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
runs every test on the full input. The cleaning functions take a data
frame; a table on disk is flagged with
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
and counted with
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md).

## See also

[`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md)
for the logical vector behind the selection,
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
to compare several rules.

## Examples

``` r
x <- data.frame(species = c("a", "a", "b", "c"),
                decimalLongitude = c(12.58, 0, 16.37, 2.35),
                decimalLatitude = c(55.67, 0, 48.21, 48.85))
f <- flag_occurrences(x, tests = c("zero", "capital"))
keep_unflagged(f)
keep_unflagged(f, tests = "zero")
```
