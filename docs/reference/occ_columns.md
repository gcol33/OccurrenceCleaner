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
  the `coun` test.

- issue:

  GBIF issue flags, either a character column with the issue names
  separated by `;` (as the GBIF snapshot read through vectra gives) or a
  list column of character vectors.

- basis:

  Basis of record (`basisOfRecord`).

- establishment:

  Establishment means (`establishmentMeans`).

- id:

  Record identifier, copied into on-disk flag output when present.

## Value

A named list of column names with class `occ_columns`.

## Examples

``` r
occ_columns(lon = "x", lat = "y")
```
