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

With `reference = "natural_earth"` (the default of
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md))
the package uses its own gazetteers built in `data-raw/`: capitals,
country and province centroids, land, urban areas and country polygons
from Natural Earth (public domain), and biodiversity institutions from
GBIF's Global Registry of Scientific Collections (GRSciColl), Wikidata,
GeoNames and BGCI GardenSearch. With `reference = "CoordinateCleaner"`
the point gazetteers are read from the user's CoordinateCleaner
installation (`countryref`, `institutions`) and the polygon layers are
downloaded through rnaturalearth exactly as that package does, which
gives its flags up to the differences documented in
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

## Examples

``` r
reference_info()
```
