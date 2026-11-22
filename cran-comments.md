## New submission

This is the first submission of OccurrenceCleaner.

## Test environments

* local Windows 11, R 4.6.1: R CMD check --as-cran
* win-builder: R-devel and R-release
* GitHub Actions: ubuntu-latest (R-devel, R-release), macos-latest, windows-latest (R-release)

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Package size

The tarball is about 6 MB, of which R/sysdata.rda is 4.4 MB (xz). It holds the
reference data the tests read offline: Natural Earth land polygons at 1:10, 1:50
and 1:110 million scale (the 1:10 million layer is the default for the sea
test), country and urban-area polygons, about 35,000 biodiversity-institution
points and a register of 318,000 genera with their marine or non-marine habitat.
Polygon coordinates are stored as successive differences, which reduced the
1:10 million layer from 2.3 MB to 1.5 MB. The sources and their licences are
listed in inst/COPYRIGHTS and returned by reference_info().

## Threads

Compiled code uses OpenMP when the user sets `n_threads`; the default is one
thread. When `_R_CHECK_LIMIT_CORES_` is set, at most two threads are used.
Examples, tests and vignettes write only to tempdir().
