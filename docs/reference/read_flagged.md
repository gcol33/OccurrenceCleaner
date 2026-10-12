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
x <- data.frame(gbifID = 1:4, kingdom = c("Plantae", "Plantae", "Animalia", "Animalia"),
                decimalLongitude = c(12.58, 0, 16.37, 2.35),
                decimalLatitude = c(55.67, 0, 48.21, 48.85))
input <- file.path(tempdir(), "occurrence.csv")
utils::write.csv(x, input, row.names = FALSE)
out <- file.path(tempdir(), "flags")
flag_occurrences(input, tests = c("zero", "capital"), out = out, keep = "kingdom",
                 verbose = FALSE)
f <- read_flagged(out)
f
vectra::collect(flagged_table(f))
unlink(c(input, out), recursive = TRUE)
```
