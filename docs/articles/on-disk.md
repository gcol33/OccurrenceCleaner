# Large tables on disk

A GBIF snapshot holds billions of records in a directory of Parquet
files, far more than fits in memory.
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
takes such a directory, a single file or a vectra query in place of a
data frame, reads it in chunks through
[vectra](https://cran.r-project.org/package=vectra), and writes the
flags to disk next to the columns kept for grouping. This article walks
through the output layout, resuming an interrupted run, tallying from
disk, and the one test whose result depends on how the input is split.

## Installation

``` r

# install.packages("pak")
pak::pak("gcol33/OccurrenceCleaner")
```

Needs a C++ compiler (Rtools on Windows).

``` r

library(OccurrenceCleaner)
```

## Example input

Three `.vtr` files stand in for the parts of a snapshot. Each holds
3,000 records with GBIF’s lower-case column names:

``` r

set.seed(7)
make_part <- function(n, offset) {
  data.frame(gbifid = as.character(offset + seq_len(n)),
             kingdom = sample(c("Animalia", "Plantae", "Fungi"), n, TRUE),
             species = sample(sprintf("sp%02d", 1:30), n, TRUE),
             year = sample(1880:2024, n, TRUE),
             decimallongitude = round(runif(n, -10, 30), 3),
             decimallatitude = round(runif(n, 36, 60), 3))
}
src <- file.path(tempdir(), "snapshot")
dir.create(src, showWarnings = FALSE)
for (i in 1:3) vectra::write_vtr(make_part(3000, (i - 1) * 3000), file.path(src, sprintf("occurrence-%d.vtr", i)))
list.files(src)
#> [1] "occurrence-1.vtr" "occurrence-2.vtr" "occurrence-3.vtr"
```

A directory of Parquet parts, a single Parquet, `.vtr`, `.csv` or `.tsv`
file, and any `vectra_node` are read the same way.

## Flagging into an output directory

For on-disk input, `out` names the output directory and `keep` the
columns copied next to the flags. The record identifier (`gbifid` here,
set through `occ_columns(id = ...)`) is kept whenever it is present, so
the flags can be joined back to the full records later:

``` r

out <- file.path(tempdir(), "flags")
f <- flag_occurrences(src, out = out, keep = c("kingdom", "year"),
                      columns = occ_columns(id = "gbifid"))
#> occurrence-1: 3000 rows in 1 part(s) [0.1 s]
#> occurrence-2: 3000 rows in 1 part(s) [0 s]
#> occurrence-3: 3000 rows in 1 part(s) [0 s]
f$n
#> [1] 9000
f$parts
#> [1] "part-occurrence-1-0001.vtr" "part-occurrence-2-0001.vtr"
#> [3] "part-occurrence-3-0001.vtr"
```

Each input file is one unit of work. Within a unit, records are read
chunk by chunk, flagged, and buffered; a `.vtr` part file is written
once at least `part_rows` rows (2 million by default) have accumulated,
and at the end of the unit. A `.done` marker per unit records that it
finished, and `flags_meta.rds` records the tests, the layout version,
the reference, the columns and the package version:

``` r

list.files(out)
#> [1] "flags_meta.rds"             "occurrence-1.done"         
#> [3] "occurrence-2.done"          "occurrence-3.done"         
#> [5] "part-occurrence-1-0001.vtr" "part-occurrence-2-0001.vtr"
#> [7] "part-occurrence-3-0001.vtr"
m <- read_flagged(out)
str(m[c("tests", "layout_version", "reference", "keep", "n", "units", "package_version")])
#> List of 7
#>  $ tests          : chr [1:9] "invalid" "zero" "equal" "capital" ...
#>  $ layout_version : int 4
#>  $ reference      : chr "natural_earth (land 110; land_110 4.1.0, land_50 4.1.0, land_10 5.1.1, countries_50 5.1.1, urban_50 4.1.0, plac"| __truncated__
#>  $ keep           : chr [1:2] "kingdom" "year"
#>  $ n              : num 9000
#>  $ units          : chr [1:3] "occurrence-1" "occurrence-2" "occurrence-3"
#>  $ package_version: chr "0.1.0"
```

Memory use is set by the chunk size of vectra and by `part_rows`, not by
the size of the input: one input chunk and the buffered output rows (the
identifier, the `keep` columns and a four-byte flag word per record) are
held at a time.

## Resuming

A rerun of the same call skips every unit whose `.done` marker exists.
Removing the marker of one unit, as an interruption during that unit
would leave it, means only that unit is flagged again:

``` r

file.remove(file.path(out, "occurrence-2.done"))
#> [1] TRUE
f <- flag_occurrences(src, out = out, keep = c("kingdom", "year"),
                      columns = occ_columns(id = "gbifid"))
#> occurrence-1: done (3000 rows), skipped
#> occurrence-2: 3000 rows in 1 part(s) [0 s]
#> occurrence-3: done (3000 rows), skipped
```

A unit that is redone first has its old part files deleted, so a
half-written unit never leaves stale parts behind. `resume = FALSE`
redoes every unit.

An output directory belongs to one configuration. A rerun into it with
different tests, a different reference or land scale, or a different
flag layout stops instead of mixing flags:

``` r

flag_occurrences(src, out = out, tests = c("invalid", "zero"), keep = c("kingdom", "year"))
#> Error in `flag_stream()`:
#> ! `out` holds flags produced with different tests, layout or reference; use a new directory
```

## Tallying from disk

[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
accepts the `occ_flagged` object or the output directory and streams the
parts, so the counts per group of records each test flags and each rule
removes are built over the whole snapshot without loading it. Grouping
columns must have been kept when flagging:

``` r

cc <- c("zero", "equal", "capital", "centroid", "institution", "gbif_headquarters", "sea")
t <- tally_flags(out, by = "kingdom", bins = list(year = c(1950, 2000)), rules = list(cc = cc))
knitr::kable(t[, c("kingdom", "year_bin", "n", "flagged_sea", "flagged_capital", "removed_cc", "kept_cc")])
```

| kingdom  | year_bin  |    n | flagged_sea | flagged_capital | removed_cc | kept_cc |
|:---------|:----------|-----:|------------:|----------------:|-----------:|--------:|
| Animalia | \<1950    | 1427 |         577 |               3 |        581 |     846 |
| Animalia | 1950-2000 | 1075 |         428 |               5 |        434 |     641 |
| Animalia | \>=2000   |  513 |         195 |               2 |        197 |     316 |
| Fungi    | \<1950    | 1425 |         553 |               4 |        557 |     868 |
| Fungi    | 1950-2000 | 1030 |         414 |               4 |        419 |     611 |
| Fungi    | \>=2000   |  493 |         200 |               1 |        202 |     291 |
| Plantae  | \<1950    | 1492 |         588 |               1 |        590 |     902 |
| Plantae  | 1950-2000 | 1003 |         397 |               2 |        399 |     604 |
| Plantae  | \>=2000   |  542 |         212 |               0 |        212 |     330 |

Most of these records are flagged by `sea`, because the simulated points
were drawn uniformly over a box that includes the Mediterranean, the Bay
of Biscay and the North Sea. A grouping column that was not kept is an
error that names it:

``` r

tally_flags(out, by = "species")
#> Error in `tally_flags()`:
#> ! grouping column(s) not kept in the flag output: species
```

## Reading the flags

[`flagged_table()`](https://gillescolling.com/OccurrenceCleaner/reference/read_flagged.md)
opens all parts as one vectra table. vectra verbs run on it lazily, and
[`vectra::collect()`](https://gillescolling.com/vectra/reference/collect.html)
brings the result into memory. A vectra query runs once, so each use
starts from a fresh
[`flagged_table()`](https://gillescolling.com/OccurrenceCleaner/reference/read_flagged.md):

``` r

ft <- flagged_table(out)
flagged <- vectra::collect(vectra::filter(ft, flags != 0L))
nrow(flagged)
#> [1] 3591
head(flagged)
#>   gbifid kingdom year flags
#> 1      4   Fungi 1920   128
#> 2      7 Plantae 1928   128
#> 3      9   Fungi 1940   128
#> 4     10 Plantae 1886   128
#> 5     13 Plantae 1884   128
#> 6     18 Plantae 1994   128
```

The flag word is an ordinary integer column, so
[`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md)
applies to it after collecting:

``` r

table(kingdom = flagged$kingdom, capital = has_flag(flagged$flags, "capital"))
#>           capital
#> kingdom    FALSE TRUE
#>   Animalia  1202   10
#>   Fungi     1169    9
#>   Plantae   1198    3
```

To attach the flags to the full records, join on the identifier. For a
snapshot, the join is best done by vectra on disk; for a small subset,
in memory:

``` r

recs <- vectra::collect(vectra::tbl(file.path(src, "occurrence-1.vtr")))
fl <- vectra::collect(flagged_table(out))
merged <- merge(recs, fl[, c("gbifid", "flags")], by = "gbifid")
nrow(merged)
#> [1] 3000
```

## Duplicates and the unit of work

`duplicate` compares a record with the earlier records of the same unit.
On a data frame the unit is the whole table; on a directory it is one
input file, so two identical records in different files are not flagged.
A copy of a record from part 1 placed in part 3 shows it:

``` r

p1 <- vectra::collect(vectra::tbl(file.path(src, "occurrence-1.vtr")))
p3 <- vectra::collect(vectra::tbl(file.path(src, "occurrence-3.vtr")))
copy <- p1[1, ]; copy$gbifid <- "copy-1"
vectra::write_vtr(rbind(p3, copy), file.path(src, "occurrence-3.vtr"))
g <- flag_occurrences(src, out = file.path(tempdir(), "flags-dupl"), tests = "duplicate",
                      columns = occ_columns(id = "gbifid"), verbose = FALSE)
d <- vectra::collect(flagged_table(g))
has_flag(d$flags[d$gbifid == "copy-1"], "duplicate")
#> [1] FALSE
```

A table that is split by species, so that all records of one species are
in the same file, makes the per-file test equal to the whole-table test,
since a duplicate must share the species. A GBIF snapshot is not split
that way. For whole-table duplicates on a snapshot, the duplicate test
is run on the records of the taxa under study after collecting them,
where it sees all of them at once.

## Selecting before flagging

A `vectra_node` is flagged as one unit, which makes it the way to flag a
subset without writing it out first. vectra pushes the filter down into
the scan:

``` r

node <- vectra::filter(vectra::tbl(file.path(src, "occurrence-1.vtr")), kingdom == "Plantae")
h <- flag_occurrences(node, out = file.path(tempdir(), "flags-plants"), keep = "kingdom",
                      columns = occ_columns(id = "gbifid"), verbose = FALSE)
h$n
#> [1] 1008
```

## A GBIF snapshot

GBIF’s Parquet snapshot (the `occurrence.parquet` directory) holds the
Darwin Core terms in lower case, which the case-insensitive defaults of
[`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md)
find. A pass over every test the snapshot supports, which is all but the
fossil tests and the range test, keeping the columns a loss analysis
groups by. The grouped tests (`outlier` and the two dataset tests, which
read `datasetkey`) add a pass over all files before the record pass:

``` r

f <- flag_occurrences(
  "gbif_snapshot/occurrence.parquet",
  tests = setdiff(flag_tests()$test, c("age_equal", "age_outlier", "spatiotemporal_outlier",
                                       "age_range_outlier", "range")),
  out = "flags",
  keep = c("kingdom", "phylum", "class", "year", "coordinateuncertaintyinmeters"),
  land_scale = 50)

tally_flags(f, by = c("kingdom", "class"),
            bins = list(year = c(1900, 1950, 1970, 1990, 2010),
                        coordinateuncertaintyinmeters = c(10, 100, 1000, 10000)),
            rules = list(cc = cc, cc_country = c(cc, "country_mismatch")))
```

Read through vectra, the snapshot’s `issue` column arrives as a string
of issue names separated by `;`, which the issue tests read directly.
The in-memory speed of the nine default tests was 17.8 s for ten million
records on an AMD Ryzen 7 5700G (`bench/benchmark.R` in the source
repository); a streamed run adds the Parquet reading and the writing of
the parts, which were not part of that benchmark. Since each Parquet
file is one resumable unit, a run over a snapshot can be stopped and
restarted at any point and loses at most the file in progress.
