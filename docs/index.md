# OccurrenceCleaner

*quality flags for occurrence records, at any scale*

[![R-CMD-check](https://github.com/gcol33/OccurrenceCleaner/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/gcol33/OccurrenceCleaner/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/gcol33/OccurrenceCleaner/graph/badge.svg)](https://app.codecov.io/gh/gcol33/OccurrenceCleaner)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**The CoordinateCleaner record tests, computed as nearest-neighbour and
point-in-polygon queries in C++, streamed from disk.**

OccurrenceCleaner flags the usual errors in species occurrence records:
coordinates at country centroids, capitals or biodiversity institutions,
zeros and swapped axes, records at sea or in the wrong country,
duplicates, and the GBIF issue, basis-of-record and establishment
fields. Every test writes one bit per record and nothing is dropped, so
a cleaning rule is a query over the flags chosen afterwards. The tests
and default buffers are those of
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)
(Zizka et al. 2019), checked record by record against it in the test
suite; the difference is that a data frame of a few million records is
flagged in seconds, and a GBIF snapshot of billions of records is
streamed from Parquet in chunks.

``` r

library(OccurrenceCleaner)

x <- data.frame(species = c("Quercus robur", "Quercus robur", "Fagus sylvatica"),
                decimalLongitude = c(12.58, 0, 16.37),
                decimalLatitude = c(55.67, 0, 48.21))
flag_occurrences(x)
```

The result is `x` with an integer `flags` column and one logical
`flag_<test>` column per test. The first record is within 1 km of the
GBIF headquarters and 10 km of Copenhagen, the second is a zero
coordinate at sea, the third is in Vienna, a capital.

## Flagged, not dropped

CoordinateCleaner’s `clean_coordinates()` returns a cleaned table, one
rule applied. OccurrenceCleaner returns every record with its flags, so
several rules are compared on the same pass:

``` r

f <- flag_occurrences(x, tests = c("val", "zero", "equ", "cap", "cen", "inst", "gbif", "sea"))

strict <- has_flag(f$flags, c("zero", "equ", "cap", "cen", "inst", "gbif", "sea"))
mild   <- has_flag(f$flags, c("zero", "equ", "gbif"))

tally_flags(f, by = "species",
            rules = list(strict = c("zero", "equ", "cap", "cen", "inst", "gbif", "sea"),
                         mild = c("zero", "equ", "gbif")))
```

[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
gives, per group, the number of records each test flags and the number
each rule removes and keeps. Year and coordinate uncertainty stay raw
columns and are cut at tally time with `bins`.

## A whole GBIF snapshot

The same verb streams an on-disk table through
[vectra](https://cran.r-project.org/package=vectra): a directory of
Parquet parts (a GBIF snapshot), a `.vtr` file, a delimited file or any
`vectra_node`. Each input file is one resumable unit, and the flags are
written as `.vtr` parts next to the columns you keep for grouping:

``` r

f <- flag_occurrences("gbif_snapshot/occurrence.parquet",
                      tests = c(default_tests(), "coun", "rounded", "fossil"),
                      out = "flags",
                      keep = c("kingdom", "year", "coordinateuncertaintyinmeters"))

tally_flags(f, by = "kingdom",
            bins = list(year = c(1950, 1970, 1990, 2000),
                        coordinateuncertaintyinmeters = c(10, 100, 1000)),
            rules = list(cc = c("zero", "equ", "cap", "cen", "inst", "gbif", "sea")))
```

An interrupted run is restarted with the same call; finished parts are
skipped.

## What’s in the box

- **[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)**:
  the one flagging verb. Data frame in, data frame out; path or
  `vectra_node` in, flag parts on disk out.
- **[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)**:
  flags to a loss table by any grouping columns, with bins and named
  rules.
- **[`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md)**,
  **[`flag_mask()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md)**:
  a rule as a bit mask over the flag word.
- **[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)**:
  the versioned flag layout: bit, test, definition, source,
  CoordinateCleaner equivalent.
- **[`default_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/default_tests.md)**:
  the CoordinateCleaner-equivalent tests that need only coordinates and
  a species name.
- **[`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md)**:
  which columns hold which field; Darwin Core defaults,
  case-insensitive.
- **[`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md)**,
  **[`download_reference()`](https://gillescolling.com/OccurrenceCleaner/reference/download_reference.md)**:
  the pinned gazetteers (source, version, SHA-256) and the on-demand
  1:10m land layer.
- **[`read_flagged()`](https://gillescolling.com/OccurrenceCleaner/reference/read_flagged.md)**,
  **[`flagged_table()`](https://gillescolling.com/OccurrenceCleaner/reference/read_flagged.md)**:
  open on-disk flag output as a vectra table.

## Tests

| test | definition | source |
|----|----|----|
| `val` | coordinate missing or out of range | `cc_val` |
| `zero` | zero longitude or latitude, or within 0.5 degrees of (0, 0) | `cc_zero` |
| `equ` | absolute longitude equals absolute latitude | `cc_equ` |
| `cap` | within 10 km of a capital | `cc_cap` |
| `cen` | within 1 km of a country or province centroid | `cc_cen` |
| `inst` | within 100 m of a biodiversity institution | `cc_inst` |
| `gbif` | within 1 km of the GBIF headquarters | `cc_gbif` |
| `sea` | outside the land polygons (Natural Earth, scale 110, 50 or 10) | `cc_sea` |
| `urb` | inside an urban area | `cc_urb` |
| `coun` | outside the country given by the record’s country code | `cc_coun` |
| `dupl` | same coordinates and species as an earlier record | `cc_dupl` |
| `issue_geo`, `issue_tax`, `issue_date`, `rounded` | GBIF issue flags by group | addition |
| `fossil`, `living` | basis of record | addition |
| `introduced`, `managed` | establishment means | addition |

Proximity tests are closed balls in WGS84 geodesic distance, found with
a kd-tree on the unit sphere and decided with the Vincenty inverse
formula. Polygon tests are planar point-in-polygon against pinned
Natural Earth layers through a grid index that resolves boundary cells
exactly. The gazetteers are rebuilt from the original public sources
(Natural Earth, public domain; GBIF GRSciColl for institutions);
`reference = "CoordinateCleaner"` reads that package’s own tables
instead and reproduces its flags. The documented differences, each
enforced by a test, are in
[`?flag_occurrences`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

## Installation

``` r

# install.packages("pak")
pak::pak("gcol33/OccurrenceCleaner")
```

Needs a C++ compiler (Rtools on Windows).

## Documentation

- [Quick
  Start](https://gillescolling.com/OccurrenceCleaner/articles/quickstart.html)
- [Full
  Reference](https://gillescolling.com/OccurrenceCleaner/reference/)

## Support

> “Software is like sex: it’s better when it’s free.” — Linus Torvalds

I’m a PhD student who builds R packages in my free time because I
believe good tools should be free and open. I started these projects for
my own work and figured others might find them useful too.

If this package saved you some time, buying me a coffee is a nice way to
say thanks. It helps with my coffee addiction.

[![Buy Me A
Coffee](https://img.shields.io/badge/-Buy%20me%20a%20coffee-FFDD00?logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/gcol33)

## License

MIT. CoordinateCleaner (GPL-3) is a suggested package used by the
equivalence tests and by `reference = "CoordinateCleaner"`; none of its
code or data is bundled.

Bundled reference data: Natural Earth layers (public domain,
naturalearthdata.com) and the institution gazetteer from GBIF’s Global
Registry of Scientific Collections (GRSciColl), exported from
`https://api.gbif.org/v1/grscicoll/institution/export` on 2026-10-09.
GBIF states no separate licence for GRSciColl records; under its data
user agreement, GBIF seeks to make data it develops “freely and openly
available, with the least possible restrictions on reuse”. Source,
version and checksum of every layer are listed by
[`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md).

## Citation

``` bibtex
@software{OccurrenceCleaner,
  author = {Colling, Gilles},
  title = {OccurrenceCleaner: Fast Quality Flags for Species Occurrence Records at Any Scale},
  year = {2026},
  url = {https://github.com/gcol33/OccurrenceCleaner}
}
```

Please also cite the tests’ origin: Zizka A, Silvestro D, Andermann T,
et al. (2019) CoordinateCleaner: standardized cleaning of occurrence
records from biological collection databases. *Methods in Ecology and
Evolution* 10:744-751. <doi:10.1111/2041-210X.13152>
