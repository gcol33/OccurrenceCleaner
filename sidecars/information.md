# Information: OccurrenceCleaner

## Relation

### coordinatecleaner
- forms: an extension of CoordinateCleaner; an extension of 'CoordinateCleaner'
- as: runs CoordinateCleaner's record tests with the same definitions and default buffers, for large-scale data, keeping every record
- avoid: follows CoordinateCleaner; reproduces CoordinateCleaner (without "up to the documented differences"); wraps or calls CoordinateCleaner (the tests are reimplemented; CoordinateCleaner runs only in the equivalence tests and under `reference = "CoordinateCleaner"`)
- stated-at: @p:desc.claim; @p:readme.claim; @p:pkg.overview; @p:qs.opener; @p:cc.opener
- reimplemented-at: @p:readme.comparable
- credit: Zizka and co-authors named for the tests, default buffers and grouped-test options at @p:readme.acknowledgements and @p:pkg.credit; cite the package at @p:readme.citation (bibtex, one entry from inst/CITATION) with CoordinateCleaner named with its DOI in the header line; both at @p:pkg.credit

### test-names
- detail: the `tests` argument of `clean_coordinates()` takes plural names ("capitals", "centroids", "countries", "duplicates", "institutions", "seas", "zeros") and "gbif"; that of `flag_occurrences()` takes singular names, "country_mismatch" and "gbif_headquarters"; the coordinate validity check has no test name in `clean_coordinates()` and stops the run (@p:cc.validity)
- avoid: `fn(tests = )` as a name for an argument in reader-facing text; write "the `tests` argument of `fn()`"; "the names here" (name the package); joining the fossil name to the coordinate names with a semicolon (it is a table row)
- home: @p:cc.test-names

### value-default
- detail: `cc_*()` default `value = "clean"` removes records; `clean_coordinates()` default `value = "spatialvalid"` flags, with TRUE meaning pass; `flag_<test>` is TRUE for fail; `as_spatialvalid()` converts to the `spatialvalid` layout (column names from the `spatialvalid` column of `flag_tests()`, `.<test>` for tests without one, `.summary`)
- home: @p:cc.pipe; @p:cc.clean-coordinates; @p:cc.spatialvalid
- stated-at: ?as_spatialvalid; NEWS.md

### sea-scale
- detail: `cc_sea(scale = 110)`; `clean_coordinates(seas_scale = 50)`; `flag_occurrences(land_scale = 110)`
- stated-at: @p:qs.reference; @p:cc.mapping; ?flag_occurrences (`land_scale`); ?test_sea; vignettes/tests.Rmd (sea); vignettes/reference-data.Rmd (land scale)
- note: verified against CoordinateCleaner 3.0.1 `formals()` on 2026-10-10

### settings-vs-args
- detail: CoordinateCleaner's outlier and dataset functions take their options as arguments (`method`, `mltpl`, `tdi`, `min_occs`, `thinning`, `size_thresh`, `replicates`, ...); `flag_occurrences()` takes them as `settings = list(<test> = list(...))`, same names and defaults
- home: @p:cc.mapping
- stated-at: ?flag_occurrences (`settings`); the six grouped test help pages (Settings); @p:readme.grouped; @p:out.methods; @p:fossil.outliers

### grouped-test-names
- detail: `clean_fossils()` names "temprange" and "spatiotemp", here `age_range_outlier` and `spatiotemporal_outlier` (and `age_outlier` for `cf_age()`); `clean_dataset()` names "ddmm" and "periodicity", here `dataset_ddmm` and `dataset_rounded`; `clean_coordinates()` "outliers", here `outlier`
- home: @p:cc.test-names
- stated-at: @p:fossil.outliers; @p:readme.fossil

### pyrate-name
- detail: CoordinateCleaner's `write_pyrate()` is `export_pyrate()` here, same file layout; the different name keeps `write_pyrate()` reachable when both packages are attached
- home: @p:cc.around-tests
- stated-at: @p:fossil.pyrate; ?export_pyrate

### sampling-counts
- detail: `cc_outl()` counts GBIF records per country online at run time, only when `sampling_thresh` is above 0 (default 0, no correction; CoordinateCleaner source read 2026-10-13); here the counts are a table passed as `gazetteers = list(sampling = ...)` with `settings = list(outlier = list(sampling_thresh = ...))`. The reference label records the number of countries and the table's md5 checksum (R/reference.R), not the counts themselves
- avoid: "each time it runs" or "every time" for the GBIF query; "records the counts in the reference label"
- home: @p:cc.around-tests
- stated-at: @p:out.sampling; ?test_outlier (Settings); ?flag_occurrences (`gazetteers`)

## Terms

### flag
- forms: flag; flags; flagged
- as: a mark on a record that a test found the problem, stored without removing the record
- defined: known

### flag-word
- forms: flag word; the `flags` column; integer flag word
- as: one integer per record whose bits hold the results of all tests
- defined: @p:qs.opener; README glosses it as "an integer `flags` column that holds all of them, one bit per test" (@p:readme.example-result) and does not use "flag word"

### rule
- forms: rule; rules; cleaning rule
- as: a set of tests; a record is removed by the rule if any of them flags it
- defined: @p:readme.two-choices; @p:gs.reference-tests
- glossed: @p:desc.flags ("which flags to filter on")

### test-selection
- forms: every test the columns allow; every test whose columns are present; test plan; `test_plan()`
- as: without `tests`, `flag_occurrences()` runs every test whose input columns are present (and `range` when range polygons are given); `test_plan()` lists the tests that run and the missing input of each other test; kept apart from the rule, which decides exclusion
- defined: @p:readme.two-choices; @p:gs.reference-tests; ?flag_occurrences details; ?test_plan
- glossed: @p:readme.input; @p:tests.flag-word; @p:gbif.flag; @p:gbif.guidance

### loss-table
- forms: loss table
- as: per group, the number of records each test flags and each rule removes and keeps
- defined: ?tally_flags (title and description)
- note: README and the on-disk article use the plain description instead of the term

### bit-mask
- forms: bit mask
- as: the integer whose set bits are a rule's tests
- defined: vignettes/rules.Rmd (counts section, `flag_mask(T)`)

### addition
- forms: addition; additions
- as: a test with no CoordinateCleaner counterpart
- defined: @p:readme.tests ("additions"); @p:tests.flag-word (the `source` column)

### equivalent-test
- forms: CoordinateCleaner-equivalent test; the tests with an `equivalent`
- as: a record test with CoordinateCleaner's definition and default buffer
- defined: @p:qs.tests-note
- note: every "reproduce" now carries "up to the documented differences", except `buffers = list(zero = 0)`, which reproduces 3.0.1 exactly

### gbif-headquarters
- forms: GBIF headquarters; `gbif_headquarters`
- as: the GBIF office in Copenhagen (12.58 E, 55.67 N), a default location some records receive
- defined: @p:tests.proximity
- avoid: GBIF secretariat

### age-equal
- forms: `age_equal`; the fossil age test; the age test
- as: flags a record whose minimum age is equal to or greater than its maximum age
- defined: @p:fossil.flag
- other-senses: CoordinateCleaner's `cf_equal()`, and "agesequal" in `clean_fossils()`

### age-fields
- forms: minimum age; maximum age; `min_age`, `max_age` fields of `occ_columns()`; `min_ma`, `max_ma` (PBDB and CoordinateCleaner column names)
- as: the two ends of a fossil record's stratigraphic age range, in million years
- defined: @p:fossil.opener
- stated-at: @p:readme.fossil (PBDB `lng` and `accepted_name` mapped; ages read from `min_ma`, `max_ma` by default)

### gazetteers-argument
- forms: `gazetteers`; custom gazetteer; custom layer
- as: the argument of `flag_occurrences()` that replaces the reference layer of single tests with the user's points or polygons, or supplies the per-country record counts of the outlier sampling correction (`sampling`)
- defined: @p:gaz.opener; `sampling` at @p:out.sampling
- glossed: @p:readme.reference

### extension-points
- forms: `extension` column; points marked `extension`; extension points
- as: the gazetteer points from sources CoordinateCleaner's tables do not draw on (243 Natural Earth capitals, 516 Natural Earth country centroids and label points, 7,665 institutions from Wikidata beyond the English list's museums and from the non-English Wikipedia lists); used by default, left out by passing the rows with `extension` FALSE through `gazetteers`
- defined: @p:ref.extension; ?test_capital, ?test_centroid, ?test_institution
- stated-at: @p:readme.usecases (7,665 institutions marked `extension`); @p:cc.gazetteers; @p:gaz.opener; @p:ref.vs-cc; NEWS.md

### reference-points
- forms: `reference_points()`
- as: returns the points a proximity test uses, with their attributes
- defined: @p:gaz.points; ?reference_points

### grouped-test
- forms: grouped test; the outlier and dataset tests; group pass
- as: a test that judges a record against the other records of its species, taxon or dataset, run in a pass over the whole input before the record tests
- defined: @p:out.opener
- glossed: @p:readme.grouped ("judge a record against the rest of its species or dataset")
- note: NEWS uses "grouped tests"; the README says "the outlier and dataset tests"

### settings-argument
- forms: `settings`
- as: the argument of `flag_occurrences()` holding per-test option lists for the grouped tests, defaults CoordinateCleaner's
- defined: ?flag_occurrences (`settings`); @p:out.methods
- glossed: @p:readme.grouped

### dataset-key
- forms: dataset key; `datasetKey`; `dataset` field of `occ_columns()`
- as: the column naming the dataset a record belongs to, GBIF's identifier of the publishing dataset by default
- defined: @p:out.datasets

### aohi
- forms: `aohi`; Artificial Hotspot Occurrence Inventory; AHOI; artificial hotspot
- as: coordinates that recur most often in GBIF records (Park et al. 2023); the test flags records within 10 km of one
- defined: @p:out.aohi; ?test_aohi
- glossed: @p:tests.flag-word

### range-test
- forms: `range`; species range; range polygons
- as: flags records outside every range polygon of their species; polygons supplied as `gazetteers = list(range = <sf>)`
- defined: @p:gaz.ranges; ?test_range
- other-senses: `age_range_outlier` (width of a fossil age range); CoordinateCleaner's `cf_range()`

### unit
- forms: unit; input unit; resumable unit
- as: one input file of a streamed table, flagged and written as a whole, skipped on rerun when done
- defined: @p:readme.snapshot; @p:qs.disk

## Quantities

### test-count
- metric: tests in the layout: 30 (11 coordinate record tests, `range`, `aohi`, `outlier`, 2 dataset tests, 4 fossil tests, 8 GBIF field tests, 2 habitat tests); 20 ported from CoordinateCleaner; layout_version 4
- source: `flag_tests()`
- stated-at: NEWS.md; @p:tests.opener (eleven, eight and two here, nine elsewhere); @p:gbif.flag (21 run on the example table, 9 not)
- stated-at (README): @p:readme.tests (30; twenty from CoordinateCleaner, ten additions)
- note: DESCRIPTION gives no count

### aohi-points
- metric: 308 points in the shipped AHOI layer
- source: data-raw/aohi.R on the Dryad deposit doi:10.5061/dryad.v41ns1s0p
- stated-at: none in prose

### outliers-simulation
- metric: 961 records of four species; 3 of 4 far records flagged by the quantile threshold, 4 plus 15 clean by MAD; herbarium loses 6 (3 outliers, 4 near AHOI points, one both)
- source: the outliers article's own chunks (set.seed(11))
- stated-at: @p:out.data; @p:out.outlier; @p:out.methods; @p:out.rule; @p:out.guidance
- note: prose constants; they go stale if the simulation changes

### fossil-outliers-simulation
- metric: `age_range_outlier` flags all 40 period-dated records; `age_outlier` 8 (10 with seed 7); `spatiotemporal_outlier` 3
- source: the fossil article's own chunks
- stated-at: @p:fossil.outliers

### speed-df
- metric: seconds to flag a data frame with the nine CoordinateCleaner tests that need only coordinates and a species (`cc_default` in bench/benchmark.R), own reference
- population: 1e6 and 1e7 synthetic records, 10 % near capitals
- source: dev_notes/benchmark.md (run 2026-10-09 on worky, AMD Ryzen 7 5700G, 64 GB, R 4.6.1, OccurrenceCleaner 0.1.0, CoordinateCleaner 3.0.1); bench/benchmark.R; table at @p:cc.speed
- stated-at: @p:desc.scale ("a few million records ... in seconds"); @p:readme.usecases (capital test 1.4 s at 1e7, linked to @p:cc.speed; the CoordinateCleaner time only in the comparison article); @p:cc.speed; @p:gbif.guidance (1.9 s at 1e6); @p:disk.snapshot (17.8 s at 1e7)
- note: vignette table matches dev_notes/benchmark.md (checked 2026-10-10)

### snapshot-size
- metric: size of the GBIF snapshot of 2026-10-01 on disk: 9,927 Parquet files, 287,983,533,156 bytes (288 GB); record count not stated as a number (no source in the repo)
- source: `E:/research/raw/occurrences/gbif_snapshot/2026-10-01/DONE` (download doi:10.15468/dl.tup2g6, 1 October 2026); the full run in one R process on worky (AMD Ryzen 7 5700G, 64 GB) started 2026-10-12, peak memory to be read from `bench/results/snapshot/peak_mb.txt` when it finishes
- stated-at: @p:readme.usecases (as "hundreds of gigabytes", a single R session on a desktop computer, chunked so memory stays bounded)

### speed-ratio
- metric: seconds per test, OccurrenceCleaner vs CoordinateCleaner
- source: as speed-df
- stated-at: @p:cc.speed

### agreement
- metric: share of records with identical flags per test
- source: dev_notes/benchmark.md; dev_notes/equivalence.md; computed live at @p:cc.agreement
- stated-at: @p:cc.agreement

### gbif-simulation
- metric: counts from the seeded simulation in the GBIF workflow article, flagged with every test the columns allow (21 tests): 274 of 2,276 records flagged; ladder 125, +21, +20, +41, +67 (duplicate 42, urban 20, aohi 6); 1,998 clean kept; 15 of 20 zero records with seven tests; 25 swapped records flagged by `outlier`; of 30 whole-degree records 5 on the France and Germany centroids, 1 at an institution, 24 kept by `wild`
- source: the article's own chunks (set.seed(42))
- stated-at: @p:gbif.flag; @p:gbif.truth; @p:gbif.combos; @p:gbif.ladder; @p:gbif.cleaned
- note: recomputed 2026-10-12 after the default changed to every applicable test; the build of 8c3de2d already showed `cc` 125 and 24 whole-degree records kept against prose 119 and none, after the reference-data update. The negated-record catch is computed inline as `neg_caught`; the other values are prose constants and go stale if the simulation or the reference data changes

### rules-simulation
- metric: the 40 zero records, flagged by `zero`, `equal` and `sea`, so none counted under `only`, in the rules article
- source: the article's own chunks (set.seed(42))

### institution-zero-entries
- metric: 5 GRSciColl institutions with zero coordinates dropped from the gazetteer (4 within 0.14 degrees of (0, 0), 1 at longitude exactly 0); 6,080 of 6,085 with coordinates shipped
- source: data-raw/institutions.R on the 2026-10-09 export; decided 2026-10-10
- stated-at: @p:ref.layers; @p:ref.vs-cc; ?test_institution
- stated-at: @p:rules.per-test; @p:rules.compare

### institutions-wikidata
- metric: 7,810 Wikidata points (3,263 BotanicalGarden, 1,835 Museum, 2,609 ZooAquarium, 103 Herbarium), incl. 110 museums by natural-history subject and the list museums with their own coordinates; 700 museums of Wikipedia's lists of natural history museums (en revision 1376233148 and the ar, de, fr, nl, pt, eo editions; 2,331 entries) placed by linked place or GeoNames populated place (en 385); 3 GeoNames places; 3,652 BGCI gardens (3,765 listed, 3,653 with coordinates, 1 at zero); 1,062 Index Herbariorum herbaria not placed by GRSciColl (4,805 with a location); 2,468 GBIF registry publishing organisations with coordinates (of 3,639); 3,254 points for the rest of CoordinateCleaner's list (2,120 placed by name, 1,134 OpenStreetMap feature points); 25,029 institution points shipped in all, 17,364 from CoordinateCleaner's sources and 7,665 marked `extension`
- metric: CoordinateCleaner's 9,773 institutions with coordinates: 6,313 held under their name, 329 by a point within 25 km sharing >= 60 % of their name words, 3,130 placed by name (Wikidata 1,052, OpenStreetMap 646, GeoNames town of the listed city 684, town named in the name 252, town nearest CoordinateCleaner's point 496), 1 not placed (SCAR expert group, Antarctica)
- metric: OpenStreetMap location check (Overpass API, retrieved 2026-10-13): 258,691 named features of university, college, research institute or office, museum, zoo, aquarium and botanical garden kinds; a feature within 25 km of CoordinateCleaner's point whose distinctive name words all occur in the institution's name and cover at least half of its own is found for 4,818 of 9,773 institutions; 1,662 lie closer to CoordinateCleaner's point than every point of the table for the institution, 1,134 added after dropping duplicates and zero coordinates (all `extension` FALSE, median 2.8 km from the nearest earlier point of the same name)
- metric: a shipped point within 100 m / 1 km / 5 km of CoordinateCleaner's point for 36 / 78 / 92 % of its 9,773 institutions (33 / 76 / 91 % for the points with `extension` FALSE; 32 / 73 / 91 % and 28 / 70 / 90 % before the OpenStreetMap check); CoordinateCleaner geocoded nearly every row itself (641 of its 712 BGCI gardens, 398 Wikipedia museums by hand)
- source: data-raw/institutions.R, data-raw/overpass.R, queried 2026-10-10 and 2026-10-13; dev_notes/reference_data.md
- stated-at: @p:readme.usecases (25,029 points, 7,665 extension, seven Wikipedia languages, all but one CoordinateCleaner institution); NEWS.md; @p:ref.layers; @p:ref.vs-cc; ?test_institution; @p:gaz.extended (CoordinateCleaner's own geocoding, union; all but one)
- avoid: "every institution of CoordinateCleaner's list" (one, the SCAR expert group in Antarctica, is not placed; README, gazetteers article fixed 2026-10-13)

### habitat-genera
- metric: 318,365 kingdom/genus pairs classed from IRMNG: 296,474 not marine, 21,891 only marine
- source: data-raw/habitat.R on the IRMNG archive of 2026-10-06; dev_notes/reference_data.md
- stated-at: @p:ref.layers

### habitat-source
- metric: IRMNG Darwin Core archive 2026-10-06, CC BY 4.0, citation "Rees, T. (compiler) (2026). The Interim Register of Marine and Nonmarine Genera. Available from https://www.irmng.org at VLIZ."
- source: eml.xml of the archive; data-raw/habitat.R
- stated-at: ?reference_habitat; ?test_habitat; @p:ref.layers; vignettes/tests.Rmd (References); DESCRIPTION; NEWS.md

### buffer-band
- metric: share of a buffer radius inside CoordinateCleaner's inscribed polygon (99.9 % at 72 vertices, 99.7 % at 40)
- source: r cos(pi/n), R/flag.R (Tests)
- stated-at: ?flag_occurrences (Tests); vignettes/tests.Rmd (capital sweep); @p:cc.buffer-circles shows the effect by example, without the numbers

## Defaults

### buffers
- argument: flag_occurrences(buffers): capital 10 km, centroid 1 km, institution 100 m, gbif_headquarters 1 km, zero 0.5 degrees (range and aohi under range-aohi-buffers)
- home: ?flag_occurrences (Tests section)
- stated-at: @p:readme.example-result (capital 10 km, gbif_headquarters 1 km); @p:tests.flag-word; @p:qs.buffers; @p:tests.proximity; @p:ref.buffers
- note: all agree with `.default_buffers` in R/flag.R (checked 2026-10-10)

### grouped-settings
- argument: flag_occurrences(settings): outlier method "quantile", mltpl 5, tdi 1000 km, min_occs 7, raster from 10,000 records at 0.5 degrees, sampling_thresh (see ?test_outlier); fossil outlier tests method "quantile", mltpl 5, size_thresh 7, replicates 5; dataset_ddmm min_span 2; dataset_rounded min_unique_ds_size 4
- home: the Settings sections of ?test_outlier, ?test_age_outlier, ?test_spatiotemporal_outlier, ?test_age_range_outlier, ?test_dataset_ddmm, ?test_dataset_rounded
- stated-at: @p:out.outlier; @p:out.methods; @p:out.large; @p:out.guidance; @p:fossil.outliers

### range-aohi-buffers
- argument: flag_occurrences(buffers): range 0 m, aohi 10 km, sea_nonmarine 0 m, land_marine 0 m
- home: ?test_range, ?test_aohi, ?test_habitat
- stated-at: @p:tests.flag-word (aohi 10 km); @p:out.aohi; @p:gaz.ranges (100 km example); @p:tests.habitat (named, no value)
- note: `@param buffers` in ?flag_occurrences names all of them with their defaults

### land-scale
- argument: flag_occurrences(land_scale = 110)
- home: ?flag_occurrences
- stated-at: @p:qs.reference

### reference
- argument: flag_occurrences(reference = "OccurrenceCleaner")
- home: ?flag_occurrences
- stated-at: @p:readme.reference; @p:qs.reference; @p:cc.gazetteers

## Rules

### coordinatecleaner-rule
- condition: an article or the README names a rule `coordinatecleaner`
- action: it is always the same eight tests: `invalid`, `zero`, `equal`, `capital`, `centroid`, `institution`, `gbif_headquarters`, `sea` (the `clean_coordinates()` defaults that need only coordinates and a species, without its outlier test)
- stated-at: vignettes/rules.Rmd (Comparing rules); vignettes/on-disk.Rmd (Tallying from disk); vignettes/gbif-workflow.Rmd (Comparing cleaning rules, since 2026-10-13); README.Rmd (snapshot example, since 2026-10-13)
- note: `invalid` flags nothing in the GBIF simulation, so the ladder counts (125, 274) did not change

### not-flagged
- condition: prose reads a `FALSE` flag or an unflagged record
- action: say "not flagged by this test" or "passed the tests that were run"; never "checked and found correct"; name the untested cases where they arise (test not run: no column; test ran but could not judge: missing age, species below `min_occs`, no range polygon, genus without a habitat class)
- stated-at: @p:gs.flag-result (first output); @p:gbif.flag; @p:fossil.flag (record 5); @p:out.outlier (`min_occs`); @p:gaz.ranges; @p:tests.habitat

### country-codes
- condition: a GBIF table checked with `country_mismatch`
- action: nothing; alpha-2 is accepted
- stated-at: ?flag_occurrences (Tests); ?test_country_mismatch; @p:cc.country-codes; vignettes/tests.Rmd (country_mismatch)
- note: all four name alpha-2, alpha-3 and `ADM0_A3`, as R/flag.R does

### streamed-duplicates
- condition: `duplicate` on an on-disk table
- action: none; streamed `duplicate` compares records across all input files, as on a data frame (on-disk article)
- stated-at: ?flag_occurrences (Tests); @p:cc.streamed-duplicates
