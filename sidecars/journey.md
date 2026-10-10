# Journey: OccurrenceCleaner

Anchors are `<doc>.<slug>`; the documents carry no `@p:` markers yet, so entries are matched by order and first words. Articles are mapped per section where a section develops one point; the opener of each is its own entry.

## DESCRIPTION

### desc.claim  [A1 A2]
- idea: extension of CC for scale
- job: Names the package as an extension of CoordinateCleaner for large-scale occurrence data.
- leaves: the parent package and the reason this one exists

### desc.tests  [A1]
- idea: the record tests, same buffers
- job: Lists the problems the tests catch, including outliers and converted or gridded datasets, and says they use CoordinateCleaner's tests and defaults.
- leaves: what is flagged and that the definitions are CoordinateCleaner's

### desc.gbif  [A4 A7]
- idea: GBIF fields; habitat at sea and on land
- job: Adds the tests that read GBIF's own quality fields and the genus-habitat check of land and sea.
- leaves: issue warnings, basis of record and establishment means are tests too; records at sea or on land are checked against the genus habitat (IRMNG)

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
- job: Names the package as an extension of CoordinateCleaner for large-scale data and lists the problems it flags, from coordinates at centroids to outliers and converted datasets.
- leaves: the parent, the purpose and the list of problems

### readme.gbif  [A4 A7]
- idea: GBIF fields; habitat tests
- job: Adds the three GBIF fields the package reads and the two habitat tests.
- leaves: issue warnings, basis of record, establishment means; land genera at sea and marine genera on land; details in the test table

### readme.flags  [A3]
- idea: flagged and kept
- job: States that records are kept and the filter is chosen afterwards.
- leaves: the package never removes a record

### readme.input  [A2 A3]
- idea: what goes in, what is out of scope, where the kept records go
- job: Places the package in the workflow: its inputs with the packages they come from (rgbif, paleobioDB), name matching left to other packages (taxize), and where the kept records go (dismo, sdm, phytools, red, PyRate via `export_pyrate()`).
- leaves: a GBIF download, a PBDB table, a snapshot or any Darwin Core table works; names are cleaned elsewhere; where the package sits between data sources and analyses

### readme.equivalence  [A1]
- idea: reimplemented; same flags, tested
- job: Says the tests are reimplemented with CoordinateCleaner's definitions and defaults, that CoordinateCleaner is needed only to compare, and that the test suite checks both return the same flags, pointing to the deliberate differences.
- leaves: CoordinateCleaner is not called at run time; equivalence is tested, and where the exceptions are listed

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

### readme.grouped  [A6]  (section)
- idea: grouped tests; settings
- job: Says why the outlier and dataset tests run in a pass over the whole input and shows `settings` in one call.
- leaves: the grouped tests exist, work streamed too, and take CoordinateCleaner's options through `settings`

### readme.fossil  [A1 A6]  (code)
- idea: PBDB table, clean_fossils' tests
- job: Shows a PBDB fossil table flagged with the age test and two fossil outlier tests, columns named once.
- leaves: fossil tables take the same verb; `occ_columns()` for PBDB names; ages read from `min_ma`, `max_ma` by default

### readme.snapshot  [A2]  (section)
- idea: streaming a snapshot
- job: Shows the same verb on a GBIF Parquet snapshot, with resumable units.
- leaves: the on-disk call, `keep`, `out`, and that a rerun resumes

### readme.box  (list)
- idea: exported functions
- job: Lists each exported function by what it does.
- leaves: the verb map, including `buffers` and `settings`, the `occ_columns()` fields (genus and kingdom among them), `reference_points()` for custom gazetteers and AHOI, `reference_habitat()`, `export_pyrate()` and `as_spatialvalid()`

### readme.tests  [A1 A4 A6 A7]  (table)
- idea: tests, definitions, sources
- job: Defines each test in one line and names its CoordinateCleaner source or marks it an addition.
- leaves: the test names and their origin: twenty from CoordinateCleaner, including range, hotspot, outlier, dataset and four fossil tests; ten additions, two of them the habitat tests

### readme.method  [A1]
- idea: how tests are computed
- job: Says how proximity and polygon tests are computed.
- leaves: kd-tree and geodesic distance; grid-indexed point-in-polygon

### readme.reference  [A1 A5]
- idea: pinned gazetteers; CC tables
- job: Says where the gazetteers come from and that CoordinateCleaner's tables give its flags up to the documented differences.
- leaves: own gazetteers are pinned, from Natural Earth, GRSciColl and Wikidata, and IRMNG for genus habitats; `reference = "CoordinateCleaner"`; where the differences are listed; `gazetteers` for the user's own layers

### readme.docs  (section)
- idea: routing
- job: Links every article and the reference index by title.
- leaves: where each topic lives

### readme.contributing  (section)
- idea: how to contribute
- job: Points to the CONTRIBUTING page on the site.
- leaves: where bug reports and changes go

### readme.support  (section)

### readme.acknowledgements  [A1]  (section)
- idea: credit CC authors in specifics
- job: Credits Zizka and co-authors for the tests, default buffers and grouped-test options, and says what this package takes from CoordinateCleaner: the specification and the reference sources.
- leaves: who made the tests and what was taken from them

### readme.license  (section)

### readme.citation  (section)
- idea: cite both, as bibtex
- job: Gives the bibtex for this package and for Zizka et al. (2019), the same two entries `citation()` returns.
- leaves: both references ready to paste

## ?OccurrenceCleaner

### pkg.overview  [A1 A3]
- idea: extension of CC; flags, rule afterwards; verb map
- job: States the relation, that records are kept and the rule chosen afterwards, and points to the three main functions.
- leaves: the verb map

### pkg.credit  [A1]
- idea: credit CC authors; cite both
- job: Credits Zizka and co-authors for the tests and defaults and asks for both citations.
- leaves: `citation("OccurrenceCleaner")` gives both

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
- idea: CC-equivalent tests, then GBIF fields
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
- idea: plural to singular test names
- job: Maps CoordinateCleaner's plural test names, and `clean_fossils()`'s "agesequal", to the names here.
- leaves: the `tests` vocabulary of both packages

### cc.validity  [A1]
- idea: validity is a named test that does not stop the run
- job: Says `clean_coordinates()` runs an unnamed coordinate check first and stops on failure, while `invalid` here is one test among the others.
- leaves: invalid records do not stop a run here

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
### cc.large-outliers  [A1 A6]
### cc.age-draws  [A1 A6]
### cc.small-datasets  [A1 A6]
### cc.streamed-duplicates  [A1 A2]
### cc.gazetteers  [A1 A5]

### cc.speed  [A2]  (section)
- idea: kd-tree vs polygons; timings
- job: Explains why proximity tests are faster and gives timings with machine and versions.
- leaves: the speed ratio per test and the benchmark script

### cc.around-tests  [A1]  (section)
- idea: every function has a counterpart; the functions around the tests
- job: Says every CoordinateCleaner function has a counterpart and maps the ones around the tests: `cc_outl(sampling_thresh)`, `write_pyrate()`, plot, summary and the class check; explains why the sampling counts are a table and why `export_pyrate()` has its own name.
- leaves: counts given as `gazetteers = list(sampling = ...)` are reproducible and recorded; both packages can be attached

### cc.spatialvalid  [A1]  (code)
- idea: code for spatialvalid runs on as_spatialvalid
- job: Says `as_spatialvalid()` writes CoordinateCleaner's column names with TRUE for pass and the `spatialvalid` class, that its methods work on it, and that the tests compare it with `clean_coordinates()`; shows it on the side-by-side records.
- leaves: a CoordinateCleaner script keeps working after the switch

## The tests in detail (explanation, A4 home)

### tests.opener  [A1 A4 A7]
- idea: eleven CC record tests, ten additions (eight GBIF fields, two habitat); the rest elsewhere; per-test help
- job: Says what the article covers per test and which tests come from CoordinateCleaner.
- leaves: the split into equivalent tests and additions; `?test_<name>` pages exist

### tests.install  (section)

### tests.flag-word  [A3]  (section)
- idea: one bit per test; layout version; default tests
- job: Defines the flag word, shows a mask and says why the layout is versioned.
- leaves: `2^bit` sums, `flag_mask()`, `has_flag()`, `layout_version`, `default_tests()`

### tests.invalid  [A1]  (section)
- idea: invalid gets no other spatial flag
- job: Defines invalid coordinates and shows that such records get no other spatial flag.
- leaves: text coercion, boundary values valid, the difference from CoordinateCleaner

### tests.zero-equal  [A1]  (section)
- idea: planar 0.5 degree disc; equal; zero buffer
- job: Defines `zero` and `equal`, shows the disc edge and how `buffers = list(zero = 0)` gives CoordinateCleaner 3.0.1's behaviour.
- leaves: the zero radius is in degrees

### tests.proximity  [A1]  (section)
- idea: four reference-point tests; geodesic closed ball; buffer sweep
- job: Defines the four proximity tests, shows the 1 km edge to 0.1 m, and how the flagged share grows with the capital buffer.
- leaves: closed geodesic buffers; the inscribed-polygon band is the only difference; the capital buffer matters most

### tests.sea  [A1 A5]  (section)
- idea: land polygons at three scales
- job: Defines `sea` and shows that the land scale decides coastal records.
- leaves: `land_scale`, which CoordinateCleaner default each scale matches

### tests.habitat  [A7]  (section)
- idea: sea vs genus habitat; IRMNG; homonyms; coast and fossils
- job: Defines `sea_nonmarine` and `land_marine`, where the habitats come from and which genera stay untested, and shows the three tests side by side.
- leaves: `reference_habitat()`; `genus` and `kingdom` columns; the land and buffers of the habitat tests; `basis_fossil` for marine fossils

### tests.urban  [A1]  (section)
- idea: urban polygons; not a default
- job: Defines `urban` and why it is off by default.
- leaves: an urban record outside the capital buffer is still urban

### tests.country  [A1]  (section)
- idea: three code systems; missing codes flagged
- job: Defines `country_mismatch`, its three code systems, and that missing codes are flagged.
- leaves: GBIF alpha-2 works; check the tally before putting it in a rule

### tests.duplicate  [A1 A2]  (section)
- idea: first kept; duplicate_by; duplicate_cell
- job: Defines `duplicate` and the two arguments that change what counts as the same record.
- leaves: removing flagged records leaves one per key; a taxon key avoids spelling splits

### tests.issues  [A4]  (section)
- idea: four issue groups; rounding is precision
- job: Defines the four issue tests by the GBIF issue names they hold and why rounding is separate.
- leaves: the group table; precision belongs to `coordinateUncertaintyInMeters`

### tests.basis-establishment  [A4]  (section)
- idea: fossil, living, introduced, managed
- job: Defines the four field-read tests and that their use depends on the question.
- leaves: the choice is made in the rule

### tests.columns  (section)
- idea: only needed fields; missing field errors
- job: Shows renaming columns and that a missing field stops with an error.
- leaves: `occ_columns()`; no test is skipped silently

## Choosing a cleaning rule (how-to, A3 home)

### rules.opener  [A3]
- idea: flag once; four steps
- job: States the approach and lists the four steps the article follows.
- leaves: flag, measure, break down, apply

### rules.install  (section)

### rules.example-data  [A3]  (section)
- idea: simulated European records with planted errors
- job: Builds records on land with GBIF fields, then plants capital, zero, sea and duplicate errors.
- leaves: an input with known errors

### rules.flag-once  [A3]
- idea: defaults plus issue and fossil tests
- job: Flags the records once with the tests the article uses.
- leaves: the `occ_flags` object `summary()` and `plot()` dispatch on

### rules.per-test  [A3]  (section)
- idea: pct and only
- job: Explains `flagged`, `pct` and `only`, and why per-test shares add up to more than the rule.
- leaves: how often a problem occurs vs how much loss a test alone causes

### rules.compare  [A3]  (section)
- idea: three candidate rules
- job: Compares three rules and shows which tests are the sole reason for removals.
- leaves: named rules in `summary()`; records failing several tests count under no `only`

### rules.by-group  [A3]  (section)
- idea: by kingdom
- job: Splits the shares by group and draws the grid.
- leaves: `by` in `summary()` and `plot()`

### rules.bins  [A3]  (section)
- idea: year and uncertainty cut at tally time
- job: Bins year and uncertainty at tally time and says when to keep the tally rather than the summary.
- leaves: `bins`; `<column>_bin`; missing values get their own class

### rules.map  [A3]  (section)
- idea: map of removed records
- job: Maps the records a rule removes.
- leaves: `plot(type = "map")`

### rules.apply  [A3]  (section)
- idea: complement of has_flag
- job: Applies the chosen rule and shows a raw-column cut beside it.
- leaves: the cleaned table; no re-flagging for another rule

### rules.math  [A3]  (section)
- idea: bit arithmetic of the counts
- job: Gives the three bit conditions behind every count.
- leaves: the bit mask of a rule; one pass per group

## Large tables on disk (how-to, A2 home)

### disk.opener  [A2]
- idea: snapshot too big for memory; what the article covers
- job: States why streaming is needed and lists the article's topics.
- leaves: inputs accepted, output beside kept columns

### disk.install  (section)

### disk.input  [A2]  (section)
- idea: three parts stand in for a snapshot
- job: Builds a three-file input with GBIF's lower-case names.
- leaves: the accepted input types

### disk.flag  [A2]  (section)
- idea: out, keep, id; units, parts, markers
- job: Flags into an output directory and explains units, part files, markers and the metadata file.
- leaves: memory is bounded by chunk size and `part_rows`

### disk.resume  [A2]  (section)
- idea: rerun skips done units; config mismatch stops
- job: Shows resuming after an interruption and that a different configuration cannot write into the same directory.
- leaves: `.done` markers; `resume = FALSE`; one directory, one configuration

### disk.tally  [A2 A3]  (section)
- idea: tally streams parts
- job: Tallies straight from disk and shows the error for a column not kept.
- leaves: grouping columns must be kept at flag time

### disk.read  [A2]  (section)
- idea: flagged_table, collect, join on id
- job: Reads the flags as a vectra table and joins them back to the records.
- leaves: `flagged_table()`, lazy queries, the identifier join

### disk.duplicates  [A1 A2]  (section)
- idea: duplicates within a unit only
- job: Shows that duplicates are found within each input file and how to get whole-table duplicates.
- leaves: split by species, or run `duplicate` on the collected taxa

### disk.node  [A2]  (section)
- idea: a vectra node is one unit
- job: Flags a filtered subset without writing it out.
- leaves: filter pushdown

### disk.snapshot  [A2]  (section)
- idea: the real snapshot call; speed; restartable
- job: Gives the call for a GBIF snapshot and what the benchmark does and does not cover.
- leaves: in-memory timing; streaming adds I/O not measured

## Cleaning GBIF data (how-to, end to end)

### gbif.opener  [A3]
- idea: whole workflow on simulated GBIF data
- job: States the workflow and why the data are simulated.
- leaves: every error is labelled, so catches can be checked

### gbif.install  (section)

### gbif.data  [A3 A4]  (section)
- idea: clean records plus 236 labelled errors
- job: Builds 2,000 clean records with GBIF columns, then adds labelled errors of nine kinds and 40 copies.
- leaves: the `truth` column; the `issue` format

### gbif.flag  [A3 A5]  (section)
- idea: all tests once; reference stamp; per-test summary
- job: Flags every test once and shows the per-test shares and the reference stamp.
- leaves: `occ_reference` to store with any cleaned table

### gbif.truth  [A1 A4]
- idea: which test catches which error
- job: Cross-tabulates truth against tests and explains the catches, the misses and the two flagged clean records.
- leaves: negated and whole-degree records are beyond any record test; GBIF warnings catch swaps on land

### gbif.map  [A3]  (section)
- idea: where flagged records are
- job: Maps the records the spatial rule removes.
- leaves: the clusters by error type

### gbif.combos  [A3]  (section)
- idea: test combinations
- job: Counts test combinations from distinct flag words and explains the most common.
- leaves: overlap decides what an extra test adds

### gbif.ladder  [A3]  (section)
- idea: five rules, loose to strict
- job: Compares five rules and gives what each step adds, overall and by kingdom.
- leaves: the rule ladder; sole-reason bars

### gbif.age-precision  [A3]  (section)
- idea: year and uncertainty bins; a threshold beside the rule
- job: Shows where a rule removes most by period and precision and applies an uncertainty cut next to it.
- leaves: thresholds stay outside flagging

### gbif.cleaned  [A3]  (section)
- idea: the wild rule result
- job: Applies one rule and checks the result against the truth.
- leaves: what the rule keeps and which errors remain

### gbif.guidance  [A1 A2 A3 A4]  (section)
- idea: six practical rules
- job: Turns the article's findings into six recommendations.
- leaves: run all tests once; know the country, sea, duplicate and issue caveats; no thresholds at flag time

## Reference data (explanation, A5 home)

### ref.opener  [A5]
- idea: seven tests use reference data; what the article covers
- job: Names the reference layers and lists the article's topics.
- leaves: points vs polygons

### ref.install  (section)

### ref.layers  [A5]  (section)
- idea: sources, versions, licences
- job: Lists each layer with source and version, which test reads it, and the licences.
- leaves: Natural Earth public domain; GRSciColl counts and status; the five zero-coordinate institutions left out; Wikidata classes and counts, CC0; IRMNG archive, licence, citation and class counts; nothing copied from CoordinateCleaner

### ref.vs-cc  [A1 A5]  (section)
- idea: same places, different tables
- job: Compares the package gazetteers with CoordinateCleaner's, layer by layer (institutions: BGCI not redistributable, Wikidata gardens instead with measured coverage; Wikipedia and GeoNames rows rebuilt from their sources), and shows the capital difference in flags.
- leaves: where the two references flag different records and why

### ref.land-scale  [A1 A5]  (section)
- idea: 1:110m vs 1:50m on the Danish coast
- job: Measures where the two land scales disagree and how to get 1:10m.
- leaves: the scale matters for coastal and island taxa; the download is checksummed

### ref.buffers  [A1]  (section)
- idea: default buffers; units
- job: States the default buffers and shows a smaller capital buffer.
- leaves: zero in degrees, others in metres

### ref.stamp  [A5]  (section)
- idea: reference recorded with the flags
- job: Shows the reference and layout stamps on a flagged table and on disk.
- leaves: one directory never mixes references

### ref.choose  [A1 A5]  (section)
- idea: which reference to use
- job: Says when to use each reference.
- leaves: own gazetteers (Natural Earth, GRSciColl, Wikidata) by default; CoordinateCleaner's to compare with published work

## Outliers and dataset tests (how-to, A6 home)

### out.opener  [A6]
- idea: six grouped tests; group pass; what the article covers
- job: Names the tests that compare a record with its species or dataset, their CoordinateCleaner functions and why they run in a pass of their own.
- leaves: the grouped tests; the fossil ones are in the fossil article

### out.install  (section)

### out.data  [A6]  (section)
- idea: alpine plants plus far records and two faulty atlases
- job: Builds 961 records of four species in three datasets and adds far records, a converted atlas and a gridded atlas.
- leaves: the `truth` column; `datasetKey`

### out.outlier  [A1 A6]  (section)
- idea: quantile fence; min_occs
- job: Flags geographic outliers with the default fence and explains the one miss and the untested small species.
- leaves: Q75 + 5 x IQR of mean distances; `min_occs`

### out.sampling  [A1 A6]
- idea: sampling correction from supplied counts
- job: Explains CoordinateCleaner's sampling correction and runs it with a per-country count table.
- leaves: `settings = list(outlier = list(sampling_thresh = ...))` with `gazetteers = list(sampling = <counts>)`; outliers stay flagged only in well-sampled countries

### out.methods  [A6]
- idea: three methods via settings
- job: Compares the quantile, MAD and distance methods and maps the default result.
- leaves: `settings = list(outlier = list(method = ...))`; MAD is stricter

### out.large  [A1 A6]  (section)
- idea: raster approximation from 10,000 records
- job: Flags one far record in a species of 15,001 and says CoordinateCleaner 3.0.1 flags none on this path.
- leaves: `thinning`, `thinning_res`

### out.datasets  [A6]  (section)
- idea: ddmm and gridded atlases; what each test reads
- job: Flags the two faulty atlases and shows the decimal parts that each test reads.
- leaves: the dataset key; `occ_columns(dataset = ...)`; records without a key untested

### out.aohi  [A5]  (section)
- idea: artificial hotspots
- job: Defines `aohi` and the inventory and shows three plant hotspots flagged.
- leaves: `reference_points("aohi")`; the notes and determination columns for filtering

### out.rule  [A3 A6]  (section)
- idea: one rule over all grouped tests
- job: Tallies a rule of all four tests by dataset and explains the herbarium and atlas losses.
- leaves: whether grid-centre records stay is an analysis decision

### out.stream  [A2 A6]  (section)
- idea: group pass on streamed input
- job: Explains how the group pass reads streamed files and shows identical tallies on a split table.
- leaves: `group_result.rds`; a species over several files is one group

### out.guidance  [A6]  (section)
- idea: five practical rules
- job: Turns the article into recommendations on input scope, fences, small groups, dataset keys and the raster.
- leaves: run grouped tests on the analysis table

## Cleaning fossil records (how-to)

### fossil.opener  [A1 A3]
- idea: fossils carry an age range too
- job: Says what fossil records add (a minimum and maximum age) and what the article covers.
- leaves: the age test, the range as a raw column, fossils in GBIF data

### fossil.install  (section)

### fossil.data  [A3]  (section)
- idea: simulated PBDB table with planted coordinate and age errors
- job: Builds a PBDB-shaped table and plants centroid, museum, zero and three kinds of age errors.
- leaves: PBDB column names; the `truth` column

### fossil.flag  [A1]  (section)
- idea: clean_fossils' record tests; age_equal defined
- job: Maps the PBDB columns, runs CoordinateCleaner's fossil record tests, defines `age_equal` and explains what each test caught and missed.
- leaves: copied and swapped ages are caught only by `age_equal`; period-dated ranges are valid

### fossil.buffers  [A1]  (section)
- idea: clean_fossils' wider buffers in degrees
- job: Converts `clean_fossils()`'s degree buffers to metres and shows what the wider centroid buffer adds and costs.
- leaves: `buffers = list(centroid = 5600, institution = 111)`

### fossil.range  [A3]  (section)
- idea: range width is a raw column cut at tally time
- job: Replaces `cf_range(method = "time")` with a binned raw column and a cut next to the rule.
- leaves: one flag pass serves any range threshold

### fossil.outliers  [A1 A6]  (section)
- idea: three per-taxon tests; seeded draws; settings
- job: Runs `age_range_outlier`, `age_outlier` and `spatiotemporal_outlier` on the genera, explains what each catches and shows `settings`.
- leaves: the range test catches the period-dated records; the draw tests catch fewer; another seed gives other draws

### fossil.vs-cc  [A1]  (section)
- idea: identical flags with CoordinateCleaner's fossil tests
- job: Shows identical flags with `cf_equal()` and says where the outlier tests are compared with `cf_age()`, `cf_outl()` and `cf_range()`.
- leaves: `age_range_outlier` identical; the draw tests identical only when nothing is drawn

### fossil.pyrate  [A1 A3]  (section)
- idea: kept records to PyRate input
- job: Says what PyRate is and writes the records a rule keeps as PyRate input with seeded age draws.
- leaves: `export_pyrate()`, `status`, `replicates`, `seed`, `random = FALSE`; same layout as `write_pyrate()`, compared in the tests

### fossil.gbif  [A4]  (section)
- idea: basis_fossil in GBIF data
- job: Shows how fossil specimens are separated in GBIF data.
- leaves: `basis_fossil`

## Using custom gazetteers (how-to, A5)

### gaz.opener  [A5 A7]
- idea: nine reference tests and the habitat tests; replace one layer
- job: Says which tests use reference data and that `gazetteers` replaces the layer of single tests, as CoordinateCleaner's `ref` arguments do.
- leaves: what the article covers

### gaz.install  (section)

### gaz.points  [A5]  (section)
- idea: reference_points returns a test's points
- job: Shows the shipped capital and institution points with their attributes.
- leaves: `reference_points()`; institution `source` (GRSciColl or Wikidata), `type` and `master_source`

### gaz.filtered  [A5]  (section)
- idea: herbaria only, wider buffer
- job: Filters the institution table to herbaria and shows the flags change.
- leaves: any data frame with longitude and latitude columns is a point layer

### gaz.extended  [A1 A5]  (section)
- idea: union of both capital tables
- job: Combines the Natural Earth and CoordinateCleaner capitals into one layer, and the shipped institutions with CoordinateCleaner's (BGCI gardens, which cannot be shipped).
- leaves: other point sets fit the same way; BGCI gardens added at run time from CoordinateCleaner's table

### gaz.polygons  [A5]  (section)
- idea: sf polygons for sea, urban, country_mismatch
- job: Uses a study-area polygon as the land of `sea` and coded polygons for `country_mismatch`.
- leaves: polygon layer requirements; which code columns are read

### gaz.ranges  [A1 A5]  (section)
- idea: species range polygons for `range`
- job: Builds range polygons for two species and shows records inside, outside and with a buffer.
- leaves: the species column, per-species indices, species without a polygon untested

### gaz.habitat  [A5 A7]  (section)
- idea: replace the genus habitat table
- job: Shows the shipped habitat table and a user table that classes a genus the register leaves open.
- leaves: `gazetteers = list(habitat = ...)` with `genus`, `marine`, optional `kingdom`

### gaz.record  [A5]  (section)
- idea: size and MD5 in the reference label
- job: Shows that a custom layer is recorded with the flags and protects streamed output.
- leaves: the label identifies the exact table

### gaz.vs-cc  [A1 A5]  (section)
- idea: ref arguments mapped; same flags with same layers
- job: Maps CoordinateCleaner's `ref` arguments to `gazetteers` entries and states the tested equivalence.
- leaves: column names found by any common spelling; every code column matched; the habitat table has no CoordinateCleaner counterpart
