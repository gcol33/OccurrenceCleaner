# Articles

### Workflows

- [Cleaning GBIF
  data](https://gillescolling.com/OccurrenceCleaner/articles/gbif-workflow.md):

  A table shaped like a GBIF download, from flagging every test to the
  retained records, with the catches checked against known errors.

- [Choosing a cleaning
  rule](https://gillescolling.com/OccurrenceCleaner/articles/rules.md):

  What each test and each rule removes, by taxon, record age and
  coordinate precision, and how to apply the rule you choose.

- [Large tables on
  disk](https://gillescolling.com/OccurrenceCleaner/articles/on-disk.md):

  Flag a directory of files too large for memory, tally from disk, join
  flags back to records and resume an interrupted run.

- [Running on several
  threads](https://gillescolling.com/OccurrenceCleaner/articles/parallel.md):

  Spread the outlier test and the proximity and polygon queries over
  several threads, check that the flags stay the same, read the measured
  speedup and set up OpenMP on each platform.

- [Cleaning fossil
  records](https://gillescolling.com/OccurrenceCleaner/articles/fossils.md):

  The age tests and PyRate export for Paleobiology Database records.

- [Custom reference points and
  polygons](https://gillescolling.com/OccurrenceCleaner/articles/gazetteers.md):

  Replace the reference points or polygons of one test with your own,
  including species range maps.

### Background

- [The tests in
  detail](https://gillescolling.com/OccurrenceCleaner/articles/tests.md):

  What each test checks, the fields it reads and the arguments that
  change it.

- [Outliers and dataset
  tests](https://gillescolling.com/OccurrenceCleaner/articles/outliers.md):

  The tests that judge a record against the rest of its species or
  dataset: geographic outliers, converted and gridded datasets,
  artificial hotspots.

- [Reference
  data](https://gillescolling.com/OccurrenceCleaner/articles/reference-data.md):

  Where each reference layer comes from, its version and licence, how
  the land scale changes the sea test and how the reference is recorded
  with the flags.

- [Compatibility with
  CoordinateCleaner](https://gillescolling.com/OccurrenceCleaner/articles/coordinatecleaner.md):

  Where the two packages agree, how that is tested, where the results
  differ and why, with timings.
