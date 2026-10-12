# Get started

This article flags a small set of species records, keeps the records
that pass a chosen cleaning rule, and counts what two different rules
exclude. It assumes basic R and data frames. Later sections change the
distance a test uses, read data with other column names, fix common
errors and flag a table on disk. The coordinate tests follow
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)
(Zizka et al. [2019](https://doi.org/10.1111/2041-210X.13152)), with the
same definitions and default distances.

1.  **Flag** the records with
    [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

2.  **Inspect** the flags with
    [`print()`](https://rdrr.io/r/base/print.html) and
    [`summary()`](https://rdrr.io/r/base/summary.html).

3.  **Keep** the records that pass a rule, using
    [`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md).

4.  **Compare** rules with
    [`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md).

## Installation

``` r

# install.packages("pak")
pak::pak("gcol33/OccurrenceCleaner")
```

Needs a C++ compiler;
[Installation](https://gillescolling.com/OccurrenceCleaner/#installation)
shows how to set one up.

``` r

library(OccurrenceCleaner)
```

## Flagging a data frame

The example has seven records of four tree species, each with an
identifier. Coordinates are longitude and latitude in decimal degrees,
in columns with their Darwin Core names.

``` r

x <- data.frame(
  id = 1:7,
  species = c("Quercus robur", "Quercus robur", "Fagus sylvatica",
              "Fagus sylvatica", "Pinus nigra", "Pinus nigra",
              "Picea abies"),
  decimalLongitude = c(14.05, 0, 16.37, 16.37, 200, -30, 13.06),
  decimalLatitude = c(47.85, 0, 48.21, 48.21, 45, 40, 47.08)
)
```

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
runs the tests named in `tests`. The first three need no reference data:

- `invalid`: a coordinate is missing, not numeric, or outside the range
  of longitude and latitude.

- `zero`: longitude or latitude is exactly zero, or the point lies
  within 0.5 degrees of (0, 0).

- `duplicate`: the record has the same species and coordinates as an
  earlier record.

``` r

f <- flag_occurrences(x, tests = c("invalid", "zero", "duplicate"))
f
#> <occ_flags> 7 records, 3 tests, reference OccurrenceCleaner 0.2.0, land 110
#>   id         species decimalLongitude decimalLatitude flags flagged_by
#> 1  1   Quercus robur            14.05           47.85     0           
#> 2  2   Quercus robur             0.00            0.00     2       zero
#> 3  3 Fagus sylvatica            16.37           48.21     0           
#> 4  4 Fagus sylvatica            16.37           48.21  1024  duplicate
#> 5  5     Pinus nigra           200.00           45.00     1    invalid
#> 6  6     Pinus nigra           -30.00           40.00     0           
#> 7  7     Picea abies            13.06           47.08     0
```

The result is `x` with the same rows in the same order and its columns
unchanged, plus the flag columns described below. Printing it adds a
`flagged_by` column that names the tests flagging each record. Record 2
has zero coordinates, record 4 repeats record 3, and record 5 has a
longitude of 200 degrees.

A record without a flag has passed only the tests that were run. Record
3 lies in Vienna but carries no flag, because no test against capitals
has run yet.

Each test also has a logical column, `flag_<test>`, which is `TRUE`
where the test flagged the record. The `flags` column holds all tests of
a record in one integer; [The tests in
detail](https://gillescolling.com/OccurrenceCleaner/articles/tests.md)
explains the encoding.

``` r

f$flag_duplicate
#> [1] FALSE FALSE FALSE  TRUE FALSE FALSE FALSE
```

## Keeping the records that pass

A cleaning rule is the set of tests whose flags exclude a record.
[`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md)
is `TRUE` for every record flagged by at least one test of the rule, so
the retained records are the others:

``` r

rule <- c("invalid", "zero", "duplicate")
cleaned <- f[!has_flag(f, rule), ]
cleaned[, c("id", "species", "decimalLongitude", "decimalLatitude")]
#>   id         species decimalLongitude decimalLatitude
#> 1  1   Quercus robur            14.05           47.85
#> 3  3 Fagus sylvatica            16.37           48.21
#> 6  6     Pinus nigra           -30.00           40.00
#> 7  7     Picea abies            13.06           47.08
```

Record 3 is kept and record 4 is excluded: the `duplicate` test flags
only the repeats, so one copy of each record remains.

## Adding the tests against reference data

Without `tests`,
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
runs the default tests listed by
[`default_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/default_tests.md).
They add checks against reference points and polygons: country capitals,
country centroids, biodiversity institutions, the GBIF headquarters, and
the land.

``` r

f <- flag_occurrences(x)
f
#> <occ_flags> 7 records, 9 tests, reference OccurrenceCleaner 0.2.0, land 110
#>   id         species decimalLongitude decimalLatitude flags        flagged_by
#> 1  1   Quercus robur            14.05           47.85     0                  
#> 2  2   Quercus robur             0.00            0.00   134    zero,equal,sea
#> 3  3 Fagus sylvatica            16.37           48.21     8           capital
#> 4  4 Fagus sylvatica            16.37           48.21  1032 capital,duplicate
#> 5  5     Pinus nigra           200.00           45.00     1           invalid
#> 6  6     Pinus nigra           -30.00           40.00   128               sea
#> 7  7     Picea abies            13.06           47.08     0
```

Records 3 and 4 lie in Vienna, within 10 km of a capital. Record 6 is in
the Atlantic. Record 2, at (0, 0), is also at sea and has equal
longitude and latitude. Records 1 and 7 pass every test.

The `sea` test compares each record with land polygons from Natural
Earth, at the 1:110 million scale by default. Near coasts and on small
islands a finer scale (`land_scale = 50` or `10`) can change the flag;
[Reference
data](https://gillescolling.com/OccurrenceCleaner/articles/reference-data.md)
maps the difference.

A flagged record may still be valid: a beech can grow within 10 km of a
capital, so users decide which tests suit their analysis.
[`summary()`](https://rdrr.io/r/base/summary.html) counts the records
each test flags, and in the `only` column the records that test alone
flags:

``` r

summary(f)
#> <occ_summary> 7 records
#>   rule all: removes 5 (71.43 %)
#>  rule              test n flagged   pct only pct_only
#>   all           invalid 7       1 14.29    1    14.29
#>   all              zero 7       1 14.29    0     0.00
#>   all             equal 7       1 14.29    0     0.00
#>   all           capital 7       2 28.57    1    14.29
#>   all          centroid 7       0  0.00    0     0.00
#>   all       institution 7       0  0.00    0     0.00
#>   all gbif_headquarters 7       0  0.00    0     0.00
#>   all               sea 7       2 28.57    1    14.29
#>   all         duplicate 7       1 14.29    0     0.00
#>   all             (any) 7       5 71.43
```

A rule excludes each record once, however many of its tests flag it.
Record 2 is flagged by three tests and record 4 by two, so the per-test
counts add up to 8 while the `(any)` row excludes 5 records.

## Comparing cleaning rules

Several rules can be compared on the same flags without running the
tests again. Here the strict rule adds the `capital` and `sea` tests to
the mild one.
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
counts, per species, the records each rule removes:

``` r

strict <- c("invalid", "zero", "capital", "sea", "duplicate")
mild <- c("invalid", "zero", "duplicate")
t <- tally_flags(f, by = "species",
                 rules = list(strict = strict, mild = mild))
```

``` r

t[, c("species", "n", "flagged_capital", "flagged_sea",
      "flagged_duplicate", "removed_strict", "removed_mild")]
```

| species | n | flagged_capital | flagged_sea | flagged_duplicate | removed_strict | removed_mild |
|:---|---:|---:|---:|---:|---:|---:|
| Fagus sylvatica | 2 | 2 | 0 | 1 | 2 | 1 |
| Picea abies | 1 | 0 | 0 | 0 | 0 | 0 |
| Pinus nigra | 2 | 0 | 1 | 0 | 2 | 1 |
| Quercus robur | 2 | 0 | 1 | 0 | 1 | 1 |

Under the strict rule both beech records go; under the mild rule one
stays.
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
also cuts numeric columns such as the record year into bins, which
[Choosing a cleaning
rule](https://gillescolling.com/OccurrenceCleaner/articles/rules.md)
shows.

## Changing a test’s distance

The distances are part of the tests, so changing one means flagging
again. The `capital` test flags records within 10 km of a capital by
default. With 200 m, the Vienna records pass it:

``` r

f500 <- flag_occurrences(x, buffers = list(capital = 200))
f500[3:4, ]
#> <occ_flags> 2 records, 9 tests, reference OccurrenceCleaner 0.2.0, land 110
#>   id         species decimalLongitude decimalLatitude flags flagged_by
#> 1  3 Fagus sylvatica            16.37           48.21     0           
#> 2  4 Fagus sylvatica            16.37           48.21  1024  duplicate
```

`buffers` takes distances in metres; the help page of
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
lists the default of each test.

## Flagging other data

Other data usually arrives as a file with its own column names. The
example below writes the records to a CSV file with the columns `taxon`,
`lon` and `lat`, then reads it back as any CSV file would be read:

``` r

csv <- tempfile(fileext = ".csv")
write.csv(data.frame(taxon = x$species, lon = x$decimalLongitude,
                     lat = x$decimalLatitude),
          csv, row.names = FALSE)
y <- read.csv(csv)
```

Columns are found by their Darwin Core names in any case. Other names
are set with
[`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md),
and for another file only the
[`read.csv()`](https://rdrr.io/r/utils/read.table.html) path and these
names change:

``` r

cols <- occ_columns(lon = "lon", lat = "lat", species = "taxon")
flag_occurrences(y, columns = cols)
#> <occ_flags> 7 records, 9 tests, reference OccurrenceCleaner 0.2.0, land 110
#>             taxon    lon   lat flags        flagged_by
#> 1   Quercus robur  14.05 47.85     0                  
#> 2   Quercus robur   0.00  0.00   134    zero,equal,sea
#> 3 Fagus sylvatica  16.37 48.21     8           capital
#> 4 Fagus sylvatica  16.37 48.21  1032 capital,duplicate
#> 5     Pinus nigra 200.00 45.00     1           invalid
#> 6     Pinus nigra -30.00 40.00   128               sea
#> 7     Picea abies  13.06 47.08     0
```

Each test reads only the columns it needs: the default tests need the
coordinates and the species.

## Checks based on GBIF metadata

Some tests read GBIF fields instead of the coordinates. `basis_fossil`
flags records whose basis of record is a fossil specimen:

``` r

x$basisOfRecord <- c(rep("HUMAN_OBSERVATION", 6), "FOSSIL_SPECIMEN")
fb <- flag_occurrences(x, tests = "basis_fossil")
fb$flag_basis_fossil
#> [1] FALSE FALSE FALSE FALSE FALSE FALSE  TRUE
```

[Cleaning GBIF
data](https://gillescolling.com/OccurrenceCleaner/articles/gbif-workflow.md)
uses these tests on a GBIF download, including the issue warnings and
establishment means.

## Fixing common errors

Each error message names the problem and the next step. Here a column
the tests need is missing, because `y` uses other names and no `columns`
were given:

``` r

flag_occurrences(y)
#> Error in `resolve_columns()`:
#> ! column `decimalLongitude` (field `lon`) not found in the input; set it with occ_columns()
```

The fix is
[`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md),
as in the previous section. A test name that does not exist stops before
anything runs;
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)
lists the valid names:

``` r

flag_occurrences(x, tests = "capitals")
#> Error in `check_tests()`:
#> ! unknown test(s): capitals. See flag_tests().
```

A rule that names a test which was not run stops with an error;
otherwise it would exclude no records for that test. The fix is to run
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
with the test, or to drop it from the rule:

``` r

f3 <- flag_occurrences(x, tests = c("invalid", "zero"))
has_flag(f3, c("zero", "sea"))
#> Error in `check_tests_run()`:
#> ! test(s) not run on these flags: sea; run flag_occurrences() with them, or drop them from the rule
```

## Flagging a table on disk

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
also takes a path to a table on disk, such as the directory of Parquet
files of a GBIF snapshot. Each file is flagged and written separately to
`out`, and `keep` names the input columns copied next to the flags. The
example directory `src` holds two files of random records.

Code that writes the example files

``` r

src <- tempfile("records")
dir.create(src)
set.seed(1)
n <- 5000
big <- data.frame(
  gbifID = as.character(seq_len(n)),
  kingdom = sample(c("Animalia", "Plantae"), n, replace = TRUE),
  species = sample(letters, n, replace = TRUE),
  decimalLongitude = runif(n, -180, 180),
  decimalLatitude = runif(n, -60, 70)
)
vectra::write_vtr(big[1:2500, ], file.path(src, "part-1.vtr"))
vectra::write_vtr(big[2501:n, ], file.path(src, "part-2.vtr"))
```

``` r

out <- flag_occurrences(src, out = tempfile("flags"),
                        keep = "kingdom", verbose = FALSE)
```

For a path, the result describes the output directory instead of holding
the records. The directory’s files hold the `id` and `keep` columns and
the flags of every record.
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
reads the directory like a data frame:

``` r

t <- tally_flags(out, by = "kingdom", rules = list(strict = strict))
t[, c("kingdom", "n", "flagged_sea", "removed_strict", "kept_strict")]
#>    kingdom    n flagged_sea removed_strict kept_strict
#> 1 Animalia 2449        1724           1724         725
#> 2  Plantae 2551        1810           1810         741
```

Most random points fall in the sea, so the `sea` test flags most of
them. A rerun into the same directory skips the files already flagged;
[Large tables on
disk](https://gillescolling.com/OccurrenceCleaner/articles/on-disk.md)
covers resuming and reading the flags back.

## Where next

- [Cleaning GBIF
  data](https://gillescolling.com/OccurrenceCleaner/articles/gbif-workflow.md):
  a GBIF download from start to the retained records.

- [Choosing a cleaning
  rule](https://gillescolling.com/OccurrenceCleaner/articles/rules.md):
  what each test and rule removes, by taxon, record age and coordinate
  precision.

- [Large tables on
  disk](https://gillescolling.com/OccurrenceCleaner/articles/on-disk.md):
  a whole GBIF snapshot, resuming, and reading the flags.

- [Cleaning fossil
  records](https://gillescolling.com/OccurrenceCleaner/articles/fossils.md):
  the age tests for Paleobiology Database records.

- [The tests in
  detail](https://gillescolling.com/OccurrenceCleaner/articles/tests.md):
  the definition and required columns of every test;
  [`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)
  lists them in R.

- [Reference
  data](https://gillescolling.com/OccurrenceCleaner/articles/reference-data.md):
  where the capitals, centroids, institutions and land polygons come
  from, their versions, and how the land scale changes the `sea` test.

- [Coming from
  CoordinateCleaner](https://gillescolling.com/OccurrenceCleaner/articles/coordinatecleaner.md):
  how each function and argument maps across.
