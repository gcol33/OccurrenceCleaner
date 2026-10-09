# Contributing to OccurrenceCleaner

Thanks for taking the time. This page covers how to set up, test and
submit changes.

## Code of Conduct

By participating you agree to the [Code of
Conduct](https://gillescolling.com/OccurrenceCleaner/CODE_OF_CONDUCT.md).

## Installation for development

``` bash
git clone https://github.com/gcol33/OccurrenceCleaner.git
cd OccurrenceCleaner
```

``` r

install.packages(c("devtools", "roxygen2", "testthat", "Rcpp", "vectra", "knitr", "rmarkdown"))
# for the equivalence tests and the benchmark
install.packages(c("CoordinateCleaner", "geosphere", "rnaturalearth"))
devtools::load_all()
```

A C++ compiler is needed (Rtools on Windows). After editing anything
under `src/`, run
[`Rcpp::compileAttributes()`](https://rdrr.io/pkg/Rcpp/man/compileAttributes.html)
and
[`devtools::document()`](https://devtools.r-lib.org/reference/document.html).
After a header-only change, delete `src/*.o` and `src/*.dll` (or `.so`)
first, or nothing is recompiled.

## Testing

``` r

devtools::test()
devtools::check(args = "--no-manual")
```

Tests that need CoordinateCleaner, geosphere, rnaturalearth or network
access skip when those are not available. The GBIF snapshot test looks
for a Parquet directory in `OCC_GBIF_SNAPSHOT` and skips otherwise.

## Principles to keep

- **Flag, never drop.** A test writes one bit; it never removes a record
  or bakes in a threshold.
- **Equivalence is the trust argument.** A CoordinateCleaner-equivalent
  test must agree with that package record by record, or the
  disagreement is documented in `tests/testthat/test-equivalence.R`, in
  [`?flag_occurrences`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
  and in `dev_notes/equivalence.md`.
- **One front door.** New behaviour is an argument of
  [`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
  or
  [`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md),
  not a new verb. Never export CoordinateCleaner’s `cc_*` names.
- **Pinned reference data.** A new gazetteer comes with a `data-raw/`
  script that records source URL, version, retrieval date and SHA-256,
  and a row in
  [`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md).
- **A new test** adds a row to the layout in `R/flag_tests.R` (bumping
  `layout_version` if any existing bit changes), a branch in
  `flag_chunk()`, unit tests, and a line in the README table.

## Project organization

    R/            flag.R (front door and engine), stream.R (on-disk input), tally.R,
                  flag_tests.R (layout), columns.R, reference.R, shapefile.R
    src/          geodesic (Vincenty), kdtree (unit sphere), polygon_index (grid PIP), rcpp_api
    data-raw/     builds R/sysdata.rda from Natural Earth and GRSciColl
    tests/        unit, equivalence, streaming
    bench/        benchmark against CoordinateCleaner
    dev_notes/    equivalence findings, reference-data comparison, benchmark table

## Workflow

1.  Open an issue for anything beyond a small fix.
2.  Branch from `main`, commit with a clear message.
3.  [`devtools::test()`](https://devtools.r-lib.org/reference/test.html)
    and
    [`devtools::check()`](https://devtools.r-lib.org/reference/check.html)
    pass.
4.  Open a pull request describing what changed and why.

## Style

R: tidyverse style, roxygen2 with markdown, ASCII only in roxygen. C++:
C++11, no external libraries, implementations in `.cpp` files with
declaration-only headers. Tests: one `test_that()` per behaviour,
`expect_identical()` where the value is exact.

## Reporting bugs

Open an issue with a minimal reproducible example, the output of
[`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html), and, for a
flag you believe is wrong, the record’s coordinates and the
CoordinateCleaner result for the same record if you have it.

By contributing you agree that your contributions are licensed under the
MIT License.
