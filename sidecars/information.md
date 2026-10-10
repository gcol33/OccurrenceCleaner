# Information: OccurrenceCleaner

## Relation

### coordinatecleaner
- forms: an extension of CoordinateCleaner; an extension of 'CoordinateCleaner'
- as: runs CoordinateCleaner's record tests with the same definitions and default buffers, for large-scale data, keeping every record
- avoid: follows CoordinateCleaner; reproduces CoordinateCleaner (without "up to the documented differences")
- stated-at: @p:desc.claim; @p:readme.claim; @p:cc.opener
- warning: relation-drift: ?OccurrenceCleaner says "The tests and their default buffers follow CoordinateCleaner" (@p:pkg.overview)
- warning: relation-missing: the Quick start opener (@p:qs.opener) does not name CoordinateCleaner

### test-names
- detail: `clean_coordinates(tests = )` takes plural names ("capitals", "centroids", "institutions", "seas", "zeros", "duplicates") and "gbif"; `flag_occurrences(tests = )` takes singular names and "gbif_headquarters"
- home: @p:cc.mapping
- warning: relation-gap: not in the mapping table

### value-default
- detail: `cc_*()` default `value = "clean"` removes records; `clean_coordinates()` default `value = "spatialvalid"` flags, with TRUE meaning pass; `flag_<test>` is TRUE for fail
- home: @p:cc.pipe; @p:cc.clean-coordinates

### sea-scale
- detail: `cc_sea(scale = 110)`; `clean_coordinates(seas_scale = 50)`; `flag_occurrences(land_scale = 110)`
- stated-at: @p:qs.reference; ?flag_occurrences (`land_scale`)
- warning: relation: both call 110 "CoordinateCleaner's default"; true for `cc_sea()`, not for `clean_coordinates()`, which the comparison article names as the closer equivalent

## Terms

### flag
- forms: flag; flags; flagged
- as: a mark on a record that a test found the problem, stored without removing the record
- defined: known

### flag-word
- forms: flag word; the `flags` column; integer flag word
- as: one integer per record whose bits hold the results of all tests
- defined: @p:qs.opener
- warning: use-before-define: README uses "flag word" (@p:readme.box) and defines it nowhere; it says "an integer `flags` column" at @p:readme.example-result

### rule
- forms: rule; rules; cleaning rule
- as: a set of tests; a record is removed by the rule if any of them flags it
- defined: @p:readme.rules; @p:qs.rules
- glossed: @p:desc.flags ("which flags to filter on")

### loss-table
- forms: loss table
- as: per group, the number of records each test flags and each rule removes and keeps
- defined: none
- warning: undefined: used once at @p:readme.box; elsewhere the README says "the number of records each test flags and the number each rule removes and keeps" (@p:readme.rules). Use that or define the term

### bit-mask
- forms: bit mask
- as: the integer whose set bits are a rule's tests
- defined: none
- warning: undefined: @p:readme.box

### addition
- forms: addition; additions
- as: a test with no CoordinateCleaner counterpart
- defined: @p:readme.tests (the "source" column)

### equivalent-test
- forms: CoordinateCleaner-equivalent test; the first eleven tests
- as: a record test with CoordinateCleaner's definition and default buffer
- defined: @p:qs.tests-note
- other-senses: "reproduce" at @p:qs.tests-note and @p:qs.reference claims identity without the documented differences

### unit
- forms: unit; input unit; resumable unit
- as: one input file of a streamed table, flagged and written as a whole, skipped on rerun when done
- defined: @p:readme.snapshot; @p:qs.disk

## Quantities

### speed-df
- metric: seconds to flag a data frame, `default_tests()`, own reference
- population: 1e6 and 1e7 synthetic records, 10 % near capitals
- source: dev_notes/benchmark.md (run 2026-10-09 on worky, AMD Ryzen 7 5700G, 64 GB, R 4.6.1, OccurrenceCleaner 0.1.0, CoordinateCleaner 3.0.1); bench/benchmark.R; table at @p:cc.speed
- stated-at: @p:desc.scale ("a few million records ... in seconds"); @p:readme.equivalence (same); @p:cc.speed
- note: vignette table matches dev_notes/benchmark.md (checked 2026-10-10)

### speed-ratio
- metric: seconds per test, OccurrenceCleaner vs CoordinateCleaner
- source: as speed-df
- stated-at: @p:cc.speed

### agreement
- metric: share of records with identical flags per test
- source: dev_notes/benchmark.md; dev_notes/equivalence.md; computed live at @p:cc.agreement
- stated-at: @p:cc.agreement

### buffer-band
- metric: share of a buffer radius inside CoordinateCleaner's inscribed polygon (99.9 % at 72 vertices, 99.7 % at 40)
- source: r cos(pi/n), @p:cc.buffer-circles
- stated-at: ?flag_occurrences (Tests); @p:cc.buffer-circles

## Defaults

### buffers
- argument: flag_occurrences(buffers): capital 10 km, centroid 1 km, institution 100 m, gbif_headquarters 1 km, zero 0.5 degrees
- home: ?flag_occurrences (Tests section)
- stated-at: @p:readme.tests; @p:qs.buffers
- note: all three agree with `.default_buffers` in R/flag.R (checked 2026-10-10)

### land-scale
- argument: flag_occurrences(land_scale = 110)
- home: ?flag_occurrences
- stated-at: @p:readme.tests; @p:qs.reference

### reference
- argument: flag_occurrences(reference = "natural_earth")
- home: ?flag_occurrences
- stated-at: @p:readme.method; @p:qs.reference; @p:cc.gazetteers

## Rules

### country-codes
- condition: a GBIF table checked with `country_mismatch`
- action: nothing; alpha-2 is accepted
- stated-at: ?flag_occurrences (Tests); @p:cc.country-codes
- warning: rule-mismatch: ?flag_occurrences says alpha-2 and alpha-3; the article and R/flag.R also match Natural Earth's `ADM0_A3`

### streamed-duplicates
- condition: `duplicate` on an on-disk table
- action: make each input file a unit within which duplicates matter (on-disk article)
- stated-at: ?flag_occurrences (Tests); @p:cc.streamed-duplicates

## Placement

### readme-gbif-fields
- at: @p:readme.claim
- detail: the three GBIF fields with examples in parentheses
- needed-for: A4; the test table at @p:readme.tests lists the same fields
- move-to: keep one of the two; the opening could name "GBIF's own quality fields" and leave the list to the table
