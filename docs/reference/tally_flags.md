# Tally flags into a loss table

Counts, per group, how many records each test flags and how many a
cleaning rule removes. A rule is a set of tests: a record is removed
when it carries any of them. Works on a flagged data frame or on the
on-disk output of
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
which is streamed part by part.

## Usage

``` r
tally_flags(x, by = NULL, rules = NULL, bins = NULL, tests = NULL)
```

## Arguments

- x:

  A data frame returned by
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
  (or any data frame with an integer `flags` column), an `occ_flagged`
  object, or its output directory.

- by:

  Character vector of grouping columns. For on-disk output these must
  have been passed as `keep` when flagging. Missing values form the
  group `"missing"`.

- rules:

  Named list of character vectors of test names. Default: one rule,
  `"all"`, holding every test present in the flags.

- bins:

  Named list of numeric break points. Each named column is cut at those
  breaks into a factor-like character column `<name>_bin` (closed on the
  left, missing values labelled `"missing"`) and added to `by`.

- tests:

  Tests to count individually. Default: those recorded with the flags,
  or every test with a set bit.

## Value

A data frame of class `occ_tally` with the `by` columns, `n` (records),
`n_valid` (records without the `invalid` flag, when `invalid` was run),
one column `flagged_<test>` per test, per rule `removed_<rule>` and
`kept_<rule>`, and per rule and test of the rule `only_<rule>_<test>`:
the records that test is the sole reason the rule removes. The attribute
`occ_rules` holds the rules and `occ_by` the grouping columns.
[summary()](https://gillescolling.com/OccurrenceCleaner/reference/summary.occ_flags.md)
turns the counts into percentages and
[plot()](https://gillescolling.com/OccurrenceCleaner/reference/plot.occ_summary.md)
draws them.

## Examples

``` r
x <- data.frame(species = c("a", "a", "b", "c"), kingdom = c("P", "P", "A", "A"),
                decimalLongitude = c(12.58, 0, 16.37, 2.35),
                decimalLatitude = c(55.67, 0, 48.21, 48.85))
f <- flag_occurrences(x, tests = c("invalid", "zero", "gbif_headquarters", "capital"))
tally_flags(f, by = "kingdom",
            rules = list(strict = c("zero", "gbif_headquarters", "capital"), mild = "zero"))
```
