# Test: fossil outliers in space and time

Flags fossil records that are far from the other records of their taxon
in space and time together. Ages are drawn as in
[test_age_outlier](https://gillescolling.com/OccurrenceCleaner/reference/test_age_outlier.md);
for each pair of records the age difference is rescaled so that the
largest age difference equals the largest geographic distance, added to
the haversine distance in km between coordinates rounded to 0.1 degrees
(Euclidean degrees for taxa of 10,000 records or more) and rounded; each
record's mean over all records of its taxon is compared with the upper
fence. Replicates, majority and seeding are as in
[test_age_outlier](https://gillescolling.com/OccurrenceCleaner/reference/test_age_outlier.md).

## Fields

`lon`, `lat`, `min_age`, `max_age`, `species`.

## Settings

`settings = list(spatiotemporal_outlier = list(...))` with the same
options and defaults as `age_outlier`.

## CoordinateCleaner

Equivalent to `cf_outl()` at taxon level, the `spatiotemp` test of
`clean_fossils()`; identical flags when every range has zero width,
agreement in distribution otherwise.

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
[`test_range`](https://gillescolling.com/OccurrenceCleaner/reference/test_range.md),
[`test_sea`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md),
[`test_urban`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`test_zero`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
set.seed(1)
x <- data.frame(accepted_name = "A", lng = c(runif(20, 0, 5), 120), lat = c(runif(20, 40, 45), -30),
                min_ma = 20, max_ma = 20)
cols <- occ_columns(lon = "lng", lat = "lat", species = "accepted_name")
flag_occurrences(x, tests = "spatiotemporal_outlier", columns = cols)$flag_spatiotemporal_outlier
```
