# Genus habitats of the habitat tests

Returns the genera the habitat tests `sea_nonmarine` and `land_marine`
know, built from the Interim Register of Marine and Nonmarine Genera
(IRMNG; Rees, T. (compiler) (2026). The Interim Register of Marine and
Nonmarine Genera. Available from https://www.irmng.org at VLIZ; CC BY
4.0), Darwin Core archive of 2026-10-06. A name that is not accepted
takes the habitat flags of its accepted name. A genus is

- not marine (`marine = FALSE`) when IRMNG sets `isMarine` to 0 and does
  not set `isBrackish` to 1;

- only marine (`marine = TRUE`) when IRMNG sets `isMarine` to 1 and both
  `isTerrestrial` and `isFreshwater` to 0, and the genus is not extinct
  (fossils of extinct marine genera lie on land).

## Usage

``` r
reference_habitat()
```

## Value

A data frame with columns `kingdom`, `genus` and `marine`.

## Details

Genera with missing flags or with both habitats are not listed, and
records of them are not tested. Several genera share a name across
kingdoms; when they disagree the name is resolved only through the
record's kingdom.

The table can be filtered or extended and passed back with
`gazetteers = list(habitat = <data frame>)` in
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

## Examples

``` r
h <- reference_habitat()
table(h$kingdom, h$marine)
h[h$genus %in% c("Quercus", "Asterias", "Gadus"), ]
```
