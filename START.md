# START — build list to OccurrenceCleaner 0.1.0

Start prompt for the next session: "Read CLAUDE.md and START.md in
`C:/GillesC/Documents/dev/OccurrenceCleaner` and work through START.md."

Delete this file in the commit that sets `Version: 0.1.0`, once every box below is ticked.

## Done

- [x] Skeleton (2026-10-09): DESCRIPTION (MIT, CoordinateCleaner in Suggests), LICENSE,
      package doc, testthat edition 3, NEWS, `.Rbuildignore`, `.gitignore`, git on `main`.

## Decide first (ask the user, these change the work)

- [ ] **Institution gazetteer.** CoordinateCleaner's `institutions` (11,601 rows) merges GRBio
      (5,832), Index Herbariorum (3,469), GBIF (958), BGCI (712), Wikipedia (627) and geonames
      (3). It ships under the package's GPL-3, and the upstream sources' redistribution terms
      differ. Options: rebuild from sources that allow it (GBIF GRSciColl, which absorbed GRBio;
      Index Herbariorum) and document the gap, or read CoordinateCleaner's table at run time
      only (no bundled copy). Check each source's terms and quote them before choosing.
- [ ] **Default reference.** Own Natural Earth-built gazetteers by default, with
      `reference = "CoordinateCleaner"` as the explicit exact-reproduction choice? Or the
      reverse? This decides what a bare call returns.
- [ ] **Duplicate definitions** to offer: exact coordinate and species, species and grid cell,
      species and cell and date. Which is the default?

## Reference data (`data-raw/`)

- [ ] Script per gazetteer from its original source, pinned version and retrieval date written
      into the output: Natural Earth land, admin-0, admin-1, populated places (capitals),
      urban areas; country and admin-1 centroids computed the way CoordinateCleaner's
      `countryref` defines them (read its documentation and compare against its table).
- [ ] Store compactly (`sysdata.rda` or `inst/extdata`), size checked against CRAN's package
      size expectations before committing large files.
- [ ] Compare each own gazetteer against CoordinateCleaner's equivalent table: row counts,
      matched points, distance between matched points. Record the comparison in `dev_notes/`.

## Engine

- [ ] C++ (Rcpp) nearest-neighbour index on the unit sphere: points as 3-D unit vectors,
      buffer as chord length, a small kd-tree written here (no external library). Port the
      predicates from `clean_tag.py`.
- [ ] Polygon tests (sea/land, country) as point-in-polygon against the pinned Natural Earth
      layers. A rasterised pre-pass is allowed only if cells touching a boundary go to the
      exact test inside the same code path.
- [ ] Record-field tests: missing/invalid coordinates, zero, equal lon/lat, GBIF HQ, GBIF issue
      flags, basis of record, establishment means.
- [ ] Flag word layout as a documented, versioned table (bit, test, definition, source).

## Front door

- [ ] One flagging verb: a data frame in returns a data frame with the flag word and one
      logical column per requested test; a vectra node or Parquet directory in writes flags to
      disk in chunks, resumable. Column names default to Darwin Core (`decimalLongitude`,
      `decimalLatitude`, `species`), overridable.
- [ ] A tally verb: flags to a loss table by any grouping columns (taxon, year bin, uncertainty
      bin), counting records removed by each test alone and by a given rule.

## Tests and evidence

- [ ] Equivalence suite against CoordinateCleaner, test by test, on sampled real records
      including edge cases (antimeridian, poles, points exactly at buffer distance).
- [ ] Benchmark against CoordinateCleaner at 1e5, 1e6, 1e7 records under `bench/`, results
      table in `dev_notes/`.
- [ ] Streaming test on a slice of the GBIF snapshot (a few Parquet parts), not the full
      288 GB.

## Release dressing

- [ ] README in the house skeleton, quickstart vignette, `inst/CITATION`, CONTRIBUTING,
      CODE_OF_CONDUCT, CI (R-CMD-check + test-coverage, no cron).
- [ ] `devtools::check()` clean.
- [ ] GitHub repo `gcol33/OccurrenceCleaner` and r-universe registry entry: confirm with the
      user before creating anything public.
- [ ] `Version: 0.1.0`, NEWS entry, delete this file, and mark it ready to share in
      `TaskGoblin/colabs/ali-filters/current.md`.
