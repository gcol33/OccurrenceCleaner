# Context: OccurrenceCleaner

## Standing

### CoordinateCleaner
- released: first CRAN release 1.0-2 on 2017-11-10; current 3.0.1, published 2023-10-24 (CRAN archive and package page, read 2026-10-12)
- review: rOpenSci software peer review, ropensci/software-review#210, approved, closed 2018-11-09; published in Methods in Ecology and Evolution (label `pub:mee`)
- use: Zizka et al. 2019 (doi:10.1111/2041-210X.13152) cited 1,214 times (OpenAlex, read 2026-10-12); 31,285 downloads 2025-10-01 to 2026-09-30 (cranlogs, RStudio CRAN mirror only)
- repository: github.com/ropensci/CoordinateCleaner since 2016-10-25
- maintainers: Alexander Zizka (CRAN maintainer)

### OccurrenceCleaner
- released: first commit 2026-10-09; version 0.2.0; not on CRAN
- review: none; JSS manuscript in preparation
- use: the ali-filters collaboration (GBIF snapshot of 2026-10-01)
- validation: tests/testthat/test-equivalence.R and tests/testthat/test-group.R run CoordinateCleaner on sampled records and require identical flags except the documented differences; test-spatialvalid.R compares `as_spatialvalid()` column by column with `clean_coordinates()`; `.github/workflows/cc-devel.yaml` runs the suite against CoordinateCleaner's GitHub version. The algorithm ran earlier over 2,460,201,588 GBIF records as a Python implementation in mountain-area-garcia; that was different code, not this package, and was not checked record by record against CoordinateCleaner.

### burden
- OccurrenceCleaner has to show where it agrees with CoordinateCleaner, under which settings and reference data, and where results change and why. CoordinateCleaner's methods are the published reference and are not re-argued.

## Debt
- From CoordinateCleaner (Zizka et al. 2019): the set of record tests and what each one looks for, their definitions and default buffers, the outlier statistics and the raster approximation for large species, the dataset tests for ddmm conversion and rounding, the fossil tests, the choice of reference sources behind the gazetteers (Natural Earth, institution lists), and the `spatialvalid` output layout.
- credit: a full sentence near the top of the README, ?OccurrenceCleaner and the comparison article saying what CoordinateCleaner supplies, next to its citation. The article's first paragraph does this (2026-10-12).

## Use case
- Flagging the CoordinateCleaner tests on tables of millions to billions of records, including a GBIF snapshot streamed from disk.
- Keeping one flag per test per record on disk, so the exclusion rule is chosen and changed afterwards and several rules are tallied from one pass.
- GBIF's own quality fields and the habitat tests in the same rule as the coordinate tests.

### novelty claims
#### flags instead of filtering
- claim: "writes the result as flags instead of filtering" (vignettes/coordinatecleaner.Rmd, line 16)
- parent-does: `clean_coordinates(value = "spatialvalid")` returns one logical column per test and keeps every record; only the `cc_*()` functions default to `value = "clean"`
- precise-form: the engine returns one flag per test per record, stored next to the data, so the exclusion rule is chosen and compared afterwards (`keep_unflagged()`, `tally_flags()`); removal is a separate selection step, also available per test as `clean_<test>()`

#### speed and scale
- claim: proximity tests as nearest-neighbour queries; tables on disk streamed in chunks
- parent-does: CoordinateCleaner works on a data frame in memory and tests against buffer polygons
- precise-form: as stated, with the timings scoped (Evidence scope)

#### additions
- claim: GBIF issue, basis of record, establishment means, `sea_nonmarine`, `land_marine`
- parent-does: none of these tests (checked against `getNamespaceExports()` of 3.0.1, 2026-10-12)
- precise-form: marked as additions, never changing a CoordinateCleaner-equivalent flag

## Discrepancies

### buffer-circles
- kind: design
- behaviour: CoordinateCleaner 3.0.1 tests against a 72-gon (`cc_cap`, `cc_cen`, `cc_gbif`) or 40-gon (`cc_inst`) inscribed in the buffer circle; OccurrenceCleaner tests the geodesic distance. Records in the band r*cos(pi/n) to r get different flags.
- evidence: tests/testthat/test-equivalence.R; dev_notes/equivalence.md
- doc: vignettes/coordinatecleaner.Rmd, Buffer circles

### zero-buffer
- kind: upstream-defect
- behaviour: `cc_zero()` 3.0.1 buffers 0.5 metres around (0, 0); its documentation says 0.5 degrees, which OccurrenceCleaner uses
- evidence: dev_notes/cc_zero_repro.R
- upstream: ropensci/CoordinateCleaner#114, filed by gcol33 2026-10-10, open on 2026-10-12
- doc: vignettes/coordinatecleaner.Rmd, The zero buffer

### country-codes
- kind: upstream-defect
- behaviour: `cc_coun()` 3.0.1 compares against Natural Earth `ISO_A3`, which holds -99 for France, Norway and Kosovo, so every record in them is flagged; it also accepts alpha-3 only, where GBIF's `countryCode` is alpha-2 (design)
- upstream: ropensci/CoordinateCleaner#99 (all records in Norway and France flagged), filed by another user 2024-03-11, open on 2026-10-12; possibly related: #70 (2022-04-27), #97 (2023-11-14), not read
- doc: vignettes/coordinatecleaner.Rmd, Records in France, Norway and Kosovo (defect); Country codes (alpha-2 handling, design)

### invalid-coordinates
- kind: design
- behaviour: CoordinateCleaner's spatial tests return `NA` or "clean" for invalid coordinates and `cc_dupl()` flags the second of two invalid rows; here such a record gets only the `invalid` bit
- doc: vignettes/coordinatecleaner.Rmd, Records without valid coordinates

### raster-outliers
- kind: upstream-defect
- behaviour: `cc_outl()` 3.0.1 flags no records on the raster path (species of 10,000 records or more, or `thinning = TRUE`); `outlier` flags the records of the outlier cells. Below 10,000 records the flags are identical.
- evidence: tests/testthat/test-group.R
- upstream: ropensci/CoordinateCleaner#110 (raster approximation flags no outliers), filed by another user 2025-08-04, open on 2026-10-12
- doc: vignettes/coordinatecleaner.Rmd, Outliers of large species

### age-draws
- kind: design
- behaviour: `cf_age()` and `cf_outl()` draw from the session's random stream in input order; `age_outlier` and `spatiotemporal_outlier` draw from a stream seeded per taxon in a content-defined order. Same distribution, not the same draws.
- doc: vignettes/coordinatecleaner.Rmd, Random age draws

### small-datasets
- kind: upstream-defect
- behaviour: `cd_round()` 3.0.1 stops with an `rbind` error when a dataset below `min_unique_ds_size` sits next to larger ones; `dataset_rounded` leaves the small one untested and tests the others
- upstream: ropensci/CoordinateCleaner#66 (rbind error from datasets below the minimum size), filed by another user 2022-02-01, open on 2026-10-12; same error in #105 (2024-12-04)
- doc: vignettes/coordinatecleaner.Rmd, Small datasets

### dataset-key
- kind: design
- behaviour: records without a dataset key are not tested by either dataset test here; `cd_ddmm()` flags them
- doc: vignettes/coordinatecleaner.Rmd, Small datasets

### gazetteers
- kind: reference-data
- behaviour: the default `reference = "OccurrenceCleaner"` rebuilds the gazetteers from the original sources, with extension points from sources CoordinateCleaner does not use; `reference = "CoordinateCleaner"` reads its tables
- evidence: dev_notes/reference_data.md; vignettes/reference-data.Rmd
- doc: vignettes/coordinatecleaner.Rmd, Gazetteers

### sampling-counts
- kind: design
- behaviour: `cc_outl(sampling_thresh)` queries GBIF record counts at run time; here the counts are a table passed in `gazetteers = list(sampling = ...)`
- doc: vignettes/coordinatecleaner.Rmd, Functions around the tests

## Evidence scope

### speed benchmark
- shows: elapsed time of one call per test on one and ten million records placed at random (a tenth within 30 km of a capital), CoordinateCleaner's reference points in both, one machine (Ryzen 7 5700G, 64 GB, Windows 11, R 4.6.1), OccurrenceCleaner 0.2.0 against CoordinateCleaner 3.0.1
- does-not-show: agreement of the flags (the equivalence tests show that), behaviour on real GBIF coordinate distributions, suitability of any test for a given analysis
- source: bench/benchmark.R; bench/results/; dev_notes/benchmark.md
- stated-at: vignettes/coordinatecleaner.Rmd, Timings, first paragraph

### equivalence tests
- shows: identical flags on the sampled records, except the documented discrepancies, against CoordinateCleaner 3.0.1 and its GitHub version
- does-not-show: agreement on inputs unlike the samples; that either package's flags are right for an analysis
- stated-at: vignettes/coordinatecleaner.Rmd, How agreement is tested

## Framing
- open-with: `clean_coordinates(value = "spatialvalid")` with matched tests, buffers and `reference = "CoordinateCleaner"`, not the `cc_*()` filter chain
- organising question: where do the two packages agree, under which settings, and where and why do results change
- defects: stated as observed behaviour with the version, under "Behaviour of CoordinateCleaner 3.0.1"; the four issues linked once, in parentheses, in the opening paragraph of "Where the results differ" as "reported issues" (none confirmed by the maintainers on 2026-10-12), not repeated in the sections (docs-style hard rule and its exception); full status lives here
- avoid: "Coming from CoordinateCleaner"; "switch from"; "replacement"; "every function has a counterpart"; "instead of filtering" as a contrast with CoordinateCleaner as a whole; a speed table followed by a completeness claim

## Open
Resolved in vignettes/coordinatecleaner.Rmd, 2026-10-12: title and opening (`migration-assumption`, `thin-credit`, `overclaimed-novelty`), comparison opens on `clean_coordinates()` (`unfair-first-comparison`), defects grouped under "Behaviour of CoordinateCleaner 3.0.1", timings scoped and the completeness claim removed (`unscoped-benchmark`), "When is CoordinateCleaner the better choice?" added.

Checked 2026-10-13: no "Coming from CoordinateCleaner" label left in README.Rmd or the vignettes; every link uses the title "Compatibility with CoordinateCleaner". Stale anchors `#speed` (README, gbif-workflow) and `#where-the-flags-differ` (Get started) now point at `#timings` and `#where-the-results-differ`. ?OccurrenceCleaner and DESCRIPTION state "same definitions and default buffers" with the documented differences; the ?OccurrenceCleaner credit sentence lists the Debt items.

Still open:
- README.Rmd states the relation as "The package extends CoordinateCleaner" (the user's wording, kept on purpose, 2026-10-13: it extends the package, not only its tests), glossing CoordinateCleaner as the package that defines the tests and runs them in memory, then what this package runs them as (nearest-neighbour queries, streamed tables, so a snapshot), not the story phrase "an extension of CoordinateCleaner tailored to large-scale occurrence data"; the README credit with substance is in Acknowledgements, at the bottom, the top has the citation and "follow CoordinateCleaner's definitions and default buffers"
