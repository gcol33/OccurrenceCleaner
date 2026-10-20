# Reference data: sources and versions

Every gazetteer the package uses is pinned to a source file, a version
and a retrieval date, and the flag output records which reference
produced it.

## Usage

``` r
reference_info()
```

## Value

A data frame with one row per layer: `layer`, `source`, `file`,
`version`, `url`, `sha256`, `retrieved`, `licence`.

## Details

With `reference = "OccurrenceCleaner"` (the default of
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md))
the package uses its own gazetteers built in `data-raw/`: capitals from
the CIA World Factbook and Natural Earth, province centroids, land,
urban areas and country polygons from Natural Earth (public domain),
country centroids from the CIA World Factbook, the thematicmapping.org
World Borders Dataset and the GEOLocate service, and biodiversity
institutions from
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)'s
table, with the points Google Maps places elsewhere moved, plus points
from GBIF's Global Registry of Scientific Collections (GRSciColl),
Wikidata, Wikipedia, GeoNames, BGCI GardenSearch, Index Herbariorum, the
GBIF registry and OpenStreetMap that a check beyond their source
confirms (see
[test_institution](https://gillescolling.com/OccurrenceCleaner/reference/test_institution.md)).
With `reference = "CoordinateCleaner"` the point gazetteers are read
from the user's
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)
installation (`countryref`, `institutions`) and the polygon layers are
downloaded through
[rnaturalearth](https://docs.ropensci.org/rnaturalearth/) exactly as
that package does, which gives its flags up to the differences
documented in
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

## Examples

``` r
reference_info()
```
