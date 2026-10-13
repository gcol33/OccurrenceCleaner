# Test: fossil age outliers

Flags fossil records whose age is far from the ages of the other records
of their taxon. One age is drawn uniformly from each record's range (the
minimum age when the range has zero width), each record gets its mean
absolute age difference to all records of the taxon, and records above
the upper fence (Q75 + `mltpl` x IQR, or median + `mltpl` x MAD) are
outliers. The draw is repeated `replicates` times and a record is
flagged when it is an outlier in more than `1 - flag_thresh` of them.
Taxa with fewer than `size_thresh` records are not tested.

## Usage

``` r
clean_age_outlier(
  x,
  method = "quantile",
  mltpl = 5,
  size_thresh = 7,
  replicates = 5,
  flag_thresh = 0.5,
  uniq_loc = FALSE,
  seed = 1L,
  ...
)
```

## Arguments

- x:

  A data frame of occurrence records.

- method, mltpl, size_thresh, replicates, flag_thresh, uniq_loc, seed:

  Options of the test, as in Settings; the defaults are in the usage
  line.

- ...:

  Further arguments to
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md):
  `columns`, `reference`, `gazetteers`, `land_scale`.

## Value

`clean_<test>()`: the rows of `x` the test does not flag, with the
columns of `x` unchanged. See
[`keep_unflagged()`](https://gillescolling.com/OccurrenceCleaner/reference/keep_unflagged.md),
Cleaning functions.

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

Equivalent to `cf_age()` at taxon level: the same draw, replicates and
majority rule. The flags are identical when no age has to be drawn
(every range of zero width). Otherwise the flags of a single run can
differ record by record, because
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) draws
from the session's random stream in input order and this test from a
stream seeded per taxon.

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)

Other tests:
[`clean_age_equal()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md),
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
[`clean_range()`](https://gillescolling.com/OccurrenceCleaner/reference/test_range.md),
[`clean_sea()`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md),
[`clean_sea_nonmarine()`](https://gillescolling.com/OccurrenceCleaner/reference/test_habitat.md),
[`clean_spatiotemporal_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_spatiotemporal_outlier.md),
[`clean_urban()`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`clean_zero()`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
x <- data.frame(accepted_name = "A", min_ma = c(rep(20, 20), 90), max_ma = c(rep(22, 20), 92))
flag_occurrences(x, tests = "age_outlier",
                 columns = occ_columns(species = "accepted_name"))$flag_age_outlier
clean_age_outlier(x, columns = occ_columns(species = "accepted_name"))
```
