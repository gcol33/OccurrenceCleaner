# OccurrenceCleaner — Claude Code context

## What it is

An R package that flags errors in species occurrence records (GBIF and similar) at any scale,
from a data frame of a few thousand records to a whole GBIF snapshot of billions. It runs the
record tests of CoordinateCleaner (Zizka et al. 2019, doi:10.1111/2041-210X.13152) with the same
definitions and default buffers, computed as nearest-neighbour queries in C++ instead of
per-record polygon buffers, and streams records from disk so memory does not bound the input.

It grows past CoordinateCleaner by adding tests of its own (duplicate definitions, stated
coordinate uncertainty, record year, GBIF issue flags, habitat-aware sea test). Those are marked
as additions and never change what a CoordinateCleaner-equivalent test returns.

Version 0.2.0 is in preparation (0.1.0 was built 2026-10-09). `dev_notes/` holds the equivalence findings against
CoordinateCleaner, the reference-data comparison and the benchmark table; read them before
changing a test or a gazetteer.

## Principles

- **The engine always returns flags.** Every test writes one bit per record; the engine removes
  nothing and bakes in no threshold. A cleaning rule is a query over the flags, chosen
  afterwards. Removing records is an optional selection interface on top: `keep_unflagged()`
  after flagging, and the per-test cleaning functions `clean_<test>()`. Year and coordinate
  uncertainty stay raw columns and are cut at analysis time.
- **Equivalence is the trust argument.** Each CoordinateCleaner-equivalent test has a test in
  `tests/testthat/` that runs CoordinateCleaner itself on sampled records and requires identical
  flags (`skip_if_not_installed("CoordinateCleaner")`). A disagreement is a bug unless it is a
  documented, deliberate difference listed in the test file and in the help page of that test.
- **One front door for flagging.** One flagging verb, `flag_occurrences()`, whose input can be
  a data frame or an on-disk table (vectra node / Parquet directory); the return follows the
  input. It is the interface for running tests together, keeping their results and processing
  large tables. Tests are chosen by an argument, not by separate `flag_*()` functions. A second
  verb tallies flags into loss tables.
- **Cleaning functions come from the registry.** `clean_<test>()` exists for every test in
  `.flag_layout`, built by `clean_fun()` in `R/clean.R`: it runs `flag_occurrences()` on one test
  and drops what it flags, with the test's buffer or `.default_settings` options as arguments.
  No test logic in a cleaning function; a new test gets its cleaning function as one line in
  `R/clean.R`, documented on the test's help page (`test-clean.R` asserts one per test). Data
  frames only; a chain applies a grouped test to the records earlier steps kept.
- Never export CoordinateCleaner's `cc_*` names: that would mask its functions on attach.
- **Reference data is pinned and versioned.** Every gazetteer the package uses carries its
  source, version and retrieval date, and the flag output records which reference version
  produced it.

## Licence and dependencies

- **MIT.** CoordinateCleaner is GPL-3, so none of its code is copied into this package.
  **Locations are public information, free to use without restrictions** (fixed rule, 2026-10-13):
  coordinates of places from any source (CoordinateCleaner, Google, iNaturalist, OSM, imagery) may
  be checked, refined and shipped; no coordinate is excluded on licence or terms grounds. It is in **Suggests** only: used by the equivalence tests and by an
  explicit `reference = "CoordinateCleaner"` choice that reads its tables from the user's own
  installation at run time. It also pulls 66 packages recursively, which is the second reason it
  is not in Imports.
- **Own reference data** is built in `data-raw/` from the original public sources that
  CoordinateCleaner itself draws on: Natural Earth (public domain) for land, countries,
  admin-1 units, populated places/capitals and urban areas; the institution gazetteer from
  GBIF's GRSciColl bulk export, Wikidata, Wikipedia's lists of natural history museums, GeoNames
  and BGCI GardenSearch (terms per source in
  `dev_notes/reference_data.md`).
- **Imports**: `vectra (>= 0.13.0)` (CRAN, the user's own C11 columnar engine;
  `tbl_parquet()` and `collect_chunked()` for streaming, `write_vtr()` for the flag parts) and
  `Rcpp` (kd-tree, geodesic and point-in-polygon core). Check the recursive footprint before
  adding anything else.

## Institution gazetteer policy (Gilles, 2026-10-14)

His words:

- "we should have the default assumption to put high confidence in handplaced locations"
- "require proof for any additional cc point"
- "Cc automatic should ship unless we got proof to contrary. Think about this cc is an established software we need good reason to disagree or add stuff that's just software politics"
- "also think about our additional these should be marked unconfirmed and not shipped to ali as is"
- "Ali has nothing we're in the process of making 0.2.0 of the package"

In practice: every CoordinateCleaner institution point (hand-placed and automatic) ships as CoordinateCleaner has it, with a documented
override list for points proven wrong; an override is a deliberate difference with CoordinateCleaner's original coordinates kept. Our
additional points are `unconfirmed` until a check beyond their own source passes, and are not shipped as they are. Agreement between
CoordinateCleaner's point and ours is not confirmation (shared origin). Findings and counts: `dev_notes/institution_points_vs_cc.md`.
State of the work, what is done and what is open: `dev_notes/points.md` (start there).

## Prior implementation to port

The algorithm already ran over 2,460,201,588 GBIF records in the mountain-area-garcia project:

- `C:/GillesC/Documents/TaskGoblin/colabs/mountain-area-garcia/occurrences/clean/clean_tag.py`
  (Python, numpy + scipy cKDTree): one `uint16` per record, proximity tests as nearest-neighbour
  queries on the unit sphere (chord distance), gazetteers exported from CoordinateCleaner 3.0.1
  by `export_gazetteers.R` in the same folder, radii asserted from `gazetteers/cc_defaults.csv`.
- `verify_clean.py` (same folder) checks a tagged stream against its tally.
- `dev_notes/cleaning_rule_decision.md` in that repo is the worked example of choosing a rule
  over the flags (nine rules from `raw` to `strict`).

Differences to fix in the port, not to carry over: the sea test there used that project's
own land mask, not Natural Earth land; there is no duplicate test; it was never checked record
by record against CoordinateCleaner.

## Consumer

The ali-filters collaboration (Ali Omar, same working group): a data paper on what the
standard filters remove across taxonomic groups, record age and coordinate precision, run over
the GBIF snapshot of 2026-10-01 at `E:/research/raw/occurrences/gbif_snapshot/2026-10-01/`.
Project notes: `C:/GillesC/Documents/TaskGoblin/colabs/ali-filters/`. Version 0.2.0 is what
gets shared with Ali.

## Build and test

Windows R at `C:/Program Files/R/R-4.6.1/bin/Rscript.exe`. Write multi-line R to a `.run*.R`
file (ignored by git and the build) rather than `Rscript -e`.

```r
devtools::document()
devtools::test()
devtools::check(args = "--no-manual")
```

After any C++ change: `Rcpp::compileAttributes()` then `devtools::document()`. After a
header-only change, delete `src/*.o` and `src/*.so`/`*.dll` before building, or nothing
recompiles.

## Conventions

- Branch `main`, commit directly.
- Every edit to `README.Rmd`, a vignette, roxygen or `inst/CITATION` is followed by a rebuild before
  committing: `devtools::build_readme()` for the README, then `Rscript build_site.R` for `docs/`.
  Never plain pkgdown.
- Roxygen and Rd text ASCII only.
- CI workflows trigger on `push`, `pull_request` and `workflow_dispatch`; no `schedule:`.
- Docs follow the house docs skills (`docs-style` with `docs-readme` or `docs-articles`);
  `sidecars/` holds story, journey and information. Session handoff and the next docs tasks:
  `dev_notes/current.md` (local, git-ignored); decisions and lessons:
  `dev_notes/docs_overhaul.md`.
