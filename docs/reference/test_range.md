# Test: outside the species range

Flags records that fall outside every range polygon of their species,
for example an IUCN range map. The polygons come from
`gazetteers = list(range = <sf>)`: an `sf` object with a species column
(named like the record's species column, `species`, `binomial` or
`sci_name`). Species without a polygon are not tested. With
`buffers = list(range = m)`, records within `m` metres of a polygon edge
count as inside.

## Usage

``` r
clean_range(x, ranges, buffer = 0, ...)
```

## Arguments

- x:

  A data frame of occurrence records.

- ranges:

  Species range polygons, as `gazetteers = list(range = ...)` in
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

- buffer:

  Buffer distance of the test, in the unit of its Buffer section; the
  default is the test's default buffer.

- ...:

  Further arguments to
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md):
  `columns`, `reference`, `gazetteers`, `land_scale`.

## Value

`clean_<test>()`: the rows of `x` the test does not flag, with the
columns of `x` unchanged. See
[`keep_unflagged()`](https://gillescolling.com/OccurrenceCleaner/reference/keep_unflagged.md),
Cleaning functions.

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
buffer
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)
buffers the polygons with [terra](https://rspatial.github.io/terra/), so
records very close to the buffer edge may differ.

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)

Other tests:
[`clean_age_equal()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md),
[`clean_age_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_outlier.md),
[`clean_age_range_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_range_outlier.md),
[`clean_aohi()`](https://gillescolling.com/OccurrenceCleaner/reference/test_aohi.md),
[`clean_basis_fossil()`](https://gillescolling.com/OccurrenceCleaner/reference/test_basis.md),
[`clean_capital()`](https://gillescolling.com/OccurrenceCleaner/reference/test_capital.md),
[`clean_centroid()`](https://gillescolling.com/OccurrenceCleaner/reference/test_centroid.md),
[`clean_country_mismatch()`](https://gillescolling.com/OccurrenceCleaner/reference/test_country_mismatch.md),
[`clean_dataset_ddmm()`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_ddmm.md),
[`clean_dataset_rounded()`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_rounded.md),
[`clean_duplicate()`](https://gillescolling.com/OccurrenceCleaner/reference/test_duplicate.md),
[`clean_equal()`](https://gillescolling.com/OccurrenceCleaner/reference/test_equal.md),
[`clean_establishment_introduced()`](https://gillescolling.com/OccurrenceCleaner/reference/test_establishment.md),
[`clean_gbif_headquarters()`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_headquarters.md),
[`clean_institution()`](https://gillescolling.com/OccurrenceCleaner/reference/test_institution.md),
[`clean_invalid()`](https://gillescolling.com/OccurrenceCleaner/reference/test_invalid.md),
[`clean_issue_coordinate()`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_issue.md),
[`clean_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_outlier.md),
[`clean_sea()`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md),
[`clean_sea_nonmarine()`](https://gillescolling.com/OccurrenceCleaner/reference/test_habitat.md),
[`clean_spatiotemporal_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_spatiotemporal_outlier.md),
[`clean_urban()`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`clean_zero()`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
if (requireNamespace("sf", quietly = TRUE)) {
  rg <- sf::st_sf(species = "a", geometry = sf::st_sfc(sf::st_polygon(list(
    rbind(c(0, 40), c(20, 40), c(20, 55), c(0, 55), c(0, 40)))), crs = 4326))
  x <- data.frame(species = c("a", "a", "b"), decimalLongitude = c(10, 30, 30),
                  decimalLatitude = 50)
  flag_occurrences(x, tests = "range", gazetteers = list(range = rg))$flag_range
  clean_range(x, ranges = rg)
}
```
