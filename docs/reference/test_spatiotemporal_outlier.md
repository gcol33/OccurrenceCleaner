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

## Usage

``` r
clean_spatiotemporal_outlier(
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

## Fields

`lon`, `lat`, `min_age`, `max_age`, `species`.

## Settings

`settings = list(spatiotemporal_outlier = list(...))` with the same
options and defaults as `age_outlier`.

## CoordinateCleaner

Equivalent to `cf_outl()` at taxon level, the `spatiotemp` test of
`clean_fossils()`; identical flags when every range has zero width, and
otherwise a single run can differ record by record, as for
`age_outlier`.

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
[`clean_range()`](https://gillescolling.com/OccurrenceCleaner/reference/test_range.md),
[`clean_sea()`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md),
[`clean_sea_nonmarine()`](https://gillescolling.com/OccurrenceCleaner/reference/test_habitat.md),
[`clean_urban()`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`clean_zero()`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
set.seed(1)
x <- data.frame(accepted_name = "A", lng = c(runif(20, 0, 5), 120), lat = c(runif(20, 40, 45), -30),
                min_ma = 20, max_ma = 20)
cols <- occ_columns(lon = "lng", lat = "lat", species = "accepted_name")
flag_occurrences(x, tests = "spatiotemporal_outlier", columns = cols)$flag_spatiotemporal_outlier
clean_spatiotemporal_outlier(x, columns = cols)
```
