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

Source is `README.Rmd`; `README.md` is rendered by `devtools::build_readme()`.

### readme.hero  [A2 A3]  (figure)
- idea: where flagged records pile up, on real GBIF data
- job: Shows 145 million records of the GBIF snapshot of 2026-10-01 as a grey density map with the records flagged near institutions, at country centroids or capitals, and with zero or equal coordinates drawn over it, each group's share written beside it. Built by `data-raw/hero.R`.
- leaves: the kinds of problem the tests find, at snapshot scale, before any word of text

### readme.claim  [A3]
- idea: what the package checks
- job: Says what the package checks records for, with examples (one sentence).
- leaves: the domain and the kinds of problem

### readme.extends  [A1 A2]
- idea: extension of CC for large-scale data · credit: CC authors define the tests, buffers and grouped-test options, run in memory · same tests as kd-tree queries, streamed, so a snapshot · additions
- job: States the relation phrase, an extension of CoordinateCleaner tailored to large-scale occurrence data, with its citation (one sentence), credits Zizka and co-authors for the tests, their default buffers and the options of the outlier and dataset tests, which CoordinateCleaner runs on a data frame in memory (one sentence; the full credit stays in readme.acknowledgements), that OccurrenceCleaner runs the same tests as nearest-neighbour queries in C++ and streams tables from disk so they apply to a full GBIF snapshot (one sentence, expanding GBIF), and that it adds tests of its own and expands the reference data (one sentence).
- leaves: the parent, what it is, why this package exists beside it, and what is added

### readme.flags  [A3]
- idea: the flag mechanism · records kept, reader decides
- job: Defines a flag as the result each test stores alongside the record (one sentence), and says every record remains available so the reader inspects flags, compares test combinations and chooses the exclusion (one sentence, ending on the decision).
- leaves: what a flag is, and that the reader decides

### readme.supports  (lead-in)
- job: "OccurrenceCleaner supports:" introduces the list; GBIF is expanded in readme.extends.

### readme.usecases  [A2 A3 A5 A4 A7]  (list)
- idea: scale · comparing rules · extension points · GBIF fields
- job: Lists the four things the package supports, each with its reason: large tables with the measured capital-test time, chunked processing keeping memory bounded so billions of records (hundreds of gigabytes) are cleaned on a desktop computer in a single R session, interrupted runs resume from saved progress, rule comparison (flags once, then a choice of tests) with `tally_flags()`, checked institution locations as a choice of two tables: `reference = "CoordinateCleaner"` for its 9,773 institutions as they are, or the default `reference = "OccurrenceCleaner"`, which corrects and extends them to 12,538 (567 of CoordinateCleaner's points found away from their institution, 180 by over 1,000 km, corrected; 2,765 points of other registries confirmed by a Google Maps or OpenStreetMap check, linked to the reference-data Institutions section), GBIF issues, record type, native or introduced status, and genus habitat.
- leaves: why a reader would pick this package, each reason backed by a number, a function or a mechanism

### readme.comparable  [A1]
- idea: CC definitions; documented differences; tested; what to cite
- job: Says the tests follow CoordinateCleaner's definitions and default buffers with the differences documented, that automated checks run both packages and require matching flags for the shared behaviour, and what a methods section cites from each package.
- leaves: a methods section can cite CoordinateCleaner for the original tests; where the exceptions are listed

### readme.install  (section)

### readme.steps  [A3]  (list)
- idea: flag, choose a rule, compare
- job: Names the three verbs in the order a user calls them.
- leaves: `flag_occurrences()`, `keep_unflagged()`, `tally_flags()` and what each step does

### readme.flag-tests  [A4]
- idea: what runs on a table; the catalog
- job: Says `test_plan()` shows which tests run on a table and why each other test does not, and `flag_tests()` lists every test with its definition and needed columns.
- leaves: where to see the selection and the catalog, without making either a step

### readme.input  [A2]
- idea: what goes in
- job: Says the input is a data frame or an on-disk table (linking the on-disk section), coordinates are decimal degrees (WGS84), columns are matched by Darwin Core names (glossed as the standard field names for biodiversity data) regardless of capitalisation, and other names are mapped with `occ_columns()`.
- leaves: the minimum input and how columns are found

### readme.tests-run
- idea: which tests run
- job: Says each test reads a few columns and by default every test whose columns are present runs (one sentence), that naming tests in `tests` runs only those (one sentence), and that a named test lacking one of its columns stops the call with a message reporting the missing column (one sentence).
- leaves: the default selection and what happens when a column is missing

### readme.example  (code)
- idea: smallest call, output shown
- job: Flags four records, one of them clean, and prints four of the flag columns.
- leaves: the call, its input shape and what comes back

### readme.example-result  [A1 A3]
- idea: what each record trips; the flag word
- job: Says a flag is TRUE on failure, why each of the first three records is flagged and that the fourth passes, and that the `flags` column holds all tests as bits.
- leaves: the reading of a flag column; the `flags` column, one bit per test

### readme.two-choices  [A3]
- idea: which tests run vs which records are excluded
- job: Says running a test only adds its flag, so the default runs every test the data allows, and that exclusion is a separate choice made afterwards with a cleaning rule; defines the rule (tests used when filtering, excluded if any flags it).
- leaves: the two decisions kept apart; what a rule is

### readme.rules  [A3]  (code)
- idea: a flagged record may be valid; the reader chooses; two rules compared; kept records
- job: Says a flagged record may still be valid (a real observation within 10 km of a capital), so you choose the tests; gives the SDM rule (fossil and living specimens plus coordinate problems) as one choice among others; marks one rule's records with `has_flag()`, compares two with `tally_flags()` and keeps the records the mild rule passes with `keep_unflagged()`, output shown.
- leaves: rules are chosen after flagging, compared on the same flags, and end in the table for the analysis

### readme.rules-link  [A3]
- idea: rules article
- job: Links the rules article, which adds bins for year and uncertainty.
- leaves: where the full treatment of rules is

### readme.tests  [A1 A4 A6 A7]  (section)
- idea: thirty tests; twenty from CC; ten additions
- job: Gives the number of tests, their two origins in one sentence each, and links the tests article and `flag_tests()`.
- leaves: the scope of the tests and where each is defined

### readme.reference  [A5]
- idea: reference data defined; pinned; CC tables; own layers
- job: Defines the reference data, says it is rebuilt, pinned and recorded with the flags so a cleaning can be repeated, links the reference-data article, and names `reference = "CoordinateCleaner"` and `gazetteers`.
- leaves: the reference data is traceable and replaceable

### readme.fits  [A2]  (list)
- idea: the workflow in order: obtain, match names, flag, use
- job: Under "Using OccurrenceCleaner in an analysis", walks the workflow in order: data sources (rgbif, paleobioDB), name matching beforehand (taxify, taxize), flagging and choosing a rule, and the analyses the kept records feed (dismo, sdm, phytools, red, PyRate via `export_pyrate()`).
- leaves: which inputs work, what is out of scope, where the output goes

### readme.grouped  [A6]  (section)
- idea: grouped tests; settings
- job: Says why the outlier and dataset tests run in a pass over the whole input and shows `settings` in one call, linking the outliers article.
- leaves: the grouped tests exist, work streamed too, and take CoordinateCleaner's options through `settings`

### readme.fossil  [A1 A6]  (section)
- idea: PBDB table, clean_fossils' tests
- job: Shows a PBDB fossil table flagged with the age test and two fossil outlier tests, columns named once, linking the fossil article.
- leaves: fossil tables take the same verb; `occ_columns()` for PBDB names

### readme.snapshot  [A2]  (section)
- idea: streaming a snapshot; units
- job: Under "Processing large datasets on disk", says `flag_occurrences()` reads on-disk tables through vectra and which inputs it accepts, that each file is flagged and written separately and a rerun skips completed files, shows `keep` in a snapshot call, and links the on-disk article.
- leaves: the on-disk call, `keep`, `out`, and that a rerun resumes

### readme.docs  (section)
- idea: routing with a starting point
- job: Marks Get started as the place to begin and labels every article and the reference by its job.
- leaves: where to start and where each topic lives

### readme.help  (section)
- idea: where to ask
- job: Points questions and bug reports to the GitHub issues and asks for a reproducible example.
- leaves: the help channel, kept apart from the donation footer

### readme.contributing  (section)

### readme.support  (section)

### readme.acknowledgements  [A1]  (section)
- idea: credit CC authors in specifics
- job: Credits Zizka and co-authors for the tests, default buffers and grouped-test options, and says what this package takes from CoordinateCleaner: the specification and the reference sources.
- leaves: who made the tests and what was taken from them

### readme.license  (section)
- idea: MIT; two external resources with their own licences
- job: States the MIT licence, then lists CoordinateCleaner (GPL-3, optional dependency, not bundled) and the World Borders centroids (CC BY-SA).
- leaves: which parts carry another licence and that nothing GPL is bundled

### readme.citation  (section, generated)
- idea: cite both, one header saying what each credits; keyed entries; downloadable files
- job: Prints `citation("OccurrenceCleaner")` with BibTeX: this package (version from DESCRIPTION) and Zizka et al. (2019). Links the generated `.bib` and `.ris` files on the site.
- leaves: the package reference ready to paste or import, and the CoordinateCleaner DOI, from `inst/CITATION`

## ?OccurrenceCleaner

### pkg.overview  [A1 A3]
- idea: extension of CC; flags, rule afterwards; verb map
- job: States the relation, that records are kept and the rule chosen afterwards, and points to the three main functions.
- leaves: the verb map

### pkg.credit  [A1]
- idea: credit CC authors; cite both
- job: Credits Zizka and co-authors for the tests and defaults and asks for both citations.
- leaves: `citation("OccurrenceCleaner")` gives both

## Get started (vignettes/OccurrenceCleaner.Rmd)

### gs.opener  [A1 A3]
- idea: what the tutorial does and where it ends; relation to CC
- job: Says the article flags records, keeps those passing a rule and counts what two rules exclude; states the assumed starting point (basic R, data frames) and the CoordinateCleaner relation, linking the documented differences.
- leaves: the end point (retained records), the parent package, where the differences are listed

### gs.steps  (list)
- idea: flag, inspect, keep, compare
- job: Lists the four steps with their functions.
- leaves: `flag_occurrences()`, `print()`/`summary()`, `keep_unflagged()`, `tally_flags()`

### gs.install  (section)

### gs.data
- idea: example records
- job: Introduces seven records of four species with an identifier, coordinates in decimal degrees; defines Darwin Core as the standard set of field names for biodiversity data.
- leaves: the example `x`, Darwin Core

### gs.first-tests  (list)
- idea: three tests without reference data
- job: Defines `invalid`, `zero` and `duplicate`.
- leaves: the three definitions

### gs.flag-result  [A1]
- idea: reading the flags
- job: States the output contract (same rows, same order, input columns unchanged, flag columns added), says `flagged_by` belongs to the printed display only (not a column of the object), which record each test flags, that a record without a flag passed only the tests run (record 3 in Vienna), that a record can also stay unflagged when a test ran but could not judge it (a fossil without an age, a species too small for the outlier test), and that `FALSE` means "not flagged by this test", not "examined and found correct".
- leaves: the contract; absence of a flag is relative to the tests run; flagged, passed and untested kept apart from the first output on

### gs.flag-columns
- idea: logical columns and the integer
- job: Says `flag_<test>` is TRUE where the test flagged the record and that `flags` holds all tests in one integer, linking the tests article for the encoding.
- leaves: `flag_<test>`, `flags`

### gs.keep  [A3]  (section)
- idea: a rule; any listed test; retained records
- job: Defines a cleaning rule, keeps the records no test of the rule flags with `keep_unflagged()`, says it stops when a named test was not run, and prints the retained records.
- leaves: `cleaned`, one copy of each duplicate kept

### gs.reference-tests  [A1 A3 A5]  (section)
- idea: every test the columns allow; running vs excluding; the reference tests
- job: Says that without `tests` every test whose columns are present runs, that running only adds flags and exclusion is a later rule; names the tests coordinates and species allow (reference points and polygons, GBIF and AHOI expanded, the species outlier test) and that the header names the missing columns, `test_plan()` the tests; runs it and says which records the capital, urban, sea, equal and AHOI tests flag; the outlier test flags none; two records pass every test run here.
- leaves: the default selection, `test_plan()`; the land scale (1:110 million default) changes `sea` near coasts, linked to Reference data

### gs.valid  [A3]
- idea: a flag may mark a valid record; summary
- job: Says a flagged record may be valid and you choose the tests, with the SDM rule as one choice among others; before `summary()`, explains the default rule `all` (every test run) and that summary only counts; then shows that a rule excludes each record once (per-test counts 11, excluded 5).
- leaves: `summary()`, the rule `all`, the `only` column, overlapping flags counted once

### gs.rules  [A3]  (section)
- idea: compare rules on the same flags
- job: Compares a strict and a mild rule per species with `tally_flags()`, without rerunning the tests; points to bins in the rules article.
- leaves: `tally_flags(rules =)`, `removed_<rule>`, `kept_<rule>` (shown by the print method)

### gs.buffers  [A1]  (section)
- idea: distances are part of a test
- job: Shows that changing a distance means flagging again, with `buffers = list(capital = 200)` (the Vienna point lies between 500 m and 1 km of the capital point).
- leaves: the capital distance in metres (`zero` in degrees); defaults in `?flag_occurrences`

### gs.own-data  (section)
- idea: bridge to own data, taught once: the error, then the mapping
- job: Writes the records to a CSV with other column names, reads it back, shows the error the unmapped call gives (the message names the coordinate columns it looked for and points to `occ_columns()`), maps the names with `occ_columns()`, says only the path and names change for another file, that the same 12 tests run as on `x`, and that a mapping which leaves out `species` runs without error with 10 tests and `species` listed as missing.
- leaves: `read.csv()`, `occ_columns()`, `columns =`; all column-mapping material lives here (2026-10-13: the errors section no longer repeats it)

### gs.errors  (section)
- idea: two more errors and their fixes
- job: Shows two real error messages (unknown test name, rule naming a test not run), each followed by the corrected call and its result.
- leaves: `flag_tests()`, rerun or drop the test

### gs.metadata  [A4]  (section)
- idea: tests on GBIF fields
- job: Shows `basis_fossil` on `basisOfRecord`, added to a copy `xb` so `x` stays the seven records; links the GBIF workflow.
- leaves: that some tests read GBIF fields

### gs.disk  [A2]  (section)
- idea: a table on disk, kept short
- job: Writes the seven records to two `.vtr` files (setup visible; vectra introduced), flags the directory with the identifier mapped (`occ_columns(id = "id")`, default `gbifID`), prints the result, says it describes the output directory whose files store the identifier, the `keep` columns and the flags, that `tally_flags()` reads them like a data frame, and hands over to the on-disk article (tallying, duplicates across files, joining, resuming). The tally and the duplicate sentence moved there (2026-10-13).
- leaves: `out`, `keep`, the id mapping; where the disk workflow continues

### gs.next  (list)
- idea: routing
- job: Labels each next article by its job.
- leaves: where each topic lives

## Compatibility with CoordinateCleaner

### cc.credit  [A1]
- idea: what CoordinateCleaner supplies
- job: Credits CoordinateCleaner with the test definitions, buffers, reference sources, outlier statistics, dataset and fossil tests, and states its standing (rOpenSci review, the cited reference).
- leaves: the tests here come from CoordinateCleaner; it is the established reference

### cc.purpose  [A2 A3]
- idea: why this package exists, and its standing
- job: Says what the package adds in the reader's terms (large tables, flags kept per record, rules chosen afterwards) and that it is new and reviewed only by its own test suite.
- leaves: the use case; the burden of proof is on this package

### cc.opener  [A1]
- idea: what the article covers
- job: States the article's scope (agreement, settings, differences, mapping, how agreement is tested, timings); CoordinateCleaner is only suggested; links Get started for installation.
- leaves: the reader knows the article's order

### cc.both  [A1]  (section)
- idea: clean_coordinates and flag_occurrences on the same records, matched reference
- job: Says in plain words that both packages return every record with one logical column per test, then gives the opposite sign in its own sentences (TRUE is pass in CoordinateCleaner, fail here) and that one output is inverted for the comparison; no function name in this prose, the calls are in the chunk below. Describes the 4,000 records near five capitals and lists the 50 overwritten records with the test each group is for (20 at the origin: zero and equal; 20 with equal coordinates: equal; 10 within 0.3 degrees of zero: the zero-buffer difference); runs seven tests in both with `reference = "CoordinateCleaner"`; tabulates flagged counts and agreement; names the two tests that differ.
- leaves: agreement per test on matched settings; where the two differences come from

### cc.remove  [A1 A3]  (subsection)
- idea: removing records, in both packages
- job: Shows the `cc_*()` chain and the `clean_<test>()` chain, says both apply each test to the remaining records and give the same result for record tests; shows flag once + `keep_unflagged()` and a second rule from the same flags; says a grouped test in a chain depends on earlier removals.
- leaves: the cleaning functions and `keep_unflagged()`; when a chain and one flagging call differ

### cc.tested  [A1]  (section)
- idea: how agreement is tested and what it shows
- job: Describes the equivalence suite against 3.0.1 and the GitHub version, the streamed duplicate check; scopes it (agreement on the samples, not suitability).
- leaves: the evidence behind the agreement claim and its limit

### cc.own-data  [A1 A6]  (subsection)
- idea: checking agreement on your own records
- job: Lists the settings to match (reference, land scale, buffers), the grouped-test caveat, and where to report a disagreement.
- leaves: the reader can reproduce the comparison on their data

### cc.mapping  [A1]  (section, tables)
- idea: function and argument mapping
- job: Says `flag_occurrences()` runs any selected combination of tests (not "one function for every test"), that each test has a `clean_<test>()` that removes what it flags, how that relates to CoordinateCleaner's `clean_*()` wrappers, and that no name is shared; maps tests, arguments and output, and the functions around the tests. After the third table: the sampling correction of the outlier test (optional, GBIF counts downloaded only when it is on; here a table whose checksum goes in the reference label), the PyRate export name, and `as_spatialvalid()` (contents of the converted result, names and sign, what runs on it, and the tested scope: validity, equal and duplicate columns against `clean_coordinates()`).
- leaves: the vocabulary of both packages; both can be attached

### cc.differ  [A1]  (section)
- idea: design differences, then behaviour of CoordinateCleaner 3.0.1
- job: Sorts the differences: design (buffer circles, invalid coordinates, random age draws, dataset key, country codes, gazetteers) and 3.0.1 behaviour departing from its documentation or stopping (zero buffer, France/Norway/Kosovo, raster outliers, small datasets), each with the version.
- leaves: every case where flags can differ, and which kind it is

### cc.timings  [A2]  (section)
- idea: timings with their scope
- job: Says what the timings measure and what they do not; method, machine, versions; one table per input size; the largest differences and the two tests where CoordinateCleaner is faster; the mechanism; the shared tests in one call; benchmark script.
- leaves: the speed per test, scoped to synthetic records on one machine

### cc.better-choice  [A1]  (section)
- idea: when CoordinateCleaner is the better choice
- job: States the standing difference and lists the cases (workflow already built on it and fast enough, live sampling counts, only `equal`/`duplicate`).
- leaves: a fair basis for choosing

## The tests in detail (explanation, A4 home)

### tests.opener  [A1 A4 A7]
- idea: eleven CC record tests, ten additions (eight GBIF fields, two habitat); the rest elsewhere; per-test help
- job: Says what the article covers per test and which tests come from CoordinateCleaner. Links Get started for installation.
- leaves: the split into equivalent tests and additions; `?test_<name>` pages exist

### tests.flag-word  [A3]  (section, "All tests and the flag word", last section before References since 2026-10-13)
- idea: the full catalogue; one bit per test; layout version; which tests run
- job: Lists every test from `flag_tests()` (bit, test, definition with default buffer, needed fields, CoordinateCleaner counterpart; the `source` column left out for width), defines the flag word, shows a mask and says why the layout is versioned.
- leaves: the full test table (the README links here for it); `2^bit` sums, `flag_mask()`, `has_flag()`, `layout_version`, `test_plan()` on a one-record table
- note: section headings of the per-test sections name the topic, not the test identifiers (sidebar width); each section's first sentence names its tests

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
- leaves: `reference_habitat()`; `genus` and `kingdom` columns; the land and buffers of the habitat tests; marine fossils on land are flagged by `land_marine`, a rule with `basis_fossil` excludes fossils in any case, a study keeping fossils leaves `land_marine` out

### tests.urban  [A1]  (section)
- idea: urban polygons; runs with coordinates; a rule may leave it out
- job: Defines `urban`, says it runs whenever coordinates are present and a rule can leave it out because city records are often correct, gives the plant-garden use, and notes that `clean_coordinates()` leaves it out by default.
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
- idea: results stored per record; what a rule is; four steps
- job: Says `flag_occurrences()` stores each test's result alongside each record and all records remain, defines a cleaning rule (tests used when filtering; excluded if any flags it), then says what the article compares and lists the four steps, each naming its function. Links Get started for installation.
- leaves: flag, compare per test and rule, compare by group, select

### rules.example-data  [A3]  (section)
- idea: simulated terrestrial European records with planted errors; code folded
- job: Describes the records in prose first (terrestrial, each species in one kingdom, four-decimal coordinates, GBIF fields; older records simulated with larger uncertainty and more `COORDINATE_ROUNDED`, so later age and uncertainty patterns follow from that; disjoint sets moved to capitals, (0, 0) and the Atlantic, exact copies appended), puts the three simulation chunks in a `<details>` block, then shows `nrow(x)` and three rows.
- leaves: an input with planted problems and stated simulation assumptions; the first package call follows the preview

### rules.flag-once  [A3]
- idea: the CoordinateCleaner tests plus issue and fossil tests, named
- job: Names the twelve tests the article compares (`cc_tests` plus three) and says the default would run every test the columns allow; flags the records and lists the added columns.
- leaves: `f` with `flags` and one `flag_<test>` column per test

### rules.per-test  [A3]  (section)
- idea: pct and only
- job: Explains `flagged`, `pct` and `only`, why per-test shares add up to more than the rule, and that the rule's `pct` minus the sum of `pct_only` is the share flagged by more than one test.
- leaves: how often a test flags vs how much loss a test alone causes

### rules.compare  [A3]  (section)
- idea: three candidate rules, named for this article
- job: Defines `strict`, `coordinatecleaner` (the eight `clean_coordinates()` defaults in this set; its outlier test left out, duplicates not in its default) and `minimal` (screening for terrestrial records; `sea` removes valid marine records); limits `coordinatecleaner` to this plot and the kingdom comparison.
- leaves: named rules in `summary()`; records failing several tests contribute zero to every `only` count (said in those words)

### rules.by-group  [A3]  (section)
- idea: by kingdom
- job: Splits the shares by group (each percentage out of its own group) and draws the grid.
- leaves: `by` in `summary()` and `plot()`

### rules.bins  [A3]  (section)
- idea: year and uncertainty cut at tally time
- job: Bins year and coordinate uncertainty at tally time, states closed-left classes, the `<first`/`>=last`/`missing` classes and per-class denominators, ties each pattern back to the simulation, and says when to keep the tally rather than the summary.
- leaves: `bins`; `<column>_bin`; missing values get their own class

### rules.map  [A3]  (section)
- idea: map of removed records
- job: Maps the records a rule removes.
- leaves: `plot(type = "map")`

### rules.apply  [A3]  (section)
- idea: purpose, then keep_unflagged (has_flag as the vector behind it)
- job: States the example's use (species map on a 10 km grid) and why `coordinatecleaner` fits it and duplicates may stay; lists tests other analyses add (duplicate key = species and coordinates); sources `COORDINATE_ROUNDED` to GBIF; applies the rule; shows a year and uncertainty cut with explicit missing-value handling; says which changes reuse `f` and which need reflagging; ends on what a comparison with `clean_coordinates()` must align (outlier test, `land_scale = 50`, `reference = "CoordinateCleaner"`).
- leaves: the cleaned table; reuse condition for `f`

### rules.math  [A3]  (section)
- idea: object classes and bit arithmetic of the counts
- job: Names the `occ_flags`/`occ_summary` classes methods dispatch on; defines $w$, $m_t$, $m_T$ and bitwise AND; gives the three bit conditions and the overlap identity.
- leaves: the bit mask of a rule; one pass per group

## Large tables on disk (how-to, A2 home)

### disk.opener  [A2]
- idea: snapshot-sized input, streamed
- job: Defines GBIF, Parquet and vectra at first use, says what `flag_occurrences()` accepts on disk and where the article ends (flags on disk, tallied, a selection joined to its records); links Get started for installation; steps list flag, tally, select/join, resume.
- leaves: the four steps

### disk.input  [A2]  (section)
- idea: three `.vtr` parts, one copy across files; code folded
- job: Defines `.vtr`, says in prose that the last record of part 3 is a copy of the first record of part 1, puts the code that writes the three parts in a `<details>` block, then lists the files and three rows of part 1.
- leaves: `src`, `p1`, `p3`, the cross-file copy

### disk.flag  [A2]  (section)
- idea: `out`, `keep`, the identifier, the test plan; progress log folded
- job: Flags the directory in a `<details>` block (the call with its progress messages), prints the `occ_flagged` object in its own chunk, shows `test_plan()` for the tests that did not run, names `duplicate` and `outlier` as grouped tests run in a group stage before the record pass.
- leaves: `out`, `f`, grouped tests

### disk.tally  [A2 A3]  (section)
- idea: counts per group without loading the records
- job: Tallies by kingdom and year class under the `coordinatecleaner` rule (same tests as in the rules article), shows the table, states the sea share computed inline and that sea accounts for most removed records, shows the error for a grouping column not kept.
- leaves: `coordinatecleaner`, kept columns are the grouping columns

### disk.read  [A2]  (section)
- idea: bounded selection, rule after collecting, join on disk
- job: Opens `flagged_table()`, filters on a kept column and `flags != 0L` (any test that ran) before collecting, applies the rule with `has_flag()` after collecting since vectra filters cannot test bits, joins the selection to the records on disk by `gbifid`.
- leaves: lazy queries, the identifier join

### disk.duplicates  [A1 A2]  (section)
- idea: duplicates across files, as in one data frame
- job: Shows the cross-file copy flagged and the original not; states the input order (files sorted, rows within each file).
- leaves: streamed and in-memory duplicate flags agree

### disk.node  [A2]  (section)
- idea: a vectra query is one unit without grouped tests
- job: Flags a filtered query, shows in `test_plan()` that `duplicate` and `outlier` do not run on it and why; naming them is an error.
- leaves: filter pushdown, grouped tests need a path

### disk.resume  [A2]  (section)
- idea: rerun to resume; configuration record
- job: Reruns the call (all units skipped) and removes one marker (that unit redone; the finished run's group files are gone, so the group stage repeats), both reruns in `<details>` blocks with the prose saying what their messages report; says the group stage checkpoints, `resume = FALSE` starts over; shows the configuration record refusing a rerun with another `keep`; says sizes and modification times are not a content hash.
- leaves: resuming, the configuration check

### disk.layout  [A2]  (section)
- idea: the files in `out`
- job: Describes part files and `part_rows`, `flags_config.rds` and `flags_meta.rds`; lists the directory and the metadata.
- leaves: `read_flagged()`

### disk.memory  [A2]  (section)
- idea: what memory and disk a run uses
- job: Lists what the record pass and the group stage hold in memory and write to disk; links the Streamed runs section of the help page.
- leaves: bounded memory

### disk.snapshot  [A2]  (section)
- idea: the real snapshot call
- job: Gives `test_plan()` on the snapshot, the flag call and a tally with two rules; says the issue column is read as a `;`-separated string, how many times the group stage reads the files, and what an interruption repeats in each stage.
- leaves: the snapshot workflow

## Running on several threads (how-to, A2)

### par.opener  [A2]
- idea: `n_threads` in `flag_occurrences()`, what it buys
- job: Defines threads and OpenMP at first use, says what `n_threads` does, lists what the article shows (set, check identical flags, read the speedup, enable OpenMP) and links Get started for installation; steps list.
- leaves: the four steps

### par.set  [A2]  (section)
- idea: one simulated table, `n_threads` 1 and 4
- job: Describes the simulated records, runs the same tests with one and four threads, says `0` uses every thread OpenMP offers and that a larger request is reduced with a message.
- leaves: `x`, `tests`, `f1`, `f4`

### par.tests  [A2]  (section)
- idea: which work is spread
- job: Lists the outlier test (per species, a large species split by rows) and the per-record proximity and point-in-polygon tests; names what stays on one thread; links the on-disk article.
- leaves: the split between threaded and single-thread work

### par.identical  [A2]  (section)
- idea: flags do not depend on the thread count
- job: States that each species and record is computed on one thread, in record order, and shows `identical()` on the two flag vectors.
- leaves: `identical(f4$flags, f1$flags)`

### par.speedup  [A2]  (section)
- idea: measured scaling on one machine
- job: Names the script that produced the timings and the machine from the shipped table, shows the table and the speedup figure with the ideal line, and scopes the claim to one machine and record mix.
- leaves: `inst/extdata/thread_timings.csv`, `data-raw/threads.R`

### par.openmp  [A2]  (section)
- idea: where OpenMP comes from
- job: Says Rtools and the default Linux compiler include OpenMP, gives the Homebrew recipe for macOS (Apple Silicon and Intel prefixes), and says how to read the thread limit of a build and that a build without OpenMP runs on one thread. The README Installation links this section (2026-10-13).
- leaves: the macOS `~/.R/Makevars` lines

## Cleaning GBIF data (how-to, end to end)

### gbif.opener  [A3]
- idea: whole workflow on simulated GBIF data
- job: States the workflow and why the data are simulated. Links Get started for installation.
- leaves: every error is labelled, so catches can be checked

### gbif.data  [A3 A4]  (section)
- idea: 2,000 background records plus 276 labelled errors; code folded
- job: Describes the table in prose first (2,276 records in GBIF's lower-case names; 2,000 background records drawn in a box per country, two of the Austrian points across the border in Bavaria, announced here; 276 planted errors of nine kinds labelled in `truth`, 40 copies among them), puts the two simulation chunks in a `<details>` block, then shows one record of three kinds and `table(occ$truth)`. The label is `background`, not `clean`, so the two Bavarian records need no reinterpretation.
- leaves: the `truth` column; the `issue` format

### gbif.flag  [A3 A5]  (section)
- idea: every test the columns allow; what ran; reference label; per-test summary
- job: Flags without `tests`, says what `FALSE` in a flag column means (not flagged; a test that did not run has no column, a grouped test leaves small species untested), names `flag_reference()` with the full label in a `<details>` block, lists with `test_plan()` the 21 tests that ran and the missing input of the 9 others (fossil, dataset, habitat, range), then the per-test shares (273 of 2,276 flagged; `only` defined as the records flagged by that test alone, the ones the rule would additionally keep without it).
- leaves: `flag_reference()` to store with any cleaned table

### gbif.truth  [A1 A4]
- idea: which test catches which error
- job: Cross-tabulates tests (rows) against the error groups (columns; duplicates and fuzzy taxon left out, one test each) and explains the catches, the misses (5 whole-degree records on the France and Germany centroids, 1 at an institution, the rest uncaught) and the two flagged background records (the Bavarian points).
- leaves: negated and most whole-degree records are beyond any record test; GBIF warnings catch swaps on land

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
- job: Defines the five rules (`coordinatecleaner` includes `invalid`, the same rule as in the rules and on-disk articles; `wild` "also excludes" living and managed records), compares them in a table with rules in rows (tests, removed, kept, added), gives what each step adds, then the share per kingdom as rules by kingdoms and as a figure. Year and uncertainty tables use short display headers from a hidden kable chunk.
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
- job: Names the reference layers and lists the article's topics. Links Get started for installation.
- leaves: points vs polygons

### ref.layers  [A5]  (section, with subsections since 2026-10-13)
- idea: sources, versions, licences, each layer under its own heading
- job: Lists each layer in a narrow table (Layer, Source, Version / snapshot, Retrieved; short factbook hash, Wikipedia revisions and the IRMNG citation in a note, `aohi` named after `cc_aohi()` while the inventory is AHOI) and which test reads it, then the provenance in subsections: Capitals; Country and province centroids (the three sources as a list); Land, countries and urban areas (Natural Earth terms); Institutions (opens with what the test uses: CoordinateCleaner's points, the `status` column and `table(inst$source, inst$status)`; the 567 moved points with their conditions and the Duke example; the Google Maps search and the review that kept 62, as a list; the confirmation checks; then the other sources: GRSciColl, Wikidata, Wikipedia, GeoNames, BGCI, Index Herbariorum, GBIF registry, the placement of CoordinateCleaner's list, OpenStreetMap); Genus habitats; Artificial hotspots.
- leaves: Natural Earth public domain; which institution points the test uses and why; GRSciColl counts and status; the five zero-coordinate institutions left out; Wikidata classes and counts, CC0; IRMNG archive, licence, citation and class counts; nothing copied from CoordinateCleaner; the README links `#institutions`

### ref.vs-cc  [A1 A5]  (section, "How the reference data differ from CoordinateCleaner's")
- idea: same places, different tables
- job: Compares the package's reference points with CoordinateCleaner's, layer by layer (counts as of 2026-10-17, the date of the last institution check; institutions: CoordinateCleaner's points used, 567 moved, 2,765 confirmed points added; its own geocoding against the source coordinates; `reference = "CoordinateCleaner"` uses its table as it is), and shows the capital difference in flags.
- leaves: where the two references flag different records and why

### ref.extension  [A1 A5]  (section)
- idea: extension points, on by default
- job: Lists the points from sources CoordinateCleaner does not use (capitals, country centroids, institutions, with counts), says they are used by default and shows how leaving them out unflags Cape Town, Sucre and Naypyidaw.
- leaves: `extension` column; `gazetteers = list(capital = g[!g$extension, ])` restricts to CC's sources

### ref.land-scale  [A1 A5]  (section)
- idea: 1:110 million vs 1:50 million on the Danish coast
- job: States the three supported scales, OccurrenceCleaner's default (1:110 million) beside CoordinateCleaner's two defaults, that 1:10 million is downloaded once and cached, then measures where 1:110 million and 1:50 million disagree.
- leaves: the scale matters for coastal and island taxa; the download is checksummed

### ref.buffers  [A1]  (section)
- idea: default buffers; units
- job: States the default buffers and shows a smaller capital buffer.
- leaves: zero in degrees, others in metres

### ref.stamp  [A5]  (section)
- idea: reference recorded with the flags
- job: Prints the flagged table (short reference form in the header) and the layout version, with the full `flag_reference()` label in a `<details>` block; says the same label is written on disk.
- leaves: one directory never mixes references

### ref.choose  [A1 A5]  (section)
- idea: which reference to use
- job: Says when to use each reference; `reference = "CoordinateCleaner"` uses its own tables, needs it installed, and reproduces its flags subject to the documented differences.
- leaves: own gazetteers (Natural Earth, Factbook, World Borders, GEOLocate, GRSciColl, Wikidata, Wikipedia, GeoNames, BGCI, Index Herbariorum, GBIF registry, OpenStreetMap) by default; CoordinateCleaner's to compare with published work

## Outliers and dataset tests (how-to, A6 home)

### out.opener  [A6]
- idea: six grouped tests; group pass; what the article covers
- job: Names the tests that compare a record with its species or dataset and their CoordinateCleaner functions; a second paragraph says why they run in a pass of their own; a third says what the article covers and links the fossil article and Get started.
- leaves: the grouped tests; the fossil ones are in the fossil article

### out.data  [A6]  (section)
- idea: alpine plants plus far records and two faulty atlases; code folded
- job: Describes the 961 records of four species in three datasets, the far records and the two faulty atlases in prose, puts the two simulation chunks in a `<details>` block, then shows three rows and the dataset-by-truth table.
- leaves: the `truth` column; `datasetKey`

### out.outlier  [A1 A6]  (section)
- idea: quantile threshold; min_occs
- job: Flags geographic outliers with the default threshold, defines Q75, IQR and MAD in words where they first appear, and explains the one miss and the untested small species.
- leaves: Q75 + 5 x IQR of mean distances; `min_occs`

### out.sampling  [A1 A6]
- idea: sampling correction from supplied counts
- job: Explains CoordinateCleaner's sampling correction as three numbered steps (the count table, the density threshold at `sampling_thresh`, which flags are lifted) and runs it with a per-country count table.
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
- job: Turns the article into recommendations on input scope, thresholds, small groups, dataset keys and the raster.
- leaves: run grouped tests on the analysis table

## Cleaning fossil records (how-to)

### fossil.opener  [A1 A3]
- idea: fossils carry an age range too
- job: Says what fossil records add (an age range in Ma) and where the article ends (PyRate export); links Get started for installation; names CoordinateCleaner as the extra package for the comparison section.
- leaves: the age test, the range as a raw column, outliers per taxon, PyRate

### fossil.steps  (list)
- idea: flag, keep, cut, test, export
- leaves: `flag_occurrences()`, `keep_unflagged()`, `tally_flags()`, the outlier tests, `export_pyrate()`

### fossil.data  [A3]  (section)
- idea: nine synthetic records in PBDB columns, one case each; cases explained beside their flags
- job: Names the PBDB columns; says `min_ma` and `max_ma` give the youngest and oldest possible ages in millions of years before the present; builds nine records, naming only the controls (1 and 9: ordered ages, Wyoming coordinates matching `US`) and records 7 and 8 (code `DE`, coordinates set in the next chunk on and 3 km from the Germany polygon centroid of `reference_points("centroid")`, ordered ages with a 1.2 Ma span); the other cases are described in fossil.flag next to the result.
- leaves: `fos`; the centroid records' distances are known

### fossil.flag  [A1]  (section)
- idea: clean_fossils' record tests; what age_equal flags; each case beside its result
- job: Maps the PBDB columns, runs the record tests; says `age_equal` flags min >= max and introduces records 2 (equal ages) and 3 (reversed) there, that the flag records the comparison and the records need review, that record 5 (missing minimum) cannot be compared and stays unflagged, that record 4 (43 Ma span) is flagged by no record test and returns in the age-range section; record 6 (zero coordinates) fails zero, equal, country_mismatch; record 7 fails centroid, record 8 at 3 km passes.
- leaves: `age_equal` is a comparison, not a verdict on the age

### fossil.keep  [A3]  (section)
- idea: one rule, keep_unflagged on the flagged table
- job: Keeps the records no test in `tests` flags with `keep_unflagged(f, rule)`; says it stops when a named test was not run; says record 5 stays because a missing age carries no `age_equal` flag, and how to require both ages.
- leaves: `kept`

### fossil.buffers  [A1]  (section)
- idea: a wider centroid buffer, chosen for the demonstration
- job: States the defaults (1 km centroids, 100 m institutions, you can change these with `buffers`); says a coarsely georeferenced collection "may have been assigned the country-centroid coordinates"; shows a 5 km buffer flagging record 8 as well; comparison note: these differ from CoordinateCleaner 3.0.1, whose `clean_fossils()` passes `centroids_rad = 0.05` and `inst_rad = 0.001` to the `buffer` of `cc_cen()`/`cc_inst()`, read in metres.
- leaves: `buffers = list(centroid = 5000)`

### fossil.range  [A3]  (section)
- idea: filter by age-range width; comparison at the end
- job: Computes `max_ma - min_ma`, counts flagged and retained records per range group with `tally_flags()`, applies an illustrative 15 Ma limit (changeable without rerunning the tests); comparison note last: CoordinateCleaner's `cf_range(method = "time")` flags ranges wider than `max_range`.
- leaves: one flagging run serves any range threshold

### fossil.outliers  [A1 A6]  (section)
- idea: three per-taxon tests on a larger synthetic table
- job: Lists the three tests in one line each; explains the threshold (75th percentile + mltpl x IQR, mltpl 5) and the seven-record minimum; explains the age sampling (five draws, majority, seeded per taxon) before any result; describes the 600 synthetic records and the injected cases; runs coordinate, age and outlier tests together; reports what each test flags, without speculating on the counts; shows `settings` (mltpl 2, seed 7) and the result.
- leaves: `g`; none of the tests flags a background record

### fossil.pyrate  [A1 A3]  (section)
- idea: one final rule over `g`, then PyRate
- job: Says what PyRate does, selects from `g` the records unflagged by every test run with an age range of at most 15 Ma, exports them, and says what each of the two files contains.
- leaves: `export_pyrate()`, `status`, `replicates`, `seed`, `random = FALSE`; same layout as `write_pyrate()`, compared in the tests

### fossil.vs-cc  [A1]  (section)
- idea: identical flags with CoordinateCleaner's fossil tests
- job: Shows `age_equal` and `cf_equal()` side by side on the small table and says where the outlier tests are compared with `cf_age()`, `cf_outl()` and `cf_range()`.
- leaves: `age_range_outlier` identical; the draw tests identical only when nothing is drawn

### fossil.gbif  [A4]  (section)
- idea: basis_fossil in GBIF data
- job: Flags fossil specimens in GBIF records and shows both selections (without and with the flag).
- leaves: `basis_fossil`

### fossil.refs  (section)
- leaves: Silvestro et al. 2014

## Custom reference points and polygons (how-to, A5; file gazetteers.Rmd, retitled 2026-10-13, listed under Workflows)

### gaz.opener  [A5 A7]
- idea: gazetteer defined; three kinds of reference data; replace one layer
- job: Defines a gazetteer as a table of reference locations, the points or polygons a test compares each record with, then lists the three kinds of reference data (points, polygons, the genus habitat table). One short paragraph per fact, each option opened by its goal: the package includes them except species ranges; to change the data for all tests, `reference = "CoordinateCleaner"` (reads the tables of the reader's CoordinateCleaner installation); to change it for one test, the `gazetteers` argument, which does the job of CoordinateCleaner's `ref` arguments (comparison last, no `cc_*()` template name). States the article's scope in one sentence without listing the sections, links Get started for installation and names sf as the extra package for the polygon examples.
- leaves: what the article covers

### gaz.filtered  [A5]  (section, "A filtered point layer"; absorbed gaz.points 2026-10-13)
- idea: a subset of a shipped layer is the simplest custom layer; herbaria only, wider buffer
- job: Defines a point layer, shows `reference_points("institution")` with `name`, `type`, `source`, says the test uses the points whose `status` is not unconfirmed, filters those to herbaria and shows the flags change; points to Reference data for the `extension` column and the institution sources (`source`, `master_source`) instead of repeating the inventory.
- leaves: any data frame with longitude and latitude columns is a point layer; `reference_points()`

### gaz.extended  [A1 A5]  (section, "An extended point layer")
- idea: union of both capital tables
- job: Combines the Natural Earth and CoordinateCleaner capitals into one layer, then says the institution test uses CoordinateCleaner's points, some moved, plus confirmed points, shows `table(inst$status)` and that passing the whole table adds the unconfirmed points.
- leaves: other point sets fit the same way; the unconfirmed institution points can be added through `gazetteers`

### gaz.polygons  [A5]  (section)
- idea: sf polygons for sea, urban, country_mismatch
- job: Uses a study-area polygon as the land of `sea` and coded polygons for `country_mismatch`.
- leaves: polygon layer requirements; which code columns are read

### gaz.ranges  [A1 A5]  (section)
- idea: species range polygons for `range`
- job: Builds range polygons for two species and shows records inside, outside and with a buffer; the lizard at 52.5 N (about 55 km north of its range) is flagged without the buffer and kept with 100 km, so the buffer column differs from the plain one; the lizard at 55 N stays flagged under both.
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
