# Package index

## Flagging

- [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
  : Flag occurrence records
- [`test_plan()`](https://gillescolling.com/OccurrenceCleaner/reference/test_plan.md)
  : Which tests run on an input
- [`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md)
  : Name the record fields

## Tests

- [`clean_invalid()`](https://gillescolling.com/OccurrenceCleaner/reference/test_invalid.md)
  : Test: invalid coordinates
- [`clean_zero()`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)
  : Test: zero coordinates
- [`clean_equal()`](https://gillescolling.com/OccurrenceCleaner/reference/test_equal.md)
  : Test: equal coordinates
- [`clean_capital()`](https://gillescolling.com/OccurrenceCleaner/reference/test_capital.md)
  : Test: country capitals
- [`clean_centroid()`](https://gillescolling.com/OccurrenceCleaner/reference/test_centroid.md)
  : Test: country and province centroids
- [`clean_institution()`](https://gillescolling.com/OccurrenceCleaner/reference/test_institution.md)
  : Test: biodiversity institutions
- [`clean_gbif_headquarters()`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_headquarters.md)
  : Test: GBIF headquarters
- [`clean_sea()`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md)
  : Test: records at sea
- [`clean_urban()`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md)
  : Test: urban areas
- [`clean_country_mismatch()`](https://gillescolling.com/OccurrenceCleaner/reference/test_country_mismatch.md)
  : Test: country code mismatch
- [`clean_duplicate()`](https://gillescolling.com/OccurrenceCleaner/reference/test_duplicate.md)
  : Test: duplicates
- [`clean_issue_coordinate()`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_issue.md)
  [`clean_issue_taxon()`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_issue.md)
  [`clean_issue_date()`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_issue.md)
  [`clean_issue_rounded()`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_issue.md)
  : Tests: GBIF issue flags
- [`clean_basis_fossil()`](https://gillescolling.com/OccurrenceCleaner/reference/test_basis.md)
  [`clean_basis_living()`](https://gillescolling.com/OccurrenceCleaner/reference/test_basis.md)
  : Tests: basis of record
- [`clean_establishment_introduced()`](https://gillescolling.com/OccurrenceCleaner/reference/test_establishment.md)
  [`clean_establishment_managed()`](https://gillescolling.com/OccurrenceCleaner/reference/test_establishment.md)
  : Tests: establishment means
- [`clean_age_equal()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md)
  : Test: fossil age range
- [`clean_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_outlier.md)
  : Test: geographic outliers
- [`clean_age_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_outlier.md)
  : Test: fossil age outliers
- [`clean_spatiotemporal_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_spatiotemporal_outlier.md)
  : Test: fossil outliers in space and time
- [`clean_age_range_outlier()`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_range_outlier.md)
  : Test: fossil age-range outliers
- [`clean_dataset_ddmm()`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_ddmm.md)
  : Test: degree-minute conversion errors in a dataset
- [`clean_dataset_rounded()`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_rounded.md)
  : Test: rasterised datasets
- [`clean_range()`](https://gillescolling.com/OccurrenceCleaner/reference/test_range.md)
  : Test: outside the species range
- [`clean_aohi()`](https://gillescolling.com/OccurrenceCleaner/reference/test_aohi.md)
  : Test: artificial hotspots
- [`clean_sea_nonmarine()`](https://gillescolling.com/OccurrenceCleaner/reference/test_habitat.md)
  [`clean_land_marine()`](https://gillescolling.com/OccurrenceCleaner/reference/test_habitat.md)
  : Tests: habitat at sea and on land

## Rules and tallies

- [`keep_unflagged()`](https://gillescolling.com/OccurrenceCleaner/reference/keep_unflagged.md)
  : Keep the records no test flagged
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
- [`as_spatialvalid()`](https://gillescolling.com/OccurrenceCleaner/reference/as_spatialvalid.md)
  : Convert flags to CoordinateCleaner's spatialvalid format

## Reference data

- [`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md)
  : Reference data: sources and versions
- [`flag_reference()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_reference.md)
  : Reference data behind a set of flags
- [`reference_points()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_points.md)
  : Reference points of a proximity test
- [`reference_habitat()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_habitat.md)
  : Genus habitats of the habitat tests
- [`download_reference()`](https://gillescolling.com/OccurrenceCleaner/reference/download_reference.md)
  : Download the 1:10 million land layer

## Data

- [`gentiana`](https://gillescolling.com/OccurrenceCleaner/reference/gentiana.md)
  : GBIF records of gentians in Austria

## Package

- [`OccurrenceCleaner`](https://gillescolling.com/OccurrenceCleaner/reference/OccurrenceCleaner-package.md)
  [`OccurrenceCleaner-package`](https://gillescolling.com/OccurrenceCleaner/reference/OccurrenceCleaner-package.md)
  : OccurrenceCleaner: fast quality flags for species occurrence records
