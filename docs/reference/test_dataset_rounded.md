# Test: rasterised datasets

Flags every record of a dataset whose coordinates lie on a regular grid,
as when records were collected or published per grid cell. For each axis
the absolute coordinates are binned into about 3000 classes, the
autocorrelation of the bin counts is computed, and its outliers (values
above Q75 + `T1` x IQR in sliding windows) are located; regularly spaced
outliers, at a common distance between `reg_dist_min` and `reg_dist_max`
degrees found at least `reg_out_thresh` times, mark the axis as
periodic. A dataset fails when both axes are periodic (`axis = "both"`)
or the chosen one is. Datasets with fewer than `min_unique_ds_size`
distinct coordinates are not tested.

## Fields

`lon`, `lat`, `dataset`.

## Settings

`settings = list(dataset_rounded = list(...))` with `T1` (7),
`reg_out_thresh` (2), `reg_dist_min` (0.1), `reg_dist_max` (2),
`min_unique_ds_size` (4) and `axis` (`"both"`).

## CoordinateCleaner

Equivalent to `cd_round()`; identical flags. In
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) 3.0.1
an input with several datasets of which one is below
`min_unique_ds_size` stops with an error; here that dataset is not
tested. Records without a dataset key are not flagged.

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
[`test_duplicate`](https://gillescolling.com/OccurrenceCleaner/reference/test_duplicate.md),
[`test_equal`](https://gillescolling.com/OccurrenceCleaner/reference/test_equal.md),
[`test_establishment`](https://gillescolling.com/OccurrenceCleaner/reference/test_establishment.md),
[`test_gbif_headquarters`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_headquarters.md),
[`test_gbif_issue`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_issue.md),
[`test_habitat`](https://gillescolling.com/OccurrenceCleaner/reference/test_habitat.md),
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
set.seed(2)
x <- data.frame(datasetKey = rep(c("ok", "grid"), each = 400),
                decimalLongitude = c(runif(400, 0, 20), round(runif(400, 0, 20) * 2) / 2 + 0.01),
                decimalLatitude = c(runif(400, 0, 20), round(runif(400, 30, 50) * 2) / 2 + 0.01))
tapply(flag_occurrences(x, tests = "dataset_rounded")$flag_dataset_rounded, x$datasetKey, all)
```
