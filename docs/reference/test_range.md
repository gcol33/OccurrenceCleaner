# Test: outside the species range

Flags records that fall outside every range polygon of their species,
for example an IUCN range map. The polygons come from
`gazetteers = list(range = <sf>)`: an `sf` object with a species column
(named like the record's species column, `species`, `binomial` or
`sci_name`). Species without a polygon are not tested. With
`buffers = list(range = m)`, records within `m` metres of a polygon edge
count as inside.

## Fields

`lon`, `lat`, `species`.

## Buffer

`buffers = list(range = 0)`, in metres. The distance to an edge is
measured on the ellipsoid from the closest point of the edge in a local
equirectangular projection.

## Custom gazetteer

required; there is no shipped range layer.

## CoordinateCleaner

Equivalent to `cc_iucn()`; identical flags without a buffer. With a
buffer CoordinateCleaner buffers the polygons with terra, so records
very close to the buffer edge may differ.

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)

Other tests:
[`test_age_equal`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md),
[`test_age_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_outlier.md),
[`test_age_range_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_range_outlier.md),
[`test_aohi`](https://gillescolling.com/OccurrenceCleaner/reference/test_aohi.md),
[`test_basis`](https://gillescolling.com/OccurrenceCleaner/reference/test_basis.md),
[`test_capital`](https://gillescolling.com/OccurrenceCleaner/reference/test_capital.md),
[`test_centroid`](https://gillescolling.com/OccurrenceCleaner/reference/test_centroid.md),
[`test_country_mismatch`](https://gillescolling.com/OccurrenceCleaner/reference/test_country_mismatch.md),
[`test_dataset_ddmm`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_ddmm.md),
[`test_dataset_rounded`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_rounded.md),
[`test_duplicate`](https://gillescolling.com/OccurrenceCleaner/reference/test_duplicate.md),
[`test_equal`](https://gillescolling.com/OccurrenceCleaner/reference/test_equal.md),
[`test_establishment`](https://gillescolling.com/OccurrenceCleaner/reference/test_establishment.md),
[`test_gbif_headquarters`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_headquarters.md),
[`test_gbif_issue`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_issue.md),
[`test_institution`](https://gillescolling.com/OccurrenceCleaner/reference/test_institution.md),
[`test_invalid`](https://gillescolling.com/OccurrenceCleaner/reference/test_invalid.md),
[`test_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_outlier.md),
[`test_sea`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md),
[`test_spatiotemporal_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_spatiotemporal_outlier.md),
[`test_urban`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`test_zero`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
if (requireNamespace("sf", quietly = TRUE)) {
  rg <- sf::st_sf(species = "a", geometry = sf::st_sfc(sf::st_polygon(list(
    rbind(c(0, 40), c(20, 40), c(20, 55), c(0, 55), c(0, 40)))), crs = 4326))
  x <- data.frame(species = c("a", "a", "b"), decimalLongitude = c(10, 30, 30),
                  decimalLatitude = 50)
  flag_occurrences(x, tests = "range", gazetteers = list(range = rg))$flag_range
}
```
