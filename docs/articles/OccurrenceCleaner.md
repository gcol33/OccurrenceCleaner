# Get started

This article flags a small set of species records, removes the records a
chosen cleaning rule flags, and counts what two different rules exclude.
It assumes basic R and data frames. The coordinate tests follow
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)
(Zizka et al. [2019](https://doi.org/10.1111/2041-210X.13152)), with the
same definitions and default distances. The documented differences are
listed in [Where the flags
differ](https://gillescolling.com/OccurrenceCleaner/articles/coordinatecleaner.html#where-the-results-differ).

1.  **Flag** the records with
    [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

2.  **Inspect** the flags with
    [`print()`](https://rdrr.io/r/base/print.html) and
    [`summary()`](https://rdrr.io/r/base/summary.html).

3.  **Filter** out flagged records, using
    [`keep_unflagged()`](https://gillescolling.com/OccurrenceCleaner/reference/keep_unflagged.md).

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

## Flagging a data frame

The example has seven records of four tree species, each with an
identifier. Coordinates are longitude and latitude in decimal degrees.
The column names follow Darwin Core, the standard set of field names for
biodiversity data.

``` r

library(OccurrenceCleaner)

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
unchanged, plus the flag columns described below. The printed display
also shows a `flagged_by` column naming the tests that flag each record;
the object itself has no such column. Record 2 has zero coordinates,
record 4 repeats record 3, and record 5 has a longitude of 200 degrees.

A record without a flag has passed only the tests that were run. Record
3 lies in Vienna but carries no flag, because no test against capitals
has run yet.

Each test also has a logical column, `flag_<test>`, which is `TRUE`
where the test flagged the record. The `flags` column combines the
results of all tests for a record into one integer; [The tests in
detail](https://gillescolling.com/OccurrenceCleaner/articles/tests.md)
explains the encoding.

``` r

f$flag_duplicate
#> [1] FALSE FALSE FALSE  TRUE FALSE FALSE FALSE
```

## Filtering records

A cleaning rule is the set of tests whose flags exclude a record.
[`keep_unflagged()`](https://gillescolling.com/OccurrenceCleaner/reference/keep_unflagged.md)
keeps the records that no test in the rule flags. It also checks that
every named test was run on the flagged table, and stops with an error
if one was not:

``` r

rule <- c("invalid", "zero", "duplicate")
cleaned <- keep_unflagged(f, rule)
cleaned[, c("id", "species", "decimalLongitude", "decimalLatitude")]
#>   id         species decimalLongitude decimalLatitude
#> 1  1   Quercus robur            14.05           47.85
#> 3  3 Fagus sylvatica            16.37           48.21
#> 6  6     Pinus nigra           -30.00           40.00
#> 7  7     Picea abies            13.06           47.08
```

Record 3 is kept and record 4 is excluded: the `duplicate` test flags
only the repeats, so one copy of each record remains.

## Running every test the columns allow

Without `tests`,
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
runs every test whose columns are in the data. Running a test only adds
its flags, so the default checks for every potential problem the columns
allow. Which records to exclude is a separate choice, made afterwards
with a cleaning rule.

With coordinates and species, the default adds tests against reference
points and polygons: country capitals, country centroids, biodiversity
institutions, the headquarters of the Global Biodiversity Information
Facility (GBIF), urban areas, the land, and the Artificial Hotspot
Occurrence Inventory (Park et al. 2023), a list of coordinates that
recur in GBIF records for reasons such as georeferencing defaults. It
also runs the test for geographic outliers within a species. The printed
header names the columns whose tests could not run, such as a country
code or GBIF’s reported issues, and
[`test_plan()`](https://gillescolling.com/OccurrenceCleaner/reference/test_plan.md)
lists those tests with the reason for each.

``` r

f <- flag_occurrences(x)
f
#> <occ_flags> 7 records, 12 tests, reference OccurrenceCleaner 0.2.0, land 110
#> # not run, missing input: countryCode, issue, basisOfRecord, establishmentMeans, min_ma, max_ma, datasetKey, range polygons, genus (18 tests); test_plan() lists them
#>   id         species decimalLongitude decimalLatitude     flags
#> 1  1   Quercus robur            14.05           47.85         0
#> 2  2   Quercus robur             0.00            0.00 134217862
#> 3  3 Fagus sylvatica            16.37           48.21       264
#> 4  4 Fagus sylvatica            16.37           48.21      1288
#> 5  5     Pinus nigra           200.00           45.00         1
#> 6  6     Pinus nigra           -30.00           40.00       128
#> 7  7     Picea abies            13.06           47.08         0
#>                flagged_by
#> 1                        
#> 2     zero,equal,sea,aohi
#> 3           capital,urban
#> 4 capital,urban,duplicate
#> 5                 invalid
#> 6                     sea
#> 7
```

Records 3 and 4 lie in Vienna, within 10 km of a capital and inside an
urban area. Record 6 is in the Atlantic. Record 2, at (0, 0), is also at
sea, has equal longitude and latitude, and lies within 10 km of an
inventory point. The outlier test flags no record. Records 1 and 7 pass
every test run here.

The `sea` test compares each record with land polygons from Natural
Earth, at the 1:110 million scale by default. Near coasts and on small
islands a finer scale (`land_scale = 50` or `10`) can change the flag;
[Reference
data](https://gillescolling.com/OccurrenceCleaner/articles/reference-data.md)
maps the difference.

A flagged record may still be valid: a beech can grow within 10 km of a
capital, so you decide which tests suit your analysis. A rule for
species distribution modelling might exclude fossil and living specimens
along with coordinate problems, and another study can choose a different
set.

[`summary()`](https://rdrr.io/r/base/summary.html) counts the records
each test flags, and in the `only` column the records that test alone
flags. Without a rule, it counts under one rule named `all` that lists
every test that was run. It only counts: `f` still contains all seven
records.

``` r

summary(f)
#> <occ_summary> 7 records
#>   rule all: removes 5 (71.43 %)
#>  rule              test n flagged   pct only pct_only
#>   all           invalid 7       1 14.29    1    14.29
#>   all              zero 7       1 14.29    0     0.00
#>   all             equal 7       1 14.29    0     0.00
#>   all           capital 7       2 28.57    0     0.00
#>   all          centroid 7       0  0.00    0     0.00
#>   all       institution 7       0  0.00    0     0.00
#>   all gbif_headquarters 7       0  0.00    0     0.00
#>   all               sea 7       2 28.57    1    14.29
#>   all             urban 7       2 28.57    0     0.00
#>   all         duplicate 7       1 14.29    0     0.00
#>   all           outlier 7       0  0.00    0     0.00
#>   all              aohi 7       1 14.29    0     0.00
#>   all             (any) 7       5 71.43
```

A rule excludes each record once, however many of its tests flag it.
Record 2 is flagged by four tests and record 4 by three, so the per-test
counts add up to 11 while the `(any)` row excludes 5 records.

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
t
#> <occ_tally> 7 records in 4 groups of species, rules: strict, mild
#>          species n removed_strict kept_strict removed_mild kept_mild
#>  Fagus sylvatica 2              2           0            1         1
#>      Picea abies 1              0           1            0         1
#>      Pinus nigra 2              2           0            1         1
#>    Quercus robur 2              1           1            1         1
#> # summary() for the share each test flags
```

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

f200 <- flag_occurrences(x, buffers = list(capital = 200))
f200[3:4, ]
#> <occ_flags> 2 records, 12 tests, reference OccurrenceCleaner 0.2.0, land 110
#> # not run, missing input: countryCode, issue, basisOfRecord, establishmentMeans, min_ma, max_ma, datasetKey, range polygons, genus (18 tests); test_plan() lists them
#>   id         species decimalLongitude decimalLatitude flags      flagged_by
#> 1  3 Fagus sylvatica            16.37           48.21   256           urban
#> 2  4 Fagus sylvatica            16.37           48.21  1280 urban,duplicate
```

The capital distance is given in metres, as are the other proximity
distances; the `zero` distance is in degrees. The help page of
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

Columns are found by their Darwin Core names regardless of
capitalisation. Other names are set with
[`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md),
and for another file only the
[`read.csv()`](https://rdrr.io/r/utils/read.table.html) path and these
names change:

``` r

cols <- occ_columns(lon = "lon", lat = "lat", species = "taxon")
flag_occurrences(y, columns = cols)
#> <occ_flags> 7 records, 12 tests, reference OccurrenceCleaner 0.2.0, land 110
#> # not run, missing input: countryCode, issue, basisOfRecord, establishmentMeans, min_ma, max_ma, datasetKey, range polygons, genus (18 tests); test_plan() lists them
#>             taxon    lon   lat     flags              flagged_by
#> 1   Quercus robur  14.05 47.85         0                        
#> 2   Quercus robur   0.00  0.00 134217862     zero,equal,sea,aohi
#> 3 Fagus sylvatica  16.37 48.21       264           capital,urban
#> 4 Fagus sylvatica  16.37 48.21      1288 capital,urban,duplicate
#> 5     Pinus nigra 200.00 45.00         1                 invalid
#> 6     Pinus nigra -30.00 40.00       128                     sea
#> 7     Picea abies  13.06 47.08         0
```

With the three columns mapped, the same 12 tests run as on `x`.

## Fixing common errors

Data often use other column names than the Darwin Core ones. In this
example, `y` stores the coordinates as `lon` and `lat` and the species
as `taxon`. The `columns` argument tells OccurrenceCleaner which columns
to read.

Running the tests without that mapping produces this error:

``` r

flag_occurrences(y)
#> Error in `apply_plan()`:
#> ! no test can run on this input: no column `decimalLongitude` and `decimalLatitude` for the coordinates, nor another column a test reads; name the columns with occ_columns(), and see test_plan() for what each test needs
```

The message names the coordinate columns it looked for and points to
[`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md).
Passing the mapping `cols` from [Flagging other
data](#flagging-other-data) fixes the call:

``` r

fy <- flag_occurrences(y, columns = cols)
print(fy, n = 3)
#> <occ_flags> 7 records, 12 tests, reference OccurrenceCleaner 0.2.0, land 110
#> # not run, missing input: countryCode, issue, basisOfRecord, establishmentMeans, min_ma, max_ma, datasetKey, range polygons, genus (18 tests); test_plan() lists them
#>             taxon   lon   lat     flags          flagged_by
#> 1   Quercus robur 14.05 47.85         0                    
#> 2   Quercus robur  0.00  0.00 134217862 zero,equal,sea,aohi
#> 3 Fagus sylvatica 16.37 48.21       264       capital,urban
#> # ... 4 more records; summary() for the share each test flags
```

A mapping that leaves out a column gives no error: the tests that need
that column do not run. Here the species column is left out:

``` r

cols_xy <- occ_columns(lon = "lon", lat = "lat")
print(flag_occurrences(y, columns = cols_xy), n = 3)
#> <occ_flags> 7 records, 10 tests, reference OccurrenceCleaner 0.2.0, land 110
#> # not run, missing input: countryCode, species, issue, basisOfRecord, establishmentMeans, min_ma, max_ma, datasetKey, genus (20 tests); test_plan() lists them
#>             taxon   lon   lat     flags          flagged_by
#> 1   Quercus robur 14.05 47.85         0                    
#> 2   Quercus robur  0.00  0.00 134217862 zero,equal,sea,aohi
#> 3 Fagus sylvatica 16.37 48.21       264       capital,urban
#> # ... 4 more records; summary() for the share each test flags
```

The header counts 10 tests instead of 12 and lists `species` among the
missing inputs: the `duplicate` and `outlier` tests did not run. Adding
`species = "taxon"`, as in `cols`, runs them again.

An unknown test name stops the call before any test runs:

``` r

flag_occurrences(x, tests = "capitals")
#> Error in `check_tests()`:
#> ! unknown test(s): capitals. See flag_tests().
```

[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)
lists the valid names; the capital test is called `capital`:

``` r

fc <- flag_occurrences(x, tests = "capital")
fc$flag_capital
#> [1] FALSE FALSE  TRUE  TRUE FALSE FALSE FALSE
```

A rule that names a test which was not run also stops with an error,
because the rule would otherwise exclude no records for that test:

``` r

f3 <- flag_occurrences(x, tests = c("invalid", "zero"))
has_flag(f3, c("zero", "sea"))
#> Error in `check_tests_run()`:
#> ! test(s) not run on these flags: sea; run flag_occurrences() with them, or drop them from the rule
```

The fix is to run
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
with the test, or to drop it from the rule. Here the `sea` test is
added:

``` r

f3 <- flag_occurrences(x, tests = c("invalid", "zero", "sea"))
has_flag(f3, c("zero", "sea"))
#> [1] FALSE  TRUE FALSE FALSE FALSE  TRUE FALSE
```

## Checks based on GBIF metadata

Some tests read GBIF fields instead of the coordinates. `basis_fossil`
flags records whose basis of record is a fossil specimen. The example
adds a `basisOfRecord` column to a copy of the records, `xb`, and marks
record 7 as a fossil:

``` r

basis <- c(rep("HUMAN_OBSERVATION", 6), "FOSSIL_SPECIMEN")
xb <- data.frame(x, basisOfRecord = basis)
fb <- flag_occurrences(xb, tests = "basis_fossil")
fb$flag_basis_fossil
#> [1] FALSE FALSE FALSE FALSE FALSE FALSE  TRUE
```

[Cleaning GBIF
data](https://gillescolling.com/OccurrenceCleaner/articles/gbif-workflow.md)
uses these tests on a GBIF download, including the issue warnings and
establishment means.

## Flagging a table on disk

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
also takes a path to a table on disk, such as the directory of Parquet
files of a GBIF snapshot. Each file is flagged and written separately to
`out`, and `keep` names the input columns copied next to the flags.

The example writes the seven records to a directory `src` as two files.
The files use the `.vtr` format of vectra, the column-store package
OccurrenceCleaner reads and writes tables on disk with:

``` r

src <- tempfile("records")
dir.create(src)
vectra::write_vtr(x[1:4, ], file.path(src, "part-1.vtr"))
vectra::write_vtr(x[5:7, ], file.path(src, "part-2.vtr"))
```

The call is the same as for a data frame, with the path and an output
directory. The identifier is looked for under its GBIF name `gbifID` by
default, so `columns` maps it to `id`:

``` r

out <- flag_occurrences(src, out = tempfile("flags"),
                        columns = occ_columns(id = "id"),
                        keep = "species", verbose = FALSE)
```

For a path, the result describes the output directory instead of holding
the records. The directory’s files hold the identifier, the `keep`
columns and the flags of every record.
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
reads the directory like a data frame:

``` r

t <- tally_flags(out, by = "species", rules = list(strict = strict))
t
#> <occ_tally> 7 records in 4 groups of species, rules: strict
#>          species n removed_strict kept_strict
#>  Fagus sylvatica 2              2           0
#>      Picea abies 1              0           1
#>      Pinus nigra 2              2           0
#>    Quercus robur 2              1           1
#> # summary() for the share each test flags
```

The counts match the strict rule on the data frame above. On disk the
`duplicate` test compares each record with all records before it across
the files, so it finds record 4 as in the data frame. A rerun into the
same directory skips the files already flagged. [Large tables on
disk](https://gillescolling.com/OccurrenceCleaner/articles/on-disk.md)
covers resuming, duplicates across files and reading the flags back.

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

- [Compatibility with
  CoordinateCleaner](https://gillescolling.com/OccurrenceCleaner/articles/coordinatecleaner.md):
  where the two packages agree, how that is tested, and where results
  differ.
