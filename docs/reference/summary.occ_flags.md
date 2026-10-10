# Share of records flagged, per test and rule

Turns flag counts into percentages: for every rule, how many records
each of its tests flags, how many it is the only reason the rule
removes, and how many the rule removes in total. A record can fail
several tests, so the per-test shares of a rule can add up to more than
the rule's total; the `only` shares add up to at most that total, and
the rest is records removed for more than one reason.

## Usage

``` r
# S3 method for class 'occ_flags'
summary(object, ...)

# S3 method for class 'occ_flagged'
summary(object, ...)

# S3 method for class 'occ_tally'
summary(object, ...)
```

## Arguments

- object:

  A data frame returned by
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
  (class `occ_flags`), an `occ_flagged` object, or a table from
  [`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md).

- ...:

  Passed to
  [`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md):
  `rules`, `by`, `bins`, `tests`.

## Value

A data frame of class `occ_summary`, one row per group, rule and test of
the rule, plus one row per group and rule with `test = "(any)"` for the
rule as a whole. Columns: the grouping columns, `rule`, `test`, `n`
(records in the group), `flagged` (records carrying the test, or removed
by the rule), `pct` (`flagged` as a percentage of `n`), `only` (records
whose sole flag among the rule's tests is this one) and `pct_only`.

## Details

[`summary()`](https://rdrr.io/r/base/summary.html) on a flagged data
frame or on on-disk flag output first calls
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
with the arguments in `...`, so `rules`, `by` and `bins` work as there;
on an `occ_tally` it reshapes the counts already made.

## See also

[`plot.occ_summary()`](https://gillescolling.com/OccurrenceCleaner/reference/plot.occ_summary.md)
to draw it.

## Examples

``` r
x <- data.frame(species = c("a", "a", "b", "c", "c"),
                kingdom = c("P", "P", "A", "A", "A"),
                decimalLongitude = c(12.58, 0, 16.37, 2.35, 2.35),
                decimalLatitude = c(55.67, 0, 48.21, 48.85, 48.85))
f <- flag_occurrences(x)
summary(f)
summary(f, rules = list(strict = c("zero", "capital", "duplicate")), by = "kingdom")
```
