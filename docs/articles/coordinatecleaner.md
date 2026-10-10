# Coming from CoordinateCleaner

OccurrenceCleaner runs the tests of CoordinateCleaner (Zizka et
al. [2019](https://doi.org/10.1111/2041-210X.13152)) with the same
definitions and default settings, and writes the result as flags instead
of filtering. This article maps each CoordinateCleaner function to its
test here, runs both packages on the same records, lists every case
where the flags differ and why, and names the parts of CoordinateCleaner
that have no counterpart. The chunks that call CoordinateCleaner run
only when it is installed; it is a suggested package, not a dependency.

## Installation

``` r

# install.packages("pak")
pak::pak("gcol33/OccurrenceCleaner")
```

Needs a C++ compiler (Rtools on Windows).

``` r

library(OccurrenceCleaner)
```

## Function mapping

| CoordinateCleaner | OccurrenceCleaner |
|:---|:---|
| cc_val() | invalid |
| cc_zero() | zero |
| cc_equ() | equal |
| cc_cap() | capital |
| cc_cen() | centroid |
| cc_inst() | institution |
| cc_gbif() | gbif_headquarters |
| cc_sea() | sea |
| cc_urb() | urban |
| cc_coun() | country_mismatch |
| cc_dupl() | duplicate |
| cf_equal() | age_equal |
| cc_outl() | outlier |
| cf_age() | age_outlier |
| cf_outl() | spatiotemporal_outlier |
| cf_range(method = “quantile” or “mad”) | age_range_outlier |
| cd_ddmm() | dataset_ddmm |
| cd_round() | dataset_rounded |
| cc_iucn() | range |
| cc_aohi() | aohi |
| write_pyrate() | export_pyrate() |
| cc_outl(sampling_thresh = …) | settings = list(outlier = list(sampling_thresh = …)) with gazetteers = list(sampling = …) |
| clean_coordinates(), clean_fossils(), clean_dataset() | flag_occurrences(x, tests = …) |
| buffer arguments (capitals_rad, …) | buffers = list(capital = …) |
| method, mltpl, size_thresh, replicates, … of the outlier and dataset tests | settings = list(outlier = list(method = …), …) |
| ref arguments (cc_cap(ref = …), cc_sea(ref = …), …) | gazetteers = list(capital = …, sea = …) |
| cf_range(method = “time”, max_range = …) | tally_flags(bins = …) on max_ma - min_ma |
| additions (cc_dupl) | duplicate_by |
| seas_scale (default 50) | land_scale (default 110, as cc_sea()) |
| value = “clean” | x\[!has_flag(x\$flags, rule), \] |
| value = “flagged” / “spatialvalid” | the flag\_ columns; as_spatialvalid(f) for the spatialvalid layout |

OccurrenceCleaner has one flagging function,
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
and its `tests` argument chooses which tests run. It has no `cc_*`
functions, so attaching both packages hides none of CoordinateCleaner’s.

CoordinateCleaner’s
[`clean_coordinates()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_coordinates.html)
and
[`clean_fossils()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_fossils.html)
also choose tests by name, but the names differ:

| CoordinateCleaner | OccurrenceCleaner |
|:---|:---|
| capitals | capital |
| centroids | centroid |
| countries | country_mismatch |
| duplicates | duplicate |
| equal | equal |
| gbif | gbif_headquarters |
| institutions | institution |
| seas | sea |
| urban | urban |
| zeros | zero |
| outliers | outlier |
| agesequal ([`clean_fossils()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_fossils.html)) | age_equal |
| spatiotemp ([`clean_fossils()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_fossils.html)) | spatiotemporal_outlier |
| temprange ([`clean_fossils()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_fossils.html)) | age_range_outlier |
| ddmm ([`clean_dataset()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_dataset.html)) | dataset_ddmm |
| periodicity ([`clean_dataset()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_dataset.html)) | dataset_rounded |

The check for missing or out-of-range coordinates has no name in
[`clean_coordinates()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_coordinates.html).
It always runs first, and if any coordinate fails it,
[`clean_coordinates()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_coordinates.html)
stops and returns that result alone. Here it is the `invalid` test, and
the other tests still run on the records that pass it.

## Side by side

A typical CoordinateCleaner pipeline filters as it goes, each `cc_*()`
call dropping the records it flags:

``` r

library(CoordinateCleaner)
clean <- x |>
  cc_val() |>
  cc_equ() |>
  cc_zero() |>
  cc_cap() |>
  cc_cen() |>
  cc_inst() |>
  cc_gbif() |>
  cc_sea()
```

The same cleaning here is one flagging call and one subset. The subset
can be changed later without flagging again:

``` r

f <- flag_occurrences(x, tests = c("invalid", "equal", "zero", "capital", "centroid",
                                   "institution", "gbif_headquarters", "sea"))
clean <- f[!has_flag(f$flags, c("invalid", "equal", "zero", "capital", "centroid",
                                "institution", "gbif_headquarters", "sea")), ]
```

[`clean_coordinates()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_coordinates.html)
is the closer equivalent, since it also returns one column per test
rather than dropping records. Its columns are `TRUE` for records that
pass, the `flag_<test>` columns here are `TRUE` for records that fail.
Records within 30 km of five capitals, plus 20 zeros, 20 equal
coordinates and 10 records within 0.3 degrees of (0, 0), run through
both:

``` r

set.seed(3)
caps <- cbind(lon = c(16.37, 2.35, -3.70, 13.40, 69.17), lat = c(48.21, 48.86, 40.42, 52.52, 34.53))
k <- sample(5, 4000, TRUE)
p <- geosphere::destPoint(caps[k, ], b = runif(4000, 0, 360), d = 30000 * sqrt(runif(4000)))
x <- data.frame(species = sample(c("a", "b"), 4000, TRUE),
                decimalLongitude = round(p[, 1], 4), decimalLatitude = round(p[, 2], 4))
x[1:20, 2:3] <- 0
x[21:40, 3] <- x[21:40, 2]
x[41:50, 2:3] <- round(runif(20, -0.3, 0.3), 4)
```

``` r

cc <- CoordinateCleaner::clean_coordinates(
  x, lon = "decimalLongitude", lat = "decimalLatitude", species = "species",
  tests = c("capitals", "centroids", "equal", "gbif", "institutions", "zeros", "duplicates"),
  value = "spatialvalid", verbose = FALSE)
oc <- flag_occurrences(x, tests = c("invalid", "zero", "equal", "capital", "centroid",
                                    "institution", "gbif_headquarters", "duplicate"),
                       reference = "CoordinateCleaner")
```

`reference = "CoordinateCleaner"` reads that package’s own gazetteers at
run time, so both packages test against the same points. Per test, the
share of records with the same verdict:

``` r

pairs <- c(.zer = "zero", .equ = "equal", .cap = "capital", .cen = "centroid",
           .inst = "institution", .gbf = "gbif_headquarters", .dpl = "duplicate")
agree <- vapply(names(pairs), function(cn)
  mean((!cc[[cn]]) == oc[[paste0("flag_", pairs[[cn]])]], na.rm = TRUE), numeric(1))
knitr::kable(data.frame(CoordinateCleaner = names(pairs), OccurrenceCleaner = pairs,
                        flagged_cc = vapply(names(pairs), function(cn) sum(!cc[[cn]], na.rm = TRUE), 1),
                        flagged_oc = vapply(pairs, function(t) sum(oc[[paste0("flag_", t)]]), 1),
                        agreement = round(agree, 5)), row.names = FALSE)
```

| CoordinateCleaner | OccurrenceCleaner | flagged_cc | flagged_oc | agreement |
|:------------------|:------------------|-----------:|-----------:|----------:|
| .zer              | zero              |         20 |         30 |   0.99750 |
| .equ              | equal             |         40 |         40 |   1.00000 |
| .cap              | capital           |        435 |        436 |   0.99975 |
| .cen              | centroid          |         29 |         29 |   1.00000 |
| .inst             | institution       |          0 |          0 |   1.00000 |
| .gbf              | gbif_headquarters |          0 |          0 |   1.00000 |
| .dpl              | duplicate         |         18 |         18 |   1.00000 |

The two differ in `zero`, on purpose, for the 10 records near but not at
(0, 0), and in `capital` for records at the buffer edge; the next
section explains both. The package’s own test suite runs this comparison
on sampled records for every equivalent test and requires the
differences to be only those documented below.

## Where the flags differ

### Buffer circles

CoordinateCleaner builds each buffer as a polygon with its vertices on
the circle (72 vertices for capitals, centroids and the GBIF
headquarters, 40 for institutions) and tests whether a record lies
inside that polygon. Between two vertices the polygon edge lies inside
the circle, at $`r \cos(\pi / n)`$ from the centre at mid-edge: 99.9 %
of the buffer for 72 vertices, 99.7 % for 40. OccurrenceCleaner tests
the geodesic distance against the buffer itself. A record due north of
Kabul’s capital point (a vertex direction) and one at a bearing of 2.5
degrees (mid-edge), each at 9,995 m:

``` r

e <- new.env(); utils::data("countryref", package = "CoordinateCleaner", envir = e)
kabul <- unlist(e$countryref[e$countryref$iso3 == "AFG", c("capital.lon", "capital.lat")][1, ])
p <- geosphere::destPoint(kabul, b = c(0, 2.5), d = 9995)
y <- data.frame(species = "a", decimalLongitude = p[, 1], decimalLatitude = p[, 2])
data.frame(bearing = c(0, 2.5), distance_m = 9995,
           cc_flagged = !CoordinateCleaner::cc_cap(y, value = "flagged", verbose = FALSE),
           oc_flagged = flag_occurrences(y, tests = "capital", reference = "CoordinateCleaner")$flag_capital)
#>   bearing distance_m cc_flagged oc_flagged
#> 1     0.0       9995       TRUE       TRUE
#> 2     2.5       9995      FALSE       TRUE
```

So every record CoordinateCleaner flags is flagged here, and the extra
flags are records between 99.7 % and 100 % of a buffer: within 9.5 m of
the 10 km capital edge, 0.95 m of the 1 km centroid and headquarters
edge, 0.31 m of the 100 m institution edge.

### The zero buffer

CoordinateCleaner’s
[`cc_zero()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_zero.html)
documents a 0.5-degree buffer around (0, 0). In version 3.0.1 the buffer
point is created without a coordinate reference system, terra assumes
longitude and latitude, and `terra::buffer(width = 0.5)` then buffers
0.5 **metres**. Only records with a longitude or latitude of exactly
zero are flagged:

``` r

z <- data.frame(species = "a", decimalLongitude = c(0, 0.3, 0.001), decimalLatitude = c(12, 0.3, 0.001))
data.frame(z[, 2:3],
           cc_flagged = !CoordinateCleaner::cc_zero(z, value = "flagged", verbose = FALSE),
           oc_flagged = flag_occurrences(z, tests = "zero")$flag_zero,
           oc_zero_buffer_0 = flag_occurrences(z, tests = "zero", buffers = list(zero = 0))$flag_zero)
#>   decimalLongitude decimalLatitude cc_flagged oc_flagged oc_zero_buffer_0
#> 1            0.000          12.000       TRUE       TRUE             TRUE
#> 2            0.300           0.300      FALSE       TRUE            FALSE
#> 3            0.001           0.001      FALSE       TRUE            FALSE
```

This package applies the documented 0.5-degree radius.
`buffers = list(zero = 0)` reproduces CoordinateCleaner 3.0.1’s results.

### Country codes

[`cc_coun()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_coun.html)
compares the record’s code with the ISO alpha-3 code of the country
polygon only. GBIF’s `countryCode` is alpha-2, so a GBIF table needs
converting first. `country_mismatch` accepts alpha-2, alpha-3 and
Natural Earth’s `ADM0_A3` code, which fills the gaps where Natural Earth
has `-99` for the ISO code. For records whose code is alpha-3 and
present in Natural Earth, the two tests agree.

### Records without valid coordinates

For rows with missing or out-of-range coordinates, CoordinateCleaner’s
spatial tests return `NA` (`cc_zero`, `cc_equ`) or “clean” (`cc_cap`),
and `cc_dupl` flags the second of two such rows. Here such a record gets
the `invalid` bit and no other spatial bit, so a rule that holds
`invalid` removes it and a rule without `invalid` sees no spatial flag
on it.

### Outliers of large species

[`cc_outl()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_outl.html)
tests species of 10,000 records or more, and every species with
`thinning = TRUE`, on a raster approximation: it counts records per cell
of a 0.5-degree grid, computes the distance statistics between cells,
and selects the outlier cells. In CoordinateCleaner 3.0.1 the last step,
which turns the outlier cells back into records, compares a data frame
with the cell numbers as a whole and matches nothing, so that path never
flags a record. Twenty records 1,000 km from the other 11,980 of their
species show it:

``` r

set.seed(1)
n <- 12000
r <- data.frame(species = "a", decimalLongitude = c(runif(n - 20, 10, 20), runif(20, 120, 130)),
                decimalLatitude = c(runif(n - 20, 40, 50), runif(20, -30, -20)))
c(cc_flagged = sum(!CoordinateCleaner::cc_outl(r, value = "flagged", verbose = FALSE)),
  oc_flagged = sum(flag_occurrences(r, tests = "outlier")$flag_outlier))
#> cc_flagged oc_flagged 
#>          0         20
```

`outlier` uses the same grid, weights and statistics and flags the
records of the outlier cells. Below 10,000 records, where
[`cc_outl()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_outl.html)
computes exact distances, the two give identical flags.

### Random age draws

[`cf_age()`](https://ropensci.github.io/CoordinateCleaner/reference/cf_age.html)
and
[`cf_outl()`](https://ropensci.github.io/CoordinateCleaner/reference/cf_outl.html)
draw one age from each record’s range, repeat the test five times and
keep the majority. CoordinateCleaner draws from the session’s random
stream in the order of the input, so its flags change with the seed and
the row order. `age_outlier` and `spatiotemporal_outlier` draw from a
stream seeded per taxon
(`settings = list(age_outlier = list(seed = ...))`) in an order fixed by
the records’ content, so the same records give the same flags in any
order and split into any files. Both follow the same distribution; when
every age range has zero width nothing is drawn and the flags are
identical.

### Small datasets

[`cd_round()`](https://ropensci.github.io/CoordinateCleaner/reference/cd_round.html)
skips datasets with fewer than `min_unique_ds_size` distinct
coordinates, but in version 3.0.1 an input holding such a dataset next
to larger ones stops with an error when the per-dataset results are
combined. `dataset_rounded` leaves the small dataset untested and tests
the others. Records without a dataset key are not flagged by either
dataset test;
[`cd_ddmm()`](https://ropensci.github.io/CoordinateCleaner/reference/cd_ddmm.html)
flags them.

### Duplicates in streamed input

On a data frame `duplicate` is evaluated over the whole table, as
[`cc_dupl()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_dupl.html)
is. On a table streamed from disk it is evaluated within each input
file; the on-disk article shows how to make the files the right units
for that.

### Gazetteers

With the default `reference = "natural_earth"` the gazetteers are
rebuilt from the original sources (Natural Earth, GBIF’s registry of
collections), not copied from CoordinateCleaner, whose code and data are
GPL-3. They hold the same kinds of points but not the same coordinates;
the reference-data article measures the differences.
`reference = "CoordinateCleaner"` uses CoordinateCleaner’s tables and
reproduces its flags up to the differences above.

## Speed

The proximity tests are where the two packages differ most, because
CoordinateCleaner builds a polygon per reference point and tests each
record against all of them, while this package queries a kd-tree.
Measured on one machine (AMD Ryzen 7 5700G, 64 GB, Windows, R 4.6.1,
OccurrenceCleaner 0.1.0, CoordinateCleaner 3.0.1), single process, both
reading CoordinateCleaner’s gazetteers, in seconds:

| test | OccurrenceCleaner, 1e6 | CoordinateCleaner, 1e6 | OccurrenceCleaner, 1e7 | CoordinateCleaner, 1e7 |
|:---|---:|---:|---:|---:|
| capital | 0.28 | 24.5 | 1.78 | 242.3 |
| centroid | 0.15 | 34.9 | 2.15 | 246.2 |
| institution | 0.18 | 1.0 | 1.73 | 7.4 |
| gbif_headquarters | 0.08 | 0.6 | 0.81 | 6.5 |
| sea | 0.06 | 5.9 | 0.66 | 59.7 |
| zero | 0.07 | 0.6 | 0.42 | 6.7 |
| equal | 0.03 | 0.0 | 0.36 | 0.1 |
| invalid | 0.02 | 5.9 | 0.38 | 64.3 |
| duplicate | 1.55 | 1.1 | 13.79 | 11.9 |
| default_tests() (own reference) | 1.90 | not run | 17.79 | not run |

At ten million records the capital test takes 1.8 s here and 242 s in
CoordinateCleaner, the centroid test 2.2 s and 246 s. The equal and
duplicate tests are plain vector operations in both packages and take
about the same time. Beyond memory, an on-disk table is streamed in
chunks (see the on-disk article), so the input size is bounded by disk
space only. The benchmark script is `bench/benchmark.R` in the source
repository.

## Functions around the tests

Every function of CoordinateCleaner 3.0.1 has a counterpart here.
Besides the tests:

| CoordinateCleaner | what it does | OccurrenceCleaner |
|:---|:---|:---|
| cc_outl(sampling_thresh = …) | keeps outliers only in well-sampled countries, with record counts queried online | the same rule, with the record counts given as a table (gazetteers = list(sampling = …)) |
| write_pyrate() | writes fossil occurrences as PyRate input files | export_pyrate(), the same file layout |
| plot() | maps flagged records | plot(f, type = “map”) |
| summary() | counts flagged records per test | summary(f) |
| is.spatialvalid() | checks the class of a clean_coordinates() result | the occ_flags class |

[`cc_outl()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_outl.html)
queries GBIF for each country’s record count at run time, so its result
changes as GBIF grows; here the counts are part of the call and recorded
in the reference label.
[`export_pyrate()`](https://gillescolling.com/OccurrenceCleaner/reference/export_pyrate.md)
takes the name it has to leave
[`write_pyrate()`](https://ropensci.github.io/CoordinateCleaner/reference/write_pyrate.html)
reachable when both packages are attached.

Code written for a `spatialvalid` object runs on `as_spatialvalid(f)`:
it writes the record columns, one column per test under
CoordinateCleaner’s name (`.cap`, `.zer`, `.otl`, …) with `TRUE` for
pass, and `.summary`, with the class `spatialvalid`, so
CoordinateCleaner’s [`summary()`](https://rdrr.io/r/base/summary.html)
and [`plot()`](https://rdrr.io/r/graphics/plot.default.html) methods and
filters on `.summary` work on it. The package tests compare it column by
column with `clean_coordinates(value = "spatialvalid")`.

``` r

sv <- as_spatialvalid(oc)
head(sv[, c(".zer", ".equ", ".cap", ".dpl", ".summary")])
#>    .zer  .equ .cap  .dpl .summary
#> 1 FALSE FALSE TRUE  TRUE    FALSE
#> 2 FALSE FALSE TRUE  TRUE    FALSE
#> 3 FALSE FALSE TRUE FALSE    FALSE
#> 4 FALSE FALSE TRUE FALSE    FALSE
#> 5 FALSE FALSE TRUE FALSE    FALSE
#> 6 FALSE FALSE TRUE FALSE    FALSE
summary(sv)
#>     .val     .zer     .equ     .cap     .cen    .inst     .gbf     .dpl 
#>        0       30       40      436       29        0        0       18 
#> .summary 
#>      491
```

The grouped tests (`outlier`, the three fossil outlier tests and the two
dataset tests) compare a record with the other records of its species,
taxon or dataset, so a record’s flag depends on the rest of the input:
adding records of a species can change whether a record of it is an
outlier. The article on outliers and dataset tests shows them on worked
examples.

## References

Zizka A, Silvestro D, Andermann T, Azevedo J, Duarte Ritter C, Edler D,
Farooq H, Herdean A, Ariza M, Scharn R, Svanteson S, Wengström N, Zizka
V, Antonelli A (2019). CoordinateCleaner: standardized cleaning of
occurrence records from biological collection databases. *Methods in
Ecology and Evolution* 10:744-751.
[doi:10.1111/2041-210X.13152](https://doi.org/10.1111/2041-210X.13152)
