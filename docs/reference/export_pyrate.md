# Export fossil records as PyRate input

Writes fossil occurrences in the input format of PyRate (Silvestro et
al. 2014), the Bayesian estimator of speciation and extinction rates
from fossil occurrences: a Python file holding, per replicate, one array
of occurrence ages per taxon, and a tab-separated list of the taxa with
their status. An extant taxon gets an extra age of 0. Each record's age
is drawn uniformly from its range (`random = TRUE`) or set to the
range's midpoint; a minimum age of 0 is set to 0.001.

## Usage

``` r
export_pyrate(
  x,
  file,
  status,
  columns = occ_columns(),
  trait = NULL,
  replicates = 1,
  random = TRUE,
  seed = NULL
)
```

## Arguments

- x:

  A data frame of fossil records, for example the kept records of a
  flagged table.

- file:

  Path prefix of the output: `<file>_PyRate.py` and
  `<file>_TaxonList.txt` are written.

- status:

  `"extinct"` or `"extant"`: one value for all records, one per record,
  or the name of a column of `x` holding them. A taxon must have a
  single status.

- columns:

  Field names, see
  [`occ_columns()`](https://gillescolling.com/OccurrenceCleaner/reference/occ_columns.md);
  the taxon is read from `species` and the ages from `min_age` and
  `max_age`.

- trait:

  Optional numeric trait, one value per record or the name of a column;
  the taxon mean is written as a continuous trait.

- replicates:

  Number of age replicates (data sets) in the file.

- random:

  Draw ages from the ranges (`TRUE`) or use the midpoints. Replicates of
  midpoint ages are identical.

- seed:

  Seed for the age draws; the caller's random-number stream is left
  unchanged. `NULL` draws from the current stream.

## Value

The paths of the two files, invisibly.

## Details

The records are exported as given, so the cleaning rule is applied
first: `x[!has_flag(x$flags, rule), ]`.

## References

Silvestro, D., Schnitzler, J., Liow, L. H., Antonelli, A. and Salamin,
N. (2014). Bayesian estimation of speciation and extinction from
incomplete fossil occurrence data. Systematic Biology 63:349-367.
[doi:10.1093/sysbio/syu006](https://doi.org/10.1093/sysbio/syu006)

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[test_age_equal](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md)

## Examples

``` r
x <- data.frame(accepted_name = c("Equus caballus", "Equus caballus", "Hipparion sp"),
                min_ma = c(0.5, 1.2, 5), max_ma = c(1, 2.6, 11))
paths <- export_pyrate(x, file.path(tempdir(), "horses"), status = c("extant", "extant", "extinct"),
                       columns = occ_columns(species = "accepted_name"), random = FALSE)
cat(readLines(paths[1]), sep = "\n")
```
