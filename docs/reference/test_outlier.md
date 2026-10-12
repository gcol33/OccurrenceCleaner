# Test: geographic outliers

Flags records far from the other records of their species. For each
record the haversine distances (km) to the species' other records are
computed, leaving out zero distances (the record itself and records at
the same point); a record is flagged when its mean distance lies above
the upper fence of the species' mean distances: Q75 + `mltpl` x IQR
(`method = "quantile"`) or median + `mltpl` x MAD (`"mad"`). With
`method = "distance"` a record is flagged when its nearest other record
is more than `tdi` km away. Species with fewer than `min_occs` distinct
points are not tested.

## Usage

``` r
clean_outlier(
  x,
  method = "quantile",
  mltpl = 5,
  tdi = 1000,
  min_occs = 7,
  thinning = FALSE,
  thinning_res = 0.5,
  sampling_thresh = 0,
  ...
)
```

## Arguments

- x:

  A data frame of occurrence records.

- method, mltpl, tdi, min_occs, thinning, thinning_res, sampling_thresh:

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

Species with 10,000 records or more, and every species when
`thinning = TRUE`, are tested on a raster approximation: records are
counted on a grid of `thinning_res` degrees spanning all valid records
(widened by two cells), distances are taken between cell centres, and
the records of the outlier cells are flagged. Without thinning,
distances are weighted by the product of the cell counts and a cell's
distance to itself counts as 100 x `thinning_res` / 2 km, as in
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/).

The test needs every record of a species, so it runs in a group pass
over the whole input before the record tests; on streamed input that
pass reads all files, and a species spread over several files is tested
as one.

## Fields

`lon`, `lat`, `species`. Records with invalid coordinates are left out.

## Settings

`settings = list(outlier = list(...))` with `method` (`"quantile"`),
`mltpl` (5), `tdi` (1000 km), `min_occs` (7), `thinning` (`FALSE`),
`thinning_res` (0.5 degrees) and `sampling_thresh` (0).

## Sampling correction

With `sampling_thresh` above 0, an outlier stays flagged only in a
country whose record density (log records per 100 km2) lies above that
quantile of the densities of all countries, so that isolated records in
poorly sampled countries are kept. The records per country come from
`gazetteers = list(sampling = <data frame>)`, with an ISO alpha-2
`country` column and a `records` column, for example from
[`rgbif::occ_count()`](https://docs.ropensci.org/rgbif/reference/occ_count.html)
or a tally of the input itself; country areas are computed from the
country polygons of the reference.

## CoordinateCleaner

Equivalent to `cc_outl()`; identical flags for species below 10,000
records. In CoordinateCleaner 3.0.1 the raster approximation (10,000
records or more, or `thinning = TRUE`) flags no records; here the
records of the outlier cells are flagged. CoordinateCleaner's sampling
correction queries GBIF record counts online at run time; here the
counts are a table given with the call, so the flags can be reproduced.

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
[`clean_range()`](https://gillescolling.com/OccurrenceCleaner/reference/test_range.md),
[`clean_sea()`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md),
[`clean_sea_nonmarine()`](https://gillescolling.com/OccurrenceCleaner/reference/test_habitat.md),
[`clean_spatiotemporal_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_spatiotemporal_outlier.md),
[`clean_urban()`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`clean_zero()`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
set.seed(1)
x <- data.frame(species = "a", decimalLongitude = c(rnorm(50, 10, 1), 60),
                decimalLatitude = c(rnorm(50, 50, 1), 10))
which(flag_occurrences(x, tests = "outlier")$flag_outlier)
nrow(clean_outlier(x, mltpl = 3))
```
