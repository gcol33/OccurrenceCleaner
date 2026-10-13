# Reference data

Eight of the tests compare a record with reference data from a shipped
layer: points (capitals, country and province centroids, biodiversity
institutions, artificial hotspots) and polygons (land, urban areas,
countries). The ninth, `range`, needs species range polygons, which the
user supplies (see the article on custom gazetteers). This article lists
where each layer comes from, how the package’s own gazetteers compare
with
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)’s,
how much the choice of land scale changes the `sea` test, and how the
reference version is recorded with the flags. Installation is covered in
[Get
started](https://gillescolling.com/OccurrenceCleaner/articles/OccurrenceCleaner.md).

## The layers

``` r

library(OccurrenceCleaner)

ri <- reference_info()
```

| Layer | Source | Version / snapshot | Retrieved |
|:---|:---|:---|:---|
| land_110 | Natural Earth | 4.1.0 | 2026-10-09 |
| land_50 | Natural Earth | 4.1.0 | 2026-10-09 |
| land_10 | Natural Earth | 5.1.1 | 2026-10-09 |
| countries_50 | Natural Earth | 5.1.1 | 2026-10-09 |
| urban_50 | Natural Earth | 4.1.0 | 2026-10-09 |
| places_10 | Natural Earth | 5.1.2 | 2026-10-09 |
| admin0_10 | Natural Earth | 5.1.1 | 2026-10-09 |
| admin1_10 | Natural Earth | 5.1.1 | 2026-10-09 |
| factbook | CIA World Factbook (factbook.json) | factbook.json 144d697 | 2026-10-11 |
| world_borders | thematicmapping.org World Borders Dataset | 0.3 (2008-07-30) | 2026-10-11 |
| geolocate | GEOLocate web service | 2026-10-11 | 2026-10-11 |
| institutions | GBIF GRSciColl | 2026-10-09 | 2026-10-09 |
| institutions_wikidata | Wikidata | 2026-10-10 | 2026-10-10 |
| institutions_wikipedia | Wikipedia, lists of natural history museums | 7 page revisions (below) | 2026-10-11 |
| institutions_geonames | GeoNames | 2026-10-10 | 2026-10-10 |
| institutions_bgci | BGCI GardenSearch | 2026-10-10 | 2026-10-10 |
| institutions_index_herbariorum | Index Herbariorum (New York Botanical Garden) | 2026-10-13 | 2026-10-13 |
| institutions_gbif_registry | GBIF registry, publishing organisations | 2026-10-13 | 2026-10-13 |
| institutions_coordinatecleaner_list | CoordinateCleaner 3.0.1 institution list, placed by Wikidata, OpenStreetMap (Nominatim) and GeoNames | 3.0.1 | 2026-10-13 |
| aohi | AHOI (Park et al. 2023) | 2022-10-10 | 2026-10-10 |
| habitat | IRMNG (Rees 2026) | 2026-10-06 | 2026-10-10 |

The factbook version is the commit of the factbook.json mirror,
shortened here;
[`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md)
gives the full hash. The Wikipedia lists are pinned by page revision: en
1376233148; de 267938927; fr 240149609; nl 69876533; pt 71307420; ar
76691072; eo 9165115. IRMNG is cited as Rees, T. (compiler) (2026), The
Interim Register of Marine and Nonmarine Genera, available from
<https://www.irmng.org> at VLIZ. The layer `aohi` takes its name from
CoordinateCleaner’s
[`cc_aohi()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_aohi.html);
the inventory’s own abbreviation is AHOI.

Each row of
[`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md)
also gives the file name, the download URL, the SHA-256 checksum of the
source file and the licence. The tests read these layers:

| test | reference data |
|:---|:---|
| capital | CIA World Factbook capital coordinates, Natural Earth populated places: admin-0 capitals, alternative capitals and capitals of dependent territories |
| centroid | CIA World Factbook, thematicmapping.org World Borders and GEOLocate country points, Natural Earth admin-0 polygon centroids and label points, admin-1 label points |
| institution | GBIF GRSciColl institutions, Wikidata botanical gardens, natural history museums, zoos, aquaria and herbaria, museums of Wikipedia’s lists of natural history museums, BGCI gardens, Index Herbariorum herbaria and GBIF publishing organisations, with coordinates, and every further institution of CoordinateCleaner’s table placed from Wikidata, OpenStreetMap or GeoNames |
| gbif_headquarters | one fixed point, 12.58 E, 55.67 N |
| aohi | Artificial Hotspot Occurrence Inventory (Park et al. 2023), 308 points |
| sea | Natural Earth land at 1:110 million (default), 1:50 million or 1:10 million |
| urban | Natural Earth urban areas 1:50 million |
| country_mismatch | Natural Earth admin-0 countries 1:50 million |
| sea_nonmarine, land_marine | the land of sea, and genus habitats from the Interim Register of Marine and Nonmarine Genera |

The capitals are the capital “geographic coordinates” of the CIA World
Factbook, the source of
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)’s
capitals, read from the same factbook.json mirror: one point per country
profile, 232 in all. The Natural Earth admin-0 capitals, alternative
capitals and capitals of dependent territories (243) are added with
`extension` `TRUE`.

The country centroids come from the three sources CoordinateCleaner’s
table is compiled from, each taken from the source itself: the
“Geographic coordinates” of the CIA World Factbook (public domain), read
from the factbook.json mirror of the Factbook country profiles on
2026-10-11 (275 points); the label points of the World Borders Dataset
0.3 by Bjorn Sandvik, thematicmapping.org (246 points), under CC BY-SA,
from the GeoJSON conversion of the dataset at
github.com/jeffaudi/world-borders-geojson; and every point the GEOLocate
georeferencing service (geo-locate.org) returns when a country name is
entered as country and locality, queried on 2026-10-11 for each country
name of the three tables (548 points). GEOLocate also returns places
that carry a country’s name; one such place, Niger State in Nigeria for
“Niger”, lies inside another country more than 100 km from the queried
one and is left out. The Natural Earth admin-0 polygon centroids,
computed on the sphere, and label points (516) are added with
`extension` `TRUE`.

All Natural Earth layers are in the public domain; the Natural Earth
terms of use say that “No permission is needed to use Natural Earth.”
The institutions come from the bulk export of GBIF’s Global Registry of
Scientific Collections (GRSciColl), retrieved on 2026-10-09: 10,002
institutions, of which 6,085 have coordinates. The five of these that
the `zero` test would flag are left out: four are registered within 0.14
degrees of (0, 0), although they are in Portugal, Nigeria, Turkey and
Taiwan, and one has a longitude of exactly 0. Kept, they would mark
every record at (0, 0) as lying at an institution as well. GRSciColl
absorbed the Global Registry of Biodiversity Repositories (GRBio) in
2018 and is synchronised weekly with Index Herbariorum. GBIF publishes
the registry through its open API and states no separate licence for it.

The institutions are completed from Wikidata, released under CC0,
queried on 2026-10-10: every item that is a botanical garden, natural
history museum, zoo, public aquarium or herbarium, or of a subclass of
one, and has a coordinate location, every museum whose main subject or
field of work is a natural-history field (geology, paleontology,
zoology, botany and the like), and the museums of Wikipedia’s “List of
natural history museums”, the list CoordinateCleaner’s Wikipedia rows
come from, and of its Arabic, Dutch, Esperanto, French, German and
Portuguese counterparts (2,331 entries, texts under CC BY-SA 4.0,
retrieved 2026-10-11) that have Wikidata coordinates of their own: by
the article the entry links, or, for an entry without one, by the one
museum item of the entry’s country whose name it is, when the town the
entry names lies within 25 km. After duplicate items are dropped these
are 7,810 points (3,263 botanical gardens, 1,835 museums, 2,609 zoos and
aquaria, 103 herbaria), none at zero coordinates. The other museums of
the lists are placed where the list says they are: at the Wikidata
coordinates of the place the entry links, such as the town or the
university, if it lies in the entry’s country, or at the GeoNames
populated place (CC BY 4.0) of the town it names. That gives 700 more
points (385 from the English list); entries that name no town are left
out. The three places CoordinateCleaner’s table takes from GeoNames are
taken from the GeoNames country files (CC BY 4.0). The botanic gardens
of Botanic Gardens Conservation International (BGCI) come from its
GardenSearch map (<https://tools.bgci.org/map.php>, all countries),
retrieved on 2026-10-10: 3,765 gardens, of which 3,653 have coordinates
and one lies at zero coordinates, leaving 3,652; they are used under the
BGCI terms (<https://www.bgci.org/terms-and-conditions/>). The `source`
column of `reference_points("institution")` says which registry each
point comes from.

Two more registries are read whole, both on 2026-10-13. Index
Herbariorum, the herbarium registry of the New York Botanical Garden,
gives a location for 4,805 herbaria; the 1,062 that GRSciColl does not
place under the same herbarium code are added. The GBIF registry gives
coordinates for 2,468 of its 3,639 publishing organisations, and all of
them are added.

Every further institution of CoordinateCleaner’s table with coordinates
is then placed from its name, city and country. These are the
institutions that no row above holds under their name, under the full
Index Herbariorum name of a herbarium, or under an alternative or
collection name GRSciColl gives. They are looked up in turn:

1.  in Wikidata, by the full name or the part before the first comma;

2.  in OpenStreetMap through Nominatim, taking a result whose name holds
    at least half the institution’s words, or one within 25 km of
    CoordinateCleaner’s point;

3.  at the GeoNames populated place of the city CoordinateCleaner or
    GRSciColl lists for it.

When a source returns several candidates, the one nearest
CoordinateCleaner’s point is taken, but the coordinates are always the
source’s. An institution none of these places is held when a shipped
point within 25 km carries at least 60 % of its name’s words. Otherwise
it gets the populated place named in its name, or, as a last resort, the
populated place of its country nearest CoordinateCleaner’s point. These
rows carry `source` “CoordinateCleaner list”, and `master_source` says
how each was placed.

The genus habitats of `sea_nonmarine` and `land_marine` come from the
Interim Register of Marine and Nonmarine Genera (IRMNG), Darwin Core
archive of 2026-10-06, under CC BY 4.0; cite it as Rees, T. (compiler)
(2026). The Interim Register of Marine and Nonmarine Genera. Available
from <https://www.irmng.org> at VLIZ. IRMNG sets marine, brackish,
freshwater and terrestrial flags per name; the package classes 296,474
genera as not marine and 21,891 as only marine, keyed by kingdom, by the
rule in
[`?reference_habitat`](https://gillescolling.com/OccurrenceCleaner/reference/reference_habitat.md).

The Artificial Hotspot Occurrence Inventory (AHOI) of Park, Xie,
Thammavong, Tulaiha and Feng ([2023](https://doi.org/10.1111/jbi.14543))
lists the coordinates that recur most often in GBIF records of plants,
birds, insects and mammals, with the reason each recurs: 154 plant, 51
bird, 51 insect and 52 mammal points. It is built from the authors’
deposit on Dryad
([doi:10.5061/dryad.v41ns1s0p](https://doi.org/10.5061/dryad.v41ns1s0p)),
released under CC0, and keeps 308 points with coordinates.
CoordinateCleaner’s bundled `aohi` table has 309; the two share 303
points, and the others differ in a few bird points and one plant
coordinate (42.26 N there, 42.20 N in the deposit).

The layers are rebuilt from the sources CoordinateCleaner itself draws
on, by the scripts in `data-raw/` of the source repository.

## How the gazetteers differ from CoordinateCleaner’s

The package gazetteers describe the same places as
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)
3.0.1’s `countryref` and `institutions` tables, but they are not the
same tables. Measured on 2026-10-09:

| gazetteer | CoordinateCleaner | OccurrenceCleaner |
|:---|:---|:---|
| capitals | 225 (one per ISO3 code) | 475: 232 Factbook capitals and 243 Natural Earth capitals, alternative capitals and dependent-territory capitals marked as extension |
| country centroids | 660 rows from the CIA World Factbook, thematicmapping.org and GEOLocate | 1,585: 1,069 from the same three sources (275 Factbook, 246 World Borders, 548 GEOLocate) and 516 Natural Earth polygon centroids and label points marked as extension |
| province centroids | 4,645 (older Natural Earth admin-1 label points) | 4,594 (Natural Earth 5.1.1 admin-1 label points) |
| institutions | 9,773 with coordinates (GRBio, Index Herbariorum, GBIF, BGCI, Wikipedia, GeoNames) | 23,895 (6,080 GRSciColl, without the five at zero coordinates, 7,810 Wikidata, 700 Wikipedia, 3,652 BGCI, 3 GeoNames, 1,062 Index Herbariorum, 2,468 GBIF registry, 2,120 for the rest of CoordinateCleaner’s list), of which 16,230 from CoordinateCleaner’s sources |

- **Capitals.** 221 of CoordinateCleaner’s 225 capital points are
  Factbook points of the package’s table rounded to 0.01 degrees, which
  moves them by up to 523 m. The other four hold values the Factbook has
  since revised: Bujumbura for Burundi, whose capital it now gives as
  Gitega; Buenos Aires at 58 40 W, 27 km west of the city, now 58 22 W;
  Melekeok for Palau, now Ngerulmud; and Rangoon, 1.8 km from its
  present coordinates. The Natural Earth points add alternative and
  official capitals that CoordinateCleaner does not hold: Cape Town and
  Bloemfontein besides Pretoria, Sucre besides La Paz, Naypyidaw besides
  Yangon, Dodoma besides Dar es Salaam, among others; the test leaves
  them out when passed the points with `extension` `FALSE`.

- **Country centroids.** 645 of CoordinateCleaner’s 660 country
  centroids are points of the package’s table at distance 0. India,
  Italy and the United Kingdom hold World Borders values that version
  0.3 of the dataset changed; three GEOLocate points for Macedonia and
  one for Guinea, at sea at 10 W 5 N, are not returned by GEOLocate
  today; eight others lie 5 m to 68 km from a shipped point. The Natural
  Earth points, which CoordinateCleaner does not hold, lie a median of
  30 km from its centroids and catch records georeferenced to the centre
  of a country’s polygon; the test leaves them out when passed the
  points with `extension` `FALSE`.

- **Province centroids.** CoordinateCleaner’s province centroids are
  Natural Earth admin-1 label points of older releases: 4,566 of its
  4,645 rows match a unit of release 3.3.0, 4.0.0 or 4.1.0 by code and
  coordinates. The package takes the same layer from release 5.1.1, so
  every province point comes from CoordinateCleaner’s source and carries
  `extension` `FALSE`. 4,591 of CoordinateCleaner’s rows are shipped
  points at distance 0. Of the other 54, 50 lie more than 10 km from any
  shipped point: 15 hold coordinates of older releases that Natural
  Earth has since changed, and 39 match no tagged release.

- **Institutions.** Every institution of CoordinateCleaner’s table with
  coordinates has a point in the package’s table, except one expert
  group listed in Antarctica. Of its 9,773 institutions, 6,313 are held
  under their name and 329 by a nearby point that shares their name’s
  words. The other 3,130 are placed from their names: 1,052 from
  Wikidata, 646 from OpenStreetMap, 684 at the town CoordinateCleaner or
  GRSciColl lists, and 252 at a town their name holds. For 496, no
  source places the institution itself, and the point is the town
  nearest CoordinateCleaner’s point.

  The points still differ, because CoordinateCleaner placed nearly every
  institution by its own geocoding. It geocoded 641 of its 712 BGCI
  gardens from their names and addresses, where the package takes BGCI’s
  own coordinates, and it placed 398 of its Wikipedia museums by hand,
  to 1 km. Some of its points sit far from the institution: every
  Iranian university museum, for example, sits at one point in Isfahan
  there, and the Museo Marino of Boca del Río, Veracruz, in Venezuela.
  For 32 % of its points a shipped point lies within the 100 m buffer,
  for 73 % within 1 km and for 91 % within 5 km. The points from sources
  CoordinateCleaner’s table does not draw on (Wikidata beyond the
  English list’s museums, and the other language editions of the list)
  carry `extension` `TRUE` in `reference_points("institution")`, so the
  test can be run on CoordinateCleaner’s sources alone. With
  CoordinateCleaner installed, its table can be added at run time (see
  the article on custom gazetteers).

The capital difference shows directly in the flags. Records at a few
alternative or official capitals, under both references:

``` r

x <- data.frame(city = c("Pretoria", "Cape Town", "La Paz", "Sucre", "Yangon", "Naypyidaw"),
                species = "a",
                decimalLongitude = c(28.19, 18.42, -68.15, -65.26, 96.16, 96.13),
                decimalLatitude = c(-25.75, -33.92, -16.50, -19.04, 16.80, 19.75))
data.frame(city = x$city,
           OccurrenceCleaner = flag_occurrences(x, tests = "capital")$flag_capital,
           CoordinateCleaner = flag_occurrences(x, tests = "capital", reference = "CoordinateCleaner")$flag_capital)
#>        city OccurrenceCleaner CoordinateCleaner
#> 1  Pretoria              TRUE              TRUE
#> 2 Cape Town              TRUE             FALSE
#> 3    La Paz              TRUE              TRUE
#> 4     Sucre              TRUE             FALSE
#> 5    Yangon              TRUE              TRUE
#> 6 Naypyidaw              TRUE             FALSE
```

Cape Town, Sucre and Naypyidaw are flagged only through the Natural
Earth extension points; Pretoria, La Paz and Yangon under both. Which
list is right depends on what an error looks like: a herbarium sheet in
Cape Town georeferenced to the city is as wrong under either reference,
and only the extension points catch it.

## Extension points

The capital, country centroid and institution tables also hold points
from sources CoordinateCleaner does not use, marked `extension` `TRUE`:

- capitals: 243 Natural Earth capitals, alternative capitals and
  capitals of dependent territories;

- country centroids: 516 Natural Earth polygon centroids and label
  points;

- institutions: 7,665 points, the botanical gardens, natural history
  museums, zoos, aquaria and herbaria of Wikidata beyond the museums of
  the English Wikipedia list, and the museums of the Arabic, Dutch,
  Esperanto, French, German and Portuguese lists.

The tests use them by default. Passing the rows with `extension` `FALSE`
through `gazetteers` restricts a test to CoordinateCleaner’s sources;
for the capitals above, that leaves Cape Town, Sucre and Naypyidaw
unflagged:

``` r

g <- reference_points("capital")
data.frame(city = x$city,
           all = flag_occurrences(x, tests = "capital")$flag_capital,
           cc_sources = flag_occurrences(x, tests = "capital",
                                         gazetteers = list(capital = g[!g$extension, ]))$flag_capital)
#>        city  all cc_sources
#> 1  Pretoria TRUE       TRUE
#> 2 Cape Town TRUE      FALSE
#> 3    La Paz TRUE       TRUE
#> 4     Sucre TRUE      FALSE
#> 5    Yangon TRUE       TRUE
#> 6 Naypyidaw TRUE      FALSE
```

## Land scale and the `sea` test

The `sea` test flags records outside the land polygons. It supports
Natural Earth land polygons at scales of 1:110 million, 1:50 million and
1:10 million. OccurrenceCleaner defaults to 1:110 million
(`land_scale = 110`).
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)
defaults to 1:110 million in
[`cc_sea()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_sea.html)
and 1:50 million in
[`clean_coordinates()`](https://ropensci.github.io/CoordinateCleaner/reference/clean_coordinates.html).
The 1:10 million layer is downloaded on first use and cached.

The coarse 1:110 million layer smooths the coast and drops small
islands; the 1:50 million layer follows the coast more closely. A grid
of points over Denmark and the western Baltic shows where the two
disagree:

``` r

g <- expand.grid(decimalLongitude = seq(7.5, 15.5, by = 0.05),
                 decimalLatitude = seq(54, 58, by = 0.05))
g$species <- "a"
s110 <- flag_occurrences(g, tests = "sea")$flag_sea
s50 <- flag_occurrences(g, tests = "sea", land_scale = 50)$flag_sea
g$verdict <- ifelse(s110 & s50, "sea at both", ifelse(!s110 & !s50, "land at both",
                    ifelse(s110, "sea at 1:110 million only", "sea at 1:50 million only")))
table(g$verdict)
#> 
#>              land at both sea at 1:110 million only  sea at 1:50 million only 
#>                      5765                       519                       783 
#>               sea at both 
#>                      5974
```

``` r

library(ggplot2)
ggplot(g, aes(decimalLongitude, decimalLatitude, fill = verdict)) +
  geom_tile() +
  scale_fill_manual(values = c(`land at both` = "#C8B88A", `sea at both` = "#A9C7E0",
                               `sea at 1:110 million only` = "#C0392B", `sea at 1:50 million only` = "#2C3E50")) +
  coord_quickmap(expand = FALSE) +
  labs(x = "longitude", y = "latitude", fill = NULL) +
  theme_minimal(base_size = 17) +
  theme(legend.position = "bottom", legend.direction = "vertical") +
  theme(panel.background = element_rect(fill = "transparent", colour = NA),
        plot.background = element_rect(fill = "transparent", colour = NA))
```

![](reference-data_files/figure-html/land-map-1.svg)

On this grid the two scales disagree for 10 % of the points, all of them
along the coast. At 1:110 million Funen, Lolland, Falster, Rügen and
Bornholm are missing, so records on them are flagged as at sea (red);
the coarse 1:110 million coastline also reaches out into the water, so
records in a strip of coastal water count as on land there and are
flagged only at 1:50 million (dark). For coastal and island taxa the
scale therefore changes a share of the `sea` flags large enough to see
in a tally. The 1:10 million layer is the most detailed of the three:

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
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)’s (10
km for capitals, 1 km for centroids and the GBIF headquarters, 100 m for
institutions, 0.5 degrees around (0, 0)) and are changed per test:

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
#> [1] "OccurrenceCleaner 0.2.0 (land 50; land_110 4.1.0, land_50 4.1.0, land_10 5.1.1, countries_50 5.1.1, urban_50 4.1.0, places_10 5.1.2, admin0_10 5.1.1, admin1_10 5.1.1, factbook factbook.json 144d6977b2b01ac1cbd220de754c0a005616760b, world_borders 0.3 (2008-07-30), geolocate 2026-10-11, institutions 2026-10-09, institutions_wikidata 2026-10-10, institutions_wikipedia en revision 1376233148; de revision 267938927; fr revision 240149609; nl revision 69876533; pt revision 71307420; ar revision 76691072; eo revision 9165115, institutions_geonames 2026-10-10, institutions_bgci 2026-10-10, institutions_index_herbariorum 2026-10-13, institutions_gbif_registry 2026-10-13, institutions_coordinatecleaner_list 3.0.1, aohi 2022-10-10, habitat 2026-10-06)"
attr(f, "occ_layout_version")
#> [1] 4
```

`reference = "CoordinateCleaner"` stamps the installed
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)
version instead. For streamed input the same label is written to the
output directory, and a rerun into that directory with a different
reference, land scale, set of tests or layout stops with an error, so
one output directory never mixes flags from two references.

## Choosing a reference

- `reference = "OccurrenceCleaner"` (the default) needs no other
  package, has a version and checksum for every layer, and uses current
  Natural Earth, GRSciColl, Wikidata, Wikipedia, GeoNames, BGCI, Index
  Herbariorum, GBIF registry and OpenStreetMap data.

- Set `reference = "CoordinateCleaner"` to use
  [CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)’s
  own reference tables, for example to compare with a published analysis
  that used it. This requires CoordinateCleaner to be installed and
  reproduces its flags subject to the differences documented in
  [Compatibility with
  CoordinateCleaner](https://gillescolling.com/OccurrenceCleaner/articles/coordinatecleaner.md).
  The polygon tests also need
  [rnaturalearth](https://docs.ropensci.org/rnaturalearth/), which
  downloads the Natural Earth layers at run time as CoordinateCleaner
  does.

Both references use the same buffers and the same geodesic distance, so
the difference between them is in the points and polygons only.
