# OccurrenceCleaner 0.2.0

* `gentiana`: the 33,025 GBIF records of the genus *Gentiana* in Austria under CC0 or CC BY 4.0 from the snapshot of 2026-10-01, for examples and the case study of the package paper.
* `print()` methods for `occ_flags` (a header and the first records, with the tests each failed), `occ_tally` (records removed and kept per rule) and `occ_columns`; `occ_flagged` prints its reference on one line. `summary()` stays the full per-test report.
* `has_flag()` takes a flagged data frame as well as the flag words.
* `flag_reference()` returns the reference label recorded with a set of flags, in memory or on disk.
* `print()` and `summary()` of a flagged data frame or tally subset to other columns fall back to the data frame methods.

# OccurrenceCleaner 0.1.0

Initial release.

## Flagging
* `flag_occurrences()`: one verb for a data frame or an on-disk table (Parquet directory, `.vtr`, delimited file, or any `vectra_node`). Thirty tests, one bit each in an integer flag word; nothing is dropped.
* Twelve tests reproduce CoordinateCleaner's record tests with its default buffers (`invalid`, `zero`, `equal`, `capital`, `centroid`, `institution`, `gbif_headquarters`, `sea`, `urban`, `country_mismatch`, `duplicate`, and the fossil age test `age_equal`, as `cf_equal()`); eight more are CoordinateCleaner's grouped and reference tests: `outlier` (`cc_outl()`), `age_outlier` (`cf_age()`), `spatiotemporal_outlier` (`cf_outl()`), `age_range_outlier` (`cf_range()`), `dataset_ddmm` (`cd_ddmm()`), `dataset_rounded` (`cd_round()`), `range` (`cc_iucn()`, with user range polygons) and `aohi` (`cc_aohi()`); eight read GBIF fields (`issue_coordinate`, `issue_taxon`, `issue_date`, `issue_rounded`, `basis_fossil`, `basis_living`, `establishment_introduced`, `establishment_managed`); two set the land test against the habitat of the record's genus (`sea_nonmarine`, `land_marine`). Tests read from a record field carry that field as a prefix.
* Proximity tests run as kd-tree candidate searches on the unit sphere decided by WGS84 geodesic distance; polygon tests as grid-indexed point-in-polygon with exact boundary cells. Both in C++ with no external library.
* Streamed input is processed per file, written as `.vtr` parts with the kept columns, and resumable.
* The grouped tests (`outlier`, the fossil outlier tests, the dataset tests) run in a group pass over the whole input before the record tests; on streamed input it reads every file, buckets small groups on disk and keeps its result for a resumed run. Their options, with CoordinateCleaner's defaults, go in `settings`. `outlier` flags the records of outlier cells on the raster approximation for large species, where CoordinateCleaner 3.0.1 flags none; the fossil tests seed their age draws per taxon.

## Rules and tallies
* `tally_flags()`: loss tables by grouping columns, with numeric bins and named rules, over a data frame or the on-disk output. Per rule it also counts the records each test is the sole reason for.
* `summary()` on flagged records, on-disk output or a tally gives the percentage of records each test and rule removes, with the sole-reason share; `plot()` draws it as bars or, by group, as a grid, and maps kept and removed records with `type = "map"`.
* `has_flag()`, `flag_mask()`, `flag_tests()`, `default_tests()`.
* `as_spatialvalid()` writes flagged records, in memory or on disk, in the layout of CoordinateCleaner's `spatialvalid` object (`.cap`, `.zer`, ..., `.summary`, `TRUE` for pass), so code and methods written for it run unchanged; `flag_tests()` gives the column name per test.

## Reference data
* Own gazetteers rebuilt from Natural Earth (province centroids, land at 1:110m and 1:50m, urban areas, countries), the CIA World Factbook (capitals: 232 points, of which CoordinateCleaner's capitals are a rounding for 221 of 225, plus 243 Natural Earth capitals, alternative capitals and dependent-territory capitals marked `extension`), the thematicmapping.org World Borders Dataset 0.3 and the GEOLocate service (country centroids: 1,069 points from the three sources of CoordinateCleaner's table, which hold 645 of its 660 country centroids exactly, plus 516 Natural Earth polygon centroids and label points marked `extension`), GBIF GRSciColl, Wikidata, GeoNames and BGCI (institutions: 6,080 GRSciColl entries without the five the `zero` test flags; 7,810 Wikidata botanical gardens, natural history museums, zoos, aquaria and herbaria; 700 museums of Wikipedia's lists of natural history museums (English and six other language editions) placed by the town or institution the list names; the three GeoNames places of CoordinateCleaner's table; 3,652 gardens of BGCI GardenSearch with BGCI's own coordinates; column `extension` marks the 7,665 points from sources CoordinateCleaner's table does not draw on), each pinned by version and SHA-256 in `reference_info()`; the 1:10m land layer is fetched on demand by `download_reference()`.
* The Artificial Hotspot Occurrence Inventory (Park et al. 2023) is built from its Dryad deposit (CC0) for the `aohi` test and returned by `reference_points("aohi")`.
* `reference = "CoordinateCleaner"` reads that package's tables at run time and reproduces its flags; the equivalence suite documents every difference.
* `gazetteers` in `flag_occurrences()` replaces the reference layer of single tests with user points (data frame) or polygons (`sf`/`sfc`), as the `ref` arguments of CoordinateCleaner's functions; the layer's size and MD5 checksum are recorded in the reference label.
* `export_pyrate()` writes fossil records as PyRate input files, the layout of CoordinateCleaner's `write_pyrate()`.
* The outlier test's sampling correction (`settings$outlier$sampling_thresh`) reads records per country from `gazetteers = list(sampling = ...)` instead of querying GBIF at run time.
* `reference_points()` returns the points of a proximity test with their attributes, to inspect, filter or extend.
* Genus habitats for `sea_nonmarine` and `land_marine` are built from the Interim Register of Marine and Nonmarine Genera (Darwin Core archive of 2026-10-06, CC BY 4.0) and returned by `reference_habitat()`; `gazetteers = list(habitat = ...)` replaces them.
