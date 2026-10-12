# GBIF records of gentians in Austria

The occurrence records of the genus *Gentiana* that GBIF holds with the
country code `AT` (Austria) and a CC0 1.0 or CC BY 4.0 licence, taken
from the GBIF snapshot of 1 October 2026. Specimens from herbaria and
observations from surveys and citizen science, from the 18th century to
2026, with their coordinates, stated coordinate uncertainty and the
fields GBIF fills during processing. Column names are those of the GBIF
snapshot;
[`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md)
matches them without renaming.

## Usage

``` r
gentiana
```

## Format

A data frame with 33,025 rows and 15 columns:

- gbifid:

  GBIF record identifier.

- datasetkey:

  GBIF dataset identifier; each record's licence and citation are those
  of its dataset.

- kingdom, genus, species:

  Taxon, as matched by GBIF.

- countrycode:

  ISO 3166-1 alpha-2 country code.

- decimallongitude, decimallatitude:

  Coordinates in decimal degrees, `NA` where the record has none.

- coordinateuncertaintyinmeters:

  Stated coordinate uncertainty in metres.

- year:

  Year the record was collected or observed.

- basisofrecord:

  Darwin Core basis of record, for example `PRESERVED_SPECIMEN` or
  `HUMAN_OBSERVATION`.

- institutioncode:

  Code of the institution holding the record.

- establishmentmeans:

  Darwin Core establishment means.

- issue:

  GBIF issue names, separated by `;`.

- license:

  Licence of the record: `CC0_1_0` or `CC_BY_4_0`.

## Source

GBIF.org (1 October 2026) GBIF Occurrence Download
[doi:10.15468/dl.tup2g6](https://doi.org/10.15468/dl.tup2g6) . Records
under CC BY 4.0 are attributed to their datasets, identified by
`datasetkey` (`https://www.gbif.org/dataset/<datasetkey>`).

## Examples

``` r
f <- flag_occurrences(gentiana, tests = c("invalid", "capital", "centroid", "institution"),
                      columns = occ_columns(id = "gbifid"))
summary(f, by = "basisofrecord")
```
