# Plot flag percentages, or map flagged records

Without grouping, one horizontal bar per test of a rule: the full bar is
the share of records the test flags, the dark part the share it is the
only reason for. With grouping (`by` or `bins` in
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)),
a grid of tests by groups shaded and labelled with the share each test
flags in each group. `type = "map"` on a flagged data frame draws the
records over the Natural Earth land, coloured by whether the rule
removes them.

## Usage

``` r
# S3 method for class 'occ_summary'
plot(x, rule = NULL, ...)

# S3 method for class 'occ_tally'
plot(x, rule = NULL, ...)

# S3 method for class 'occ_flags'
plot(x, type = c("tests", "map"), rules = NULL, ...)

# S3 method for class 'occ_flagged'
plot(x, rules = NULL, ...)
```

## Arguments

- x:

  A flagged data frame (`occ_flags`), an `occ_flagged` object, an
  `occ_tally` or an `occ_summary`.

- rule:

  Name of the rule to draw. Default: the first rule.

- ...:

  For `occ_flags` and `occ_flagged`: passed to
  [`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
  (`by`, `bins`, `tests`). Otherwise unused.

- type:

  For a flagged data frame: `"tests"` (the shares, as for an
  `occ_summary`) or `"map"`.

- rules:

  Named list of rules, as in
  [`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md).
  For `type = "map"` the first rule decides which records are drawn as
  removed. Default: one rule holding every test run.

## Value

`x`, invisibly.

## Examples

``` r
x <- data.frame(species = c("a", "a", "b", "c", "c"),
                kingdom = c("P", "P", "A", "A", "A"),
                decimalLongitude = c(12.58, 0, 16.37, 2.35, 2.35),
                decimalLatitude = c(55.67, 0, 48.21, 48.85, 48.85))
f <- flag_occurrences(x)
plot(f)
plot(f, by = "kingdom")
plot(f, type = "map")
```
