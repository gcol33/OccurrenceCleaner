# Changelog

## OccurrenceCleaner 0.1.0

Initial release.

### Flagging

- [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md):
  one verb for a data frame or an on-disk table (Parquet directory,
  `.vtr`, delimited file, or any `vectra_node`). Nineteen tests, one bit
  each in an integer flag word; nothing is dropped.
- Eleven tests reproduce CoordinateCleaner’s record tests with its
  default buffers (`invalid`, `zero`, `equal`, `capital`, `centroid`,
  `institution`, `gbif_headquarters`, `sea`, `urban`,
  `country_mismatch`, `duplicate`); eight read GBIF fields
  (`issue_coordinate`, `issue_taxon`, `issue_date`, `issue_rounded`,
  `basis_fossil`, `basis_living`, `establishment_introduced`,
  `establishment_managed`). Tests read from a record field carry that
  field as a prefix.
- Proximity tests run as kd-tree candidate searches on the unit sphere
  decided by WGS84 geodesic distance; polygon tests as grid-indexed
  point-in-polygon with exact boundary cells. Both in C++ with no
  external library.
- Streamed input is processed per file, written as `.vtr` parts with the
  kept columns, and resumable.

### Rules and tallies

- [`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md):
  loss tables by grouping columns, with numeric bins and named rules,
  over a data frame or the on-disk output. Per rule it also counts the
  records each test is the sole reason for.
- [`summary()`](https://rdrr.io/r/base/summary.html) on flagged records,
  on-disk output or a tally gives the percentage of records each test
  and rule removes, with the sole-reason share;
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) draws it as
  bars or, by group, as a grid, and maps kept and removed records with
  `type = "map"`.
- [`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md),
  [`flag_mask()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md),
  [`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md),
  [`default_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/default_tests.md).

### Reference data

- Own gazetteers rebuilt from Natural Earth (capitals, country and
  province centroids, land at 1:110m and 1:50m, urban areas, countries)
  and GBIF GRSciColl (institutions), each pinned by version and SHA-256
  in
  [`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md);
  the 1:10m land layer is fetched on demand by
  [`download_reference()`](https://gillescolling.com/OccurrenceCleaner/reference/download_reference.md).
- `reference = "CoordinateCleaner"` reads that package’s tables at run
  time and reproduces its flags; the equivalence suite documents every
  difference.
