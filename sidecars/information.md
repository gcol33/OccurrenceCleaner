# Information: OccurrenceCleaner

## Relation

### coordinatecleaner
- forms: an extension of CoordinateCleaner; an extension of 'CoordinateCleaner'
- as: runs CoordinateCleaner's record tests with the same definitions and default buffers, for large-scale data, keeping every record
- avoid: follows CoordinateCleaner; reproduces CoordinateCleaner (without "up to the documented differences"); wraps or calls CoordinateCleaner (the tests are reimplemented; CoordinateCleaner runs only in the equivalence tests and under `reference = "CoordinateCleaner"`)
- stated-at: @p:desc.claim; @p:readme.claim; @p:pkg.overview; @p:qs.opener; @p:cc.opener
- reimplemented-at: @p:readme.equivalence
- credit: Zizka and co-authors named for the tests, default buffers and grouped-test options at @p:readme.acknowledgements and @p:pkg.credit; cite both at @p:readme.citation (bibtex), @p:pkg.credit and inst/CITATION

### test-names
- detail: the `tests` argument of `clean_coordinates()` takes plural names ("capitals", "centroids", "countries", "duplicates", "institutions", "seas", "zeros") and "gbif"; that of `flag_occurrences()` takes singular names, "country_mismatch" and "gbif_headquarters"; the coordinate validity check has no test name in `clean_coordinates()` and stops the run (@p:cc.validity)
- avoid: `fn(tests = )` as a name for an argument in reader-facing text; write "the `tests` argument of `fn()`"; "the names here" (name the package); joining the fossil name to the coordinate names with a semicolon (it is a table row)
- home: @p:cc.test-names

### value-default
- detail: `cc_*()` default `value = "clean"` removes records; `clean_coordinates()` default `value = "spatialvalid"` flags, with TRUE meaning pass; `flag_<test>` is TRUE for fail
- home: @p:cc.pipe; @p:cc.clean-coordinates

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
- stated-at: @p:fossil.pyrate; @p:readme.box; ?export_pyrate

### sampling-counts
- detail: `cc_outl(sampling_thresh)` counts GBIF records per country online at run time; here the counts are a table passed as `gazetteers = list(sampling = ...)` with `settings = list(outlier = list(sampling_thresh = ...))`, and are recorded in the reference label
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
- defined: @p:readme.rules; @p:qs.rules
- glossed: @p:desc.flags ("which flags to filter on")

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
- defined: @p:readme.tests (the "source" column)

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
- glossed: @p:readme.grouped; @p:readme.box

### dataset-key
- forms: dataset key; `datasetKey`; `dataset` field of `occ_columns()`
- as: the column naming the dataset a record belongs to, GBIF's identifier of the publishing dataset by default
- defined: @p:out.datasets

### aohi
- forms: `aohi`; Artificial Hotspot Occurrence Inventory; AHOI; artificial hotspot
- as: coordinates that recur most often in GBIF records (Park et al. 2023); the test flags records within 10 km of one
- defined: @p:out.aohi; ?test_aohi
- glossed: @p:readme.tests

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
- metric: tests in the layout: 28 (11 coordinate record tests, `range`, `aohi`, `outlier`, 2 dataset tests, 4 fossil tests, 8 GBIF field tests); 20 ported from CoordinateCleaner; layout_version 3
- source: `flag_tests()`
- stated-at: NEWS.md; @p:tests.opener (eleven and eight here, nine elsewhere); @p:gbif.flag ("nineteen tests in the first bits")
- note: README and DESCRIPTION give no count

### aohi-points
- metric: 308 points in the shipped AHOI layer
- source: data-raw/aohi.R on the Dryad deposit doi:10.5061/dryad.v41ns1s0p
- stated-at: none in prose

### outliers-simulation
- metric: 961 records of four species; 3 of 4 far records flagged by the quantile fence, 4 plus 15 clean by MAD; herbarium loses 6 (3 outliers, 4 near AHOI points, one both)
- source: the outliers article's own chunks (set.seed(11))
- stated-at: @p:out.data; @p:out.outlier; @p:out.methods; @p:out.rule; @p:out.guidance
- note: prose constants; they go stale if the simulation changes

### fossil-outliers-simulation
- metric: `age_range_outlier` flags all 40 period-dated records; `age_outlier` 8 (10 with seed 7); `spatiotemporal_outlier` 3
- source: the fossil article's own chunks
- stated-at: @p:fossil.outliers

### speed-df
- metric: seconds to flag a data frame, `default_tests()`, own reference
- population: 1e6 and 1e7 synthetic records, 10 % near capitals
- source: dev_notes/benchmark.md (run 2026-10-09 on worky, AMD Ryzen 7 5700G, 64 GB, R 4.6.1, OccurrenceCleaner 0.1.0, CoordinateCleaner 3.0.1); bench/benchmark.R; table at @p:cc.speed
- stated-at: @p:desc.scale ("a few million records ... in seconds"); @p:readme.scale (same, linked to @p:cc.speed); @p:cc.speed; @p:gbif.guidance (1.9 s at 1e6); @p:disk.snapshot (17.8 s at 1e7)
- note: vignette table matches dev_notes/benchmark.md (checked 2026-10-10)

### speed-ratio
- metric: seconds per test, OccurrenceCleaner vs CoordinateCleaner
- source: as speed-df
- stated-at: @p:cc.speed

### agreement
- metric: share of records with identical flags per test
- source: dev_notes/benchmark.md; dev_notes/equivalence.md; computed live at @p:cc.agreement
- stated-at: @p:cc.agreement

### gbif-simulation
- metric: counts from the seeded simulation in the GBIF workflow article (263 of 2,276 records flagged; ladder 119, +21, +20, +41, +62; 1,998 clean kept; 15 of 20 zero records with five tests)
- source: the article's own chunks (set.seed(42))
- stated-at: @p:gbif.flag; @p:gbif.truth; @p:gbif.combos; @p:gbif.ladder; @p:gbif.cleaned
- note: recomputed on committed HEAD 7b9d944 on 2026-10-10; all hard-coded values matched except the negated-record catch (18, not 17), now computed inline as `neg_caught`. The other values are prose constants and go stale if the simulation changes

### rules-simulation
- metric: the 40 zero records, flagged by `zero`, `equal` and `sea`, so none counted under `only`, in the rules article
- source: the article's own chunks (set.seed(42))

### institution-zero-entries
- metric: 5 GRSciColl institutions with zero coordinates dropped from the gazetteer (4 within 0.14 degrees of (0, 0), 1 at longitude exactly 0); 6,080 of 6,085 with coordinates shipped
- source: data-raw/institutions.R on the 2026-10-09 export; decided 2026-10-10
- stated-at: @p:ref.layers; @p:ref.vs-cc; ?test_institution
- stated-at: @p:rules.per-test; @p:rules.compare

### buffer-band
- metric: share of a buffer radius inside CoordinateCleaner's inscribed polygon (99.9 % at 72 vertices, 99.7 % at 40)
- source: r cos(pi/n), @p:cc.buffer-circles
- stated-at: ?flag_occurrences (Tests); @p:cc.buffer-circles

## Defaults

### buffers
- argument: flag_occurrences(buffers): capital 10 km, centroid 1 km, institution 100 m, gbif_headquarters 1 km, zero 0.5 degrees (range and aohi under range-aohi-buffers)
- home: ?flag_occurrences (Tests section)
- stated-at: @p:readme.tests; @p:qs.buffers; @p:tests.proximity; @p:ref.buffers
- note: all agree with `.default_buffers` in R/flag.R (checked 2026-10-10)

### grouped-settings
- argument: flag_occurrences(settings): outlier method "quantile", mltpl 5, tdi 1000 km, min_occs 7, raster from 10,000 records at 0.5 degrees, sampling_thresh (see ?test_outlier); fossil outlier tests method "quantile", mltpl 5, size_thresh 7, replicates 5; dataset_ddmm min_span 2; dataset_rounded min_unique_ds_size 4
- home: the Settings sections of ?test_outlier, ?test_age_outlier, ?test_spatiotemporal_outlier, ?test_age_range_outlier, ?test_dataset_ddmm, ?test_dataset_rounded
- stated-at: @p:out.outlier; @p:out.methods; @p:out.large; @p:out.guidance; @p:fossil.outliers

### range-aohi-buffers
- argument: flag_occurrences(buffers): range 0 m, aohi 10 km
- home: ?test_range, ?test_aohi
- stated-at: @p:readme.tests (aohi 10 km); @p:out.aohi; @p:gaz.ranges (100 km example)
- note: `@param buffers` in ?flag_occurrences names only capital, centroid, institution, gbif_headquarters and zero

### land-scale
- argument: flag_occurrences(land_scale = 110)
- home: ?flag_occurrences
- stated-at: @p:readme.tests; @p:qs.reference

### reference
- argument: flag_occurrences(reference = "natural_earth")
- home: ?flag_occurrences
- stated-at: @p:readme.reference; @p:qs.reference; @p:cc.gazetteers

## Rules

### country-codes
- condition: a GBIF table checked with `country_mismatch`
- action: nothing; alpha-2 is accepted
- stated-at: ?flag_occurrences (Tests); ?test_country_mismatch; @p:cc.country-codes; vignettes/tests.Rmd (country_mismatch)
- note: all four name alpha-2, alpha-3 and `ADM0_A3`, as R/flag.R does

### streamed-duplicates
- condition: `duplicate` on an on-disk table
- action: make each input file a unit within which duplicates matter (on-disk article)
- stated-at: ?flag_occurrences (Tests); @p:cc.streamed-duplicates
