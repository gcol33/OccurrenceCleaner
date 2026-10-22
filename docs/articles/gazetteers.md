# Custom reference points and polygons

A gazetteer is a table of reference locations: the points or polygons a
test compares each record with. The tests use three kinds:

- Points marking capitals, centroids, institutions, the GBIF
  headquarters and artificial hotspots.

- Polygons outlining land, urban areas, countries and species ranges.

- A table of genus habitats, used together with land polygons by the two
  habitat tests.

The package includes all of these except species ranges, which you
supply.

To change the reference data for all tests at once, set
`reference = "CoordinateCleaner"`. The tests then read the corresponding
tables from your
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)
installation.

To change it for a single test, pass your own layer in the `gazetteers`
argument of
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.html).
This argument does the job of the `ref` arguments in CoordinateCleaner’s
test functions.

This article shows how to filter, extend or replace the layer of a test
and how a custom layer is recorded with the flags. Installation is
covered in [Get
started](https://gillescolling.com/OccurrenceCleaner/articles/OccurrenceCleaner.md).
The polygon examples also need [sf](https://r-spatial.github.io/sf/).

## A filtered point layer

A point layer is any data frame with longitude and latitude columns
(`lon`/`lat`, `longitude`/`latitude` or
`decimalLongitude`/`decimalLatitude`, in any case). The simplest custom
layer is a subset of a shipped one.
[`reference_points()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_points.md)
returns the points of a proximity test with their attributes; for the
institutions, `type` gives the kind of institution and `source` the
registry each point comes from:

``` r

library(OccurrenceCleaner)

inst <- reference_points("institution")
head(inst[, c("name", "type", "source", "lon", "lat")], 3)
#>                                  name      type            source      lon
#> 1         Andorra Recerca + Innovació      <NA>     GBIF registry  1.49218
#> 2       Andorra Research + Innovation Herbarium         GRSciColl  1.49210
#> 3 CENMA, Institut d Estudis Andorrans Herbarium CoordinateCleaner 51.39320
#>        lat
#> 1 42.46876
#> 2 42.46650
#> 3 35.79940
head(sort(table(inst$type), decreasing = TRUE))
#> 
#>                                 Herbarium 
#>                                      8272 
#>                           BotanicalGarden 
#>                                      7810 
#>                                    Museum 
#>                                      4879 
#>                         UniversityCollege 
#>                                      3007 
#>                               ZooAquarium 
#>                                      2861 
#> OtherTypeResearchInstitutionBiorepository 
#>                                       507
```

The institution test uses the points whose `status` is not
`"unconfirmed"`; [Reference
data](https://gillescolling.com/OccurrenceCleaner/articles/reference-data.html#institutions)
explains the status. A plant study, for example, may want to flag
records at herbaria only, since a specimen georeferenced to a zoological
museum is unlikely in a plant table, and use a wider buffer for them:

``` r

used <- inst[inst$status != "unconfirmed", ]
herbaria <- used[used$type %in% "Herbarium", ]
nrow(herbaria)
#> [1] 4206
near <- rbind(herbaria[1:3, ], used[used$type %in% "Museum", ][1:3, ])
x <- data.frame(species = "Quercus robur", decimalLongitude = near$lon + 0.005,
                decimalLatitude = near$lat)
f_all <- flag_occurrences(x, tests = "institution", buffers = list(institution = 1000))
f_herb <- flag_occurrences(x, tests = "institution", buffers = list(institution = 1000),
                           gazetteers = list(institution = herbaria))
data.frame(near = near$name, type = near$type, all = f_all$flag_institution,
           herbaria_only = f_herb$flag_institution)
#>                                                                                            near
#> 1                                                           CENMA, Institut d Estudis Andorrans
#> 2 United Arab Emirates University, Islamic Institute, Faculty of Science, Department of Biology
#> 3                                      Kabul University, Faculty of Science, Biology Department
#> 4                                                             Museum of Natural History, Tirane
#> 5                                                                        Natural Science Museum
#> 6                                                  Bernardino Rivadavia Natural Sciences Museum
#>        type  all herbaria_only
#> 1 Herbarium TRUE          TRUE
#> 2 Herbarium TRUE          TRUE
#> 3 Herbarium TRUE          TRUE
#> 4    Museum TRUE         FALSE
#> 5    Museum TRUE         FALSE
#> 6    Museum TRUE          TRUE
```

Each record lies about 0.005 degrees (a few hundred metres) east of an
institution: three herbaria, then three museums. The full table flags
all six at a 1 km buffer. The herbarium table flags 4: the three records
next to the herbaria, and the record next to the Bernardino Rivadavia
museum in Buenos Aires, whose herbarium is listed as its own point about
450 m away.

The same works with the `extension` column. It is `TRUE` for points from
sources CoordinateCleaner does not use; the rows with `extension`
`FALSE` restrict a test to CoordinateCleaner’s sources, as [Reference
data](https://gillescolling.com/OccurrenceCleaner/articles/reference-data.html#extension-points)
shows for the capitals. That article also lists the sources of every
layer
([Institutions](https://gillescolling.com/OccurrenceCleaner/articles/reference-data.html#institutions)
for the `source` and `master_source` columns of the institution table).

## An extended point layer

The two capital tables differ: the shipped table has the Factbook
capitals unrounded and adds Natural Earth’s alternative and official
capitals, while
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)’s has
one point per country, rounded to 0.01 degrees. Their union flags
records near either:

``` r

caps <- reference_points("capital")
both <- rbind(caps[, c("lon", "lat")], reference_points("capital", reference = "CoordinateCleaner"))
nrow(both)
#> [1] 700
y <- data.frame(city = c("Cape Town", "Naypyidaw", "Vienna"), decimalLongitude = c(18.42, 96.13, 16.37),
                decimalLatitude = c(-33.92, 19.75, 48.21))
data.frame(city = y$city,
           CoordinateCleaner = flag_occurrences(y, tests = "capital", reference = "CoordinateCleaner")$flag_capital,
           union = flag_occurrences(y, tests = "capital", gazetteers = list(capital = both))$flag_capital)
#>        city CoordinateCleaner union
#> 1 Cape Town             FALSE  TRUE
#> 2 Naypyidaw             FALSE  TRUE
#> 3    Vienna              TRUE  TRUE
```

Other point sets fit the same way: regional capitals for a study in
which collections were georeferenced to provincial seats, the field
stations of a survey, or the coordinates a particular data provider uses
as a default.

The institution table is one of them. The test uses CoordinateCleaner’s
institutions, some moved to the place Google Maps gives for the
institution, and the points of other sources that a check has confirmed.
The table also contains points that no check has confirmed, which the
test leaves out:

``` r

table(inst$status)
#> 
#>          cc   confirmed    override unconfirmed 
#>        9206        2765         567       22154
```

`gazetteers = list(institution = inst)` flags records near any point of
the table, the unconfirmed ones included.

The Artificial Hotspot Occurrence Inventory (Park et al. 2023) behind
the `aohi` test marks each point as a real observation site
(`determination = TRUE`, for example a birding reserve) or an artificial
aggregate of records (`FALSE`, for example a georeferencing default). A
study that keeps records from popular sites can flag only the
aggregates:

``` r

ah <- reference_points("aohi")
table(ah$taxon, ah$determination)
#>           
#>            FALSE TRUE
#>   Aves        10   41
#>   Insecta     36   15
#>   Mammalia    33   19
#>   Plantae    152    2
artificial <- ah[!ah$determination, ]
v <- data.frame(decimalLongitude = ah$lon[1:4] + 0.02, decimalLatitude = ah$lat[1:4])
data.frame(point = ah$notes[1:4], site = ah$determination[1:4],
           all = flag_occurrences(v, tests = "aohi")$flag_aohi,
           aggregates = flag_occurrences(v, tests = "aohi", gazetteers = list(aohi = artificial))$flag_aohi)
#>                           point site  all aggregates
#> 1                  birding site TRUE TRUE      FALSE
#> 2 birding site/center of island TRUE TRUE      FALSE
#> 3                  birding site TRUE TRUE      FALSE
#> 4   birding site/center of park TRUE TRUE      FALSE
```

The four records lie about 2 km from the first four bird hotspots, all
of them birding sites, so the full inventory flags them and the
aggregates-only table does not.

## Polygon layers

Polygon layers are `sf` or `sfc` objects of POLYGON or MULTIPOLYGON
geometries in longitude and latitude (EPSG:4326). For `sea`, the
polygons are the land: a record outside every polygon is flagged. That
makes `sea` with a custom layer a test for “outside the study area”:

``` r

area <- sf::st_sfc(sf::st_polygon(list(rbind(c(9.5, 46.4), c(17.2, 46.4), c(17.2, 49.0),
                                             c(9.5, 49.0), c(9.5, 46.4)))), crs = 4326)
z <- data.frame(decimalLongitude = c(16.37, 11.40, 8.54, 19.04), decimalLatitude = c(48.21, 47.26, 47.37, 47.50))
flag_occurrences(z, tests = "sea", gazetteers = list(sea = area))$flag_sea
#> [1] FALSE FALSE  TRUE  TRUE
```

The first two points (Vienna and Innsbruck) lie inside the box; the last
two (Zurich and Budapest) lie outside. For `urban`, polygons likewise
define the areas to flag, such as a city’s built-up area mapped in finer
detail than Natural Earth provides.

For `country_mismatch`, polygons also carry country or territory codes
in columns named `iso_a2`, `iso_a3`, `adm0_a3` or `code`
(case-insensitive). Each record’s code is checked against all available
code columns. The following example uses two territories with their own
codes:

``` r

terr <- sf::st_sf(
  code = c("XA", "XB"),
  geometry = sf::st_sfc(sf::st_polygon(list(rbind(c(0, 0), c(10, 0), c(10, 10), c(0, 10), c(0, 0)))),
                        sf::st_polygon(list(rbind(c(10, 0), c(20, 0), c(20, 10), c(10, 10), c(10, 0)))),
                        crs = 4326))
w <- data.frame(decimalLongitude = c(5, 15, 15, 25), decimalLatitude = 5, countryCode = c("XA", "XB", "XA", "XA"))
flag_occurrences(w, tests = "country_mismatch", gazetteers = list(country_mismatch = terr))$flag_country_mismatch
#> [1] FALSE FALSE  TRUE  TRUE
```

The third record is in territory XB with code XA, the fourth outside
both territories, so both are flagged.

## Species ranges

The `range` test flags records outside the range polygons of their
species, such as IUCN range maps. The layer is an `sf` object with one
or more polygons per species and a species column, named like the
record’s species column or `species`, `binomial` or `sci_name`. Each
species gets an index of its own polygons, so overlapping ranges of
different species do not interfere; species without a polygon are not
tested:

``` r

ranges <- sf::st_sf(
  species = c("Bufo bufo", "Bufo bufo", "Lacerta viridis"),
  geometry = sf::st_sfc(sf::st_polygon(list(rbind(c(-10, 36), c(30, 36), c(30, 60), c(-10, 60), c(-10, 36)))),
                        sf::st_polygon(list(rbind(c(30, 40), c(60, 40), c(60, 60), c(30, 60), c(30, 40)))),
                        sf::st_polygon(list(rbind(c(5, 40), c(30, 40), c(30, 52), c(5, 52), c(5, 40)))),
                        crs = 4326))
r <- data.frame(species = c("Bufo bufo", "Bufo bufo", "Bufo bufo", "Lacerta viridis", "Lacerta viridis",
                            "Lacerta viridis", "Rana arvalis"),
                decimalLongitude = c(10, 45, -20, 15, 15, 15, 100),
                decimalLatitude = c(50, 50, 50, 45, 52.5, 55, 10))
data.frame(r, outside = flag_occurrences(r, tests = "range", gazetteers = list(range = ranges))$flag_range,
           outside_100km = flag_occurrences(r, tests = "range", gazetteers = list(range = ranges),
                                            buffers = list(range = 100000))$flag_range)
#>           species decimalLongitude decimalLatitude outside outside_100km
#> 1       Bufo bufo               10            50.0   FALSE         FALSE
#> 2       Bufo bufo               45            50.0   FALSE         FALSE
#> 3       Bufo bufo              -20            50.0    TRUE          TRUE
#> 4 Lacerta viridis               15            45.0   FALSE         FALSE
#> 5 Lacerta viridis               15            52.5    TRUE         FALSE
#> 6 Lacerta viridis               15            55.0    TRUE          TRUE
#> 7    Rana arvalis              100            10.0   FALSE         FALSE
```

The toad at 45 E lies in the second of its two polygons and is kept; the
one at 20 W lies in the Atlantic, outside both. The lizard at 52.5 N
lies half a degree, about 55 km, north of its range: it is flagged
without a buffer and kept with the 100 km buffer. The lizard at 55 N is
3 degrees north and stays flagged under both. *Rana arvalis* has no
polygon and is not tested.

## A genus habitat table

The habitat tests `sea_nonmarine` and `land_marine` use
[`reference_habitat()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_habitat.md)
to look up each record’s genus in the Interim Register of Marine and
Nonmarine Genera. You can supply your own table with columns `genus`,
`marine` (`TRUE` for exclusively marine genera, `FALSE` for nonmarine
genera) and optionally `kingdom`. For example, you can classify a genus
whose habitat the register leaves unspecified:

``` r

h <- reference_habitat()
h[h$genus %in% c("Larus", "Zostera"), ]
#> [1] kingdom genus   marine 
#> <0 rows> (or 0-length row.names)
mine <- rbind(h, data.frame(kingdom = "Plantae", genus = "Zostera", marine = TRUE))
x <- data.frame(kingdom = "Plantae", genus = "Zostera", decimalLongitude = 16.37, decimalLatitude = 48.21)
flag_occurrences(x, tests = "land_marine")$flag_land_marine
#> [1] FALSE
flag_occurrences(x, tests = "land_marine", gazetteers = list(habitat = mine))$flag_land_marine
#> [1] TRUE
```

The register marks seagrass (*Zostera*) as marine but leaves its
freshwater and terrestrial flags empty, so the shipped table does not
class it and its records are not tested; classed as only marine, a
record of it in Vienna is flagged.

## Recording the layer

A custom layer is indexed once per call, and its size and an MD5
checksum of its coordinates are written into the reference label of the
output:

``` r

f <- flag_occurrences(x, tests = "institution", gazetteers = list(institution = herbaria))
attr(f, "occ_reference")
#> [1] "OccurrenceCleaner 0.2.0 (land 110; land_110 4.1.0, land_50 4.1.0, land_10 5.1.1, countries_50 5.1.1, urban_50 4.1.0, places_10 5.1.2, admin0_10 5.1.1, admin1_10 5.1.1, factbook factbook.json 144d6977b2b01ac1cbd220de754c0a005616760b, world_borders 0.3 (2008-07-30), geolocate 2026-10-11, institutions 2026-10-09, institutions_wikidata 2026-10-10, institutions_wikipedia en revision 1376233148; de revision 267938927; fr revision 240149609; nl revision 69876533; pt revision 71307420; ar revision 76691072; eo revision 9165115, institutions_geonames 2026-10-10, institutions_bgci 2026-10-10, institutions_index_herbariorum 2026-10-13, institutions_gbif_registry 2026-10-13, institutions_coordinatecleaner_list 3.0.1, institutions_openstreetmap 2026-10-13, institutions_status 2026-10-17, aohi 2022-10-10, habitat 2026-10-06); custom: institution 4206 points md5 789446bf66a5e600fd0ddbd0c1cd8165"
```

The checksum identifies the exact table, so two analyses that report the
same label used the same points. For streamed input the label is stored
in the output directory, and a rerun into that directory with a
different custom layer stops with an error instead of mixing flags from
two layers.

## Comparison with CoordinateCleaner

| CoordinateCleaner | OccurrenceCleaner |
|:---|:---|
| cc_cap(ref = …) | gazetteers = list(capital = points) |
| cc_cen(ref = …) | gazetteers = list(centroid = points) |
| cc_inst(ref = …) | gazetteers = list(institution = points) |
| cc_sea(ref = …) | gazetteers = list(sea = polygons) |
| cc_urb(ref = …) | gazetteers = list(urban = polygons) |
| cc_coun(ref = …, ref_col = …) | gazetteers = list(country_mismatch = polygons) |
| cc_iucn(range = …) | gazetteers = list(range = polygons) |
| cc_aohi(taxa = …) | gazetteers = list(aohi = subset of reference_points(“aohi”)) |
| (none) | gazetteers = list(habitat = genera) |

OccurrenceCleaner recognises common longitude and latitude column names
and matches records against every country-code column present.
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)
requires specific coordinate names, such as `capital.lon`,
`centroid.lon` or `decimalLongitude`, and its
[`cc_coun()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_coun.html)
uses one code column selected with `ref_col`.

With the same reference points and polygons, both packages produce the
same flags except near buffer boundaries, as described in [Compatibility
with
CoordinateCleaner](https://gillescolling.com/OccurrenceCleaner/articles/coordinatecleaner.md).
Package tests check this agreement for `institution`, `sea` and `range`.
