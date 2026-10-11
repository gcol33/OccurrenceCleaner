# Choosing a cleaning rule

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
writes one flag per record and test and removes nothing. A cleaning rule
is a set of tests: a record is dropped when it carries any of them. This
article flags a set of records once, measures what share each test and
each candidate rule would remove, overall and by group, and then applies
the chosen rule. All of the comparisons below reuse the flags from that
single pass.

1.  **Flag** the records once with every test of interest,
    [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

2.  **Measure** the share each test and rule removes,
    [`summary()`](https://rdrr.io/r/base/summary.html) and
    [`plot()`](https://rdrr.io/r/graphics/plot.default.html).

3.  **Break it down** by taxon, record age and coordinate precision,
    [`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
    with `by` and `bins`.

4.  **Apply** the chosen rule,
    [`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md).

## Installation

``` r

# install.packages("pak")
pak::pak("gcol33/OccurrenceCleaner")
```

Needs a C++ compiler (Rtools on Windows).

## Example

``` r

library(OccurrenceCleaner)
```

### Records with known errors

The example records are random points on land in Europe, drawn by
rejecting points the `sea` test flags, with species, kingdom, year and
the GBIF fields a download carries. Older records get larger coordinate
uncertainty and are more often rounded, as in real GBIF data.

``` r

set.seed(42)
n <- 3000
lon <- runif(3 * n, -10, 30)
lat <- runif(3 * n, 36, 60)
sea <- flag_occurrences(data.frame(decimalLongitude = lon, decimalLatitude = lat),
                        tests = "sea")$flag_sea
x <- data.frame(decimalLongitude = round(lon[!sea][1:n], 4),
                decimalLatitude = round(lat[!sea][1:n], 4),
                kingdom = sample(c("Animalia", "Plantae", "Fungi"), n, TRUE, c(0.5, 0.4, 0.1)),
                species = paste("species", sample(60, n, TRUE)),
                year = sample(1850:2024, n, TRUE, prob = exp(seq(-3, 0, length.out = 175))))
```

``` r

old <- x$year < 1970
x$coordinateUncertaintyInMeters <- round(rlnorm(n, ifelse(old, 8, 4), 1))
x$coordinateUncertaintyInMeters[sample(n, 600)] <- NA
x$basisOfRecord <- ifelse(old, "PRESERVED_SPECIMEN", "HUMAN_OBSERVATION")
x$basisOfRecord[sample(n, 15)] <- "FOSSIL_SPECIMEN"
x$issue <- ifelse(runif(n) < ifelse(old, 0.3, 0.03), "COORDINATE_ROUNDED", "")
x$issue[sample(n, 40)] <- "TAXON_MATCH_FUZZY;GEODETIC_DATUM_ASSUMED_WGS84"
```

Then the errors are planted: records placed within 3 km of five
capitals, records at (0, 0), records in the Atlantic and exact copies of
earlier records.

``` r

capitals <- data.frame(lon = c(16.37, 2.35, 13.40, -3.70, 12.50),
                       lat = c(48.21, 48.86, 52.52, 40.42, 41.90))
i <- sample(n, 150); j <- sample(5, 150, TRUE)
x$decimalLongitude[i] <- capitals$lon[j] + runif(150, -0.02, 0.02)
x$decimalLatitude[i] <- capitals$lat[j] + runif(150, -0.02, 0.02)
i <- sample(setdiff(seq_len(n), i), 40)
x[i, c("decimalLongitude", "decimalLatitude")] <- 0
i <- sample(n, 60)
x$decimalLongitude[i] <- runif(60, -25, -15)
x$decimalLatitude[i] <- runif(60, 40, 55)
x <- rbind(x, x[sample(n, 120), ])
nrow(x)
#> [1] 3120
```

### Flag once

The tests are the defaults (the CoordinateCleaner-equivalent tests that
need only coordinates and a species), the GBIF issue flags on
coordinates and rounding, and the fossil test on the basis of record.

``` r

tests <- c(default_tests(), "issue_coordinate", "issue_rounded", "basis_fossil")
f <- flag_occurrences(x, tests = tests)
class(f)
#> [1] "occ_flags"  "data.frame"
```

The result is `x` with a `flags` column and one logical `flag_<test>`
column per test. Its class, `occ_flags`, is what
[`summary()`](https://rdrr.io/r/base/summary.html) and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) dispatch on.

### What each test removes

[`summary()`](https://rdrr.io/r/base/summary.html) turns the flags into
shares of records. Without a `rules` argument it uses one rule, `all`,
holding every test that was run.

``` r

summary(f)
#> <occ_summary> 3,120 records
#>   rule all: removes 750 (24.04 %)
#>  rule              test    n flagged   pct only pct_only
#>   all           invalid 3120       0  0.00    0     0.00
#>   all              zero 3120      40  1.28    0     0.00
#>   all             equal 3120      40  1.28    0     0.00
#>   all           capital 3120     161  5.16  120     3.85
#>   all          centroid 3120      16  0.51    1     0.03
#>   all       institution 3120       5  0.16    0     0.00
#>   all gbif_headquarters 3120       0  0.00    0     0.00
#>   all               sea 3120     105  3.37   52     1.67
#>   all         duplicate 3120     130  4.17   92     2.95
#>   all  issue_coordinate 3120       0  0.00    0     0.00
#>   all     issue_rounded 3120     411 13.17  361    11.57
#>   all      basis_fossil 3120      15  0.48   12     0.38
#>   all             (any) 3120     750 24.04
```

For each test of the rule, `flagged` is the number of records carrying
that test and `pct` the same as a percentage of all records. `only`
counts the records for which that test is the sole flag among the rule’s
tests: dropping that test from the rule would keep exactly these
records. The row `(any)` is the rule itself, the records that carry at
least one of its tests.

A record can fail several tests at once. The 40 records at (0, 0) are
flagged by `zero`, `equal` (\|0\| = \|0\|) and `sea`, so none of them is
counted under `only`. The per-test shares therefore add up to more than
the rule’s total, while the `only` shares add up to at most that total;
the difference is the records removed for more than one reason. Both
figures are needed to say why records are lost: `pct` is how often a
problem occurs, `pct_only` is how much of the loss would disappear
without that test.

The same numbers as a plot: the full bar is `pct`, the dark part
`pct_only`.

``` r

plot(f)
```

![](rules_files/figure-html/unnamed-chunk-7-1.svg)

### Comparing rules

Candidate rules go into `rules` as a named list. Here `strict` uses all
the tests, `cc` the CoordinateCleaner tests without the duplicate test,
and `minimal` only the tests for coordinates that cannot be right.

``` r

rules <- list(strict = tests,
              cc = setdiff(default_tests(), "duplicate"),
              minimal = c("invalid", "zero", "sea"))
s <- summary(f, rules = rules)
s[s$test == "(any)", c("rule", "n", "flagged", "pct")]
#>     rule    n flagged   pct
#>   strict 3120     750 24.04
#>       cc 3120     267  8.56
#>  minimal 3120     105  3.37
```

The summary is a data frame of class `occ_summary`, so rows can be
selected as usual; the selection above keeps one row per rule.
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) draws one rule
at a time:

``` r

plot(s, rule = "cc")
```

![](rules_files/figure-html/unnamed-chunk-9-1.svg)

Under `cc`, no record at (0, 0) is counted under `only`, since `zero`,
`equal` and `sea` all flag it; dropping any one of the three from the
rule keeps every such record removed. The capital test, by contrast, is
the sole reason for most of its records.

### By group

The arguments of
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
pass through [`summary()`](https://rdrr.io/r/base/summary.html), so `by`
splits the shares by any column of the records.

``` r

s <- summary(f, rules = rules["cc"], by = "kingdom")
s[s$test %in% c("capital", "sea", "(any)"), ]
#> <occ_summary> 3,120 records, grouped by kingdom
#>   kingdom rule    test    n flagged  pct only pct_only
#>  Animalia   cc capital 1546      85 5.50   77     4.98
#>  Animalia   cc     sea 1546      53 3.43   33     2.13
#>  Animalia   cc   (any) 1546     138 8.93              
#>     Fungi   cc capital  312      15 4.81   12     3.85
#>     Fungi   cc     sea  312      10 3.21    6     1.92
#>     Fungi   cc   (any)  312      25 8.01              
#>   Plantae   cc capital 1262      61 4.83   52     4.12
#>   Plantae   cc     sea 1262      42 3.33   26     2.06
#>   Plantae   cc   (any) 1262     104 8.24
```

With grouping, [`plot()`](https://rdrr.io/r/graphics/plot.default.html)
shows a grid of tests by groups, shaded by the share each test flags in
each group, with the rule itself in the bottom row.

``` r

plot(f, rules = rules["cc"], by = "kingdom")
```

![](rules_files/figure-html/unnamed-chunk-11-1.svg)

### Record age and coordinate precision

Year and coordinate uncertainty stay raw columns of the records and are
cut into classes only when tallying. `bins` takes the break points and
adds a `<column>_bin` grouping column, with missing values in their own
class.

``` r

t <- tally_flags(f, rules = rules,
                 bins = list(year = c(1900, 1950, 1970, 2000)))
s <- summary(t)
s[s$rule == "strict" & s$test %in% c("issue_rounded", "(any)"),
  c("year_bin", "test", "n", "pct")]
#>   year_bin          test    n   pct
#>      <1900 issue_rounded  240 30.00
#>      <1900         (any)  240 40.42
#>  1900-1950 issue_rounded  526 30.99
#>  1900-1950         (any)  526 38.02
#>  1950-1970 issue_rounded  362 30.39
#>  1950-1970         (any)  362 37.29
#>  1970-2000 issue_rounded  852  3.52
#>  1970-2000         (any)  852 14.67
#>     >=2000 issue_rounded 1140  3.16
#>     >=2000         (any) 1140 16.93
```

[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
returns the counts; [`summary()`](https://rdrr.io/r/base/summary.html)
on its result gives the percentages, and
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) the grid. The
tally is the one to keep when the counts will be summed or merged later.

``` r

plot(t, rule = "strict")
```

![](rules_files/figure-html/unnamed-chunk-13-1.svg)

The same works for the stated coordinate uncertainty, where the classes
are distances in metres:

``` r

t <- tally_flags(f, rules = rules["strict"],
                 bins = list(coordinateUncertaintyInMeters = c(100, 1000, 10000)))
s <- summary(t)
s[s$test %in% c("issue_rounded", "(any)"),
  c("coordinateUncertaintyInMeters_bin", "test", "n", "pct")]
#>  coordinateUncertaintyInMeters_bin          test    n   pct
#>                               <100 issue_rounded 1159  3.97
#>                               <100         (any) 1159 17.95
#>                           100-1000 issue_rounded  567  9.35
#>                           100-1000         (any)  567 18.87
#>                         1000-10000 issue_rounded  664 30.12
#>                         1000-10000         (any)  664 38.70
#>                            >=10000 issue_rounded  111 31.53
#>                            >=10000         (any)  111 36.94
#>                            missing issue_rounded  619 12.44
#>                            missing         (any)  619 22.13
```

### Where the removed records are

On a flagged data frame, `plot(type = "map")` draws the records over the
Natural Earth land, coloured by whether the first rule of `rules`
removes them.

``` r

plot(f, type = "map", rules = rules["cc"])
```

![](rules_files/figure-html/unnamed-chunk-15-1.svg)

### Applying the rule

[`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md)
returns `TRUE` for every record carrying at least one test of the rule,
so the cleaned table is the complement.

``` r

clean <- f[!has_flag(f$flags, rules$cc), ]
nrow(clean)
#> [1] 2853
```

The removed records keep their flags, and a different rule only needs a
different set of tests in the same call; the records never have to be
flagged again. A cut on record age or uncertainty is an ordinary filter
on the raw columns, for example `clean[clean$year >= 1950, ]`.

## How the shares are computed

All counts come from the integer flag word. For a rule with tests $`T`$
and the bit mask $`m_T`$ of those tests (`flag_mask(T)`), a record with
flag word $`w`$ is

- flagged by test $`t`$ when bit $`t`$ of $`w`$ is set,

- removed by the rule when $`w \mathbin{\&} m_T \neq 0`$,

- removed by $`t`$ alone when $`w \mathbin{\&} m_T = m_t`$.

[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
counts these per group in one pass over the flags, which is also how it
runs on on-disk output part by part (see [Large tables on
disk](https://gillescolling.com/OccurrenceCleaner/articles/on-disk.md)).
The percentages in [`summary()`](https://rdrr.io/r/base/summary.html)
divide each count by the number of records in its group.
