# Read flag output written by flag_occurrences()

Read flag output written by flag_occurrences()

## Usage

``` r
read_flagged(x)

flagged_table(x)
```

## Arguments

- x:

  An `occ_flagged` object or the output directory it describes.

## Value

The `occ_flagged` metadata (`read_flagged()`), or a `vectra_node` over
all parts (`flagged_table()`), to be used with
[vectra](https://gillescolling.com/vectra/) verbs and
[`vectra::collect()`](https://gillescolling.com/vectra/reference/collect.html).

## Examples

``` r
if (FALSE) { # \dontrun{
f <- flag_occurrences("snapshot/occurrence.parquet", out = "flags", keep = "kingdom")
vectra::collect(flagged_table(f))
} # }
```
