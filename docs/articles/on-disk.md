# Large tables on disk

A snapshot of GBIF (the Global Biodiversity Information Facility) holds
billions of occurrence records in a directory of Parquet files, a
column-oriented file format. That is far more than fits in memory.
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
accepts such a directory, a single file or a query in place of a data
frame. It reads the input in chunks through
[vectra](https://gillescolling.com/vectra/), the column-store package
OccurrenceCleaner uses for tables on disk, and writes the flags to an
output directory. This article ends with flags on disk, tallied by
group, and a selected subset joined back to its full records.
Installation is covered in [Get
started](https://gillescolling.com/OccurrenceCleaner/articles/OccurrenceCleaner.md).

1.  **Flag** a directory of files into an output directory with
    [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

2.  **Tally** what each test flags and each rule removes with
    [`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md).

3.  **Select** flagged records and **join** them to the full records
    with
    [`flagged_table()`](https://gillescolling.com/OccurrenceCleaner/reference/read_flagged.md).

4.  **Resume** an interrupted run by repeating the call.

## Example

### Example input

Three files stand in for the parts of a snapshot. They are `.vtr` files,
the on-disk table format of vectra; a directory of Parquet files, a
single Parquet, `.csv` or `.tsv` file, and a vectra query are read the
same way. Each file has 3,000 records with GBIF’s lower-case column
names, at random points in a box over western and central Europe. The
last record of part 3 is a copy of the first record of part 1 with its
own identifier, so the same species and coordinates appear in two files.

Code that writes the three files

``` r

library(OccurrenceCleaner)

set.seed(7)
make_part <- function(n, offset) {
  data.frame(
    gbifid = as.character(offset + seq_len(n)),
    kingdom = sample(c("Animalia", "Plantae", "Fungi"), n, TRUE),
    species = sample(sprintf("sp%02d", 1:30), n, TRUE),
    year = sample(1880:2024, n, TRUE),
    decimallongitude = round(runif(n, -10, 30), 3),
    decimallatitude = round(runif(n, 36, 60), 3))
}
p1 <- make_part(3000, 0)
p2 <- make_part(3000, 3000)
p3 <- make_part(3000, 6000)
p3[3000, -1] <- p1[1, -1]
src <- file.path(tempdir(), "snapshot")
dir.create(src, showWarnings = FALSE)
parts <- list(p1, p2, p3)
for (i in 1:3) {
  path <- file.path(src, sprintf("occurrence-%d.vtr", i))
  vectra::write_vtr(parts[[i]], path)
}
```

``` r

list.files(src)
#> [1] "occurrence-1.vtr" "occurrence-2.vtr" "occurrence-3.vtr"
head(p1, 3)
#>   gbifid kingdom species year decimallongitude decimallatitude
#> 1      1 Plantae    sp10 2009           -1.485          40.392
#> 2      2   Fungi    sp18 1928           -1.194          45.822
#> 3      3   Fungi    sp11 1949            3.827          47.919
```

### Flagging into an output directory

For on-disk input, `out` names the output directory and `keep` the
columns copied next to the flags for grouping later. The record
identifier (`gbifid` here, set through `occ_columns(id = ...)`) is kept
whenever it is present, so the flags can be joined back to the full
records. The run reports its progress as it goes; the messages are
folded away here.

The call and its progress messages

``` r

out <- file.path(tempdir(), "flags")
f <- flag_occurrences(src, out = out, keep = c("kingdom", "year"),
                      columns = occ_columns(id = "gbifid"))
#> tests: 12 run; not run, missing input: countryCode, issue, basisOfRecord, establishmentMeans, min_ma, max_ma, datasetKey, range polygons, genus (18 tests)
#> group tests: reading 3 file(s) (pass 1 of 2)
#> progress: group pass (counts), 0 of 9,000 rows | step ETA 0 s | run 0%, ETA ~1 s | elapsed 0 s
#> group tests: reading 3 file(s) (pass 2 of 2)
#> progress: group pass (counts), 9,000 of 9,000 rows | step ETA 0 s | run 0%, ETA ~10 s | elapsed 0 s
#> progress: group pass (counts) done [0 s]
#> progress: group pass (buckets), 0 of 9,000 rows | step ETA 0 s | run 0%, ETA ~10 s | elapsed 0 s
#> group tests: duplicate: 64 bucket(s)
#> progress: group pass (buckets), 9,000 of 9,000 rows | step ETA 0 s | run 1%, ETA ~10 s | elapsed 0 s
#> progress: group pass (buckets) done [0 s]
#> progress: duplicate buckets, 0 of 9,000 rows | step ETA 0 s | run 1%, ETA ~10 s | elapsed 0 s
#> group tests: outlier: 26 bucket(s)
#> progress: duplicate buckets, 9,000 of 9,000 rows | step ETA 0 s | run 2%, ETA ~9 s | elapsed 0 s
#> progress: duplicate buckets done [0 s]
#> progress: outlier buckets, 0 of 9,000 rows | step ETA 8 s | run 2%, ETA ~9 s | elapsed 0 s
#> progress: outlier buckets, 9,000 of 9,000 rows | step ETA 0 s | run 89%, ETA ~0 s | elapsed 0 s
#> progress: outlier buckets done [0 s]
#> progress: large species, 0 of 0 species | step ETA 0 s | run 89%, ETA ~0 s | elapsed 0 s
#> progress: large species, 0 of 0 species | step ETA 0 s | run 89%, ETA ~0 s | elapsed 0 s
#> progress: large species done [0 s]
#> group tests: done [0.3 s]
#> progress: record pass, 0 of 9,000 rows | step ETA 0 s | run 89%, ETA ~0 s | elapsed 0 s
#> occurrence-1: 3000 rows in 1 part(s) [0.1 s]
#> occurrence-2: 3000 rows in 1 part(s) [0 s]
#> occurrence-3: 3000 rows in 1 part(s) [0 s]
#> progress: record pass, 9,000 of 9,000 rows | step ETA 0 s | run 100%, ETA ~0 s | elapsed 0 s
#> progress: record pass done [0 s]
```

``` r

f
#> <occ_flagged> 9,000 records in 3 part(s)
#>   out:       C:\Users\Gilles Colling\AppData\Local\Temp\RtmpOEyyos\flags
#>   tests:     invalid, zero, equal, capital, centroid, institution, gbif_headquarters, sea, urban, duplicate, outlier, aohi
#>   not run:   missing input: countryCode, issue, basisOfRecord, establishmentMeans, min_ma, max_ma, datasetKey, range polygons, genus (18 tests); test_plan() lists them
#>   layout:    v4
#>   reference: OccurrenceCleaner 0.2.0, land 110
#>   keep:      kingdom, year
```

Without `tests`, the run covers every test the columns allow. The
printed object lists them, and
[`test_plan()`](https://gillescolling.com/OccurrenceCleaner/reference/test_plan.md)
gives the reason for each test that did not run:

``` r

p <- test_plan(f)
p[!p$run, c("test", "reason")]
#>                        test                            reason
#> 10         country_mismatch           no column `countryCode`
#> 12         issue_coordinate                 no column `issue`
#> 13              issue_taxon                 no column `issue`
#> 14               issue_date                 no column `issue`
#> 15            issue_rounded                 no column `issue`
#> 16             basis_fossil         no column `basisOfRecord`
#> 17             basis_living         no column `basisOfRecord`
#> 18 establishment_introduced    no column `establishmentMeans`
#> 19    establishment_managed    no column `establishmentMeans`
#> 20                age_equal      no column `min_ma`, `max_ma`
#> 22              age_outlier      no column `min_ma`, `max_ma`
#> 23   spatiotemporal_outlier      no column `min_ma`, `max_ma`
#> 24        age_range_outlier      no column `min_ma`, `max_ma`
#> 25             dataset_ddmm            no column `datasetKey`
#> 26          dataset_rounded            no column `datasetKey`
#> 27                    range no range polygons in `gazetteers`
#> 29            sea_nonmarine                 no column `genus`
#> 30              land_marine                 no column `genus`
```

`duplicate` and `outlier` are grouped tests: they compare a record with
other records of its key or species anywhere in the input. They run in a
group stage that reads the input before the record pass, which the
progress messages report.

### Tallying from disk

[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
takes the `occ_flagged` object or the output directory and reads the
flag files in chunks. It counts, per group, the records each test flags
and each rule removes, without loading the records. A grouping column
must have been kept when flagging.

The rule `coordinatecleaner` holds the same tests as in [Choosing a
cleaning
rule](https://gillescolling.com/OccurrenceCleaner/articles/rules.md):
the default tests of CoordinateCleaner’s
[`clean_coordinates()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_coordinates.html)
that need only coordinates and a species, apart from its outlier test.

``` r

coordinatecleaner <- c("invalid", "zero", "equal", "capital", "centroid",
                       "institution", "gbif_headquarters", "sea")
t <- tally_flags(out, by = "kingdom", bins = list(year = c(1950, 2000)),
                 rules = list(coordinatecleaner = coordinatecleaner))
sel <- t[, c("kingdom", "year_bin", "n", "flagged_sea", "flagged_capital",
             "removed_coordinatecleaner")]
```

| kingdom  | year_bin  |    n | flagged_sea | flagged_capital | removed_coordinatecleaner |
|:---------|:----------|-----:|------------:|----------------:|--------------------------:|
| Animalia | \<1950    | 1427 |         577 |               3 |                       581 |
| Animalia | 1950-2000 | 1075 |         428 |               5 |                       434 |
| Animalia | \>=2000   |  513 |         195 |               2 |                       197 |
| Fungi    | \<1950    | 1424 |         553 |               4 |                       557 |
| Fungi    | 1950-2000 | 1030 |         414 |               4 |                       418 |
| Fungi    | \>=2000   |  493 |         200 |               1 |                       202 |
| Plantae  | \<1950    | 1492 |         588 |               1 |                       590 |
| Plantae  | 1950-2000 | 1003 |         397 |               2 |                       399 |
| Plantae  | \>=2000   |  543 |         212 |               0 |                       212 |

The sea test flags 40 % of all records, and it accounts for most of the
3,590 records the rule removes: the points were drawn uniformly over a
box that includes the Mediterranean, the Bay of Biscay and the North
Sea. A grouping column that was not kept is an error that names it:

``` r

tally_flags(out, by = "species")
#> Error in `tally_flags()`:
#> ! grouping column(s) not kept in the flag output: species
```

### Selecting and joining flagged records

[`flagged_table()`](https://gillescolling.com/OccurrenceCleaner/reference/read_flagged.md)
opens the flag files as one vectra table. vectra verbs run on it lazily
and read only what the query needs;
[`vectra::collect()`](https://gillescolling.com/vectra/reference/collect.html)
brings the result into memory. A vectra query runs once, so each use
starts from a fresh
[`flagged_table()`](https://gillescolling.com/OccurrenceCleaner/reference/read_flagged.md).

A filter on a kept column bounds what is collected. For a snapshot,
choose one that keeps the result small, such as one class or one region.
`flags != 0L` keeps the records flagged by any test that ran, which here
includes `duplicate` and `outlier` as well as the tests of the rule
above:

``` r

fungi <- vectra::filter(flagged_table(out), kingdom == "Fungi", flags != 0L)
flagged <- vectra::collect(fungi)
nrow(flagged)
#> [1] 1251
```

vectra filters cannot test a single bit of the flag word, so a rule is
applied after collecting, with
[`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md):

``` r

table(removed = has_flag(flagged$flags, coordinatecleaner))
#> removed
#> FALSE  TRUE 
#>    74  1177
```

To attach the flags to the full records, join on the identifier. vectra
runs the join on disk, so only the joined rows of the selection are
collected:

``` r

files <- list.files(src, full.names = TRUE)
records <- do.call(vectra::bind_rows, lapply(files, vectra::tbl))
fungi <- vectra::filter(flagged_table(out), kingdom == "Fungi", flags != 0L)
fungi <- vectra::select(fungi, gbifid, flags)
merged <- vectra::collect(vectra::inner_join(fungi, records, by = "gbifid"))
head(merged[, c("gbifid", "species", "decimallongitude", "flags")])
#>   gbifid species decimallongitude flags
#> 1      4    sp10           27.043   128
#> 2      9    sp02           13.312   128
#> 3     22    sp27           19.655   128
#> 4     25    sp06           28.251   128
#> 5     28    sp15            8.826   128
#> 6     33    sp12           20.121   128
```

### Duplicates across files

The duplicate test compares each record with every record before it in
the input order: the files in sorted order and the rows within each
file. The copy in the last row of part 3 is flagged and the original in
part 1 is not, as they would be in one data frame holding all three
parts in that order:

``` r

d <- vectra::collect(flagged_table(out))
pair <- d[d$gbifid %in% c(p1$gbifid[1], p3$gbifid[3000]), ]
data.frame(gbifid = pair$gbifid, duplicate = has_flag(pair$flags, "duplicate"))
#>   gbifid duplicate
#> 1      1     FALSE
#> 2   9000      TRUE
```

### Selecting records before flagging

A vectra query can be flagged without writing the subset out first;
vectra applies the filter while it scans the file. A query runs once, so
it is flagged as one unit, and the grouped tests, which read the input
more than once, do not run on it.
[`test_plan()`](https://gillescolling.com/OccurrenceCleaner/reference/test_plan.md)
on the result lists them with that reason:

``` r

plants <- vectra::filter(vectra::tbl(file.path(src, "occurrence-1.vtr")),
                         kingdom == "Plantae")
h <- flag_occurrences(plants, out = file.path(tempdir(), "flags-plants"),
                      keep = "kingdom", columns = occ_columns(id = "gbifid"),
                      verbose = FALSE)
h$n
#> [1] 1008
p <- test_plan(h)
p[p$test %in% c("duplicate", "outlier"), c("test", "run", "reason")]
#>         test   run
#> 11 duplicate FALSE
#> 21   outlier FALSE
#>                                                                  reason
#> 11 reads the input more than once; pass a path instead of a vectra_node
#> 21 reads the input more than once; pass a path instead of a vectra_node
```

Naming a grouped test for a query is an error; flag the file or
directory path instead, and select the records afterwards.

### Resuming an interrupted run

Each input file is one unit of work, and a finished unit leaves a
`.done` marker in `out`. Repeating the call skips every finished unit,
so a run that was stopped is continued by running the same call again.
The messages of the rerun report every unit as skipped:

Messages of the rerun

``` r

f <- flag_occurrences(src, out = out, keep = c("kingdom", "year"),
                      columns = occ_columns(id = "gbifid"))
#> tests: 12 run; not run, missing input: countryCode, issue, basisOfRecord, establishmentMeans, min_ma, max_ma, datasetKey, range polygons, genus (18 tests)
#> progress: record pass, 0 of 9,000 rows | step ETA 0 s | run 0%, ETA ~0 s | elapsed 0 s
#> occurrence-1: done (3000 rows), skipped
#> occurrence-2: done (3000 rows), skipped
#> occurrence-3: done (3000 rows), skipped
#> progress: record pass, 9,000 of 9,000 rows | step ETA 0 s | run 100%, ETA ~0 s | elapsed 0 s
#> progress: record pass done [0 s]
```

An interruption during a unit leaves that unit without its marker.
Removing a marker by hand has the same effect, and only that unit is
flagged again:

Messages after removing one marker

``` r

file.remove(file.path(out, "occurrence-2.done"))
#> [1] TRUE
f <- flag_occurrences(src, out = out, keep = c("kingdom", "year"),
                      columns = occ_columns(id = "gbifid"))
#> tests: 12 run; not run, missing input: countryCode, issue, basisOfRecord, establishmentMeans, min_ma, max_ma, datasetKey, range polygons, genus (18 tests)
#> group tests: reading 3 file(s) (pass 1 of 2)
#> progress: group pass (counts), 0 of 9,000 rows | step ETA 0 s | run 0%, ETA ~1 s | elapsed 0 s
#> group tests: reading 3 file(s) (pass 2 of 2)
#> progress: group pass (counts), 9,000 of 9,000 rows | step ETA 0 s | run 0%, ETA ~0 s | elapsed 0 s
#> progress: group pass (counts) done [0 s]
#> progress: group pass (buckets), 0 of 9,000 rows | step ETA 0 s | run 0%, ETA ~0 s | elapsed 0 s
#> group tests: duplicate: 64 bucket(s)
#> progress: group pass (buckets), 9,000 of 9,000 rows | step ETA 0 s | run 1%, ETA ~10 s | elapsed 0 s
#> progress: group pass (buckets) done [0 s]
#> progress: duplicate buckets, 0 of 9,000 rows | step ETA 0 s | run 1%, ETA ~10 s | elapsed 0 s
#> group tests: outlier: 26 bucket(s)
#> progress: duplicate buckets, 9,000 of 9,000 rows | step ETA 0 s | run 2%, ETA ~9 s | elapsed 0 s
#> progress: duplicate buckets done [0 s]
#> progress: outlier buckets, 0 of 9,000 rows | step ETA 8 s | run 2%, ETA ~9 s | elapsed 0 s
#> progress: outlier buckets, 9,000 of 9,000 rows | step ETA 0 s | run 89%, ETA ~0 s | elapsed 0 s
#> progress: outlier buckets done [0 s]
#> progress: large species, 0 of 0 species | step ETA 0 s | run 89%, ETA ~0 s | elapsed 0 s
#> progress: large species, 0 of 0 species | step ETA 0 s | run 89%, ETA ~0 s | elapsed 0 s
#> progress: large species done [0 s]
#> group tests: done [0.3 s]
#> progress: record pass, 0 of 9,000 rows | step ETA 0 s | run 89%, ETA ~0 s | elapsed 0 s
#> occurrence-1: done (3000 rows), skipped
#> occurrence-3: done (3000 rows), skipped
#> occurrence-2: 3000 rows in 1 part(s) [0 s]
#> progress: record pass, 9,000 of 9,000 rows | step ETA 0 s | run 100%, ETA ~0 s | elapsed 0 s
#> progress: record pass done [0 s]
```

A unit that is redone has its old part files deleted first. The group
stage keeps its state in `out/.group` until the run finishes. It saves a
checkpoint after a file or a bucket of records once five minutes have
passed, and at the end of each of its passes, so an interruption there
repeats at most the work since the last checkpoint, and an interruption
in the record pass reuses its result. Here the run had finished and its
group files were deleted, so the redone unit first repeats the group
stage. `resume = FALSE` deletes the earlier output and starts over.

Before writing any output, a run records its configuration: the tests,
columns, `keep`, reference, buffers, test settings, duplicate options,
package version, and each input file with its size and modification
time. A later call into the same directory must match it, or it stops
and names what differs:

``` r

flag_occurrences(src, out = out, keep = "kingdom",
                 columns = occ_columns(id = "gbifid"))
#> Error:
#> ! `out` holds flags from a different configuration (keep); use a new directory or resume = FALSE
```

Sizes and modification times detect a replaced, grown or touched file;
they are not a hash of the file contents.

### The output directory

The flags are written as `.vtr` part files. Within a unit, records are
read chunk by chunk, flagged and buffered, and a part file is written
once at least `part_rows` rows (two million by default) have
accumulated, and at the end of the unit. `flags_config.rds` holds the
configuration record and `flags_meta.rds` the summary of the finished
run:

``` r

list.files(out)
#> [1] "flags_config.rds"           "flags_meta.rds"            
#> [3] "occurrence-1.done"          "occurrence-2.done"         
#> [5] "occurrence-3.done"          "part-occurrence-1-0001.vtr"
#> [7] "part-occurrence-2-0001.vtr" "part-occurrence-3-0001.vtr"
#> [9] "progress.txt"
m <- read_flagged(out)
str(m[c("tests", "layout_version", "keep", "n", "units")])
#> List of 5
#>  $ tests         : chr [1:12] "invalid" "zero" "equal" "capital" ...
#>  $ layout_version: int 4
#>  $ keep          : chr [1:2] "kingdom" "year"
#>  $ n             : num 9000
#>  $ units         : chr [1:3] "occurrence-1" "occurrence-2" "occurrence-3"
```

### Progress and threads

A run writes its progress to `progress.txt` in the output directory, one
line overwritten on every report: the step, the items done and their
total, the seconds elapsed, the estimated seconds left in the step and
in the run, and the share of the run done. A detached run whose console
output is buffered can be followed by reading this file. The estimate
for the step in progress comes from its own rate; the steps after it are
estimated from per-record costs measured on a part of the GBIF snapshot,
scaled to the speed of the run so far, so it is rough until the slower
steps have started. With `verbose = TRUE` the same line is printed every
minute.

``` r

readLines(file.path(out, "progress.txt"))
#> [1] "record 9000 9000 0.3 0.0 0.0 1.0000"
```

`n_threads` spreads the exact outlier test and the proximity and
point-in-polygon queries over several threads, and the flags are the
same for any number of threads. [Running on several
threads](https://gillescolling.com/OccurrenceCleaner/articles/parallel.md)
lists the tests that use them and the measured speedup.

### Memory and disk

The record pass holds one input chunk, up to `part_rows` buffered output
rows (the identifier, the `keep` columns and a four-byte flag word per
record) and the group-test results for the current block of about one
million rows. The group stage holds up to two million bucketed rows
before writing them, the record counts per species, the histograms per
dataset, the duplicate keys of one bucket (about four million records
per bucket on a large input) and the records of one species for the
outlier test. On disk it writes up to 24 bytes per record for
`duplicate`, plus the coordinates of the records the outlier test
compares; these files are deleted when the run finishes. The Streamed
runs section of
[`?flag_occurrences`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
lists the details.

## A GBIF snapshot

GBIF’s Parquet snapshot (the `occurrence.parquet` directory) names its
columns in lower case. They follow Darwin Core, the standard set of
field names for biodiversity records, and the case-insensitive defaults
of
[`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md)
find them.
[`test_plan()`](https://gillescolling.com/OccurrenceCleaner/reference/test_plan.md)
on the directory lists the tests the columns allow before anything runs,
and `keep` names the columns a loss analysis groups by:

``` r

snapshot <- "gbif_snapshot/occurrence.parquet"
p <- test_plan(snapshot)
p[!p$run, c("test", "reason")]

f <- flag_occurrences(
  snapshot,
  out = "flags",
  keep = c("kingdom", "phylum", "class", "year",
           "coordinateuncertaintyinmeters"),
  land_scale = 50,
  n_threads = 0)

bins <- list(year = c(1900, 1950, 1970, 1990, 2010),
             coordinateuncertaintyinmeters = c(10, 100, 1000, 10000))
rules <- list(coordinatecleaner = coordinatecleaner,
              with_country = c(coordinatecleaner, "country_mismatch"))
tally_flags(f, by = c("kingdom", "class"), bins = bins, rules = rules)
```

Read through vectra, the snapshot’s `issue` column arrives as a string
of issue names separated by `;`, which the issue tests read directly.
With the outlier and dataset tests, which read `datasetkey`, the group
stage reads every file twice before the record pass; with `duplicate`
alone it reads them once. An interruption during the group stage repeats
the work since its last checkpoint, and one during the record pass
repeats the file in progress.
