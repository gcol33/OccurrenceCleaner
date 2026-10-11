# Quick start

OccurrenceCleaner is an extension of CoordinateCleaner (Zizka et
al. [2019](https://doi.org/10.1111/2041-210X.13152)) tailored to
large-scale occurrence data. It flags errors in species occurrence
records and keeps every record. Each test sets one bit in an integer
flag word, so deciding which records to drop is a query over the flags,
made after the pass and changed without rerunning it.

## Installation

``` r

# install.packages("pak")
pak::pak("gcol33/OccurrenceCleaner")
```

Needs a C++ compiler (Rtools on Windows).

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
f <- flag_occurrences(x, tests = c("invalid", "zero", "capital", "gbif_headquarters", "sea",
                                  "country_mismatch", "duplicate"))
knitr::kable(f[, c("species", "flags", "flag_zero", "flag_capital", "flag_gbif_headquarters",
                   "flag_sea", "flag_country_mismatch", "flag_duplicate")])
```

| species | flags | flag_zero | flag_capital | flag_gbif_headquarters | flag_sea | flag_country_mismatch | flag_duplicate |
|:---|---:|:---|:---|:---|:---|:---|:---|
| Quercus robur | 584 | FALSE | TRUE | TRUE | FALSE | TRUE | FALSE |
| Quercus robur | 642 | TRUE | FALSE | FALSE | TRUE | TRUE | FALSE |
| Fagus sylvatica | 8 | FALSE | TRUE | FALSE | FALSE | FALSE | FALSE |
| Fagus sylvatica | 1032 | FALSE | TRUE | FALSE | FALSE | FALSE | TRUE |
| Pinus nigra | 640 | FALSE | FALSE | FALSE | TRUE | TRUE | FALSE |

The first record is within 1 km of the GBIF headquarters in Copenhagen,
hence also within 10 km of a capital; it also fails `country_mismatch`,
because that point lies just off the 1:50m Natural Earth coastline of
Denmark. The second is a zero coordinate at sea with no country code.
The third and fourth are the same species at the same place in Vienna,
so the fourth is a duplicate; both are in a capital. The fifth is in the
Atlantic with a French country code.

## The tests

``` r

knitr::kable(flag_tests()[, c("bit", "test", "definition", "equivalent")])
```

| bit | test | definition | equivalent |
|---:|:---|:---|:---|
| 0 | invalid | coordinate missing, not numeric or outside \[-180, 180\] x \[-90, 90\] | cc_val |
| 1 | zero | longitude or latitude exactly zero, or within 0.5 degrees of (0, 0) | cc_zero |
| 2 | equal | absolute longitude equal to absolute latitude | cc_equ |
| 3 | capital | within 10 km of a country capital | cc_cap |
| 4 | centroid | within 1 km of a country or province centroid | cc_cen |
| 5 | institution | within 100 m of a biodiversity institution | cc_inst |
| 6 | gbif_headquarters | within 1 km of the GBIF headquarters (12.58 E, 55.67 N) | cc_gbif |
| 7 | sea | outside the land polygons | cc_sea |
| 8 | urban | inside an urban-area polygon | cc_urb |
| 9 | country_mismatch | coordinates fall outside the country given by the record’s country code | cc_coun |
| 10 | duplicate | same coordinates and species as an earlier record | cc_dupl |
| 11 | issue_coordinate | a GBIF georeferencing issue is present | NA |
| 12 | issue_taxon | GBIF matched the taxon fuzzily or to a higher rank | NA |
| 13 | issue_date | GBIF found the recorded date invalid or unlikely | NA |
| 14 | issue_rounded | GBIF rounded the coordinates (COORDINATE_ROUNDED) | NA |
| 15 | basis_fossil | basis of record is a fossil specimen | NA |
| 16 | basis_living | basis of record is a living specimen | NA |
| 17 | establishment_introduced | establishment means is introduced, naturalised or invasive | NA |
| 18 | establishment_managed | establishment means is managed or cultivated | NA |
| 19 | age_equal | minimum age equal to or greater than the maximum age | cf_equal |
| 20 | outlier | geographic outlier among the records of its species | cc_outl |
| 21 | age_outlier | age outlier among the records of its taxon | cf_age |
| 22 | spatiotemporal_outlier | outlier in space and time among the records of its taxon | cf_outl |
| 23 | age_range_outlier | age range wider than that of the other records of its taxon | cf_range |
| 24 | dataset_ddmm | in a dataset with a degree-minute to decimal conversion error | cd_ddmm |
| 25 | dataset_rounded | in a dataset whose coordinates lie on a regular grid | cd_round |
| 26 | range | outside the range polygons of its species | cc_iucn |
| 27 | aohi | within 10 km of an Artificial Hotspot Occurrence Inventory point | cc_aohi |
| 28 | sea_nonmarine | outside the land polygons, and the genus does not live in the sea | NA |
| 29 | land_marine | inside the land polygons, and the genus lives only in the sea | NA |

The tests with an `equivalent` are CoordinateCleaner’s record tests with
its default buffers, up to the differences listed in the article Coming
from CoordinateCleaner; the others read GBIF’s `issue`, `basisOfRecord`
and `establishmentMeans` fields.
[`default_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/default_tests.md)
names the tests that need only coordinates and a species.

## Rules are queries over the flags

A rule is a set of tests.
[`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md)
marks the records any of them flags:

``` r

strict <- c("zero", "capital", "gbif_headquarters", "sea", "duplicate")
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
knitr::kable(t[, c("species", "n", "flagged_capital", "flagged_sea", "flagged_duplicate",
                   "removed_strict", "removed_mild")])
```

| species | n | flagged_capital | flagged_sea | flagged_duplicate | removed_strict | removed_mild |
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

flag_occurrences(x[3, ], tests = "capital")$flag_capital
#> [1] TRUE
flag_occurrences(x[3, ], tests = "capital", buffers = list(capital = 500))$flag_capital
#> [1] FALSE
```

The gazetteers are rebuilt from Natural Earth and GBIF’s registry of
scientific collections, each pinned to a version and checksum:

``` r

knitr::kable(reference_info()[, c("layer", "source", "version", "retrieved")])
```

| layer | source | version | retrieved |
|:---|:---|:---|:---|
| land_110 | Natural Earth | 4.1.0 | 2026-10-09 |
| land_50 | Natural Earth | 4.1.0 | 2026-10-09 |
| land_10 | Natural Earth | 5.1.1 | 2026-10-09 |
| countries_50 | Natural Earth | 5.1.1 | 2026-10-09 |
| urban_50 | Natural Earth | 4.1.0 | 2026-10-09 |
| places_10 | Natural Earth | 5.1.2 | 2026-10-09 |
| admin0_10 | Natural Earth | 5.1.1 | 2026-10-09 |
| admin1_10 | Natural Earth | 5.1.1 | 2026-10-09 |
| factbook | CIA World Factbook (factbook.json) | factbook.json 144d6977b2b01ac1cbd220de754c0a005616760b | 2026-10-11 |
| world_borders | thematicmapping.org World Borders Dataset | 0.3 (2008-07-30) | 2026-10-11 |
| geolocate | GEOLocate web service | 2026-10-11 | 2026-10-11 |
| institutions | GBIF GRSciColl | 2026-10-09 | 2026-10-09 |
| institutions_wikidata | Wikidata | 2026-10-10 | 2026-10-10 |
| institutions_wikipedia | Wikipedia, lists of natural history museums | en revision 1376233148; de revision 267938927; fr revision 240149609; nl revision 69876533; pt revision 71307420; ar revision 76691072; eo revision 9165115 | 2026-10-11 |
| institutions_geonames | GeoNames | 2026-10-10 | 2026-10-10 |
| institutions_bgci | BGCI GardenSearch | 2026-10-10 | 2026-10-10 |
| aohi | Park et al. 2023, AHOI (Dryad <doi:10.5061/dryad.v41ns1s0p>) | 2022-10-10 | 2026-10-10 |
| habitat | IRMNG, Rees, T. (compiler) (2026). The Interim Register of Marine and Nonmarine Genera | 2026-10-06 | 2026-10-10 |

`reference = "CoordinateCleaner"` uses that package’s own tables
instead, which gives its flags up to the same differences
(CoordinateCleaner must be installed). The land layer for the `sea` test
comes at Natural Earth scale 110 (the default of CoordinateCleaner’s
[`cc_sea()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_sea.html);
its
[`clean_coordinates()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_coordinates.html)
uses 50), 50, or 10; the 1:10m layer is downloaded once on first use.

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
#>   out:       C:\Users\Gilles Colling\AppData\Local\Temp\RtmpiAte4y\flags1b8050b468c2
#>   tests:     invalid, zero, equal, capital, centroid, institution, gbif_headquarters, sea, duplicate
#>   layout:    v4
#>   reference: natural_earth (land 110; land_110 4.1.0, land_50 4.1.0, land_10 5.1.1, countries_50 5.1.1, urban_50 4.1.0, places_10 5.1.2, admin0_10 5.1.1, admin1_10 5.1.1, factbook factbook.json 144d6977b2b01ac1cbd220de754c0a005616760b, world_borders 0.3 (2008-07-30), geolocate 2026-10-11, institutions 2026-10-09, institutions_wikidata 2026-10-10, institutions_wikipedia en revision 1376233148; de revision 267938927; fr revision 240149609; nl revision 69876533; pt revision 71307420; ar revision 76691072; eo revision 9165115, institutions_geonames 2026-10-10, institutions_bgci 2026-10-10, aohi 2022-10-10, habitat 2026-10-06)
#>   keep:      kingdom, year
t <- tally_flags(out, by = "kingdom", bins = list(year = c(1950, 2000)),
                 rules = list(cc = c("zero", "equal", "capital", "centroid", "institution",
                                     "gbif_headquarters", "sea")))
knitr::kable(t[, c("kingdom", "year_bin", "n", "flagged_sea", "flagged_capital", "removed_cc", "kept_cc")])
```

| kingdom  | year_bin  |    n | flagged_sea | flagged_capital | removed_cc | kept_cc |
|:---------|:----------|-----:|------------:|----------------:|-----------:|--------:|
| Animalia | \<1950    | 1011 |         723 |               0 |        723 |     288 |
| Animalia | 1950-2000 | 1024 |         715 |               0 |        715 |     309 |
| Animalia | \>=2000   |  414 |         279 |               0 |        279 |     135 |
| Plantae  | \<1950    | 1087 |         753 |               0 |        753 |     334 |
| Plantae  | 1950-2000 | 1004 |         709 |               0 |        709 |     295 |
| Plantae  | \>=2000   |  460 |         333 |               0 |        333 |     127 |

For a GBIF snapshot, point
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
at the `occurrence.parquet` directory and pass the taxon, year and
uncertainty columns through `keep`.
[`flagged_table()`](https://gillescolling.com/OccurrenceCleaner/reference/read_flagged.md)
opens the output as a vectra table for anything the tally does not
cover.
