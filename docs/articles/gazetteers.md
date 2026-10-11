# Using custom gazetteers

Nine tests compare records with reference data: five with points
(capitals, centroids, institutions, the GBIF headquarters, artificial
hotspots) and four with polygons (land, urban areas, countries, species
ranges); the two habitat tests read the land together with a table of
genus habitats. The package ships its own pinned layers for all but the
species ranges, which only a user can supply, and
`reference = "CoordinateCleaner"` swaps in
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)’s.
The `gazetteers` argument of
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
replaces the layer of single tests with a user’s own, as the `ref`
arguments of CoordinateCleaner’s `cc_*()` functions do. This article
filters and extends the shipped point tables, builds polygon layers with
[sf](https://r-spatial.github.io/sf/), replaces the genus habitats, and
shows how a custom layer is recorded with the flags.

## Installation

``` r

# install.packages("pak")
pak::pak("gcol33/OccurrenceCleaner")
```

Needs a C++ compiler;
[Installation](https://gillescolling.com/OccurrenceCleaner/index.html#installation)
shows how to set one up. The polygon examples also need
[sf](https://r-spatial.github.io/sf/).

``` r

library(OccurrenceCleaner)
```

## The shipped points

[`reference_points()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_points.md)
returns the points of a proximity test with their attributes:

``` r

caps <- reference_points("capital")
head(caps)
#>         name     country adm0_a3 iso_a2                  class       lon
#> 1 Oranjestad       Aruba     ABW     AW       Factbook capital -70.03333
#> 2 Oranjestad       Aruba     ABW     AW Admin-0 region capital -70.02899
#> 3      Kabul Afghanistan     AFG     AF       Factbook capital  69.18333
#> 4      Kabul Afghanistan     AFG     AF        Admin-0 capital  69.18131
#> 5     Luanda      Angola     AGO     AO       Factbook capital  13.21667
#> 6     Luanda      Angola     AGO     AO        Admin-0 capital  13.23248
#>         lat             source               key extension
#> 1 12.516667 CIA World Factbook       factbook:AA     FALSE
#> 2 12.530384      Natural Earth ne:ABW:Oranjestad      TRUE
#> 3 34.516667 CIA World Factbook       factbook:AF     FALSE
#> 4 34.518636      Natural Earth      ne:AFG:Kabul      TRUE
#> 5 -8.833333 CIA World Factbook       factbook:AO     FALSE
#> 6 -8.836340      Natural Earth     ne:AGO:Luanda      TRUE
table(caps$class)
#> 
#>        Admin-0 capital    Admin-0 capital alt Admin-0 region capital 
#>                    202                     13                     28 
#>       Factbook capital 
#>                    232
inst <- reference_points("institution")
head(sort(table(inst$type), decreasing = TRUE))
#> 
#>        BotanicalGarden                 Museum              Herbarium 
#>                   7003                   3218                   3085 
#>            ZooAquarium      UniversityCollege OtherInstitutionalType 
#>                   2732                    284                    152
```

The institution table joins the GBIF registry of scientific collections
(GRSciColl), the botanical gardens, natural history museums, zoos,
aquaria and herbaria of Wikidata, the museums of Wikipedia’s lists of
natural history museums (the English list and six other language
editions), the gardens of Botanic Gardens Conservation International
(BGCI) and three GeoNames places: `source` says which registry each
point comes from, `type` what kind of institution it is, and
`master_source`, for GRSciColl entries, where GBIF took the entry from
(Index Herbariorum, GRSciColl itself, or the GBIF registry), and for the
Wikipedia museums that the list places only by town, where the town’s
coordinates come from. `extension` is `TRUE` for the points from sources
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)’s own
table does not draw on (Wikidata beyond the museums of the English list,
and the other language editions); the rows with `extension` `FALSE`,
passed as the institution gazetteer, restrict the test to
CoordinateCleaner’s sources.

## A filtered point gazetteer

A point layer is any data frame with longitude and latitude columns
(`lon`/`lat`, `longitude`/`latitude` or
`decimalLongitude`/`decimalLatitude`, in any case). A plant study, for
example, may want to flag records at herbaria only, since a specimen
georeferenced to a zoological museum is unlikely in a plant table, and
use a wider buffer for them:

``` r

herbaria <- inst[inst$type %in% "Herbarium", ]
nrow(herbaria)
#> [1] 3085
near <- rbind(herbaria[1:3, ], inst[inst$type %in% "Museum", ][1:3, ])
x <- data.frame(species = "Quercus robur", decimalLongitude = near$lon + 0.005,
                decimalLatitude = near$lat)
f_all <- flag_occurrences(x, tests = "institution", buffers = list(institution = 1000))
f_herb <- flag_occurrences(x, tests = "institution", buffers = list(institution = 1000),
                           gazetteers = list(institution = herbaria))
data.frame(near = near$name, type = near$type, all = f_all$flag_institution,
           herbaria_only = f_herb$flag_institution)
#>                               near      type  all herbaria_only
#> 1    Andorra Research + Innovation Herbarium TRUE          TRUE
#> 2                   UAE University Herbarium TRUE          TRUE
#> 3                 Kabul University Herbarium TRUE          TRUE
#> 4                             <NA>    Museum TRUE         FALSE
#> 5 Natural History Museum Abu Dhabi    Museum TRUE         FALSE
#> 6   Sharjah Natural History Museum    Museum TRUE         FALSE
```

Each record lies about 0.005 degrees (a few hundred metres) east of an
institution: three herbaria, then three museums. The full table flags
all six at a 1 km buffer; the herbarium table flags only 3, the records
next to the herbaria.

## An extended point gazetteer

The two capital tables differ: the shipped table holds the Factbook
capitals unrounded and adds Natural Earth’s alternative and official
capitals, while
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)’s has
one point per country, rounded to 0.01 degrees. Their union flags
records near either:

``` r

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

The institution table is one of them. CoordinateCleaner geocoded most of
its botanic gardens and many of its museums itself, so its points can
mark a different spot of the same institution. With CoordinateCleaner
installed, the union adds them to the shipped points at run time:

``` r

inst_both <- rbind(inst[, c("lon", "lat")], reference_points("institution", reference = "CoordinateCleaner"))
nrow(inst_both)
#> [1] 28018
```

`gazetteers = list(institution = inst_both)` then flags records near an
institution of either table.

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

The first two points (Vienna, Innsbruck) lie inside the box, the last
two (Zurich, Budapest) outside it. The same applies to `urban`, whose
polygons are the areas to flag, for example a city’s built-up area at a
finer scale than Natural Earth’s.

For `country_mismatch` the polygons carry codes. Any of the columns
`iso_a2`, `iso_a3`, `adm0_a3` or `code` (in any case) is read, and the
record’s code is matched against all of them. Two territories with their
own codes:

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
r <- data.frame(species = c("Bufo bufo", "Bufo bufo", "Bufo bufo", "Lacerta viridis", "Lacerta viridis", "Rana arvalis"),
                decimalLongitude = c(10, 45, -20, 15, 15, 100), decimalLatitude = c(50, 50, 50, 45, 55, 10))
data.frame(r, outside = flag_occurrences(r, tests = "range", gazetteers = list(range = ranges))$flag_range,
           outside_100km = flag_occurrences(r, tests = "range", gazetteers = list(range = ranges),
                                            buffers = list(range = 100000))$flag_range)
#>           species decimalLongitude decimalLatitude outside outside_100km
#> 1       Bufo bufo               10              50   FALSE         FALSE
#> 2       Bufo bufo               45              50   FALSE         FALSE
#> 3       Bufo bufo              -20              50    TRUE          TRUE
#> 4 Lacerta viridis               15              45   FALSE         FALSE
#> 5 Lacerta viridis               15              55    TRUE          TRUE
#> 6    Rana arvalis              100              10   FALSE         FALSE
```

The toad at 45 E lies in the second of its two polygons and is kept; the
one at 20 W lies in the Atlantic, outside both. The lizard at 55 N is 3
degrees north of its range and stays flagged with a 100 km buffer. *Rana
arvalis* has no polygon and is not tested.

## A genus habitat table

The habitat tests `sea_nonmarine` and `land_marine` look up the record’s
genus in
[`reference_habitat()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_habitat.md),
built from the Interim Register of Marine and Nonmarine Genera. A table
with a `genus` column, a logical `marine` column (`TRUE` only marine,
`FALSE` not marine) and optionally a `kingdom` column replaces it, for
example to class a genus the register leaves open:

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
#> [1] "OccurrenceCleaner 0.1.0 (land 110; land_110 4.1.0, land_50 4.1.0, land_10 5.1.1, countries_50 5.1.1, urban_50 4.1.0, places_10 5.1.2, admin0_10 5.1.1, admin1_10 5.1.1, factbook factbook.json 144d6977b2b01ac1cbd220de754c0a005616760b, world_borders 0.3 (2008-07-30), geolocate 2026-10-11, institutions 2026-10-09, institutions_wikidata 2026-10-10, institutions_wikipedia en revision 1376233148; de revision 267938927; fr revision 240149609; nl revision 69876533; pt revision 71307420; ar revision 76691072; eo revision 9165115, institutions_geonames 2026-10-10, institutions_bgci 2026-10-10, aohi 2022-10-10, habitat 2026-10-06); custom: institution 3085 points md5 69360e0c3f54a8d8744cba3d2211610f"
```

The checksum identifies the exact table, so two analyses that report the
same label used the same points. For streamed input the label is stored
in the output directory, and a rerun into that directory with a
different custom layer stops with an error instead of mixing flags from
two gazetteers.

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

[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)’s
point references need its own column names (`capital.lon`,
`centroid.lon`, `decimalLongitude`); here the longitude and latitude
columns are found by name in any of the common spellings. Its
[`cc_coun()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_coun.html)
reads one code column chosen with `ref_col`; here every code column
present is matched. With the same reference points and polygons the two
packages give the same flags, up to the buffer-polygon band described in
the article Coming from CoordinateCleaner; the package tests check this
for `institution`, `sea` and `range`.
