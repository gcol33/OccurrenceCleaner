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
  reference = c("OccurrenceCleaner", "CoordinateCleaner")
)
```

## Arguments

- test:

  One of `"capital"`, `"centroid"`, `"institution"`,
  `"gbif_headquarters"`, `"aohi"`.

- reference:

  `"OccurrenceCleaner"` (the package's own gazetteers) or
  `"CoordinateCleaner"` (that package's tables, which must be
  installed).

## Value

A data frame with columns `lon` and `lat` and, for the package's own
gazetteers, the attributes of each point: `name`, `country`, `adm0_a3`,
`iso_a2`, `class`, `source`, `key`, `extension` for capitals (`source`
is CIA World Factbook or Natural Earth, `key` the Factbook code or the
Natural Earth country code and name with its prefix); `name`, `adm0_a3`,
`code`, `type`, `method`, `source`, `key`, `extension` for centroids
(`source` is CIA World Factbook, thematicmapping, GEOLocate or Natural
Earth, `key` the Factbook code, ISO3 code or GEOLocate query with its
prefix); `key`, `code`, `name`, `country`, `city`, `type`, `active`,
`master_source`, `source`, `extension`, `status`, `evidence`, `cc_lon`,
`cc_lat` for institutions (`source` is CoordinateCleaner, Google Maps,
GRSciColl, Wikidata, Wikipedia, GeoNames, BGCI, Index Herbariorum, GBIF
registry or CoordinateCleaner list, `key` the row of CoordinateCleaner's
table, the GRSciColl key, Wikidata item, the Wikipedia list language,
revision and line, or the GeoNames, BGCI, Index Herbariorum, GBIF
organisation or OpenStreetMap id with its prefix; for Wikipedia rows
`city` is the place they are located by; for Wikipedia and
CoordinateCleaner list rows `master_source` is where the coordinates
come from, for CoordinateCleaner rows its geocoding source; `status` is
`"cc"`, `"override"`, `"confirmed"` or `"unconfirmed"` (see
[test_institution](https://gillescolling.com/OccurrenceCleaner/reference/test_institution.md)),
`evidence` the check behind an override or a confirmed point, `cc_lon`
and `cc_lat` CoordinateCleaner's coordinates of an overridden point;
`extension` is TRUE for points from sources
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)'s
table does not draw on, for capitals, centroids and institutions alike);
`id`, `taxon` (the group the hotspot was found in: Aves, Insecta,
Mammalia, Plantae), `frequency` (records at the point), `category`,
`determination` (TRUE for a real observation site, FALSE for an
artificial aggregate of records) and `notes` for the inventory. For
`reference = "CoordinateCleaner"` the columns are `lon` and `lat` only.

## Examples

``` r
head(reference_points("capital"))
table(reference_points("centroid")$type)
```
