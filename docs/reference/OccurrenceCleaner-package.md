# OccurrenceCleaner: fast quality flags for species occurrence records

An extension of
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)
(Zizka et al. 2019) tailored to large-scale occurrence data: it runs
that package's record tests with the same definitions and default
buffers, up to the differences listed in
[`vignette("coordinatecleaner", package = "OccurrenceCleaner")`](https://gillescolling.com/OccurrenceCleaner/articles/coordinatecleaner.md),
and keeps every record. Each test writes one flag per record, so a
cleaning rule is chosen afterwards as a query over the flags. See
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
to flag a data frame or an on-disk table,
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)
for the bit each test sets, and
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
to count what each test and rule removes.

## Details

CoordinateCleaner by Alexander Zizka and co-authors supplies the record
tests and what each one looks for, their default buffers, the outlier
statistics and the raster approximation for species with many records,
the dataset tests, the fossil tests, the choice of reference sources
behind the gazetteers and the `spatialvalid` output layout; please cite
Zizka et al. (2019) together with this package
(`citation("OccurrenceCleaner")` gives both).

## References

Zizka A, Silvestro D, Andermann T, et al. (2019) CoordinateCleaner:
standardized cleaning of occurrence records from biological collection
databases. Methods in Ecology and Evolution 10:744-751.
[doi:10.1111/2041-210X.13152](https://doi.org/10.1111/2041-210X.13152)

## See also

Useful links:

- <https://gillescolling.com/OccurrenceCleaner/>

- <https://github.com/gcol33/OccurrenceCleaner>

- Report bugs at <https://github.com/gcol33/OccurrenceCleaner/issues>

## Author

**Maintainer**: Gilles Colling <gilles.colling051@gmail.com>
([ORCID](https://orcid.org/0000-0003-3070-6066)) \[copyright holder\]

Authors:

- Gilles Colling <gilles.colling051@gmail.com>
  ([ORCID](https://orcid.org/0000-0003-3070-6066)) \[copyright holder\]
