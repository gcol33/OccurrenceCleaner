# OccurrenceCleaner: fast quality flags for species occurrence records

Flags common errors in species occurrence records and keeps every
record. Each test writes one flag per record, so a cleaning rule is
chosen afterwards as a query over the flags. The tests and their default
buffers follow CoordinateCleaner (Zizka et al. 2019); see
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md)
for the flag layout,
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
to flag a data frame or an on-disk table and
[`tally_flags()`](https://gillescolling.com/OccurrenceCleaner/reference/tally_flags.md)
to summarise what each test removes.

## References

Zizka A, Silvestro D, Andermann T, et al. (2019) CoordinateCleaner:
standardized cleaning of occurrence records from biological collection
databases. Methods in Ecology and Evolution 10:744-751.
[doi:10.1111/2041-210X.13152](https://doi.org/10.1111/2041-210X.13152)

## See also

Useful links:

- <https://github.com/gcol33/OccurrenceCleaner>

- Report bugs at <https://github.com/gcol33/OccurrenceCleaner/issues>

## Author

**Maintainer**: Gilles Colling <gilles.colling051@gmail.com>
([ORCID](https://orcid.org/0000-0003-3070-6066)) \[copyright holder\]

Authors:

- Gilles Colling <gilles.colling051@gmail.com>
  ([ORCID](https://orcid.org/0000-0003-3070-6066)) \[copyright holder\]
