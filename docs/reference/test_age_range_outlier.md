# Test: fossil age-range outliers

Flags fossil records whose age range (`max_age - min_age`) lies above
the upper fence of the ranges of the other records of their taxon (Q75 +
`mltpl` x IQR, or median + `mltpl` x MAD). A record dated only to a long
period among records dated to stages is the typical case. With
`level = "all"` the fence is taken over the whole input instead of per
taxon, as in CoordinateCleaner's dataset-level `cf_range(taxon = "")`. A
fixed limit in million years needs no test: the range stays a raw column
and is cut in
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md).

## Fields

`min_age`, `max_age`, `species`.

## Settings

`settings = list(age_range_outlier = list(...))` with `method`
(`"quantile"`), `mltpl` (5), `size_thresh` (7), `uniq_loc` (`FALSE`) and
`level` (`"taxon"`).

## CoordinateCleaner

Equivalent to `cf_range()` with `method = "quantile"` or `"mad"`;
identical flags. With `uniq_loc = TRUE`, CoordinateCleaner also flags
records of other taxa that happen to share a flagged range width; here
the flag goes to the records with the same taxon, coordinates and ages.

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md),
[test_age_equal](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md)

Other tests:
[`test_age_equal`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md),
[`test_age_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_outlier.md),
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
x <- data.frame(accepted_name = "A", min_ma = 20, max_ma = c(rep(21, 20), 60))
flag_occurrences(x, tests = "age_range_outlier",
                 columns = occ_columns(species = "accepted_name"))$flag_age_range_outlier
```
