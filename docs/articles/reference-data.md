# Reference data

Seven of the tests compare a record with reference data: points
(capitals, country and province centroids, biodiversity institutions)
and polygons (land, urban areas, countries). This article lists where
each layer comes from, how the package’s own gazetteers compare with
CoordinateCleaner’s, how much the choice of land scale changes the `sea`
test, and how the reference version is recorded with the flags.

## Installation

``` r

# install.packages("pak")
pak::pak("gcol33/OccurrenceCleaner")
```

Needs a C++ compiler (Rtools on Windows).

``` r

library(OccurrenceCleaner)
```

## The layers

``` r

ri <- reference_info()
knitr::kable(ri[, c("layer", "source", "file", "version", "retrieved")])
```

| layer | source | file | version | retrieved |
|:---|:---|:---|:---|:---|
| land_110 | Natural Earth | ne_110m_land.zip | 4.1.0 | 2026-10-09 |
| land_50 | Natural Earth | ne_50m_land.zip | 4.1.0 | 2026-10-09 |
| land_10 | Natural Earth | ne_10m_land.zip | 5.1.1 | 2026-10-09 |
| countries_50 | Natural Earth | ne_50m_admin_0_countries.zip | 5.1.1 | 2026-10-09 |
| urban_50 | Natural Earth | ne_50m_urban_areas.zip | 4.1.0 | 2026-10-09 |
| places_10 | Natural Earth | ne_10m_populated_places_simple.zip | 5.1.2 | 2026-10-09 |
| admin0_10 | Natural Earth | ne_10m_admin_0_countries.zip | 5.1.1 | 2026-10-09 |
| admin1_10 | Natural Earth | ne_10m_admin_1_states_provinces.zip | 5.1.1 | 2026-10-09 |
| institutions | GBIF GRSciColl | grscicoll_institutions.tsv | 2026-10-09 | 2026-10-09 |

Each row also holds the download URL, the SHA-256 checksum of the source
file and the licence. The tests read these layers:

| test | reference data |
|:---|:---|
| capital | Natural Earth populated places: admin-0 capitals, alternative capitals and capitals of dependent territories |
| centroid | Natural Earth admin-0 country centroids and label points, admin-1 label points |
| institution | GBIF GRSciColl institutions with coordinates |
| gbif_headquarters | one fixed point, 12.58 E, 55.67 N |
| sea | Natural Earth land at 1:110m (default), 1:50m or 1:10m |
| urban | Natural Earth urban areas 1:50m |
| country_mismatch | Natural Earth admin-0 countries 1:50m |

All Natural Earth layers are in the public domain; the Natural Earth
terms of use say that “No permission is needed to use Natural Earth.”
The institutions come from the bulk export of GBIF’s Global Registry of
Scientific Collections (GRSciColl), retrieved on 2026-10-09: 10,002
institutions, of which 6,085 have coordinates. GRSciColl absorbed the
Global Registry of Biodiversity Repositories (GRBio) in 2018 and is
synchronised weekly with Index Herbariorum. GBIF publishes the registry
through its open API and states no separate licence for it.

The layers are rebuilt from the sources CoordinateCleaner itself draws
on, by the scripts in `data-raw/` of the source repository;
CoordinateCleaner’s code and data are GPL-3, and nothing is copied from
them.

## How the gazetteers differ from CoordinateCleaner’s

The package gazetteers describe the same places as CoordinateCleaner
3.0.1’s `countryref` and `institutions` tables, but they are not the
same tables. Measured on 2026-10-09:

| gazetteer | CoordinateCleaner | OccurrenceCleaner |
|:---|:---|:---|
| capitals | 225 (one per ISO3 code) | 243 (215 admin-0 capitals and alternative capitals, plus dependent-territory capitals) |
| country centroids | 660 rows from the CIA World Factbook, thematicmapping.org and geo-locate | 516 (polygon centroid and label point per country, Natural Earth 5.1.1) |
| province centroids | 4,645 (older Natural Earth admin-1 label points) | 4,596 (Natural Earth 5.1.1 admin-1 label points) |
| institutions | 9,773 with coordinates (GRBio, Index Herbariorum, GBIF, BGCI, Wikipedia, GeoNames) | 6,085 (GRSciColl) |

- **Capitals.** 212 countries match by ISO3 code. The median distance
  between the two packages’ capital points for the same country is 0.92
  km, 90 % are within 7.1 km; CoordinateCleaner’s coordinates are
  rounded to 0.01 degrees. Natural Earth also lists alternative and
  official capitals that CoordinateCleaner does not hold: Cape Town and
  Bloemfontein besides Pretoria, Sucre besides La Paz, Naypyidaw instead
  of Yangon, Dodoma instead of Dar es Salaam, among others.

- **Country centroids.** The two define centroids differently, so the
  points lie a median of 30 km apart (90 % within 259 km). Both use a 1
  km buffer, so they flag different records: each catches records
  georeferenced to its own definition of the centre of a country.

- **Province centroids.** CoordinateCleaner’s province centroids are
  exactly the Natural Earth admin-1 label points of an older release:
  all 4,549 codes that still exist match at distance 0. The package uses
  the 5.1.1 release, in which 96 of CoordinateCleaner’s codes no longer
  exist.

- **Institutions.** The package uses GRSciColl only. CoordinateCleaner’s
  table also has 712 botanic gardens from Botanic Gardens Conservation
  International, 627 points from Wikipedia and 3 from GeoNames, which
  are not rebuilt here. GRSciColl has added institutions since
  CoordinateCleaner’s table was compiled.

The capital difference shows directly in the flags. Records at a few
alternative or official capitals, under both references:

``` r

x <- data.frame(city = c("Pretoria", "Cape Town", "La Paz", "Sucre", "Yangon", "Naypyidaw"),
                species = "a",
                decimalLongitude = c(28.19, 18.42, -68.15, -65.26, 96.16, 96.13),
                decimalLatitude = c(-25.75, -33.92, -16.50, -19.04, 16.80, 19.75))
data.frame(city = x$city,
           natural_earth = flag_occurrences(x, tests = "capital")$flag_capital,
           CoordinateCleaner = flag_occurrences(x, tests = "capital", reference = "CoordinateCleaner")$flag_capital)
#>        city natural_earth CoordinateCleaner
#> 1  Pretoria          TRUE              TRUE
#> 2 Cape Town          TRUE             FALSE
#> 3    La Paz          TRUE              TRUE
#> 4     Sucre          TRUE             FALSE
#> 5    Yangon          TRUE              TRUE
#> 6 Naypyidaw          TRUE             FALSE
```

Cape Town, Sucre and Naypyidaw are flagged only with the Natural Earth
list; Pretoria, La Paz and Yangon under both. Which list is right
depends on what an error looks like: a herbarium sheet in Cape Town
georeferenced to the city is as wrong under either reference, and only
the Natural Earth list catches it.

## Land scale and the `sea` test

The `sea` test flags records outside the land polygons. The coarse
1:110m layer, the default of CoordinateCleaner’s
[`cc_sea()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_sea.html)
(its
[`clean_coordinates()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_coordinates.html)
uses 1:50m), smooths the coast and drops small islands; the 1:50m layer
follows the coast more closely. A grid of points over Denmark and the
western Baltic shows where the two disagree:

``` r

g <- expand.grid(decimalLongitude = seq(7.5, 15.5, by = 0.05),
                 decimalLatitude = seq(54, 58, by = 0.05))
g$species <- "a"
s110 <- flag_occurrences(g, tests = "sea")$flag_sea
s50 <- flag_occurrences(g, tests = "sea", land_scale = 50)$flag_sea
g$verdict <- ifelse(s110 & s50, "sea at both", ifelse(!s110 & !s50, "land at both",
                    ifelse(s110, "sea at 1:110m only", "sea at 1:50m only")))
table(g$verdict)
#> 
#>       land at both sea at 1:110m only  sea at 1:50m only        sea at both 
#>               5765                519                783               5974
```

``` r

library(ggplot2)
ggplot(g, aes(decimalLongitude, decimalLatitude, fill = verdict)) +
  geom_tile() +
  scale_fill_manual(values = c(`land at both` = "#C8B88A", `sea at both` = "#A9C7E0",
                               `sea at 1:110m only` = "#C0392B", `sea at 1:50m only` = "#2C3E50")) +
  coord_quickmap(expand = FALSE) +
  labs(x = "longitude", y = "latitude", fill = NULL) +
  theme_minimal() +
  theme(panel.background = element_rect(fill = "transparent", colour = NA),
        plot.background = element_rect(fill = "transparent", colour = NA))
```

![](reference-data_files/figure-html/land-map-1.svg)

On this grid the two scales disagree for 10 % of the points, all of them
along the coast. At 1:110m Funen, Lolland, Falster, Rügen and Bornholm
are missing, so records on them are flagged as at sea (red); the coarse
1:110m coastline also reaches out into the water, so records in a strip
of coastal water count as on land there and are flagged only at 1:50m
(dark). For coastal and island taxa the scale therefore changes a share
of the `sea` flags large enough to see in a tally. The 1:10m layer is
the most detailed of the three and is downloaded on first use:

``` r

download_reference("land_10")
f <- flag_occurrences(x, tests = "sea", land_scale = 10)
```

The download is checked against the SHA-256 in
[`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md)
and refused if Natural Earth has published a different file under the
same name. The converted layer is stored in
`tools::R_user_dir("OccurrenceCleaner", "cache")`, so it is downloaded
once per machine.

## Buffers

The buffers are the other half of every proximity test. They default to
CoordinateCleaner’s (10 km for capitals, 1 km for centroids and the GBIF
headquarters, 100 m for institutions, 0.5 degrees around (0, 0)) and are
changed per test:

``` r

x <- data.frame(species = "a", decimalLongitude = c(16.37, 16.45), decimalLatitude = c(48.21, 48.21))
flag_occurrences(x, tests = "capital")$flag_capital
#> [1] TRUE TRUE
flag_occurrences(x, tests = "capital", buffers = list(capital = 2000))$flag_capital
#> [1]  TRUE FALSE
```

A buffer of 2 km for capitals keeps records from the outer districts of
a capital while still removing those placed at the city’s coordinates.
The 0.5-degree zero buffer is in degrees, the others in metres.

## Recording the reference

Every flagged data frame carries the reference that produced it, with
the version of each layer:

``` r

f <- flag_occurrences(x, tests = c("capital", "sea"), land_scale = 50)
attr(f, "occ_reference")
#> [1] "natural_earth (land 50; land_110 4.1.0, land_50 4.1.0, land_10 5.1.1, countries_50 5.1.1, urban_50 4.1.0, places_10 5.1.2, admin0_10 5.1.1, admin1_10 5.1.1, institutions 2026-10-09)"
attr(f, "occ_layout_version")
#> [1] 2
```

`reference = "CoordinateCleaner"` stamps the installed CoordinateCleaner
version instead. For streamed input the same label is written to the
output directory, and a rerun into that directory with a different
reference, land scale, set of tests or layout stops with an error, so
one output directory never mixes flags from two references.

## Choosing a reference

- `reference = "natural_earth"` (the default) needs no other package,
  has a version and checksum for every layer, and uses current Natural
  Earth and GRSciColl data.

- `reference = "CoordinateCleaner"` gives CoordinateCleaner’s flags up
  to the differences listed in the article Coming from
  CoordinateCleaner, for example to compare with a published analysis
  that used it. It needs CoordinateCleaner installed, and rnaturalearth
  for the polygon tests, which downloads the Natural Earth layers at run
  time as CoordinateCleaner does.

Both references use the same buffers and the same geodesic distance, so
the difference between them is in the points and polygons only.
