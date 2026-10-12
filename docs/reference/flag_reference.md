# Reference data behind a set of flags

Returns the label
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
records with its flags: the package version, the land scale, the version
of every reference layer, and for each user gazetteer passed through
`gazetteers` its size and MD5 checksum. Store it next to any cleaned
table that goes into an analysis.

## Usage

``` r
flag_reference(x)
```

## Arguments

- x:

  A data frame returned by
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
  an `occ_flagged` object, or the output directory of a streamed run.

## Value

A character string.

## Examples

``` r
x <- data.frame(decimalLongitude = c(16.37, 0), decimalLatitude = c(48.21, 0))
flag_reference(flag_occurrences(x, tests = c("zero", "capital")))
```
