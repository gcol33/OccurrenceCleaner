# Tests: habitat at sea and on land

Two tests set the land test against the habitat of the record's genus:

- `sea_nonmarine` flags records outside the land polygons whose genus
  does not live in the sea (a tree or a toad in open water);

- `land_marine` flags records inside the land polygons whose genus lives
  only in the sea (a starfish or a coral inland).

## Details

The genus habitats come from the Interim Register of Marine and
Nonmarine Genera (IRMNG; Rees, T. (compiler) (2026). The Interim
Register of Marine and Nonmarine Genera. Available from
https://www.irmng.org at VLIZ; CC BY 4.0), see
[`reference_habitat()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_habitat.md)
for how a genus is classed. Records of a genus IRMNG does not class
(missing flags, or both habitats, as for gulls, seals, salmon or
mangroves) are not tested. The genus is the first word of the `genus`
field, so a binomial species column works too; a `kingdom` column, when
present, resolves genus names used in two kingdoms. The land is the
layer of `sea`: `land_scale`, or `gazetteers$sea`.

A coarse coast puts coastal records on the wrong side: at the default
`land_scale = 110` the coastline is generalised by kilometres. The
buffers leave records within that distance of the coast untested.

Marine fossils of a living marine genus lie on land too; combine with
`basis_fossil` in a rule to keep them.

## Fields

`lon`, `lat`, `genus`; `kingdom` when present.

## Buffer

`buffers = list(sea_nonmarine = 0, land_marine = 0)`, in metres from the
land polygon edge.

## Custom gazetteer

`gazetteers = list(habitat = <data frame>)` with columns `genus`,
`marine` (logical: `TRUE` only marine, `FALSE` not marine) and
optionally `kingdom`; `gazetteers = list(sea = <sf>)` replaces the land.

## CoordinateCleaner

Not in CoordinateCleaner, whose `cc_sea()` flags every record off the
land, marine or not.

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md),
[`reference_habitat()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_habitat.md),
[test_sea](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md)

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
[`test_range`](https://gillescolling.com/OccurrenceCleaner/reference/test_range.md),
[`test_sea`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md),
[`test_spatiotemporal_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_spatiotemporal_outlier.md),
[`test_urban`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`test_zero`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
x <- data.frame(kingdom = c("Plantae", "Animalia", "Animalia", "Plantae"),
                genus = c("Quercus", "Asterias", "Asterias", "Quercus"),
                decimalLongitude = c(-30, 16.37, -30, 16.37),
                decimalLatitude = c(40, 48.21, 40, 48.21))
f <- flag_occurrences(x, tests = c("sea", "sea_nonmarine", "land_marine"))
f[, c("genus", "flag_sea", "flag_sea_nonmarine", "flag_land_marine")]
```
