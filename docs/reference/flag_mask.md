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

  Integer flag words as returned by
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

## Value

`flag_mask()`: a single integer. `has_flag()`: a logical vector the
length of `flags`; `NA` flags give `NA`.

## Examples

``` r
flag_mask(c("capital", "centroid"))
has_flag(c(0L, 8L, 16L, 24L), c("capital", "centroid"))
```
