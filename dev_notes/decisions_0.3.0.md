# Decisions for OccurrenceCleaner 0.3.0

2026-11-17. I keep the engine's output as flags on every input record. These decisions concern reference points, the default coastline, the duplicate key and the example exclusion rules. The full snapshot is GBIF's 2026-10-01 download, DOI [10.15468/dl.tup2g6](https://doi.org/10.15468/dl.tup2g6).

## Evidence and scope

`qa/decisions_0.3.0.R` reproduces the sensitivity measurements; its CSV outputs are in `results_0.3.0/`. It reads the existing `bench/results/snapshot_worky_own2/tally.rds` and `snapshot_worky_cc/tally.rds`, verifies their grouped totals against 3,762,210,648 records, and checks that the paper's `for_ali/by_kingdom_year_uncertainty.csv` has the same total. Those snapshot runs used land scale 110 and the reference data of their recorded package versions. They establish prevalence under those configurations. They do not measure the full-snapshot effect of this release.

The POC extraction contains 12,530,386 records. Its flagging script removed absence records before saving `flags.rds`, leaving 12,439,653 records across 25 species cards. I use that complete saved cohort, assert its size and card count, and preserve its order. Some cards group several species. The saved flags identify OccurrenceCleaner 0.1.0 and land scale 110. The sensitivity run uses installed OccurrenceCleaner 0.2.2 with explicit scales and duplicate options. `git diff v0.2.2 v0.2.4 -- R/flag.R R/group.R src` is empty. The rerun's 110-scale sea and exact-duplicate flags reproduce the saved counts; the sea flags are also asserted identical record by record. The original flags and POC files remain unchanged. Session information and the input MD5 are recorded beside the results.

The alternative coastline and duplicate counts are freshly computed. Rounding-rule marginals hold the POC's other saved flags fixed, which isolates the contribution of `issue_rounded`. All 25 named flag columns match the bit words on all 12,439,653 saved rows (`results_0.3.0/flag_layout.txt`), verifying the bit interpretation used for those marginals. Snapshot marginals for rounding or alternative duplicates cannot be reconstructed from per-test totals, because those totals do not retain the required joint distributions. I make no whole-snapshot extrapolation from the POC.

## 1. Institution points

I accept a named sub-unit on its parent's university, research or administrative grounds when the names establish that relationship and an independent mapped feature places the point on or within the existing 200 m confirmation distance of that site. The institution test still applies its 100 m point buffer. The confirmation distance establishes confidence in the reference point; it does not enlarge the occurrence buffer or turn the parent polygon into an exclusion area.

Each of the 22 pending pairs has a decision, explanation, feature identifier and source URL in `data-raw/institution_review_2026-11-17.csv`. `qa/apply_institution_review.R` applies these to the existing check and rejection lists using keys and full-precision cached coordinates. Two seed-bank/arboretum rows share one coordinate, so 21 accepted rows add 20 checks.

Of the 19 parent-site candidates, 18 are accepted. The university and research-institute pairs explicitly identify their parent, including the Chinese, Japanese, Hungarian and Norwegian names in OSM. The Coimbra science museum point is beside the same university's botanical garden, an institution site in its own right. Hampshire's museum service is beside its parent council building.

The build confirms 23 rows in total because two further entries share reviewed coordinates. Hatley Park National Historic Site shares the Royal Roads garden point; [Royal Roads University's campus description](https://www.royalroads.ca/campus/colwood-campus) identifies the campus within Hatley Park. The Mineralogical Museum and Zoological Museum of Babeș-Bolyai University shares the reviewed point of that university's paleontological museum and explicitly names the same parent. I accept both under the same site rule. `results_0.3.0/institution_changes.csv` records every changed row. A keyed comparison with v0.2.4 finds the same 34,575 rows, names and coordinates, with exactly these 23 status changes.

Booderee is accepted on specific administrative-site evidence: the point lies beside the named Booderee Visitor Centre, OSM node 1514056572. [Parks Australia](https://booderee.gov.au/things-do/visit/botanic-gardens/) documents the shared management of the gardens and national park. Membership in the park polygon alone would leave the garden unconfirmed.

Bongil Bongil is rejected. The [Australian National Botanic Gardens photograph record](https://cpbr.gov.au/photo/apii/id/dig/3143) locates John Wrigley's private Bongil Bongil garden at Korora Basin. The national park feature matched by OSM names a different place. The rejection is recorded explicitly and overrides any coordinate-level check.

All three generic names are accepted individually:

| Point | Independent feature evidence | Distance in the saved review |
|---|---|---:|
| Butterfly Farm, Ko Lanta | OSM node 4508525989 gives the English name Butterfly Farm, describes the botanical garden and identifies Q55424278. | 6 m |
| Green Farm, Sala Dan | OSM node 5747537496 identifies Q55424230 and gives Sala Dan, postcode 81150 and a telephone number. | 36 m |
| Rose Garden, Cornwall Park, Hastings | OSM node 14104212420 identifies Q134517161; the [council's park page](https://www.hastingsdc.govt.nz/hastings/reserves/cornwall-park/) independently names its formal rose garden. | 4 m |

The rebuilt reference contains 24,365 test points (14,592 confirmed additions and 9,773 CoordinateCleaner points) and 10,210 excluded unconfirmed points. The table has 5,671 confirmed extension points and 1,989 unconfirmed extension points.

The completed build's status counts are recorded in `results_0.3.0/institution_counts.csv`. Unconfirmed points are permanently excluded from the default test for this release. The review sequence covered Google Maps, OpenStreetMap, labelled imagery and the final nearby-feature review where applicable; these points have no accepted independent confirmation after that sequence. The table retains their provenance and status for inspection and explicit custom-gazetteer use. This is an exclusion of unverified reference points, with no assertion that every such institution is absent or every point is wrong.

## 2. GBIF rounding

I leave `issue_rounded` out of every recommended named exclusion rule, including `strict`. The engine still records it. The diagnostic `all` summary and an explicitly requested `clean_issue_rounded()` remain available.

[GBIF's issue documentation](https://techdocs.gbif.org/en/data-use/occurrence-issues-and-flags) defines `COORDINATE_ROUNDED` as rounding during interpretation to six decimal places. Its [processing documentation](https://techdocs.gbif.org/en/data-processing/) lists coordinate validity, range, zero coordinates and country mismatch as the geospatial suspicious-record checks. Rounding marks a processing operation. Spatial suitability still depends on the analysis resolution and the stated uncertainty.

CoordinateCleaner 3.0.1 has no equivalent of this GBIF issue flag. Zizka et al.'s [2019 paper](https://doi.org/10.1111/2041-210X.13152), Table 1 and the empirical example, assess dataset-level decimal periodicity and excess zero decimals through `cd_round()`, with case-specific interpretation. That is the package's `dataset_rounded` test. Ribeiro et al.'s [2022 bdc paper](https://doi.org/10.1111/2041-210X.13868) and the [bdc spatial workflow](https://brunobrr.github.io/bdc/articles/space.html) screen coarse coordinate precision; their example tests zero or one decimal place. Neither provides a basis for excluding a record merely because GBIF rounded it to six decimals.

Both snapshot references flag 559,053,689 records with `issue_rounded`, out of 3,762,210,648. The grouped table contains 173,051,635 such records among the 349,400,491 reporting uncertainty below 100 m. This includes records with fine stated precision. It is not evidence that rounding itself made them spatially unsuitable.

The POC has 2,712,764 rounding flags. Adding rounding to the saved `cc_gbif` rule alone would exclude another 2,241,138 records. Adding it to `strict` after all that rule's other tests would exclude another 911,244. These are measured marginal losses, not sums of overlapping per-test counts. The cost has no corresponding demonstrated error signal. Coordinate uncertainty remains an explicit analysis criterion.

The mountain-area-garcia project's `dev_notes/cleaning_rule_decision.md` makes the same distinction: its rules leave the processing-rounding flag out and evaluate uncertainty relative to their spatial grain. Its reported 11.28% applies to that older project's cohort, not this snapshot.

## 3. Coastline

I use Natural Earth 1:10 million by default with the own reference. This is a documented addition. `reference = "CoordinateCleaner"` selects 110 unless a scale is explicitly supplied. The shared configuration resolver applies this choice to data frames, streamed runs and cleaning functions, and records the resolved scale in provenance and resume configuration.

The installed CoordinateCleaner 3.0.1 functions specify scale 110 in `cc_sea()` and 50 in `clean_coordinates()`. Equivalence therefore means using the same chosen layer. Zizka et al. (2019, empirical example) used a custom one-degree buffered land gazetteer to avoid flagging coastal records. The [bdc workflow](https://brunobrr.github.io/bdc/articles/space.html) omits `seas` after a country/coast prefilter; its [country test](https://brunobrr.github.io/bdc/reference/bdc_coordinates_country_inconsistent.html) allows a coastal buffer. GBIF's processing documentation describes country-coordinate consistency and reverse geocoding; it does not specify the unbuffered Natural Earth 110-scale sea test as its standard. These approaches make the coastline and buffer part of the method.

| POC land scale | Sea flags out of 12,439,653 |
|---|---:|
| 110 | 574,465 |
| 50 | 499,948 |
| 10 | 329,317 |

Moving from 110 to 10 clears 444,347 flags and adds 199,199, for 245,148 fewer overall. A coarse coastline can cover adjacent water as well as omit land, so both directions matter. The snapshot sea count is 530,261,276 at scale 110 under either reference. It includes marine records and is not an error count for all organisms.

For kahili ginger, the saved POC cohort has 20,747 records. Sea flags are 12,086 at 110, 2,331 at 50 and 1,293 at 10. The exact current-file baseline is therefore 58.25%; the earlier 61.5% figure in the task is not the count in this saved cohort. In the Azores bounding box (-32 to -24 longitude, 36 to 40 latitude), all 7,065 ginger records fail at 110 and 297 fail at 10. In the Reunion box (55 to 56 longitude, -22 to -20 latitude), all 4,182 fail at 110 and 10 fail at 10. These box counts describe sensitivity around known omitted islands, without classifying every changed record as correct.

The finer layer addresses demonstrated missing-island errors while preserving the same point-in-polygon definition. It remains a generalised map; coastal uncertainty and organism habitat still require analysis choices. The existing pinned download and SHA-256 check supply the 10-scale layer on first use.

## 4. Duplicates

I retain exact species, longitude and latitude as the default key. Its purpose is to flag repeated species locations for spatial analyses. Temporal revisits can be valid observations and still share that location. Excluding them is a rule choice. `duplicate_by = "eventDate"` (using the input column's actual name) and `duplicate_cell` remain explicit options; `clean_duplicate()` exposes them as `by` and `cell`.

I inspected the installed CoordinateCleaner 3.0.1 `cc_dupl()`: it compares species and exact coordinates, with optional `additions`. Zizka et al. (2019, Table 1) and Ribeiro et al. (2022, section 2.5) describe the same spatial key. [GBIF occurrence clustering](https://techdocs.gbif.org/en/data-processing/clustering-occurrences) uses dates, identifiers, taxonomic and spatial assertions to find relationships across datasets, retaining the linked records. That is a broader record-identity task; its grouping is not a prescription to thin all occurrences to a cell or date.

| POC duplicate key | Flagged records |
|---|---:|
| Exact species and coordinates | 7,573,378 |
| Exact species, coordinates and year | 6,519,135 |
| Species and 0.01-degree cell | 10,357,387 |
| Species and 1/120-degree cell | 10,223,234 |

The cell sizes are sensitivity settings, not recommended universal resolutions: 0.01 degrees is the documented duplicate example, and 1/120 degrees corresponds to the mountain-area project's angular lattice. Cell widths in metres vary with latitude.

The exact definition flags 2,664,032,245 of the 3,762,210,648 snapshot records. In the POC, adding year preserves 1,054,243 records that the exact spatial key flags. The year-aware key still flags 151,883 records with missing year; the input contains 501,987 missing years. A date option needs an explicit missing-date policy for any analysis that uses it.

The POC extraction script selects `year` and omits `eventDate`, as do the available genus-extract scripts. Consequently an event-date duplicate total is not observable from these saved records. I asked about an existing dated extract and made no new whole-snapshot scan. The unconditional bound is zero to 7,573,378 event-date duplicates because adding a key field can only split groups. The measured year comparison establishes sensitivity to temporal grouping; it is not presented as an event-date estimate. If year is consistently derived from eventDate, the year count supplies a tighter upper bound, an assumption not verified for this extract.

The evidence supports keeping the established spatial default: adding dates changes the temporal unit of analysis, and cell-based thinning imposes an analysis resolution. Neither demonstrates that the exact-location definition is wrong for its stated purpose. All options flag records and preserve the input for later selection.

## Release validation

Natural Earth's 1:10 million land data include a feature named `Null island` at (0, 0). I checked its attributes and polygon membership with `sf` and reproduced the land verdict with CoordinateCleaner 3.0.1 `cc_sea(scale = 10)`. OccurrenceCleaner preserves that layer and the separate `zero` test flags the origin. The polygon fixture now asserts the detailed layer's verdict, with a separate test of the combined `sea` and `zero` behavior. [Natural Earth's build recipe](https://github.com/nvkelso/natural-earth-vector/blob/master/Makefile) explicitly includes this feature class.

Validation on R 4.6.1 for Windows:

- `data-raw/institutions.R` and `data-raw/sysdata.R` complete; `qa/audit_institution_changes.R` compares the bundled table with v0.2.4 and finds only status and evidence changes.
- `qa/verify_institution_review.R` checks every accepted and rejected review row against the installed package and verifies the institution flags at every accepted point.
- `qa/check_overpass_cache.R` passes complete-coverage, incomplete-coverage and parent-file checks. The reference build reuses 93 cached museum tiles.
- `devtools::document()`, package installation and `devtools::check(args = "--no-manual")` complete with 0 errors, 0 warnings and 0 notes. The installed-package suite reports 639 passing assertions, 0 failures, 0 warnings and 0 skips, including CoordinateCleaner equivalence and worker-process tests. `results_0.3.0/00check.log`, `testthat.Rout` and `validation_session.txt` retain the output and environment.
- `devtools::build_readme()` and `build_site.R` rebuild the documentation. Headless Edge screenshots verify the changed pages at desktop and mobile widths, in light and dark themes, plus all nine figures in the reference-data, rules and GBIF-workflow articles.

The package archive excludes local hidden logs, and the unused tracked Overpass timeout response `t.json` is removed. The final check uses a standard temporary directory. The tag is local; publication and a new snapshot run remain for review.
