# Information: OccurrenceCleaner

## Relation

### coordinatecleaner
- forms: an extension of CoordinateCleaner; an extension of 'CoordinateCleaner'
- as: runs CoordinateCleaner's record tests with the same definitions and default buffers, for large-scale data, keeping every record
- avoid: follows CoordinateCleaner; reproduces CoordinateCleaner (without "up to the documented differences")
- stated-at: @p:desc.claim; @p:readme.claim; @p:pkg.overview; @p:qs.opener; @p:cc.opener

### test-names
- detail: the `tests` argument of `clean_coordinates()` takes plural names ("capitals", "centroids", "countries", "duplicates", "institutions", "seas", "zeros") and "gbif"; that of `flag_occurrences()` takes singular names, "country_mismatch" and "gbif_headquarters"; the coordinate validity check has no test name in `clean_coordinates()` and stops the run (@p:cc.validity)
- avoid: `fn(tests = )` as a name for an argument in reader-facing text; write "the `tests` argument of `fn()`"
- home: @p:cc.test-names

### value-default
- detail: `cc_*()` default `value = "clean"` removes records; `clean_coordinates()` default `value = "spatialvalid"` flags, with TRUE meaning pass; `flag_<test>` is TRUE for fail
- home: @p:cc.pipe; @p:cc.clean-coordinates

### sea-scale
- detail: `cc_sea(scale = 110)`; `clean_coordinates(seas_scale = 50)`; `flag_occurrences(land_scale = 110)`
- stated-at: @p:qs.reference; @p:cc.mapping; ?flag_occurrences (`land_scale`); ?test_sea; vignettes/tests.Rmd (sea); vignettes/reference-data.Rmd (land scale)
- note: verified against CoordinateCleaner 3.0.1 `formals()` on 2026-10-10

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

### gazetteers-argument
- forms: `gazetteers`; custom gazetteer; custom layer
- as: the argument of `flag_occurrences()` that replaces the reference layer of single tests with the user's points or polygons
- defined: @p:gaz.opener
- glossed: @p:readme.reference

### reference-points
- forms: `reference_points()`
- as: returns the points a proximity test uses, with their attributes
- defined: @p:gaz.points; ?reference_points

### unit
- forms: unit; input unit; resumable unit
- as: one input file of a streamed table, flagged and written as a whole, skipped on rerun when done
- defined: @p:readme.snapshot; @p:qs.disk

## Quantities

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
- argument: flag_occurrences(buffers): capital 10 km, centroid 1 km, institution 100 m, gbif_headquarters 1 km, zero 0.5 degrees
- home: ?flag_occurrences (Tests section)
- stated-at: @p:readme.tests; @p:qs.buffers; @p:tests.proximity; @p:ref.buffers
- note: all agree with `.default_buffers` in R/flag.R (checked 2026-10-10)

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
