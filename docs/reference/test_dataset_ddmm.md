# Test: degree-minute conversion errors in a dataset

Flags every record of a dataset whose coordinates look converted from
degrees and minutes as if they were decimal degrees, which leaves no
decimal part above .59. The decimal parts of each dataset's distinct
coordinates are placed on a `mat_size` x `mat_size` grid; a binomial
test compares the share of filled cells with both decimals below .6 with
its expected share, and the dataset fails when the excess is significant
(p \< `pvalue`) and larger than `diff` times the expected share.
Datasets spanning less than `min_span` degrees in longitude or latitude
are not tested.

## Fields

`lon`, `lat`, `dataset` (`datasetKey` by default).

## Settings

`settings = list(dataset_ddmm = list(...))` with `pvalue` (0.025),
`diff` (1), `mat_size` (1000) and `min_span` (2).

## CoordinateCleaner

Equivalent to `cd_ddmm()`; identical flags. Records without a dataset
key are not flagged here; `cd_ddmm()` flags them.

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
set.seed(2)
ddmm <- function(n) floor(runif(n, 0, 20)) + sample(0:59, n, TRUE) / 100
x <- data.frame(datasetKey = rep(c("ok", "ddmm"), each = 300),
                decimalLongitude = c(runif(300, 0, 20), ddmm(300)),
                decimalLatitude = c(runif(300, 0, 20), ddmm(300)))
tapply(flag_occurrences(x, tests = "dataset_ddmm")$flag_dataset_ddmm, x$datasetKey, all)
```
