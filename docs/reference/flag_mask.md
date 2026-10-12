# Bit mask and membership for sets of tests

`flag_mask()` turns test names into the integer with those bits set;
`has_flag()` tells which flag words carry at least one of the tests. A
cleaning rule is a set of tests, so `has_flag(flags, rule)` marks the
records that rule removes.

## Usage

``` r
flag_mask(tests)

has_flag(flags, tests)
```

## Arguments

- tests:

  Character vector of test names from
  [`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md).

- flags:

  Integer flag words, or a data frame returned by
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
  whose `flags` column is then used.

## Value

`flag_mask()`: a single integer. `has_flag()`: a logical vector, one
element per flag word (per row of a data frame); `NA` flags give `NA`,
so subset with [`which()`](https://rdrr.io/r/base/which.html) or
`%in% TRUE` when flags can be missing. For a flagged data frame, a test
that was not run is an error, so a rule never silently removes nothing
for a test it names.

## Examples

``` r
flag_mask(c("capital", "centroid"))
has_flag(c(0L, 8L, 16L, 24L), c("capital", "centroid"))
x <- data.frame(decimalLongitude = c(16.37, 0), decimalLatitude = c(48.21, 0))
f <- flag_occurrences(x, tests = c("zero", "capital"))
f[!has_flag(f, "zero"), ]
```
