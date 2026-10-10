# Story: OccurrenceCleaner

## Claim
Quality flags for species occurrence records at any scale: CoordinateCleaner's record tests, computed fast enough for a whole GBIF snapshot, with every record kept.

## Audience
Ecologists and biogeographers who clean GBIF or similar occurrence data in R. Most know CoordinateCleaner or have seen its tests in a methods section; many have only used `cc_*()` pipes that drop records. They know Darwin Core column names; they do not know vectra, Parquet streaming or kd-trees, and do not need to.

## Relation
- to: CoordinateCleaner 3.0.1 (Zizka et al. 2019)
- phrase: an extension of CoordinateCleaner tailored to large-scale occurrence data
- same: test definitions and default buffers of the eleven record tests; verified by `tests/testthat/test-equivalence.R`, which runs CoordinateCleaner on sampled records
- differs: flags instead of filtering (CoordinateCleaner's `cc_*()` default `value = "clean"` removes records); one verb with a `tests` argument instead of one function per test; singular test names (`capital`) where `clean_coordinates()` takes plural ones (`capitals`); one `buffers` list instead of `*_rad` arguments; own gazetteers by default; the documented flag differences (buffer circles, zero buffer, country codes, invalid coordinates, streamed duplicates); additions (GBIF issue, basis of record, establishment means)
- status: not a replacement; CoordinateCleaner remains the tool for outlier, range, dataset-level and fossil tests
- home: vignettes/coordinatecleaner.Rmd ("Coming from CoordinateCleaner")

## Arcs

### A1 Same answers as CoordinateCleaner
- question: Will my flags change if I switch from CoordinateCleaner?
- answer: The eleven record tests use CoordinateCleaner's definitions and default buffers; the test suite requires identical flags except for five documented differences, each tested.
- payoff: A user can cite CoordinateCleaner's tests in a methods section and run them here, and knows exactly where and by how much results can differ.
- evidence: tests/testthat/test-equivalence.R; ?flag_occurrences (Tests section); vignettes/coordinatecleaner.Rmd (side by side, where the flags differ)
- limits: buffer-edge band (99.7 to 99.9 % of each buffer); the zero buffer follows the documentation, not 3.0.1's behaviour; own gazetteers differ in coordinates from CoordinateCleaner's
- home: vignettes/coordinatecleaner.Rmd
- also: DESCRIPTION, README, ?OccurrenceCleaner, quickstart

### A2 Handles my scale
- question: Will it run on my data, up to a whole GBIF snapshot?
- answer: Proximity tests are nearest-neighbour queries, so a data frame of a few million records is flagged in seconds; an on-disk table is streamed in chunks, resumable per input file, so memory does not bound the input.
- payoff: The tests CoordinateCleaner users know can be run on the full GBIF snapshot instead of a download subset.
- evidence: vignettes/coordinatecleaner.Rmd (Speed); dev_notes/benchmark.md; bench/benchmark.R; vignettes/on-disk.Rmd
- limits: `duplicate` on streamed input is evaluated within each input file; `duplicate` and `equal` are no faster than CoordinateCleaner
- home: vignettes/on-disk.Rmd (streaming); vignettes/coordinatecleaner.Rmd (speed against CoordinateCleaner)
- also: DESCRIPTION, README

### A3 Flag once, choose the rule afterwards
- question: Which records should I drop?
- answer: Every test writes one flag per record and nothing is removed; a cleaning rule is a set of tests applied afterwards, and several rules can be compared on one pass.
- payoff: A user can report how much each rule removes per taxon, period or precision class, and change the rule without flagging again.
- evidence: vignettes/rules.Rmd; ?tally_flags; ?has_flag
- limits: year and coordinate uncertainty are not tests; they stay raw columns and are cut at tally time
- home: vignettes/rules.Rmd
- also: DESCRIPTION, README, ?OccurrenceCleaner, quickstart

### A4 GBIF's own quality fields
- question: Can I use what GBIF already tells me about each record?
- answer: Additional tests read GBIF's issue flags, basis of record and establishment means, marked as additions so they never change a CoordinateCleaner-equivalent flag.
- payoff: GBIF's processing warnings and record types enter the same rule as the coordinate tests.
- evidence: ?flag_tests; vignettes/tests.Rmd
- limits: the issue groups are this package's grouping of GBIF's issue names
- home: vignettes/tests.Rmd
- also: DESCRIPTION, README

### A5 Pinned reference data
- question: Which gazetteer produced these flags, and can I reproduce them?
- answer: Every gazetteer is rebuilt from its public source, pinned by version and checksum, and recorded in the flag output; `reference = "CoordinateCleaner"` uses that package's tables instead.
- payoff: A flag table can be traced to the exact reference data that produced it, years later.
- evidence: ?reference_info; vignettes/reference-data.Rmd; dev_notes/reference_data.md
- limits: GRSciColl licence not yet confirmed (dev_notes/reference_data.md)
- home: vignettes/reference-data.Rmd
- also: README, quickstart

## Non-goals
- No record is removed by the package.
- No outlier, range, dataset-level or fossil-age tests (CoordinateCleaner's `cc_outl`, `cc_iucn`, `cc_aohi`, `cd_*`, `cf_*`).
- No taxonomic name cleaning.

## Documents
- DESCRIPTION: listing text; claim, relation, A1-A4 in one sentence each
- README / landing: claim, relation, A1-A3 one line each, first example, rules, snapshot, test table, routing
- ?OccurrenceCleaner: entry point inside R; claim, relation, verb map
- quickstart (Get Started): tutorial from a data frame to a tally and a streamed table
- tests: explanation of each test (A4 home)
- rules: how-to choose and compare rules (A3 home)
- on-disk: how-to stream a snapshot (A2 home)
- gbif-workflow: how-to, a GBIF download end to end
- reference-data: explanation of the gazetteers (A5 home)
- coordinatecleaner: comparison (A1 home, relation home)
- help pages: reference

## Open
- Journey entries for the tests, rules, on-disk, gbif-workflow and reference-data articles.
