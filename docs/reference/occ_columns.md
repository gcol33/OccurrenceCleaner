# Name the record fields

Tells
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
which columns of the input hold each field. The defaults are the Darwin
Core terms GBIF uses; matching is case-insensitive, so GBIF's lower-case
snapshot columns (`decimallongitude`, ...) are found by the defaults
too. Fields are resolved only when a requested test needs them.

## Usage

``` r
occ_columns(
  lon = "decimalLongitude",
  lat = "decimalLatitude",
  species = "species",
  country = "countryCode",
  issue = "issue",
  basis = "basisOfRecord",
  establishment = "establishmentMeans",
  min_age = "min_ma",
  max_age = "max_ma",
  dataset = "datasetKey",
  genus = "genus",
  kingdom = "kingdom",
  id = "gbifID"
)
```

## Arguments

- lon, lat:

  Longitude and latitude in decimal degrees.

- species:

  Taxon name or key used by the duplicate test.

- country:

  Country code of the record (ISO 3166-1 alpha-2 or alpha-3), used by
  the `country_mismatch` test.

- issue:

  GBIF issue flags, either a character column with the issue names
  separated by `;` (as the GBIF snapshot read through
  [vectra](https://gillescolling.com/vectra/) gives) or a list column of
  character vectors.

- basis:

  Basis of record (`basisOfRecord`).

- establishment:

  Establishment means (`establishmentMeans`).

- min_age, max_age:

  Minimum and maximum age of a fossil record, in million years, as the
  Paleobiology Database's `min_ma` and `max_ma`.

- dataset:

  Dataset the record belongs to, for the dataset-level tests
  (`datasetKey` in GBIF data).

- genus:

  Genus of the record, for the habitat tests `sea_nonmarine` and
  `land_marine`. The first word is taken, so a binomial species column
  (`occ_columns(genus = "species")`) works as well as a genus column.

- kingdom:

  Kingdom of the record, read by the habitat tests when the column is
  present, to tell apart genus names used in two kingdoms.

- id:

  Record identifier, copied into on-disk flag output when present.

## Value

A named list of column names with class `occ_columns`.

## Examples

``` r
occ_columns(lon = "x", lat = "y")
```
