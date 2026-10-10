# Test: biodiversity institutions

Flags records within 100 m of a biodiversity institution (WGS84 geodesic
distance, closed ball): herbaria, museums, botanic gardens, zoos and
universities holding collections, where specimens are often
georeferenced to the institution. The default gazetteer holds 13,515
points: the 6,080 institutions with coordinates in GBIF's Global
Registry of Scientific Collections (GRSciColl), less five whose
coordinates the `zero` test flags (they lie near (0, 0) or have a
longitude of exactly 0, and are geocoding errors), and 7,435 botanical
gardens, natural history museums, zoos, aquaria and herbaria with
coordinates in Wikidata (CC0), retrieved 2026-10-10. The `source` column
of
[`reference_points()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_points.md)
tells them apart.

## Fields

`lon`, `lat`.

## Buffer

`buffers = list(institution = 100)`, in metres.

## CoordinateCleaner

Equivalent to `cc_inst()`. Its 40-gon buffer edge lies within 0.31 m of
the 100 m circle. Its `institutions` table (9,773 points with
coordinates) takes botanic gardens from BGCI and museums from Wikipedia
where this package takes Wikidata; `reference = "CoordinateCleaner"`
uses that table.

## Custom gazetteer

`gazetteers = list(institution = points)`, a data frame of longitude and
latitude; see
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md),
[`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md)

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
[`test_habitat`](https://gillescolling.com/OccurrenceCleaner/reference/test_habitat.md),
[`test_invalid`](https://gillescolling.com/OccurrenceCleaner/reference/test_invalid.md),
[`test_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_outlier.md),
[`test_range`](https://gillescolling.com/OccurrenceCleaner/reference/test_range.md),
[`test_sea`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md),
[`test_spatiotemporal_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_spatiotemporal_outlier.md),
[`test_urban`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`test_zero`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
x <- data.frame(decimalLongitude = c(16.3598, 15), decimalLatitude = c(48.2052, 47))
flag_occurrences(x, tests = "institution")$flag_institution
```
