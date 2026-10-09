# Default tests

The tests
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
runs when `tests` is not given: every CoordinateCleaner-equivalent test
that needs only coordinates and a species name. `coun` needs a country
code, `urb` is left out as in CoordinateCleaner's `clean_coordinates()`,
and the GBIF-field additions need GBIF columns.

## Usage

``` r
default_tests()
```

## Value

A character vector of test names.

## Examples

``` r
default_tests()
```
