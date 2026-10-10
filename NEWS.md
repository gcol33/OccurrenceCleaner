# OccurrenceCleaner 0.1.0

Initial release.

## Flagging
* `flag_occurrences()`: one verb for a data frame or an on-disk table (Parquet directory, `.vtr`, delimited file, or any `vectra_node`). Twenty-eight tests, one bit each in an integer flag word; nothing is dropped.
* Twelve tests reproduce CoordinateCleaner's record tests with its default buffers (`invalid`, `zero`, `equal`, `capital`, `centroid`, `institution`, `gbif_headquarters`, `sea`, `urban`, `country_mismatch`, `duplicate`, and the fossil age test `age_equal`, as `cf_equal()`); eight more are CoordinateCleaner's grouped and reference tests: `outlier` (`cc_outl()`), `age_outlier` (`cf_age()`), `spatiotemporal_outlier` (`cf_outl()`), `age_range_outlier` (`cf_range()`), `dataset_ddmm` (`cd_ddmm()`), `dataset_rounded` (`cd_round()`), `range` (`cc_iucn()`, with user range polygons) and `aohi` (`cc_aohi()`); eight read GBIF fields (`issue_coordinate`, `issue_taxon`, `issue_date`, `issue_rounded`, `basis_fossil`, `basis_living`, `establishment_introduced`, `establishment_managed`). Tests read from a record field carry that field as a prefix.
* Proximity tests run as kd-tree candidate searches on the unit sphere decided by WGS84 geodesic distance; polygon tests as grid-indexed point-in-polygon with exact boundary cells. Both in C++ with no external library.
* Streamed input is processed per file, written as `.vtr` parts with the kept columns, and resumable.
* The grouped tests (`outlier`, the fossil outlier tests, the dataset tests) run in a group pass over the whole input before the record tests; on streamed input it reads every file, buckets small groups on disk and keeps its result for a resumed run. Their options, with CoordinateCleaner's defaults, go in `settings`. `outlier` flags the records of outlier cells on the raster approximation for large species, where CoordinateCleaner 3.0.1 flags none; the fossil tests seed their age draws per taxon.

## Rules and tallies
* `tally_flags()`: loss tables by grouping columns, with numeric bins and named rules, over a data frame or the on-disk output. Per rule it also counts the records each test is the sole reason for.
* `summary()` on flagged records, on-disk output or a tally gives the percentage of records each test and rule removes, with the sole-reason share; `plot()` draws it as bars or, by group, as a grid, and maps kept and removed records with `type = "map"`.
* `has_flag()`, `flag_mask()`, `flag_tests()`, `default_tests()`.

## Reference data
* Own gazetteers rebuilt from Natural Earth (capitals, country and province centroids, land at 1:110m and 1:50m, urban areas, countries) and GBIF GRSciColl (institutions, without the five entries the `zero` test flags), each pinned by version and SHA-256 in `reference_info()`; the 1:10m land layer is fetched on demand by `download_reference()`.
* The Artificial Hotspot Occurrence Inventory (Park et al. 2023) is built from its Dryad deposit (CC0) for the `aohi` test and returned by `reference_points("aohi")`.
* `reference = "CoordinateCleaner"` reads that package's tables at run time and reproduces its flags; the equivalence suite documents every difference.
* `gazetteers` in `flag_occurrences()` replaces the reference layer of single tests with user points (data frame) or polygons (`sf`/`sfc`), as the `ref` arguments of CoordinateCleaner's functions; the layer's size and MD5 checksum are recorded in the reference label.
* `reference_points()` returns the points of a proximity test with their attributes, to inspect, filter or extend.
