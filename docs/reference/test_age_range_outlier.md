# Test: fossil age-range outliers

Flags fossil records whose age range (`max_age - min_age`) lies above
the upper fence of the ranges of the other records of their taxon (Q75 +
`mltpl` x IQR, or median + `mltpl` x MAD). A record dated only to a long
period among records dated to stages is the typical case. With
`level = "all"` the fence is taken over the whole input instead of per
taxon, as in
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)'s
dataset-level `cf_range(taxon = "")`. A fixed limit in million years
needs no test: the range stays a raw column and is cut in
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md).

## Usage

``` r
clean_age_range_outlier(
  x,
  method = "quantile",
  mltpl = 5,
  size_thresh = 7,
  uniq_loc = FALSE,
  level = "taxon",
  ...
)
```

## Arguments

- x:

  A data frame of occurrence records.

- method, mltpl, size_thresh, uniq_loc, level:

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
[`clean_age_equal()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md),
[`clean_age_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_outlier.md),
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
x <- data.frame(accepted_name = "A", min_ma = 20, max_ma = c(rep(21, 20), 60))
flag_occurrences(x, tests = "age_range_outlier",
                 columns = occ_columns(species = "accepted_name"))$flag_age_range_outlier
clean_age_range_outlier(x, columns = occ_columns(species = "accepted_name"))
```
