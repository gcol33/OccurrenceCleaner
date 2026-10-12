# Cleaning fossil records

Fossil occurrences, such as those downloaded from the Paleobiology
Database (PBDB), can carry the same coordinate errors as modern records,
and they have one more field to check: the age of the record, given as a
range in million years (Ma). This article flags a small fossil table
with the coordinate tests and the age test `age_equal`, filters records
by the width of their age range, tests a larger table for outliers
within a taxon, and exports the kept records to PyRate. [Get
started](https://gillescolling.com/OccurrenceCleaner/articles/OccurrenceCleaner.md)
covers installation; the comparison with
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) at
the end also needs that package installed.

1.  **Flag** a fossil table with
    [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

2.  **Filter** out flagged records, using
    [`keep_unflagged()`](https://gillescolling.com/OccurrenceCleaner/reference/keep_unflagged.md).

3.  **Filter** by the width of the age range, counting each group with
    [`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md).

4.  **Test** each taxon for outliers in age and space.

5.  **Export** the kept records with
    [`export_pyrate()`](https://gillescolling.com/OccurrenceCleaner/reference/export_pyrate.md).

## A small fossil table

PBDB uses `accepted_name` for taxon names, `lng` and `lat` for
coordinates, and `cc` for two-letter country codes. The columns `min_ma`
and `max_ma` give the youngest and oldest possible ages in millions of
years before the present.

The example below contains nine synthetic records. Record 2 has equal
minimum and maximum ages; record 3 has the ages reversed; record 4 spans
43 million years; record 5 is missing its minimum age; and record 6 has
both coordinates set to zero. Records 1 and 9 have a minimum age below
the maximum age, a span under 4 million years, and coordinates in
Wyoming that match their country code `US`; they pass every test.
Records 7 and 8 have a minimum age below the maximum age, a span of 1.2
million years, and the country code `DE`; their coordinates are missing
in the table and set in the next chunk:

``` r

library(OccurrenceCleaner)

fos <- data.frame(
  occurrence_no = 1:9,
  accepted_name = c("Coryphodon", "Coryphodon", "Hyracotherium", "Hyracotherium",
                    "Hyracotherium", "Mesonyx", "Mesonyx", "Mesonyx", "Uintatherium"),
  lng = c(-108.52, -108.40, -108.71, -107.95, -108.10, 0, NA, NA, -109.03),
  lat = c(44.31, 44.05, 43.92, 44.60, 44.40, 0, NA, NA, 41.62),
  cc = c("US", "US", "US", "US", "US", "US", "DE", "DE", "US"),
  min_ma = c(53.0, 55.8, 56.0, 23.0, NA, 48.6, 47.8, 47.8, 46.2),
  max_ma = c(56.0, 55.8, 52.5, 66.0, 54.0, 50.2, 49.0, 49.0, 48.6))
```

Records 7 and 8 are placed relative to the centroid of Germany in the
package’s reference points, so their distance to it is known: record 7
sits on the point, record 8 lies 0.027 degrees of latitude (about 3 km)
north of it.

``` r

cen <- reference_points("centroid")
de <- cen[cen$key == "ne:DEU" & cen$method == "polygon centroid", ]
de[, c("name", "method", "lon", "lat")]
#>        name           method      lon      lat
#> 380 Germany polygon centroid 10.36071 51.05001
fos[7:8, "lng"] <- de$lon
fos[7:8, "lat"] <- de$lat + c(0, 0.027)
```

## Flagging

[`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md)
maps the PBDB names onto the fields the tests read. The coordinate tests
are the record tests of
[`clean_fossils()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_fossils.html)
in CoordinateCleaner; `age_equal` is its `agesequal` test, and the
country check runs too because the table has country codes:

``` r

cols <- occ_columns(lon = "lng", lat = "lat", species = "accepted_name",
                    country = "cc", id = "occurrence_no")
tests <- c("invalid", "zero", "equal", "centroid", "institution",
           "gbif_headquarters", "country_mismatch", "age_equal")
f <- flag_occurrences(fos, tests = tests, columns = cols)
f[, c("occurrence_no", "accepted_name", "min_ma", "max_ma", "flags")]
#> <occ_flags> 9 records, 8 tests, reference OccurrenceCleaner 0.2.0, land 110
#>   occurrence_no accepted_name min_ma max_ma  flags                  flagged_by
#> 1             1    Coryphodon   53.0   56.0      0                            
#> 2             2    Coryphodon   55.8   55.8 524288                   age_equal
#> 3             3 Hyracotherium   56.0   52.5 524288                   age_equal
#> 4             4 Hyracotherium   23.0   66.0      0                            
#> 5             5 Hyracotherium     NA   54.0      0                            
#> 6             6       Mesonyx   48.6   50.2    518 zero,equal,country_mismatch
#> 7             7       Mesonyx   47.8   49.0     16                    centroid
#> 8             8       Mesonyx   47.8   49.0      0                            
#> 9             9  Uintatherium   46.2   48.6      0
```

`age_equal` flags a record whose minimum age is equal to or greater than
its maximum age: here records 2 and 3. A zero-width range can come from
one age copied into both fields, and an inverted one from swapped
fields, but the flag only records the comparison; such records need a
look at their source before they are corrected or dropped. A record with
a missing age, such as record 5, is not flagged by this test.

Record 6 fails `zero`, `equal` and `country_mismatch`, since (0, 0) lies
in the Gulf of Guinea. Record 7 fails `centroid`: it lies within the
default 1 km of the centroid of Germany.

## Filtering records

[`keep_unflagged()`](https://gillescolling.com/OccurrenceCleaner/reference/keep_unflagged.md)
keeps the records that no test in `tests` flags. It also checks that
every named test was run on the flagged table, and stops with an error
if one was not. The later sections reuse this rule as `rule`:

``` r

rule <- tests
kept <- keep_unflagged(f, rule)
kept[, c("occurrence_no", "accepted_name", "min_ma", "max_ma")]
#>   occurrence_no accepted_name min_ma max_ma
#> 1             1    Coryphodon   53.0   56.0
#> 4             4 Hyracotherium   23.0   66.0
#> 5             5 Hyracotherium     NA   54.0
#> 8             8       Mesonyx   47.8   49.0
#> 9             9  Uintatherium   46.2   48.6
```

Record 5 stays because `age_equal` cannot compare a missing age, so the
record carries no flag. A study that needs both ages adds
`!is.na(f$min_ma) & !is.na(f$max_ma)` to the selection.

## A wider centroid buffer

OccurrenceCleaner uses default buffers of 1 km around centroids and 100
m around institutions. You can change these with `buffers`.

Fossil localities can be georeferenced coarsely, so a collection placed
a few kilometres from a country centroid may still have been put there
by the centroid. A wider buffer catches such records, at the cost of
flagging any correct locality within the same distance. With a 5 km
buffer, chosen here to reach record 8, both records near the centroid of
Germany are flagged:

``` r

f5 <- flag_occurrences(fos, tests = tests, columns = cols,
                       buffers = list(centroid = 5000))
data.frame(occurrence_no = fos$occurrence_no,
           centroid_1km = f$flag_centroid, centroid_5km = f5$flag_centroid)
#>   occurrence_no centroid_1km centroid_5km
#> 1             1        FALSE        FALSE
#> 2             2        FALSE        FALSE
#> 3             3        FALSE        FALSE
#> 4             4        FALSE        FALSE
#> 5             5        FALSE        FALSE
#> 6             6        FALSE        FALSE
#> 7             7         TRUE         TRUE
#> 8             8        FALSE         TRUE
#> 9             9        FALSE        FALSE
```

These defaults differ from those in CoordinateCleaner. In version 3.0.1,
[`clean_fossils()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_fossils.html)
applies its defaults `centroids_rad = 0.05` and `inst_rad = 0.001` as
radii in metres, so its centroid and institution tests flag only records
within 5 cm and 1 mm of a reference point.

## Filtering by age range

Calculate the width of each record’s age range as `max_ma - min_ma`. Use
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
to count flagged and retained records in each age-range group:

``` r

f$age_range <- f$max_ma - f$min_ma
tally_flags(f, bins = list(age_range = c(5, 15)), rules = list(all = rule))
#> <occ_tally> 9 records in 3 groups of age_range_bin, rules: all
#>  age_range_bin n removed_all kept_all
#>             <5 7           4        3
#>           >=15 1           0        1
#>        missing 1           0        1
#> # summary() for the share each test flags
```

Record 4 has an age range of 43 Ma and is the only record above 15 Ma.
To retain unflagged records with an age range of at most 15 Ma, apply
the limit to the kept records;
[`which()`](https://rdrr.io/r/base/which.html) also drops records
without an age range:

``` r

kept15 <- keep_unflagged(f, rule)
kept15 <- kept15[which(kept15$age_range <= 15), ]
kept15$occurrence_no
#> [1] 1 8 9
```

The 15 Ma limit is illustrative; choose a limit appropriate for your
study. You can change it without rerunning the flagging tests.

For comparison, CoordinateCleaner provides this filter through
[`cf_range()`](https://ropensci.github.io/CoordinateCleaner/reference/cf_range.html)
with `method = "time"`, which flags age ranges wider than `max_range`
Ma.

## Outliers within a taxon

Three tests compare each record with others in the same taxon. Here,
taxa are the genera in `accepted_name`:

- `age_range_outlier` identifies unusually wide age ranges.

- `age_outlier` identifies unusual ages.

- `spatiotemporal_outlier` identifies unusual combinations of location
  and age.

The tests use an upper threshold calculated within each taxon: the 75th
percentile plus `mltpl` times the interquartile range, with `mltpl = 5`
by default. Each test applies this threshold to its own measure of
difference. Taxa need at least seven records to be tested.

The two tests that use ages, `age_outlier` and `spatiotemporal_outlier`,
sample one age from each record’s range. They repeat this five times and
flag records identified in a majority of runs. Sampling uses a seed for
each taxon, making the results reproducible. You can change the seed
through `settings`.

Generate 600 synthetic records with PBDB column names. Locations fall
within a region of Wyoming, ages span 46 to 60 Ma, and age ranges are 1
to 4 Ma wide. Genera are assigned independently of location and age.

Then give 20 records a broad age range of 23 to 66 Ma and five records
an age range of 99 to 101 Ma. The `injected_case` column labels these
changes; unchanged records are labelled `background`.

``` r

set.seed(5)
n <- 600
big <- data.frame(
  occurrence_no = 100 + seq_len(n),
  accepted_name = sample(c("Coryphodon", "Hyracotherium", "Mesonyx"), n, TRUE),
  lng = round(runif(n, -110, -106), 3), lat = round(runif(n, 42, 46), 3),
  cc = "US", min_ma = round(runif(n, 46, 56), 1), injected_case = "background")
big$max_ma <- big$min_ma + round(runif(n, 1, 4), 1)
i <- sample(n, 25)
big[i[1:20], c("min_ma", "max_ma", "injected_case")] <- list(23, 66, "broad_range")
big[i[21:25], c("min_ma", "max_ma", "injected_case")] <- list(99, 101, "far_age")
table(big$injected_case)
#> 
#>  background broad_range     far_age 
#>         575          20           5
```

Run the outlier tests alongside the coordinate and age tests to collect
their flags in one table:

``` r

otests <- c("age_range_outlier", "age_outlier", "spatiotemporal_outlier")
g <- flag_occurrences(big, tests = c(tests, otests), columns = cols)
aggregate(as.data.frame(g)[paste0("flag_", otests)],
          by = list(injected_case = g$injected_case), FUN = sum)
#>   injected_case flag_age_range_outlier flag_age_outlier
#> 1    background                      0                0
#> 2   broad_range                     20                7
#> 3       far_age                      0                5
#>   flag_spatiotemporal_outlier
#> 1                           0
#> 2                           0
#> 3                           4
```

The range test flags all 20 broad-range records. The age test flags
seven broad-range records and all five records near 100 Ma. The
spatiotemporal test flags four of the five records near 100 Ma. All
three tests leave the background records unflagged.

You can adjust the tests through `settings`. The call below lowers
`mltpl` to 2 for the range test and changes the age test’s seed to 7:

``` r

g2 <- flag_occurrences(big, tests = otests, columns = cols,
                       settings = list(age_range_outlier = list(mltpl = 2),
                                       age_outlier = list(seed = 7)))
colSums(as.data.frame(g2)[paste0("flag_", otests)])
#>      flag_age_range_outlier            flag_age_outlier 
#>                          20                          14 
#> flag_spatiotemporal_outlier 
#>                           4
```

The range test still flags the same 20 records: their 43 Ma ranges
exceed the threshold under both settings. Changing the age test’s seed
gives 14 flagged records, compared with 12 under the default seed.

## Export to PyRate

PyRate (Silvestro et al. [2014](https://doi.org/10.1093/sysbio/syu006))
estimates speciation and extinction rates from fossil occurrences.
Select the records from `g` that are not flagged by any of the tests run
and have an age range of at most 15 Ma:

``` r

g$age_range <- g$max_ma - g$min_ma
final <- keep_unflagged(g)
final <- final[which(final$age_range <= 15), ]
nrow(final)
#> [1] 575
```

[`export_pyrate()`](https://gillescolling.com/OccurrenceCleaner/reference/export_pyrate.md)
writes them in PyRate’s input format: one array of ages per taxon, an
extra age of 0 for extant taxa, and replicates of ages drawn from each
record’s range.

``` r

paths <- export_pyrate(final, file.path(tempdir(), "wyoming"), status = "extinct",
                       columns = cols, replicates = 3, seed = 1)
basename(paths)
#> [1] "wyoming_PyRate.py"     "wyoming_TaxonList.txt"
```

The `_PyRate.py` file contains the ages and is the input PyRate reads;
the `_TaxonList.txt` file lists each taxon with its status. The draws
are seeded, so the same call writes the same files; `random = FALSE`
uses the midpoints of the ranges instead. CoordinateCleaner’s
[`write_pyrate()`](https://ropensci.github.io/CoordinateCleaner/reference/write_pyrate.html)
writes the same layout, and the package tests compare the two files.

## Comparison with CoordinateCleaner

`age_equal` and
[`cf_equal()`](https://ropensci.github.io/CoordinateCleaner/reference/cf_equal.html)
give the same flags on the small table:

``` r

theirs <- !CoordinateCleaner::cf_equal(fos, value = "flagged", verbose = FALSE)
data.frame(occurrence_no = fos$occurrence_no,
           OccurrenceCleaner = f$flag_age_equal, CoordinateCleaner = theirs)
#>   occurrence_no OccurrenceCleaner CoordinateCleaner
#> 1             1             FALSE             FALSE
#> 2             2              TRUE              TRUE
#> 3             3              TRUE              TRUE
#> 4             4             FALSE             FALSE
#> 5             5             FALSE             FALSE
#> 6             6             FALSE             FALSE
#> 7             7             FALSE             FALSE
#> 8             8             FALSE             FALSE
#> 9             9             FALSE             FALSE
```

The package’s test suite compares the outlier tests with
[`cf_age()`](https://ropensci.github.io/CoordinateCleaner/reference/cf_age.html),
[`cf_outl()`](https://ropensci.github.io/CoordinateCleaner/reference/cf_outl.html)
and
[`cf_range()`](https://ropensci.github.io/CoordinateCleaner/reference/cf_range.html):
`age_range_outlier` gives identical flags, and the two tests that draw
ages give identical flags when no age has to be drawn.

## Fossils in GBIF data

GBIF stores fossil specimens alongside modern records, marked by
`basisOfRecord = "FOSSIL_SPECIMEN"`, usually without PBDB-style age
fields. `basis_fossil` flags them:

``` r

gb <- data.frame(
  gbifID = 1:3,
  basisOfRecord = c("HUMAN_OBSERVATION", "FOSSIL_SPECIMEN", "PRESERVED_SPECIMEN"),
  decimalLongitude = c(16.37, 11.2, 14.5), decimalLatitude = c(48.21, 50.1, 47.1))
fg <- flag_occurrences(gb, tests = c("invalid", "basis_fossil"))
```

A study of present-day distributions keeps the records without the flag,
and a palaeontological one keeps only the flagged records:

``` r

keep_unflagged(fg, "basis_fossil")[, c("gbifID", "basisOfRecord")]
#>   gbifID      basisOfRecord
#> 1      1  HUMAN_OBSERVATION
#> 3      3 PRESERVED_SPECIMEN
fg[has_flag(fg, "basis_fossil"), c("gbifID", "basisOfRecord")]
#>   gbifID   basisOfRecord
#> 2      2 FOSSIL_SPECIMEN
```

## References

Silvestro, D., Schnitzler, J., Liow, L. H., Antonelli, A. and Salamin,
N. (2014). Bayesian estimation of speciation and extinction from
incomplete fossil occurrence data. *Systematic Biology* 63:349-367.
<https://doi.org/10.1093/sysbio/syu006>
