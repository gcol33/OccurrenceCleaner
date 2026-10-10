# Tests: GBIF issue flags

Four tests read the issue names GBIF attaches to a record during
processing:

- `issue_coordinate`: COORDINATE_INVALID, COORDINATE_OUT_OF_RANGE,
  COORDINATE_REPROJECTION_FAILED, COORDINATE_REPROJECTION_SUSPICIOUS,
  COORDINATE_UNCERTAINTY_METERS_INVALID, COORDINATE_PRECISION_INVALID,
  GEODETIC_DATUM_INVALID, CONTINENT_COORDINATE_MISMATCH,
  COUNTRY_COORDINATE_MISMATCH, PRESUMED_SWAPPED_COORDINATE,
  PRESUMED_NEGATED_LONGITUDE, PRESUMED_NEGATED_LATITUDE,
  ZERO_COORDINATE;

- `issue_taxon`: TAXON_MATCH_FUZZY, TAXON_MATCH_HIGHERRANK,
  TAXON_MATCH_NONE, TAXON_MATCH_AGGREGATE;

- `issue_date`: RECORDED_DATE_INVALID, RECORDED_DATE_UNLIKELY,
  RECORDED_DATE_MISMATCH;

- `issue_rounded`: COORDINATE_ROUNDED, which GBIF sets when it rounds a
  coordinate to five decimals.

## Details

The `issue` column is a string of names separated by `;`, `,`, `|` or
spaces, or a list column of character vectors; case is ignored.

## Fields

`issue`.

## CoordinateCleaner

No equivalent; additions of this package.

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
x <- data.frame(issue = c("COORDINATE_ROUNDED;GEODETIC_DATUM_ASSUMED_WGS84",
                          "TAXON_MATCH_FUZZY", "PRESUMED_SWAPPED_COORDINATE", ""))
f <- flag_occurrences(x, tests = c("issue_coordinate", "issue_taxon", "issue_rounded"))
f[, c("flag_issue_coordinate", "flag_issue_taxon", "flag_issue_rounded")]
```
