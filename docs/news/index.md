# Changelog

## OccurrenceCleaner 0.1.0

Initial release.

### Flagging

- [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md):
  one verb for a data frame or an on-disk table (Parquet directory,
  `.vtr`, delimited file, or any `vectra_node`). Twenty-eight tests, one
  bit each in an integer flag word; nothing is dropped.
- Twelve tests reproduce CoordinateCleaner’s record tests with its
  default buffers (`invalid`, `zero`, `equal`, `capital`, `centroid`,
  `institution`, `gbif_headquarters`, `sea`, `urban`,
  `country_mismatch`, `duplicate`, and the fossil age test `age_equal`,
  as
  [`cf_equal()`](https://ropensci.github.io/CoordinateCleaner/reference/cf_equal.html));
  eight more are CoordinateCleaner’s grouped and reference tests:
  `outlier`
  ([`cc_outl()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_outl.html)),
  `age_outlier`
  ([`cf_age()`](https://ropensci.github.io/CoordinateCleaner/reference/cf_age.html)),
  `spatiotemporal_outlier`
  ([`cf_outl()`](https://ropensci.github.io/CoordinateCleaner/reference/cf_outl.html)),
  `age_range_outlier`
  ([`cf_range()`](https://ropensci.github.io/CoordinateCleaner/reference/cf_range.html)),
  `dataset_ddmm`
  ([`cd_ddmm()`](https://ropensci.github.io/CoordinateCleaner/reference/cd_ddmm.html)),
  `dataset_rounded`
  ([`cd_round()`](https://ropensci.github.io/CoordinateCleaner/reference/cd_round.html)),
  `range`
  ([`cc_iucn()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_iucn.html),
  with user range polygons) and `aohi`
  ([`cc_aohi()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_aohi.html));
  eight read GBIF fields (`issue_coordinate`, `issue_taxon`,
  `issue_date`, `issue_rounded`, `basis_fossil`, `basis_living`,
  `establishment_introduced`, `establishment_managed`). Tests read from
  a record field carry that field as a prefix.
- Proximity tests run as kd-tree candidate searches on the unit sphere
  decided by WGS84 geodesic distance; polygon tests as grid-indexed
  point-in-polygon with exact boundary cells. Both in C++ with no
  external library.
- Streamed input is processed per file, written as `.vtr` parts with the
  kept columns, and resumable.
- The grouped tests (`outlier`, the fossil outlier tests, the dataset
  tests) run in a group pass over the whole input before the record
  tests; on streamed input it reads every file, buckets small groups on
  disk and keeps its result for a resumed run. Their options, with
  CoordinateCleaner’s defaults, go in `settings`. `outlier` flags the
  records of outlier cells on the raster approximation for large
  species, where CoordinateCleaner 3.0.1 flags none; the fossil tests
  seed their age draws per taxon.

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
- [`as_spatialvalid()`](https://gillescolling.com/OccurrenceCleaner/reference/as_spatialvalid.md)
  writes flagged records, in memory or on disk, in the layout of
  CoordinateCleaner’s `spatialvalid` object (`.cap`, `.zer`, …,
  `.summary`, `TRUE` for pass), so code and methods written for it run
  unchanged;
  [`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)
  gives the column name per test.

### Reference data

- Own gazetteers rebuilt from Natural Earth (capitals, country and
  province centroids, land at 1:110m and 1:50m, urban areas, countries)
  and GBIF GRSciColl (institutions, without the five entries the `zero`
  test flags), each pinned by version and SHA-256 in
  [`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md);
  the 1:10m land layer is fetched on demand by
  [`download_reference()`](https://gillescolling.com/OccurrenceCleaner/reference/download_reference.md).
- The Artificial Hotspot Occurrence Inventory (Park et al. 2023) is
  built from its Dryad deposit (CC0) for the `aohi` test and returned by
  `reference_points("aohi")`.
- `reference = "CoordinateCleaner"` reads that package’s tables at run
  time and reproduces its flags; the equivalence suite documents every
  difference.
- `gazetteers` in
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
  replaces the reference layer of single tests with user points (data
  frame) or polygons (`sf`/`sfc`), as the `ref` arguments of
  CoordinateCleaner’s functions; the layer’s size and MD5 checksum are
  recorded in the reference label.
- [`export_pyrate()`](https://gillescolling.com/OccurrenceCleaner/reference/export_pyrate.md)
  writes fossil records as PyRate input files, the layout of
  CoordinateCleaner’s
  [`write_pyrate()`](https://ropensci.github.io/CoordinateCleaner/reference/write_pyrate.html).
- The outlier test’s sampling correction
  (`settings$outlier$sampling_thresh`) reads records per country from
  `gazetteers = list(sampling = ...)` instead of querying GBIF at run
  time.
- [`reference_points()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_points.md)
  returns the points of a proximity test with their attributes, to
  inspect, filter or extend.
