# Test: fossil age outliers

Flags fossil records whose age is far from the ages of the other records
of their taxon. One age is drawn uniformly from each record's range (the
minimum age when the range has zero width), each record gets its mean
absolute age difference to all records of the taxon, and records above
the upper fence (Q75 + `mltpl` x IQR, or median + `mltpl` x MAD) are
outliers. The draw is repeated `replicates` times and a record is
flagged when it is an outlier in more than `1 - flag_thresh` of them.
Taxa with fewer than `size_thresh` records are not tested.

## Details

The draws are seeded per taxon from `seed` and the taxon name, and taken
in an order fixed by the records' ages, coordinates and identifier, so
the flags are reproducible and do not depend on the order or the
splitting of the input. The caller's random-number stream is left
unchanged.

## Fields

`min_age`, `max_age`, `species` (the taxon), and `lon`, `lat` for
`uniq_loc`.

## Settings

`settings = list(age_outlier = list(...))` with `method` (`"quantile"`),
`mltpl` (5), `size_thresh` (7), `replicates` (5), `flag_thresh` (0.5),
`uniq_loc` (`FALSE`: when `TRUE`, records sharing taxon, coordinates
rounded to 0.1 degrees and ages are tested once) and `seed` (1).

## CoordinateCleaner

Equivalent to `cf_age()` at taxon level; identical flags when no age has
to be drawn (every range of zero width). Otherwise both draw ages at
random and the flags agree in distribution, not record by record:
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) draws
from the session's random stream in input order.

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)

Other tests:
[`test_age_equal`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md),
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
x <- data.frame(accepted_name = "A", min_ma = c(rep(20, 20), 90), max_ma = c(rep(22, 20), 92))
flag_occurrences(x, tests = "age_outlier",
                 columns = occ_columns(species = "accepted_name"))$flag_age_outlier
```
