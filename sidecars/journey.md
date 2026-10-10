# Journey: OccurrenceCleaner

Anchors are `<doc>.<slug>`; the documents carry no `@p:` markers yet, so entries are matched by order and first words. Entries for tests, rules, on-disk, gbif-workflow and reference-data are pending: those vignettes were written in another session on 2026-10-10 and are mapped in a later pass.

## DESCRIPTION

### desc.claim  [A1 A2]
- idea: extension of CC for scale
- job: Names the package as an extension of CoordinateCleaner for large-scale occurrence data.
- leaves: the parent package and the reason this one exists

### desc.tests  [A1]
- idea: the record tests, same buffers
- job: Lists the problems the tests catch and says they use CoordinateCleaner's tests and default buffers.
- leaves: what is flagged and that the definitions are CoordinateCleaner's

### desc.gbif  [A4]
- idea: GBIF fields
- job: Adds the tests that read GBIF's own quality fields.
- leaves: issue warnings, basis of record and establishment means are tests too

### desc.flags  [A3]
- idea: flagged and kept
- job: States that records are kept and the filter is chosen afterwards.
- leaves: the package never removes a record

### desc.scale  [A2]
- idea: seconds; billions by chunks
- job: Gives the scale: millions in seconds in memory, snapshots by streaming Parquet.
- leaves: both ends of the size range are covered

## README

### readme.claim  [A1 A2]
- idea: extension of CC · what is flagged
- job: Names the package as an extension of CoordinateCleaner for large-scale data and lists the coordinate problems it flags.
- leaves: the parent, the purpose and the list of problems

### readme.gbif  [A4]
- idea: GBIF fields
- job: Adds the three GBIF fields the package reads.
- leaves: issue warnings, basis of record, establishment means; details in the test table

### readme.flags  [A3]
- idea: flagged and kept
- job: States that records are kept and the filter is chosen afterwards.
- leaves: the package never removes a record

### readme.input  [A2]
- idea: what goes in; what is out of scope
- job: Places the package in the workflow by naming its inputs and the one neighbouring task it leaves out.
- leaves: a GBIF download, a snapshot or any Darwin Core table works; names are cleaned elsewhere

### readme.equivalence  [A1]
- idea: same flags, tested
- job: Says the test suite checks both packages return the same flags and points to the deliberate differences.
- leaves: equivalence is tested, and where the exceptions are listed

### readme.scale  [A2]
- idea: seconds; billions by chunks
- job: Gives the practical input size, with a link to the timings.
- leaves: how large an input is practical, and where the numbers come from

### readme.install  (section)

### readme.example  [A3]  (code)
- idea: smallest call
- job: Shows the smallest call on three records.
- leaves: the call and its input shape

### readme.example-result  [A1 A3]
- idea: what each record trips
- job: Explains the returned columns and why each of the three records is flagged.
- leaves: the `flag_<test>` columns and the `flags` column, one bit per test; one record can trip several tests

### readme.rules  [A3]  (section)
- idea: several rules, one pass
- job: Shows a rule as a set of tests and compares two rules on the same flags.
- leaves: `has_flag()`, `tally_flags()`, and that year and uncertainty are binned at tally time

### readme.snapshot  [A2]  (section)
- idea: streaming a snapshot
- job: Shows the same verb on a GBIF Parquet snapshot, with resumable units.
- leaves: the on-disk call, `keep`, `out`, and that a rerun resumes

### readme.box  (list)
- idea: exported functions
- job: Lists each exported function by what it does.
- leaves: the verb map

### readme.tests  [A1 A4]  (table)
- idea: tests, definitions, sources
- job: Defines each test in one line and names its CoordinateCleaner source or marks it an addition.
- leaves: the test names and their origin

### readme.method  [A1]
- idea: how tests are computed
- job: Says how proximity and polygon tests are computed.
- leaves: kd-tree and geodesic distance; grid-indexed point-in-polygon

### readme.reference  [A1 A5]
- idea: pinned gazetteers; CC tables
- job: Says where the gazetteers come from and that CoordinateCleaner's tables give its flags up to the documented differences.
- leaves: own gazetteers are pinned; `reference = "CoordinateCleaner"`; where the differences are listed

### readme.docs  (section)
- idea: routing
- job: Links every article and the reference index by title.
- leaves: where each topic lives

### readme.support  (section)
### readme.license  (section)
### readme.citation  (section)

## ?OccurrenceCleaner

### pkg.overview  [A1 A3]
- idea: extension of CC; flags, rule afterwards; verb map
- job: States the relation, that records are kept and the rule chosen afterwards, and points to the three main functions.
- leaves: the verb map

## Quick start

### qs.opener  [A1 A3]
- idea: extension of CC; flag, keep, query
- job: States the relation and that the drop decision is a query over the flags.
- leaves: the parent package, the flag word, and the idea of choosing afterwards

### qs.install  (section)

### qs.input
- idea: required columns
- job: Names the columns the input needs.
- leaves: Darwin Core names, case-insensitive, `occ_columns()`

### qs.flag  (code)
### qs.flag-result  [A1]
- idea: why each record is flagged
- job: Explains each of the five records' flags.
- leaves: one record can trip several tests; coastline effects on `country_mismatch`

### qs.tests  [A1 A4]  (table)
### qs.tests-note  [A1 A4]
- idea: eleven CC tests, then GBIF fields
- job: Says which tests come from CoordinateCleaner, up to the documented differences, and which read GBIF fields.
- leaves: the split between equivalent tests and additions

### qs.rules  [A3]  (section)
- idea: rules as queries; tally
- job: Defines a rule and compares two with `has_flag()` and `tally_flags()`.
- leaves: a rule, the tally columns

### qs.bins  [A3]
- idea: raw columns cut at tally time
- job: Shows year binned at tally time.
- leaves: `bins`

### qs.buffers  [A1]
- idea: CC default buffers; override
- job: States the default buffers and shows changing one.
- leaves: `buffers = list(capital = 500)`

### qs.reference  [A5]
- idea: pinned gazetteers; CC tables; land scale
- job: Shows where the gazetteers come from, the CoordinateCleaner alternative and the land scales.
- leaves: `reference_info()`, `reference = "CoordinateCleaner"`, `land_scale` and which CoordinateCleaner default it matches

### qs.disk  [A2]  (section)
- idea: stream a table
- job: Streams a two-part table and tallies it.
- leaves: `out`, `keep`, resumable units

### qs.snapshot-pointer  [A2]
- idea: for a snapshot
- job: Says how to point the same call at a GBIF snapshot.
- leaves: the snapshot path and `flagged_table()`

## Coming from CoordinateCleaner

### cc.opener  [A1]
- idea: same tests, flags; what this article covers
- job: States the relation and lists what the article covers.
- leaves: the article's scope; CoordinateCleaner is only suggested

### cc.install  (section)

### cc.mapping  [A1]  (table)
- idea: function to test map
- job: Maps each CoordinateCleaner function and argument to its counterpart here.
- leaves: the name map, including the two land-scale defaults

### cc.no-cc-names  [A1]
- idea: one verb, no cc_* names
- job: Explains that tests are chosen by name and no `cc_*` function is masked.
- leaves: both packages can be attached together

### cc.test-names  [A1]  (table)
- idea: plural to singular test names; validity
- job: Maps `clean_coordinates()` test names to the names here and says how validity differs.
- leaves: the `tests` vocabulary of both packages; invalid records do not stop a run here

### cc.pipe  [A1 A3]  (section)
- idea: filter-as-you-go vs flag and subset
- job: Shows a dropping `cc_*()` pipe and the same cleaning as one flag call and one subset.
- leaves: the rule can be changed without flagging again

### cc.clean-coordinates  [A1]
- idea: clean_coordinates is closer; TRUE means opposite
- job: Names `clean_coordinates()` as the closer equivalent and warns that its TRUE means pass.
- leaves: the sign convention differs

### cc.both  [A1]  (code)
### cc.agreement  [A1]  (table)
### cc.agreement-note  [A1]
- idea: where they differ and that it is tested
- job: Names the two tests that differ in the example and says the suite enforces the documented differences.
- leaves: the reader expects the next section

### cc.buffer-circles  [A1]
### cc.zero-buffer  [A1]
### cc.country-codes  [A1]
### cc.invalid  [A1]
### cc.streamed-duplicates  [A1 A2]
### cc.gazetteers  [A1 A5]

### cc.speed  [A2]  (section)
- idea: kd-tree vs polygons; timings
- job: Explains why proximity tests are faster and gives timings with machine and versions.
- leaves: the speed ratio per test and the benchmark script

### cc.no-counterpart  [A1]  (section)
- idea: what stays in CoordinateCleaner
- job: Lists the CoordinateCleaner functions with no counterpart and why `cc_outl()` is not a record test.
- leaves: when to keep using CoordinateCleaner

## tests
TODO: pending.

## rules
TODO: pending.

## on-disk
TODO: pending.

## gbif-workflow
TODO: pending.

## reference-data
TODO: pending.
