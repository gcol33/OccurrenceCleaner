# Quick start

OccurrenceCleaner flags errors in species occurrence records and keeps
every record. Each test sets one bit in an integer flag word, so
deciding which records to drop is a query over the flags, made after the
pass and changed without rerunning it.

``` r

library(OccurrenceCleaner)
```

## Flag a data frame

The input needs longitude, latitude and a species column under their
Darwin Core names (`decimalLongitude`, `decimalLatitude`, `species`;
matching is case-insensitive, and
[`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md)
renames them).

``` r

x <- data.frame(
  species = c("Quercus robur", "Quercus robur", "Fagus sylvatica", "Fagus sylvatica", "Pinus nigra"),
  decimalLongitude = c(12.58, 0, 16.37, 16.37, -30),
  decimalLatitude = c(55.67, 0, 48.21, 48.21, 40),
  countryCode = c("DK", NA, "AT", "AT", "FR")
)
f <- flag_occurrences(x, tests = c("val", "zero", "cap", "gbif", "sea", "coun", "dupl"))
knitr::kable(f[, c("species", "flags", "flag_zero", "flag_cap", "flag_gbif", "flag_sea", "flag_coun", "flag_dupl")])
```

| species         | flags | flag_zero | flag_cap | flag_gbif | flag_sea | flag_coun | flag_dupl |
|:----------------|------:|:----------|:---------|:----------|:---------|:----------|:----------|
| Quercus robur   |   584 | FALSE     | TRUE     | TRUE      | FALSE    | TRUE      | FALSE     |
| Quercus robur   |   642 | TRUE      | FALSE    | FALSE     | TRUE     | TRUE      | FALSE     |
| Fagus sylvatica |     8 | FALSE     | TRUE     | FALSE     | FALSE    | FALSE     | FALSE     |
| Fagus sylvatica |  1032 | FALSE     | TRUE     | FALSE     | FALSE    | FALSE     | TRUE      |
| Pinus nigra     |   640 | FALSE     | FALSE    | FALSE     | TRUE     | TRUE      | FALSE     |

The first record is within 1 km of the GBIF headquarters in Copenhagen,
hence also within 10 km of a capital; it also fails `coun`, because that
point lies just off the 1:50m Natural Earth coastline of Denmark. The
second is a zero coordinate at sea with no country code. The third and
fourth are the same species at the same place in Vienna, so the fourth
is a duplicate; both are in a capital. The fifth is in the Atlantic with
a French country code.

## The tests

``` r

knitr::kable(flag_tests()[, c("bit", "test", "definition", "equivalent")])
```

| bit | test | definition | equivalent |
|---:|:---|:---|:---|
| 0 | val | coordinate missing, not numeric or outside \[-180, 180\] x \[-90, 90\] | cc_val |
| 1 | zero | longitude or latitude exactly zero, or within 0.5 degrees of (0, 0) | cc_zero |
| 2 | equ | absolute longitude equal to absolute latitude | cc_equ |
| 3 | cap | within 10 km of a country capital | cc_cap |
| 4 | cen | within 1 km of a country or province centroid | cc_cen |
| 5 | inst | within 100 m of a biodiversity institution | cc_inst |
| 6 | gbif | within 1 km of the GBIF headquarters (12.58 E, 55.67 N) | cc_gbif |
| 7 | sea | outside the land polygons | cc_sea |
| 8 | urb | inside an urban-area polygon | cc_urb |
| 9 | coun | coordinates fall outside the country given by the record’s country code | cc_coun |
| 10 | dupl | same coordinates and species as an earlier record | cc_dupl |
| 11 | issue_geo | a GBIF georeferencing issue is present | NA |
| 12 | issue_tax | GBIF matched the taxon fuzzily or to a higher rank | NA |
| 13 | issue_date | GBIF found the recorded date invalid or unlikely | NA |
| 14 | rounded | GBIF rounded the coordinates (COORDINATE_ROUNDED) | NA |
| 15 | fossil | basis of record is a fossil specimen | NA |
| 16 | living | basis of record is a living specimen | NA |
| 17 | introduced | establishment means is introduced, naturalised or invasive | NA |
| 18 | managed | establishment means is managed or cultivated | NA |

The first eleven tests reproduce CoordinateCleaner’s record tests with
its default buffers; the rest read GBIF’s `issue`, `basisOfRecord` and
`establishmentMeans` fields.
[`default_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/default_tests.md)
names the tests that need only coordinates and a species.

## Rules are queries over the flags

A rule is a set of tests.
[`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md)
marks the records any of them flags:

``` r

strict <- c("zero", "cap", "gbif", "sea", "dupl")
mild <- c("zero", "sea")
knitr::kable(data.frame(species = f$species, strict = has_flag(f$flags, strict), mild = has_flag(f$flags, mild)))
```

| species         | strict | mild  |
|:----------------|:-------|:------|
| Quercus robur   | TRUE   | FALSE |
| Quercus robur   | TRUE   | TRUE  |
| Fagus sylvatica | TRUE   | FALSE |
| Fagus sylvatica | TRUE   | FALSE |
| Pinus nigra     | TRUE   | TRUE  |

[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
counts, per group, how many records each test flags and how many each
rule removes. It returns one `flagged_<test>` column per test; a few are
shown here:

``` r

t <- tally_flags(f, by = "species", rules = list(strict = strict, mild = mild))
knitr::kable(t[, c("species", "n", "flagged_cap", "flagged_sea", "flagged_dupl",
                   "removed_strict", "removed_mild")])
```

| species | n | flagged_cap | flagged_sea | flagged_dupl | removed_strict | removed_mild |
|:---|---:|---:|---:|---:|---:|---:|
| Fagus sylvatica | 2 | 2 | 0 | 1 | 2 | 0 |
| Pinus nigra | 1 | 0 | 1 | 0 | 1 | 1 |
| Quercus robur | 2 | 1 | 1 | 0 | 2 | 1 |

Numeric columns such as the record year or the stated coordinate
uncertainty stay raw and are cut at tally time:

``` r

f$year <- c(1890, 1950, 1999, 2015, NA)
t <- tally_flags(f, bins = list(year = c(1950, 2000)), rules = list(strict = strict))
knitr::kable(t[, c("year_bin", "n", "removed_strict", "kept_strict")])
```

| year_bin  |   n | removed_strict | kept_strict |
|:----------|----:|---------------:|------------:|
| \<1950    |   1 |              1 |           0 |
| 1950-2000 |   2 |              2 |           0 |
| \>=2000   |   1 |              1 |           0 |
| missing   |   1 |              1 |           0 |

## Buffers, reference data and scale

The buffers default to CoordinateCleaner’s (10 km capitals, 1 km
centroids, 100 m institutions, 1 km GBIF headquarters, 0.5 degrees
around the origin) and can be changed per test:

``` r

flag_occurrences(x[3, ], tests = "cap")$flag_cap
#> [1] TRUE
flag_occurrences(x[3, ], tests = "cap", buffers = list(cap = 500))$flag_cap
#> [1] FALSE
```

The gazetteers are rebuilt from Natural Earth and GBIF’s registry of
scientific collections, each pinned to a version and checksum:

``` r

knitr::kable(reference_info()[, c("layer", "source", "version", "retrieved")])
```

| layer        | source         | version    | retrieved  |
|:-------------|:---------------|:-----------|:-----------|
| land_110     | Natural Earth  | 4.1.0      | 2026-10-09 |
| land_50      | Natural Earth  | 4.1.0      | 2026-10-09 |
| land_10      | Natural Earth  | 5.1.1      | 2026-10-09 |
| countries_50 | Natural Earth  | 5.1.1      | 2026-10-09 |
| urban_50     | Natural Earth  | 4.1.0      | 2026-10-09 |
| places_10    | Natural Earth  | 5.1.2      | 2026-10-09 |
| admin0_10    | Natural Earth  | 5.1.1      | 2026-10-09 |
| admin1_10    | Natural Earth  | 5.1.1      | 2026-10-09 |
| institutions | GBIF GRSciColl | 2026-10-09 | 2026-10-09 |

`reference = "CoordinateCleaner"` uses that package’s own tables
instead, which reproduces its flags (CoordinateCleaner must be
installed). The land layer for the `sea` test comes at Natural Earth
scale 110 (CoordinateCleaner’s default), 50, or 10; the 1:10m layer is
downloaded once on first use.

## A table on disk

The same verb streams an on-disk table through vectra: a directory of
Parquet parts such as a GBIF snapshot, a `.vtr` file, or a delimited
file. Each input file is one unit of work; the flags are written as
`.vtr` parts next to the columns kept for grouping, and a rerun skips
finished units.

``` r

src <- tempfile("records"); dir.create(src)
set.seed(1)
big <- data.frame(gbifID = as.character(1:5000), kingdom = sample(c("Animalia", "Plantae"), 5000, TRUE),
                  year = sample(1900:2020, 5000, TRUE), species = sample(letters, 5000, TRUE),
                  decimalLongitude = runif(5000, -180, 180), decimalLatitude = runif(5000, -60, 70))
vectra::write_vtr(big[1:2500, ], file.path(src, "part-1.vtr"))
vectra::write_vtr(big[2501:5000, ], file.path(src, "part-2.vtr"))

out <- flag_occurrences(src, out = tempfile("flags"), keep = c("kingdom", "year"), verbose = FALSE)
out
#> <occ_flagged> 5,000 records in 2 part(s)
#>   out:       C:\Users\Gilles Colling\AppData\Local\Temp\RtmpioIdgD\flags5e9ca5a2a12
#>   tests:     val, zero, equ, cap, cen, inst, gbif, sea, dupl
#>   layout:    v1
#>   reference: natural_earth (land 110; land_110 4.1.0, land_50 4.1.0, land_10 5.1.1, countries_50 5.1.1, urban_50 4.1.0, places_10 5.1.2, admin0_10 5.1.1, admin1_10 5.1.1, institutions 2026-10-09)
#>   keep:      kingdom, year
t <- tally_flags(out, by = "kingdom", bins = list(year = c(1950, 2000)),
                 rules = list(cc = c("zero", "equ", "cap", "cen", "inst", "gbif", "sea")))
knitr::kable(t[, c("kingdom", "year_bin", "n", "flagged_sea", "flagged_cap", "removed_cc", "kept_cc")])
```

| kingdom  | year_bin  |    n | flagged_sea | flagged_cap | removed_cc | kept_cc |
|:---------|:----------|-----:|------------:|------------:|-----------:|--------:|
| Animalia | \<1950    | 1011 |         723 |           0 |        723 |     288 |
| Animalia | 1950-2000 | 1024 |         715 |           0 |        715 |     309 |
| Animalia | \>=2000   |  414 |         279 |           0 |        279 |     135 |
| Plantae  | \<1950    | 1087 |         753 |           0 |        753 |     334 |
| Plantae  | 1950-2000 | 1004 |         709 |           0 |        709 |     295 |
| Plantae  | \>=2000   |  460 |         333 |           0 |        333 |     127 |

For a GBIF snapshot, point
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
at the `occurrence.parquet` directory and pass the taxon, year and
uncertainty columns through `keep`.
[`flagged_table()`](https://gillescolling.com/OccurrenceCleaner/reference/read_flagged.md)
opens the output as a vectra table for anything the tally does not
cover.
