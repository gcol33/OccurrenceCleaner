# Flag occurrence records

Runs record tests over species occurrence records and writes one flag
per record per test. Nothing is removed and no threshold is baked in.

## Usage

``` r
flag_occurrences(
  x,
  tests = NULL,
  columns = occ_columns(),
  reference = c("OccurrenceCleaner", "CoordinateCleaner"),
  gazetteers = NULL,
  land_scale = 110,
  buffers = NULL,
  settings = NULL,
  duplicate_by = NULL,
  duplicate_cell = NULL,
  out = NULL,
  keep = NULL,
  part_rows = 2e+06,
  resume = TRUE,
  verbose = TRUE,
  n_threads = 1L
)
```

## Arguments

- x:

  A data frame, a `vectra_node`, or a path (file or directory).

- tests:

  Character vector of test names, see
  [`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md).
  `NULL` (the default) runs every test whose columns are in `x` (and
  `range` when `gazetteers` has range polygons); see
  [`test_plan()`](https://gillescolling.com/OccurrenceCleaner/reference/test_plan.md).
  A named test whose columns are missing from `x` is an error.

- columns:

  Field names, see
  [`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md).

- reference:

  `"OccurrenceCleaner"` (own gazetteers, the default) or
  `"CoordinateCleaner"` (that package's tables, read at run time). See
  [`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md).

- gazetteers:

  Named list of user-supplied reference layers, each replacing the
  reference layer of one test. Point tests (`capital`, `centroid`,
  `institution`, `gbif_headquarters`) take a data frame with longitude
  and latitude columns (named `lon`/`lat`, `longitude`/`latitude` or
  `decimalLongitude`/`decimalLatitude`, any case). Polygon tests (`sea`,
  `urban`, `country_mismatch`) take an `sf` or `sfc` object of POLYGON
  or MULTIPOLYGON geometries in longitude and latitude; for `sea` they
  are the land, and for `country_mismatch` the features need at least
  one code column (`iso_a2`, `iso_a3`, `adm0_a3` or `code`, any case).
  Each layer is indexed once per call, and its size and MD5 checksum are
  recorded in the reference label of the output. `range` takes species
  range polygons (see
  [test_range](https://gillescolling.com/OccurrenceCleaner/reference/test_range.md)),
  `sampling` a table of records per country for the sampling correction
  of
  [test_outlier](https://gillescolling.com/OccurrenceCleaner/reference/test_outlier.md),
  and `habitat` a table of genus habitats for
  [test_habitat](https://gillescolling.com/OccurrenceCleaner/reference/test_habitat.md)
  (see
  [`reference_habitat()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_habitat.md)).
  The land layer given for `sea` is also the land of the habitat tests.

- land_scale:

  Natural Earth scale of the land layer for `sea` and the habitat tests:
  110 (the default of CoordinateCleaner's `cc_sea()`; its
  `clean_coordinates()` uses `seas_scale = 50`), 50, or 10 (downloaded
  on first use, see
  [`download_reference()`](https://gillescolling.com/OccurrenceCleaner/reference/download_reference.md)).

- buffers:

  Named list overriding buffer distances in metres for `capital`
  (10000), `centroid` (1000), `institution` (100), `gbif_headquarters`
  (1000), `range` (0), `aohi` (10000), `sea_nonmarine` (0) and
  `land_marine` (0), or in degrees for `zero` (0.5). Unnamed entries
  keep the defaults.

- settings:

  Named list overriding the options of the grouped tests, one entry per
  test, each a named list; unnamed options keep their defaults, which
  are CoordinateCleaner's. See
  [test_outlier](https://gillescolling.com/OccurrenceCleaner/reference/test_outlier.md),
  [test_age_outlier](https://gillescolling.com/OccurrenceCleaner/reference/test_age_outlier.md),
  [test_spatiotemporal_outlier](https://gillescolling.com/OccurrenceCleaner/reference/test_spatiotemporal_outlier.md),
  [test_age_range_outlier](https://gillescolling.com/OccurrenceCleaner/reference/test_age_range_outlier.md),
  [test_dataset_ddmm](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_ddmm.md)
  and
  [test_dataset_rounded](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_rounded.md).

- duplicate_by:

  Additional column names a duplicate must share (as CoordinateCleaner's
  `additions`), for example an event date.

- duplicate_cell:

  Cell size in degrees. When given, coordinates are binned to this grid
  before comparing duplicates, so "same cell and species" counts.

- out:

  Output directory for streamed input (required then, ignored for a data
  frame).

- keep:

  Column names copied next to the flags in streamed output, for grouping
  in
  [`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
  (taxon, year, uncertainty, ...). The `id` column of `columns` is kept
  when present.

- part_rows:

  Target rows per output part file for streamed input: a part is written
  once at least this many rows have accumulated, and at the end of each
  input unit.

- resume:

  Continue a run in `out`: skip input files whose `.done` marker exists
  and resume the group stage from its checkpoint. `FALSE` deletes the
  earlier output in `out` and starts over.

- verbose:

  Report progress for streamed input.

- n_threads:

  Number of threads for the outlier test and the spatial queries. `0`
  uses every thread OpenMP hands out; a request above that is reduced to
  it, with a message.

## Value

For a data frame: `x` with an integer column `flags` and one logical
column `flag_<test>` per test, class `occ_flags` added in front, and
attributes `occ_tests`, `occ_test_plan`, `occ_layout_version`,
`occ_reference` and `occ_columns`.
[summary()](https://gillescolling.com/OccurrenceCleaner/reference/summary.occ_flags.md)
reports the share of records each test flags,
[plot()](https://gillescolling.com/OccurrenceCleaner/reference/plot.occ_summary.md)
draws it or maps the records. For streamed input: an object of class
`occ_flagged` describing the output directory, which
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
accepts; the parts are `.vtr` files holding the `id` and `keep` columns
and `flags`, readable with
[`vectra::tbl()`](https://gillescolling.com/vectra/reference/tbl.html).

## Details

Two choices are kept apart. Which tests run: by default every test whose
inputs are available, so a screening sees every potential problem the
columns allow;
[`test_plan()`](https://gillescolling.com/OccurrenceCleaner/reference/test_plan.md)
lists the tests that ran and the reason each other test did not. Which
records are excluded: a cleaning rule, a set of tests chosen afterwards
and applied with
[`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md)
or compared with
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md).
A rule for species distribution modelling might exclude fossil and
living specimens along with the coordinate problems; a study of fossil
ranges would keep the fossils and exclude other flags.

The grouped tests (`duplicate`, `outlier`, the three fossil outlier
tests and the two dataset tests) compare a record with the other records
of its key, species, taxon or dataset; they run in a group stage before
the record tests, which on streamed input reads every file once or twice
more and keeps its buckets and results in `out/.group`.

The input is either a data frame, or an on-disk table streamed in
chunks: a `vectra_node` (from
[`vectra::tbl_parquet()`](https://gillescolling.com/vectra/reference/tbl_parquet.html),
[`vectra::tbl_csv()`](https://gillescolling.com/vectra/reference/tbl_csv.html),
[`vectra::tbl()`](https://gillescolling.com/vectra/reference/tbl.html)),
a path to a Parquet file or directory of Parquet parts (such as a GBIF
snapshot), or a path to a `.vtr` or delimited text file. For a directory
each file is one resumable unit of work; the return follows the input,
see Value.

## Streamed runs

Before writing any output, a run records its configuration in
`out/flags_config.rds`: the tests, columns, `keep`, reference, buffers,
settings, duplicate options, package version, and each input file with
its size and modification time. A later call into the same `out` must
match the record, or it stops and names what differs; `resume = FALSE`
clears the directory instead. Sizes and modification times detect a
replaced, grown or touched file; they are not a hash of the contents.

The group stage checkpoints its state after a file or a bucket whenever
five minutes have passed, and at the end of each pass, so an
interruption repeats at most the work since the last checkpoint. The
record pass writes a `.done` marker per input file; an interruption
there repeats the file in progress.

A streamed run writes its progress to `out/progress.txt`, one line
overwritten on every report: the step, items done and total, seconds
elapsed, and the estimated seconds left in the step and in the run, and
the share of the run done. The estimate for the steps ahead uses
per-record costs measured on a part of the GBIF snapshot, scaled to the
speed of the run so far, so it is rough until the slower steps have
started. With `verbose`, the same is reported on the console every
minute.

## Threads

`n_threads` spreads the exact outlier test over species and the
proximity and point-in-polygon queries of the record tests over records.
Each species and each record is computed on one thread, so the flags do
not depend on the number of threads. Reading the input, the other tests
and the bookkeeping of the group stage run on one thread. Without OpenMP
support in the compiler every query runs on one thread.

Memory in the record pass is one input chunk, up to `part_rows` buffered
output rows and the group-test hits of the current block of 2^20 rows.
The group stage holds two million bucketed rows before writing them
(more above four billion records), the per-species record counts,
per-dataset histograms and raster cell counts of large species, the
duplicate keys of one bucket (at most four million records on average
when the input has more than 256 million), and the records of one
species (fewer than 10,000 for the exact outlier test) or one fossil
taxon. Its disk use is at most 24 bytes per record for `duplicate`, plus
the coordinates of the records of the outlier and fossil tests.

## Tests

See
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)
for the layout. Tests equivalent to
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/) use
its default buffers: `capital` 10 km, `centroid` 1 km, `institution` 100
m, `gbif_headquarters` 1 km, `zero` 0.5 degrees. Proximity tests are
closed balls in WGS84 geodesic distance. Records failing `invalid` are
given no spatial flag.

Documented differences to CoordinateCleaner 3.0.1, each verified in the
package tests:

- CoordinateCleaner approximates each buffer circle by an inscribed
  polygon (72 vertices for `capital`, `centroid`, `gbif_headquarters`;
  40 for `institution`), so a record between 99.9 % (`capital`,
  `centroid`, `gbif_headquarters`) or 99.7 % (`institution`) of the
  buffer and the buffer itself is flagged here and may not be there.
  Everything CoordinateCleaner flags is flagged here.

- `cc_zero`'s 0.5 degree buffer is interpreted by
  [terra](https://rspatial.github.io/terra/) as 0.5 metres, so
  CoordinateCleaner 3.0.1 flags only exact zeros; this package applies
  the documented 0.5 degree radius.

- `country_mismatch` compares the record's code with the ISO alpha-2
  code, the ISO alpha-3 code and the Natural Earth `ADM0_A3` code of the
  country polygon the point falls in, taking the ISO codes from Natural
  Earth's `ISO_A2_EH` and `ISO_A3_EH` columns, which are filled where
  `ISO_A2` and `ISO_A3` hold `-99` (France, Norway, Kosovo);
  CoordinateCleaner compares `ISO_A3` only, so it flags every record in
  France and Norway. Records without a code, or at sea, are flagged as
  in CoordinateCleaner.

- `outlier` flags the records of outlier cells in the raster
  approximation (species of 10,000 records or more, or
  `thinning = TRUE`); in CoordinateCleaner 3.0.1 that path never flags a
  record.

- `age_outlier` and `spatiotemporal_outlier` draw ages by the same
  procedure as `cf_age()` and `cf_outl()` but from a stream seeded per
  taxon, so a single run can differ record by record; when every age
  range has zero width the flags are identical.

- `dataset_rounded` leaves datasets below `min_unique_ds_size` untested,
  where `cd_round()` stops with an error; the dataset tests do not flag
  records without a dataset key.

- With the default reference the gazetteers are rebuilt from the
  original sources; `reference = "CoordinateCleaner"` uses that
  package's own tables, and `gazetteers` replaces the layer of single
  tests, as the `ref` arguments of CoordinateCleaner's functions do.

## Examples

``` r
x <- data.frame(species = c("a", "a", "b", "c"),
                decimalLongitude = c(12.58, 0, 16.37, 2.35),
                decimalLatitude = c(55.67, 0, 48.21, 48.85))
f <- flag_occurrences(x, tests = c("invalid", "zero", "gbif_headquarters", "capital"))
f[, c("species", "flags", "flag_zero", "flag_gbif_headquarters", "flag_capital")]
```
