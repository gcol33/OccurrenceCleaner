# Reference points of a proximity test

Returns the points a proximity test measures distance to: capitals,
country and province centroids, biodiversity institutions, the GBIF
headquarters, or the points of the Artificial Hotspot Occurrence
Inventory (Park et al. 2023). The table can be inspected, filtered or
extended and passed back through the `gazetteers` argument of
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

## Usage

``` r
reference_points(
  test = c("capital", "centroid", "institution", "gbif_headquarters", "aohi"),
  reference = c("natural_earth", "CoordinateCleaner")
)
```

## Arguments

- test:

  One of `"capital"`, `"centroid"`, `"institution"`,
  `"gbif_headquarters"`, `"aohi"`.

- reference:

  `"natural_earth"` (the package's own gazetteers) or
  `"CoordinateCleaner"` (that package's tables, which must be
  installed).

## Value

A data frame with columns `lon` and `lat` and, for the package's own
gazetteers, the attributes of each point: `name`, `country`, `adm0_a3`,
`iso_a2`, `class` for capitals; `name`, `adm0_a3`, `code`, `type`,
`method` for centroids; `key`, `code`, `name`, `country`, `city`,
`type`, `active`, `master_source`, `source` for institutions (`source`
is GRSciColl, Wikidata, GeoNames or BGCI, `key` the GRSciColl key,
Wikidata item, or the GeoNames or BGCI id with its prefix); `id`,
`taxon` (the group the hotspot was found in: Aves, Insecta, Mammalia,
Plantae), `frequency` (records at the point), `category`,
`determination` (TRUE for a real observation site, FALSE for an
artificial aggregate of records) and `notes` for the inventory. For
`reference = "CoordinateCleaner"` the columns are `lon` and `lat` only.

## Examples

``` r
head(reference_points("capital"))
table(reference_points("centroid")$type)
```
