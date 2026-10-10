# Using custom gazetteers

Seven tests compare records with reference data: four with points
(capitals, centroids, institutions, the GBIF headquarters) and three
with polygons (land, urban areas, countries). The package ships its own
pinned layers for all of them, and `reference = "CoordinateCleaner"`
swaps in CoordinateCleaner’s. The `gazetteers` argument of
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
replaces the layer of single tests with a user’s own, as the `ref`
arguments of CoordinateCleaner’s `cc_*()` functions do. This article
filters and extends the shipped point tables, builds polygon layers with
sf, and shows how a custom layer is recorded with the flags.

## Installation

``` r

# install.packages("pak")
pak::pak("gcol33/OccurrenceCleaner")
```

Needs a C++ compiler (Rtools on Windows). The polygon examples also need
sf.

``` r

library(OccurrenceCleaner)
```

## The shipped points

[`reference_points()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_points.md)
returns the points of a proximity test with their attributes:

``` r

caps <- reference_points("capital")
head(caps)
#>         name     country adm0_a3 iso_a2                  class        lon
#> 1 Oranjestad       Aruba     ABW     AW Admin-0 region capital -70.028992
#> 2      Kabul Afghanistan     AFG     AF        Admin-0 capital  69.181314
#> 3     Luanda      Angola     AGO     AO        Admin-0 capital  13.232481
#> 4     Tirana     Albania     ALB     AL        Admin-0 capital  19.818883
#> 5  Mariehamn       Aland     ALD     AX Admin-0 region capital  19.949005
#> 6    Andorra     Andorra     AND     AD        Admin-0 capital   1.516486
#>        lat
#> 1 12.53038
#> 2 34.51864
#> 3 -8.83634
#> 4 41.32754
#> 5 60.09700
#> 6 42.50000
table(caps$class)
#> 
#>        Admin-0 capital    Admin-0 capital alt Admin-0 region capital 
#>                    202                     13                     28
inst <- reference_points("institution")
head(sort(table(inst$type), decreasing = TRUE))
#> 
#>              Herbarium                 Museum      UniversityCollege 
#>                   2983                    683                    286 
#> OtherInstitutionalType            ZooAquarium        BotanicalGarden 
#>                    152                    122                     87
```

The institution table is the GBIF registry of scientific collections
(GRSciColl): `type` says what kind of institution each is, and
`master_source` where GBIF took the entry from (Index Herbariorum,
GRSciColl itself, or the GBIF registry).

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
#> [1] 2983
near <- rbind(herbaria[1:3, ], inst[inst$type %in% "Museum", ][1:3, ])
x <- data.frame(species = "Quercus robur", decimalLongitude = near$lon + 0.005,
                decimalLatitude = near$lat)
f_all <- flag_occurrences(x, tests = "institution", buffers = list(institution = 1000))
f_herb <- flag_occurrences(x, tests = "institution", buffers = list(institution = 1000),
                           gazetteers = list(institution = herbaria))
data.frame(near = near$name, type = near$type, all = f_all$flag_institution,
           herbaria_only = f_herb$flag_institution)
#>                                                         near      type  all
#> 1                              Andorra Research + Innovation Herbarium TRUE
#> 2                                             UAE University Herbarium TRUE
#> 3                                           Kabul University Herbarium TRUE
#> 4                         Museu Nacional de História Natural    Museum TRUE
#> 5 Museo Argentino de Ciencias Naturales Bernardino Rivadavia    Museum TRUE
#> 6                              Burgenländisches Landesmuseum    Museum TRUE
#>   herbaria_only
#> 1          TRUE
#> 2          TRUE
#> 3          TRUE
#> 4         FALSE
#> 5         FALSE
#> 6         FALSE
```

Each record lies about 0.005 degrees (a few hundred metres) east of an
institution: three herbaria, then three museums. The full table flags
all six at a 1 km buffer; the herbarium table flags only 3, the records
next to the herbaria.

## An extended point gazetteer

The two capital tables differ: the Natural Earth table lists alternative
and official capitals, CoordinateCleaner’s has one point per country,
rounded to 0.01 degrees. Their union flags records near either:

``` r

both <- rbind(caps[, c("lon", "lat")], reference_points("capital", reference = "CoordinateCleaner"))
nrow(both)
#> [1] 468
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

## Recording the layer

A custom layer is indexed once per call, and its size and an MD5
checksum of its coordinates are written into the reference label of the
output:

``` r

f <- flag_occurrences(x, tests = "institution", gazetteers = list(institution = herbaria))
attr(f, "occ_reference")
#> [1] "natural_earth (land 110; land_110 4.1.0, land_50 4.1.0, land_10 5.1.1, countries_50 5.1.1, urban_50 4.1.0, places_10 5.1.2, admin0_10 5.1.1, admin1_10 5.1.1, institutions 2026-10-09); custom: institution 2983 points md5 7d490d60f19912d8df72119163656e18"
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

CoordinateCleaner’s point references need its own column names
(`capital.lon`, `centroid.lon`, `decimalLongitude`); here the longitude
and latitude columns are found by name in any of the common spellings.
Its
[`cc_coun()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_coun.html)
reads one code column chosen with `ref_col`; here every code column
present is matched. With the same reference points and polygons the two
packages give the same flags, up to the buffer-polygon band described in
the article Coming from CoordinateCleaner; the package tests check this
for `institution` and `sea`.
