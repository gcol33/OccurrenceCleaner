# Flag occurrence records

Runs a set of record tests over species occurrence records and writes
one flag per record per test. Nothing is removed and no threshold is
baked in: a cleaning rule is a set of tests, applied afterwards with
[`has_flag()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_mask.md)
or summarised with
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md).

## Usage

``` r
flag_occurrences(
  x,
  tests = NULL,
  columns = occ_columns(),
  reference = c("natural_earth", "CoordinateCleaner"),
  land_scale = 110,
  buffers = NULL,
  duplicate_by = NULL,
  duplicate_cell = NULL,
  out = NULL,
  keep = NULL,
  part_rows = 2e+06,
  resume = TRUE,
  verbose = TRUE
)
```

## Arguments

- x:

  A data frame, a `vectra_node`, or a path (file or directory).

- tests:

  Character vector of test names, see
  [`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md).
  Default
  [`default_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/default_tests.md).
  A test whose fields are missing from `x` is an error.

- columns:

  Field names, see
  [`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md).

- reference:

  `"natural_earth"` (own gazetteers, the default) or
  `"CoordinateCleaner"` (that package's tables, read at run time). See
  [`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md).

- land_scale:

  Natural Earth scale of the land layer for `sea`: 110
  (CoordinateCleaner's default), 50, or 10 (downloaded on first use, see
  [`download_reference()`](https://gillescolling.com/OccurrenceCleaner/reference/download_reference.md)).

- buffers:

  Named list overriding buffer distances in metres for `capital`,
  `centroid`, `institution`, `gbif_headquarters`, or in degrees for
  `zero`. Unnamed entries keep the defaults.

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

  Skip input units whose output already exists.

- verbose:

  Report progress for streamed input.

## Value

For a data frame: `x` with an integer column `flags` and one logical
column `flag_<test>` per test, class `occ_flags` added in front, and
attributes `occ_tests`, `occ_layout_version`, `occ_reference` and
`occ_columns`.
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

The input is either a data frame, or an on-disk table streamed in
chunks: a `vectra_node` (from
[`vectra::tbl_parquet()`](https://gillescolling.com/vectra/reference/tbl_parquet.html),
[`vectra::tbl_csv()`](https://gillescolling.com/vectra/reference/tbl_csv.html),
[`vectra::tbl()`](https://gillescolling.com/vectra/reference/tbl.html)),
a path to a Parquet file or directory of Parquet parts (such as a GBIF
snapshot), or a path to a `.vtr` or delimited text file. For a directory
each file is one resumable unit of work; the return follows the input,
see Value.

## Tests

See
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)
for the layout. Tests equivalent to CoordinateCleaner use its default
buffers: `capital` 10 km, `centroid` 1 km, `institution` 100 m,
`gbif_headquarters` 1 km, `zero` 0.5 degrees. Proximity tests are closed
balls in WGS84 geodesic distance. Records failing `invalid` are given no
spatial flag.

Documented differences to CoordinateCleaner 3.0.1, each verified in the
package tests:

- CoordinateCleaner approximates each buffer circle by an inscribed
  polygon (72 vertices for `capital`, `centroid`, `gbif_headquarters`;
  40 for `institution`), so a record between 99.9 % (`capital`,
  `centroid`, `gbif_headquarters`) or 99.7 % (`institution`) of the
  buffer and the buffer itself is flagged here and may not be there.
  Everything CoordinateCleaner flags is flagged here.

- `cc_zero`'s 0.5 degree buffer is interpreted by terra as 0.5 metres,
  so CoordinateCleaner 3.0.1 flags only exact zeros; this package
  applies the documented 0.5 degree radius.

- `country_mismatch` compares the record's code with both the alpha-2
  and alpha-3 codes of the Natural Earth country polygon the point falls
  in; CoordinateCleaner compares alpha-3 only. Records without a code,
  or at sea, are flagged as in CoordinateCleaner.

- `duplicate` on streamed input is evaluated within each input file
  (Parquet part), not across the whole table.

- With the default reference the gazetteers are rebuilt from the
  original sources; `reference = "CoordinateCleaner"` uses that
  package's own tables.

## Examples

``` r
x <- data.frame(species = c("a", "a", "b", "c"),
                decimalLongitude = c(12.58, 0, 16.37, 2.35),
                decimalLatitude = c(55.67, 0, 48.21, 48.85))
f <- flag_occurrences(x, tests = c("invalid", "zero", "gbif_headquarters", "capital"))
f[, c("species", "flags", "flag_zero", "flag_gbif_headquarters", "flag_capital")]
```
