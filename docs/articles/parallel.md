# Running on several threads

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
can use several CPU threads to speed up its most time-consuming steps.
Set `n_threads` to choose how many threads work in parallel within the
same R process. The package uses OpenMP to manage them.

This article explains which tests use multiple threads, how to choose
the thread count, and why changing it leaves the flags unchanged. It
also reports timings from one machine and explains how to enable OpenMP
when building the package. For installation instructions, see [Get
started](https://gillescolling.com/OccurrenceCleaner/articles/OccurrenceCleaner.md).

1.  **Set** the number of threads with `n_threads`.

2.  **Check** that the flags are the same for any number.

3.  **Read** the measured speedup of each kind of test.

4.  **Enable** OpenMP where the compiler does not include it.

## Setting the number of threads

`n_threads = 1` is the default and runs everything on one thread. A
larger number requests that many threads, and `0` uses every thread
OpenMP offers on the machine. The records below are simulated: 20,000
points in the Alps, spread over 40 species.

``` r

library(OccurrenceCleaner)
set.seed(7)
n <- 20000
x <- data.frame(species = sample(sprintf("sp%02d", 1:40), n, TRUE),
                decimalLongitude = runif(n, 6, 16),
                decimalLatitude = runif(n, 45.5, 48))
tests <- c("capital", "centroid", "sea", "outlier")
f1 <- flag_occurrences(x, tests = tests, n_threads = 1, verbose = FALSE)
f4 <- flag_occurrences(x, tests = tests, n_threads = 4, verbose = FALSE)
```

A request above the number of threads OpenMP offers is reduced to that
number, and a message says so. `OccurrenceCleaner:::cpp_max_threads()`
returns the limit of the current build.

## Tests that use the threads

Two kinds of work are spread over threads:

- The outlier test computes the distances between the records of one
  species. Each species is one unit of work, and a species with many
  records is split by rows over several threads.

- The record tests that query reference data run per record: the
  proximity tests (`capital`, `centroid`, `institution`,
  `gbif_headquarters` and `aohi`) and the point-in-polygon tests (`sea`,
  `urban`, the habitat tests and `range`).

Reading the input, the other tests and the bookkeeping of the group
stage run on one thread. On a table on disk each chunk of records is
processed with the same number of threads (see [Large tables on
disk](https://gillescolling.com/OccurrenceCleaner/articles/on-disk.md)).

## Identical flags

Each species and each record is computed on one thread, and the
distances of a species are added in the order of its records. The result
does not depend on the number of threads or on how the work is divided
between them.

``` r

identical(f4$flags, f1$flags)
#> [1] TRUE
```

## Speedup

The timings below come from `data-raw/threads.R`, which times
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
on simulated records with 1, 2, 4, 8, and 16 threads and keeps the
median of three runs. It ran on an Intel(R) Core(TM) i9-14900K under R
4.6.1, with the other tests switched off.

| Tests | Records | 1 thread(s), s | 2 thread(s), s | 4 thread(s), s | 8 thread(s), s | 16 thread(s), s |
|:---|---:|---:|---:|---:|---:|---:|
| Proximity and polygon tests | 5,000,000 | 3.64 | 1.94 | 1.10 | 0.69 | 0.52 |
| Outlier test | 1,000,000 | 54.41 | 43.09 | 26.39 | 13.75 | 8.95 |

Proximity and polygon tests run 7 times faster with 16 threads than with
one, and the outlier test 6.1 times faster. The machine has 8
performance cores and 16 efficiency cores, 32 logical processors in all,
so the gain per added thread falls beyond 8 threads.

![Speedup against one thread for two sets of tests, plotted against the
number of threads, with the line of ideal
speedup.](parallel_files/figure-html/timings-plot-1.svg)

The measurement covers one machine and one record mix. A table with few
species, or one species holding most records, gives the outlier test
fewer units of work to spread.

## Enabling OpenMP

OpenMP comes with the compiler. Rtools on Windows and the default
compiler on Linux include it, and the package uses it from the first
installation. Apple’s compiler on macOS does not. There, install the
runtime with `brew install libomp` and add these lines to
`~/.R/Makevars` before installing the package:

    CPPFLAGS += -I/opt/homebrew/opt/libomp/include -Xclang -fopenmp
    LDFLAGS += -L/opt/homebrew/opt/libomp/lib -lomp

On Intel Macs the Homebrew prefix is `/usr/local/opt/libomp`. A build
without OpenMP installs and runs every test on one thread, so
`n_threads` has no effect. `OccurrenceCleaner:::cpp_max_threads()`
returns `1` for such a build and the number of available threads
otherwise.
