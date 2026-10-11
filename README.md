# OccurrenceCleaner

*quality flags for occurrence records, at any scale*

[![R-CMD-check](https://github.com/gcol33/OccurrenceCleaner/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/gcol33/OccurrenceCleaner/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/gcol33/OccurrenceCleaner/graph/badge.svg)](https://app.codecov.io/gh/gcol33/OccurrenceCleaner)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

OccurrenceCleaner is an extension of [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) (Zizka et al. 2019) tailored to large-scale occurrence data. It flags common problems in species occurrence records: coordinates at country centroids, capitals or biodiversity institutions; zero or equal coordinates; records at sea, in the wrong country or outside the species range; duplicates; records far from the rest of their species; and datasets whose coordinates were converted from degrees and minutes or published on a grid.

It also reads three fields GBIF fills for each record: the quality warnings GBIF attaches during processing, the basis of record and the establishment means. Two more tests set the land test against the habitat of the record's genus, to find land genera at sea and marine genera on land.

Records are flagged and kept, and users choose afterwards which flags to filter on.

The input is any table of records with Darwin Core coordinate and species columns: a GBIF download (for example from [rgbif](https://docs.ropensci.org/rgbif/)), a fossil table from the Paleobiology Database (for example from [paleobioDB](https://cran.r-project.org/package=paleobioDB)), a whole GBIF snapshot, or another aggregator's export. Taxonomic name cleaning is not part of the package; names are matched beforehand, for example with [taxify](https://gillescolling.com/taxify/) or [taxize](https://docs.ropensci.org/taxize/). The kept records go on to species distribution models such as [dismo](https://cran.r-project.org/package=dismo) or [sdm](https://cran.r-project.org/package=sdm), to biogeographic analyses on phylogenies with [phytools](https://cran.r-project.org/package=phytools), to IUCN Red List assessments with [red](https://cran.r-project.org/package=red), or, for fossils, to PyRate through `export_pyrate()`.

The tests are reimplemented with CoordinateCleaner's definitions, default buffers and settings, and CoordinateCleaner itself is needed only to compare: the test suite runs it on sampled records and checks that both packages return the same flags; the few deliberate differences are listed in [Coming from CoordinateCleaner](https://gillescolling.com/OccurrenceCleaner/articles/coordinatecleaner.html).

Data frames containing a few million records are flagged in seconds ([timings](https://gillescolling.com/OccurrenceCleaner/articles/coordinatecleaner.html#speed)), and GBIF snapshots containing billions of records are processed by reading Parquet files in chunks.

## Installation

```r
# install.packages("pak")
pak::pak("gcol33/OccurrenceCleaner")
```

Needs a C++ compiler:

- Windows: install [Rtools](https://cran.r-project.org/bin/windows/Rtools/), the version matching your R.
- macOS: run `xcode-select --install` in a terminal.
- Linux: install R's development package, for example `sudo apt install r-base-dev` on Debian or Ubuntu.

`pkgbuild::has_build_tools(debug = TRUE)` checks that R finds the compiler.

## Flag a data frame

```r
library(OccurrenceCleaner)

x <- data.frame(species = c("Quercus robur", "Quercus robur", "Fagus sylvatica"),
                decimalLongitude = c(12.58, 0, 16.37),
                decimalLatitude = c(55.67, 0, 48.21))
flag_occurrences(x)
```

The result is `x` with one logical `flag_<test>` column per test and an integer `flags` column that holds all of them, one bit per test. The first record is within 1 km of the GBIF headquarters and 10 km of Copenhagen, the second is a zero coordinate at sea, the third is in Vienna, a capital.

## Several rules from one pass

A rule is a set of tests. `has_flag()` marks the records a rule removes, and `tally_flags()` compares several rules on the same flags:

```r
f <- flag_occurrences(x, tests = c("invalid", "zero", "equal", "capital", "centroid",
                                  "institution", "gbif_headquarters", "sea"))

strict <- c("zero", "equal", "capital", "centroid", "institution", "gbif_headquarters", "sea")
mild   <- c("zero", "equal", "gbif_headquarters")

has_flag(f$flags, strict)
tally_flags(f, by = "species", rules = list(strict = strict, mild = mild))
```

`tally_flags()` gives, per group, the number of records each test flags and the number each rule removes and keeps. Year and coordinate uncertainty stay raw columns and are cut at tally time with `bins`.

## Outliers and dataset tests

The outlier and dataset tests judge a record against the rest of its species or dataset, so they run in a pass over the whole input before the record tests, streamed input included. Their options go in `settings`, with [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)'s defaults:

```r
flag_occurrences(occ, tests = c("invalid", "outlier", "dataset_ddmm", "dataset_rounded"),
                 settings = list(outlier = list(method = "mad")))
```

Fossil records from the Paleobiology Database add an age test and the outlier tests of `clean_fossils()`, with the PBDB column names given once:

```r
flag_occurrences(pbdb, tests = c("invalid", "zero", "centroid", "institution", "age_equal",
                                 "age_range_outlier", "spatiotemporal_outlier"),
                 columns = occ_columns(lon = "lng", lat = "lat", species = "accepted_name"))
```

## A whole GBIF snapshot

The same verb streams an on-disk table through [vectra](https://gillescolling.com/vectra/): a directory of Parquet parts (a GBIF snapshot), a `.vtr` file, a delimited file or any `vectra_node`. Each input file is one resumable unit, and the flags are written as `.vtr` parts next to the columns you keep for grouping:

```r
f <- flag_occurrences("gbif_snapshot/occurrence.parquet",
                      tests = c(default_tests(), "country_mismatch", "issue_rounded",
                                "basis_fossil"),
                      out = "flags",
                      keep = c("kingdom", "year", "coordinateuncertaintyinmeters"))

tally_flags(f, by = "kingdom",
            bins = list(year = c(1950, 1970, 1990, 2000),
                        coordinateuncertaintyinmeters = c(10, 100, 1000)),
            rules = list(cc = c("zero", "equal", "capital", "centroid", "institution",
                                "gbif_headquarters", "sea")))
```

Rerunning the same call after an interruption skips the input files already finished.

## What's in the box

- **`flag_occurrences()`**: the one flagging verb. Data frame in, data frame out; path or `vectra_node` in, flag parts on disk out. `buffers` sets the proximity distances and `settings` the options of the outlier and dataset tests, both with [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)'s defaults.
- **`tally_flags()`**: per group, the number of records each test flags and each rule removes and keeps, with bins and named rules.
- **`summary()`**, **`plot()`**: the percentage of records each test and rule removes, and how much of it each test is the sole reason for; bars, a grid by group, or a map of kept and removed records.
- **`has_flag()`**, **`flag_mask()`**: which records a rule removes, read from the `flags` column.
- **`as_spatialvalid()`**: the flags in the layout of CoordinateCleaner's `spatialvalid` object, for code written for it.
- **`flag_tests()`**: which bit of `flags` holds which test, with its definition, source and CoordinateCleaner equivalent; versioned.
- **`default_tests()`**: the CoordinateCleaner-equivalent tests that need only coordinates and a species name.
- **`occ_columns()`**: which columns hold which field (coordinates, species, genus and kingdom, country code, fossil ages, dataset key, GBIF fields); Darwin Core defaults, case-insensitive.
- **`reference_info()`**, **`download_reference()`**: the pinned gazetteers (source, version, SHA-256) and the on-demand 1:10m land layer.
- **`reference_points()`**: the points a proximity test uses (capitals, centroids, institutions, GBIF headquarters, artificial hotspots), to inspect, filter or extend and pass back through `gazetteers`.
- **`reference_habitat()`**: the genera the habitat tests know, marine or not, from the Interim Register of Marine and Nonmarine Genera.
- **`read_flagged()`**, **`flagged_table()`**: open on-disk flag output as a [vectra](https://gillescolling.com/vectra/) table.
- **`export_pyrate()`**: write fossil records as PyRate input files.

## Tests

| test | definition | source |
|---|---|---|
| `invalid` | coordinate missing or out of range | `cc_val` |
| `zero` | zero longitude or latitude, or within 0.5 degrees of (0, 0) | `cc_zero` |
| `equal` | absolute longitude equals absolute latitude | `cc_equ` |
| `capital` | within 10 km of a capital | `cc_cap` |
| `centroid` | within 1 km of a country or province centroid | `cc_cen` |
| `institution` | within 100 m of a biodiversity institution | `cc_inst` |
| `gbif_headquarters` | within 1 km of the GBIF headquarters | `cc_gbif` |
| `sea` | outside the land polygons (Natural Earth, scale 110, 50 or 10) | `cc_sea` |
| `urban` | inside an urban area | `cc_urb` |
| `country_mismatch` | outside the country given by the record's country code | `cc_coun` |
| `duplicate` | same coordinates and species as an earlier record | `cc_dupl` |
| `range` | outside every range polygon of its species (user-supplied ranges) | `cc_iucn` |
| `aohi` | within 10 km of an artificial hotspot (Park et al. 2023) | `cc_aohi` |
| `outlier` | far from the other records of its species | `cc_outl` |
| `dataset_ddmm` | in a dataset whose coordinates look converted from degrees and minutes | `cd_ddmm` |
| `dataset_rounded` | in a dataset whose coordinates lie on a regular grid | `cd_round` |
| `age_equal` | fossil minimum age equal to or greater than the maximum age | `cf_equal` |
| `age_outlier` | fossil age far from the ages of its taxon | `cf_age` |
| `spatiotemporal_outlier` | fossil far from its taxon in space and time | `cf_outl` |
| `age_range_outlier` | fossil age range unusually wide | `cf_range` |
| `issue_coordinate`, `issue_taxon`, `issue_date`, `issue_rounded` | GBIF quality warnings (`issue` field) on coordinates, taxon match, date, rounding | addition |
| `basis_fossil`, `basis_living` | basis of record | addition |
| `establishment_introduced`, `establishment_managed` | establishment means | addition |
| `sea_nonmarine` | outside the land polygons, genus not marine (IRMNG) | addition |
| `land_marine` | inside the land polygons, genus only marine (IRMNG) | addition |

Proximity tests are closed balls in WGS84 geodesic distance, found with a kd-tree on the unit sphere and decided with the Vincenty inverse formula. Polygon tests are planar point-in-polygon against pinned Natural Earth layers through a grid index that resolves boundary cells exactly.

The gazetteers are rebuilt from the original public sources (Natural Earth, public domain; the CIA World Factbook, public domain, for capitals and country centroids; the World Borders Dataset by Bjorn Sandvik, thematicmapping.org, CC BY-SA, and the GEOLocate service for country centroids; GBIF GRSciColl, Wikidata, Wikipedia's lists of natural history museums, GeoNames and BGCI GardenSearch for institutions; the Interim Register of Marine and Nonmarine Genera, CC BY 4.0, for genus habitats), each pinned to a version and checksum. Points from sources CoordinateCleaner's tables do not draw on (Natural Earth capitals and country centroids, Wikidata institutions beyond the museums of the English Wikipedia list, the museums of the non-English Wikipedia lists) are marked `extension` and used by default; the rows without the mark restrict a test to CoordinateCleaner's sources. `reference = "CoordinateCleaner"` reads that package's own tables instead and gives its flags up to the documented differences, which `?flag_occurrences` lists and the test suite enforces. The `gazetteers` argument replaces the layer of single tests with the user's own points or polygons, recorded with the flags by size and checksum.

## Documentation

- [Quick Start](https://gillescolling.com/OccurrenceCleaner/articles/quickstart.html)
- [Cleaning GBIF data](https://gillescolling.com/OccurrenceCleaner/articles/gbif-workflow.html)
- [Choosing a cleaning rule](https://gillescolling.com/OccurrenceCleaner/articles/rules.html)
- [Large tables on disk](https://gillescolling.com/OccurrenceCleaner/articles/on-disk.html)
- [The tests in detail](https://gillescolling.com/OccurrenceCleaner/articles/tests.html)
- [Outliers and dataset tests](https://gillescolling.com/OccurrenceCleaner/articles/outliers.html)
- [Cleaning fossil records](https://gillescolling.com/OccurrenceCleaner/articles/fossils.html)
- [Reference data](https://gillescolling.com/OccurrenceCleaner/articles/reference-data.html)
- [Using custom gazetteers](https://gillescolling.com/OccurrenceCleaner/articles/gazetteers.html)
- [Coming from CoordinateCleaner](https://gillescolling.com/OccurrenceCleaner/articles/coordinatecleaner.html)
- [Full Reference](https://gillescolling.com/OccurrenceCleaner/reference/)

## Contributing

Bug reports and pull requests are welcome; see the [contributing guide](https://gillescolling.com/OccurrenceCleaner/CONTRIBUTING.html).

## Support

> "Software is like sex: it's better when it's free." — Linus Torvalds

I'm a PhD student who builds R packages in my free time because I believe good tools should be free and open. I started these projects for my own work and figured others might find them useful too.

If this package saved you some time, buying me a coffee is a nice way to say thanks. It helps with my coffee addiction.

[![Buy Me A Coffee](https://img.shields.io/badge/-Buy%20me%20a%20coffee-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/gcol33)

## Acknowledgements

The tests, their default buffers and the options of the outlier and dataset tests come from [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) by Alexander Zizka and co-authors (Zizka et al. 2019), an rOpenSci package. Its documented definitions are what the equivalence tests check against, and the gazetteers here are rebuilt from the public sources it draws on.

## License

MIT. [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) (GPL-3) is a suggested package used by the equivalence tests and by `reference = "CoordinateCleaner"`; none of its code or data is bundled. The country centroid points from the World Borders Dataset (Bjorn Sandvik, thematicmapping.org) are under CC BY-SA.

## Citation

```bibtex
@software{OccurrenceCleaner,
  author = {Colling, Gilles},
  title = {OccurrenceCleaner: Fast Quality Flags for Species Occurrence Records at Any Scale},
  year = {2026},
  url = {https://github.com/gcol33/OccurrenceCleaner}
}
```

The tests and their defaults follow CoordinateCleaner; please cite it as well:

```bibtex
@article{CoordinateCleaner,
  author = {Zizka, Alexander and Silvestro, Daniele and Andermann, Tobias and Azevedo, Josue and Duarte Ritter, Camila and Edler, Daniel and Farooq, Harith and Herdean, Andrei and Ariza, Maria and Scharn, Ruud and Svantesson, Sten and Wengstrom, Niklas and Zizka, Vera and Antonelli, Alexandre},
  title = {CoordinateCleaner: Standardized cleaning of occurrence records from biological collection databases},
  journal = {Methods in Ecology and Evolution},
  year = {2019},
  volume = {10},
  pages = {744--751},
  doi = {10.1111/2041-210X.13152}
}
```
