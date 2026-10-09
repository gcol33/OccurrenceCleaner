# OccurrenceCleaner 0.1.0

Initial release.

## Flagging
* `flag_occurrences()`: one verb for a data frame or an on-disk table (Parquet directory, `.vtr`, delimited file, or any `vectra_node`). Nineteen tests, one bit each in an integer flag word; nothing is dropped.
* Eleven tests reproduce CoordinateCleaner's record tests with its default buffers (`val`, `zero`, `equ`, `cap`, `cen`, `inst`, `gbif`, `sea`, `urb`, `coun`, `dupl`); eight read GBIF fields (`issue_geo`, `issue_tax`, `issue_date`, `rounded`, `fossil`, `living`, `introduced`, `managed`).
* Proximity tests run as kd-tree candidate searches on the unit sphere decided by WGS84 geodesic distance; polygon tests as grid-indexed point-in-polygon with exact boundary cells. Both in C++ with no external library.
* Streamed input is processed per file, written as `.vtr` parts with the kept columns, and resumable.

## Rules and tallies
* `tally_flags()`: loss tables by grouping columns, with numeric bins and named rules, over a data frame or the on-disk output.
* `has_flag()`, `flag_mask()`, `flag_tests()`, `default_tests()`.

## Reference data
* Own gazetteers rebuilt from Natural Earth (capitals, country and province centroids, land at 1:110m and 1:50m, urban areas, countries) and GBIF GRSciColl (institutions), each pinned by version and SHA-256 in `reference_info()`; the 1:10m land layer is fetched on demand by `download_reference()`.
* `reference = "CoordinateCleaner"` reads that package's tables at run time and reproduces its flags; the equivalence suite documents every difference.
