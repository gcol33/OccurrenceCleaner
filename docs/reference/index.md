# Package index

## Flagging

- [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
  : Flag occurrence records
- [`default_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/default_tests.md)
  : Default tests
- [`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md)
  : Name the record fields

## Tests

- [`test_invalid`](https://gillescolling.com/OccurrenceCleaner/reference/test_invalid.md)
  : Test: invalid coordinates
- [`test_zero`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)
  : Test: zero coordinates
- [`test_equal`](https://gillescolling.com/OccurrenceCleaner/reference/test_equal.md)
  : Test: equal coordinates
- [`test_capital`](https://gillescolling.com/OccurrenceCleaner/reference/test_capital.md)
  : Test: country capitals
- [`test_centroid`](https://gillescolling.com/OccurrenceCleaner/reference/test_centroid.md)
  : Test: country and province centroids
- [`test_institution`](https://gillescolling.com/OccurrenceCleaner/reference/test_institution.md)
  : Test: biodiversity institutions
- [`test_gbif_headquarters`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_headquarters.md)
  : Test: GBIF headquarters
- [`test_sea`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md)
  : Test: records at sea
- [`test_urban`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md)
  : Test: urban areas
- [`test_country_mismatch`](https://gillescolling.com/OccurrenceCleaner/reference/test_country_mismatch.md)
  : Test: country code mismatch
- [`test_duplicate`](https://gillescolling.com/OccurrenceCleaner/reference/test_duplicate.md)
  : Test: duplicates
- [`test_gbif_issue`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_issue.md)
  : Tests: GBIF issue flags
- [`test_basis`](https://gillescolling.com/OccurrenceCleaner/reference/test_basis.md)
  : Tests: basis of record
- [`test_establishment`](https://gillescolling.com/OccurrenceCleaner/reference/test_establishment.md)
  : Tests: establishment means
- [`test_age_equal`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md)
  : Test: fossil age range
- [`test_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_outlier.md)
  : Test: geographic outliers
- [`test_age_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_outlier.md)
  : Test: fossil age outliers
- [`test_spatiotemporal_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_spatiotemporal_outlier.md)
  : Test: fossil outliers in space and time
- [`test_age_range_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_range_outlier.md)
  : Test: fossil age-range outliers
- [`test_dataset_ddmm`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_ddmm.md)
  : Test: degree-minute conversion errors in a dataset
- [`test_dataset_rounded`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_rounded.md)
  : Test: rasterised datasets
- [`test_range`](https://gillescolling.com/OccurrenceCleaner/reference/test_range.md)
  : Test: outside the species range
- [`test_aohi`](https://gillescolling.com/OccurrenceCleaner/reference/test_aohi.md)
  : Test: artificial hotspots

## Rules and tallies

- [`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
  : Tally flags into a loss table
- [`summary(`*`<occ_flags>`*`)`](https://gillescolling.com/OccurrenceCleaner/reference/summary.occ_flags.md)
  [`summary(`*`<occ_flagged>`*`)`](https://gillescolling.com/OccurrenceCleaner/reference/summary.occ_flags.md)
  [`summary(`*`<occ_tally>`*`)`](https://gillescolling.com/OccurrenceCleaner/reference/summary.occ_flags.md)
  : Share of records flagged, per test and rule
- [`plot(`*`<occ_summary>`*`)`](https://gillescolling.com/OccurrenceCleaner/reference/plot.occ_summary.md)
  [`plot(`*`<occ_tally>`*`)`](https://gillescolling.com/OccurrenceCleaner/reference/plot.occ_summary.md)
  [`plot(`*`<occ_flags>`*`)`](https://gillescolling.com/OccurrenceCleaner/reference/plot.occ_summary.md)
  [`plot(`*`<occ_flagged>`*`)`](https://gillescolling.com/OccurrenceCleaner/reference/plot.occ_summary.md)
  : Plot flag percentages, or map flagged records
- [`flag_mask()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md)
  [`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md)
  : Bit mask and membership for sets of tests
- [`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)
  : The flag layout: one bit per test

## On-disk output

- [`read_flagged()`](https://gillescolling.com/OccurrenceCleaner/reference/read_flagged.md)
  [`flagged_table()`](https://gillescolling.com/OccurrenceCleaner/reference/read_flagged.md)
  : Read flag output written by flag_occurrences()

## Export

- [`export_pyrate()`](https://gillescolling.com/OccurrenceCleaner/reference/export_pyrate.md)
  : Export fossil records as PyRate input

## Reference data

- [`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md)
  : Reference data: sources and versions
- [`reference_points()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_points.md)
  : Reference points of a proximity test
- [`download_reference()`](https://gillescolling.com/OccurrenceCleaner/reference/download_reference.md)
  : Download the 1:10m land layer

## Package

- [`OccurrenceCleaner`](https://gillescolling.com/OccurrenceCleaner/reference/OccurrenceCleaner-package.md)
  [`OccurrenceCleaner-package`](https://gillescolling.com/OccurrenceCleaner/reference/OccurrenceCleaner-package.md)
  : OccurrenceCleaner: fast quality flags for species occurrence records
