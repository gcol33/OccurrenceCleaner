# Reference data

Eight of the tests compare a record with reference data from a shipped
layer: points (capitals, country and province centroids, biodiversity
institutions, artificial hotspots) and polygons (land, urban areas,
countries). The ninth, `range`, needs species range polygons, which the
user supplies ([Custom reference points and
polygons](https://gillescolling.com/OccurrenceCleaner/articles/gazetteers.md)).
This article lists where each layer comes from, how the package’s own
reference data compare with
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

[`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md)
lists each source’s version, file name, download URL, SHA-256 checksum
and licence.

- The factbook version is the shortened commit hash of the factbook.json
  mirror.
  [`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md)
  gives the full hash.

- Wikipedia lists use fixed page revisions: en 1376233148; de 267938927;
  fr 240149609; nl 69876533; pt 71307420; ar 76691072; eo 9165115.

- The Interim Register of Marine and Nonmarine Genera (IRMNG) is cited
  as: Rees, T. (compiler) (2026), *The Interim Register of Marine and
  Nonmarine Genera*, available from [irmng.org](https://www.irmng.org)
  at VLIZ.

- The layer name `aohi` follows CoordinateCleaner’s
  [`cc_aohi()`](https://ropensci.github.io/CoordinateCleaner/reference/cc_aohi.html).
  The inventory itself uses the abbreviation AHOI.

The tests use the following layers:

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

The sections below give the provenance of each layer: its sources, their
licences and retrieval dates, and how the points were matched or placed.

### Capitals

The capitals are the capital “geographic coordinates” of the CIA World
Factbook, the source of
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)’s
capitals, read from the same factbook.json mirror: one point per country
profile, 232 in all. The Natural Earth admin-0 capitals, alternative
capitals and capitals of dependent territories (243) are added with
`extension` `TRUE`.

### Country and province centroids

The country centroids come from the three sources CoordinateCleaner’s
table is compiled from, each taken from the source itself:

- The “Geographic coordinates” of the CIA World Factbook (public
  domain), read from the factbook.json mirror of the Factbook country
  profiles on 2026-10-11: 275 points.

- The label points of the World Borders Dataset 0.3 by Bjorn Sandvik,
  thematicmapping.org, under CC BY-SA, from the GeoJSON conversion of
  the dataset at github.com/jeffaudi/world-borders-geojson: 246 points.

- Every point the GEOLocate georeferencing service (geo-locate.org)
  returns when a country name is entered as country and locality,
  queried on 2026-10-11 for each country name of the three tables: 548
  points. GEOLocate also returns places that carry a country’s name. One
  such place, Niger State in Nigeria for “Niger”, lies inside another
  country more than 100 km from the queried one and is left out.

The Natural Earth admin-0 polygon centroids, computed on the sphere, and
label points (516) are added with `extension` `TRUE`. The province
centroids are the Natural Earth admin-1 label points.

### Land, countries and urban areas

The land, country and urban-area polygons are Natural Earth layers at
the scales the table above gives. All Natural Earth layers are in the
public domain; the Natural Earth terms of use say that “No permission is
needed to use Natural Earth.”

### Institutions

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

The institution table includes locations from Wikidata, Wikipedia,
GeoNames and Botanic Gardens Conservation International (BGCI). The
`source` column of `reference_points("institution")` identifies the
source of each point.

Wikidata (CC0, queried 2026-10-10) supplies coordinates for:

- Botanical gardens, natural history museums, zoos, public aquaria and
  herbaria, including items in subclasses of these categories.

- Museums whose main subject or field of work is a natural-history
  discipline, such as geology, paleontology, zoology or botany.

- Museums in Wikipedia’s English “List of natural history museums”,
  which supplies CoordinateCleaner’s Wikipedia entries, and its Arabic,
  Dutch, Esperanto, French, German and Portuguese counterparts.

The Wikipedia lists contain 2,331 entries (CC BY-SA 4.0, retrieved
2026-10-11). Entries are matched to Wikidata through their linked
articles. Entries without an article are matched when a single museum
item in the same country has the corresponding name and lies within 25
km of the named town.

After removing duplicate Wikidata items, these sources provide 7,810
points: 3,263 botanical gardens, 1,835 museums, 2,609 zoos and aquaria,
and 103 herbaria. None has zero coordinates.

Museums without their own Wikidata coordinates are located using the
place named in the Wikipedia entry. This is either the Wikidata location
of a linked town or university, checked against the entry’s country, or
a GeoNames populated place matching the named town (CC BY 4.0). This
adds 700 points, including 385 from the English list. Entries without a
town are omitted.

The three GeoNames locations in CoordinateCleaner’s table come from the
GeoNames country files (CC BY 4.0).

BGCI’s [GardenSearch map](https://tools.bgci.org/map.php), retrieved for
all countries on 2026-10-10, lists 3,765 gardens. Of these, 3,653 have
coordinates; removing one at zero coordinates leaves 3,652 points. These
are used under the [BGCI
terms](https://www.bgci.org/terms-and-conditions/).

Two further registries were downloaded in full on 2026-10-13:

- Index Herbariorum, the New York Botanical Garden’s herbarium registry,
  provides locations for 4,805 herbaria. The table adds the 1,062 for
  which GRSciColl lacks coordinates under the same herbarium code.

- The GBIF registry provides coordinates for 2,468 of its 3,639
  publishing organisations. All 2,468 are added.

The remaining institutions with coordinates in CoordinateCleaner’s table
are located using their name, city and country. An institution is
already represented if an entry matches its name, its full Index
Herbariorum name, or an alternative or collection name recorded by
GRSciColl.

Each remaining institution is looked up in this order:

1.  Wikidata, using its full name or the part before the first comma.

2.  OpenStreetMap through Nominatim, accepting a result that matches at
    least half the institution’s name words or lies within 25 km of
    CoordinateCleaner’s point.

3.  GeoNames, using the city listed by CoordinateCleaner or GRSciColl.

When several candidates are returned, the candidate nearest
CoordinateCleaner’s point is selected. Coordinates come from the
selected source.

If these searches find no location, the institution is considered
represented when an existing point lies within 25 km and matches at
least 60% of its name words. Otherwise, it is assigned to the populated
place mentioned in its name or, as a last resort, the populated place in
its country nearest CoordinateCleaner’s point. These entries have
`source = "CoordinateCleaner list"`; `master_source` records how they
were located.

### Genus habitats

The habitat tests `sea_nonmarine` and `land_marine` use genus
classifications from the Interim Register of Marine and Nonmarine Genera
(IRMNG), supplied as a Darwin Core archive dated 2026-10-06 under CC BY
4.0. IRMNG records marine, brackish, freshwater and terrestrial flags
for each name. Following the rule in
[`reference_habitat()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_habitat.md),
the package classifies 296,474 genera as nonmarine and 21,891 as
exclusively marine, with kingdom used to distinguish names.

The citation is: Rees, T. (compiler) (2026). *The Interim Register of
Marine and Nonmarine Genera*. Available from
[irmng.org](https://www.irmng.org) at VLIZ.

### Artificial hotspots

The Artificial Hotspot Occurrence Inventory (AHOI; [Park, Xie,
Thammavong, Tulaiha and Feng, 2023](https://doi.org/10.1111/jbi.14543))
identifies coordinates that recur most often in GBIF records and records
why they recur. The authors’ [Dryad
deposit](https://doi.org/10.5061/dryad.v41ns1s0p), released under CC0,
supplies 308 points with coordinates: 154 for plants, 51 for birds, 51
for insects and 52 for mammals.

CoordinateCleaner’s bundled `aohi` table contains 309 points. The two
datasets share 303 points; differences involve a few bird locations and
one plant latitude, recorded as 42.26° N in CoordinateCleaner and 42.20°
N in the deposit.

Scripts in the source repository’s `data-raw/` directory rebuild the
layers from their source datasets.

## How the reference data differ from CoordinateCleaner’s

The package’s reference points describe the same places as
[CoordinateCleaner](https://ropensci.github.io/CoordinateCleaner/)
3.0.1’s `countryref` and `institutions` tables, but they are not the
same tables. Counts as of 2026-10-13, the retrieval date of the last two
institution registries:

| gazetteer | CoordinateCleaner | OccurrenceCleaner |
|:---|:---|:---|
| capitals | 225 (one per ISO3 code) | 475: 232 Factbook capitals and 243 Natural Earth capitals, alternative capitals and dependent-territory capitals marked as extension |
| country centroids | 660 rows from the CIA World Factbook, thematicmapping.org and GEOLocate | 1,585: 1,069 from the same three sources (275 Factbook, 246 World Borders, 548 GEOLocate) and 516 Natural Earth polygon centroids and label points marked as extension |
| province centroids | 4,645 (older Natural Earth admin-1 label points) | 4,594 (Natural Earth 5.1.1 admin-1 label points) |
| institutions | 9,773 with coordinates (GRBio, Index Herbariorum, GBIF, BGCI, Wikipedia, GeoNames) | 23,895 (6,080 GRSciColl, without the five at zero coordinates, 7,810 Wikidata, 700 Wikipedia, 3,652 BGCI, 3 GeoNames, 1,062 Index Herbariorum, 2,468 GBIF registry, 2,120 for the rest of CoordinateCleaner’s list), of which 16,230 from CoordinateCleaner’s sources |

- **Capitals.** Of CoordinateCleaner’s 225 capital points, 221 match
  this package’s Factbook points when rounded to 0.01 degrees. Rounding
  shifts their positions by up to 523 m. The remaining four reflect
  Factbook entries that have since changed: Bujumbura to Gitega for
  Burundi; Buenos Aires from 58°40′ W to 58°22′ W, correcting a location
  27 km west of the city; Melekeok to Ngerulmud for Palau; and a 1.8 km
  coordinate adjustment for Rangoon.

  Natural Earth adds alternative and official capitals, including Cape
  Town and Bloemfontein alongside Pretoria, Sucre alongside La Paz,
  Naypyidaw alongside Yangon, and Dodoma alongside Dar es Salaam.
  Selecting `extension = FALSE` excludes these additions.

- **Country centroids.** Of CoordinateCleaner’s 660 points, 645 match
  this package’s points exactly. India, Italy and the United Kingdom use
  World Borders coordinates that changed in version 0.3. GEOLocate no
  longer returns three points for Macedonia or a point for Guinea
  located at sea at 10° W, 5° N. The remaining eight points lie between
  5 m and 68 km from the nearest point in this package.

  Natural Earth adds polygon centres, which lie a median of 30 km from
  CoordinateCleaner’s centroids and flag records georeferenced to those
  centres. Selecting `extension = FALSE` excludes these additions.

- **Province centroids.** CoordinateCleaner uses Natural Earth
  administrative label points: 4,566 of its 4,645 rows match codes and
  coordinates in releases 3.3.0, 4.0.0 or 4.1.0. This package uses
  release 5.1.1. All province points therefore carry
  `extension = FALSE`, since they come from the same source.

  Of CoordinateCleaner’s rows, 4,591 match this package’s points
  exactly. Of the remaining 54, 50 lie more than 10 km from any included
  point: 15 use coordinates Natural Earth has since changed, and 39
  match no tagged release.

- **Institutions.** This package represents 9,772 of CoordinateCleaner’s
  9,773 institutions, covering every entry with coordinates except one
  expert group listed in Antarctica. It matches 6,313 by name and
  another 329 to nearby points with overlapping name words. The
  remaining 3,130 are located through Wikidata (1,052), OpenStreetMap
  (646), the town listed by CoordinateCleaner or GRSciColl (684), or a
  town mentioned in the institution’s name (252). For 496 institutions,
  searches found no institution location, so the nearest town to
  CoordinateCleaner’s point is used.

  Coordinates differ because CoordinateCleaner geocoded nearly all its
  institutions independently. For example, it located 641 of its 712
  BGCI gardens from names and addresses; this package uses BGCI’s
  coordinates. CoordinateCleaner also located 398 Wikipedia museums
  manually, to 1 km precision.

  Some locations differ substantially. CoordinateCleaner places all
  Iranian university museums at one point in Isfahan and the Museo
  Marino of Boca del Río, Veracruz, in Venezuela. Across its institution
  points, 32% have a point in this package within 100 m, 73% within 1 km
  and 91% within 5 km.

  Additional Wikidata institutions and museums from Wikipedia’s other
  language editions carry `extension = TRUE`. Selecting
  `extension = FALSE` restricts the test to CoordinateCleaner’s sources.
  With CoordinateCleaner installed, its table can also be added at run
  time ([Custom reference points and
  polygons](https://gillescolling.com/OccurrenceCleaner/articles/gazetteers.html#an-extended-point-layer)).

The following example shows how the capital references affect flags for
records at alternative or official capitals:

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

The capital, country centroid and institution tables also contain points
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
the version of each layer. The printed object shows the short form;
[`flag_reference()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_reference.md)
returns the full label, which names every layer with its version,
snapshot date or page revision:

``` r

f <- flag_occurrences(x, tests = c("capital", "sea"), land_scale = 50)
f
#> <occ_flags> 2 records, 2 tests, reference OccurrenceCleaner 0.2.0, land 50
#>   species decimalLongitude decimalLatitude flags flagged_by
#> 1       a            16.37           48.21     8    capital
#> 2       a            16.45           48.21     8    capital
attr(f, "occ_layout_version")
#> [1] 4
```

The full reference label

``` r

flag_reference(f)
#> [1] "OccurrenceCleaner 0.2.0 (land 50; land_110 4.1.0, land_50 4.1.0, land_10 5.1.1, countries_50 5.1.1, urban_50 4.1.0, places_10 5.1.2, admin0_10 5.1.1, admin1_10 5.1.1, factbook factbook.json 144d6977b2b01ac1cbd220de754c0a005616760b, world_borders 0.3 (2008-07-30), geolocate 2026-10-11, institutions 2026-10-09, institutions_wikidata 2026-10-10, institutions_wikipedia en revision 1376233148; de revision 267938927; fr revision 240149609; nl revision 69876533; pt revision 71307420; ar revision 76691072; eo revision 9165115, institutions_geonames 2026-10-10, institutions_bgci 2026-10-10, institutions_index_herbariorum 2026-10-13, institutions_gbif_registry 2026-10-13, institutions_coordinatecleaner_list 3.0.1, aohi 2022-10-10, habitat 2026-10-06)"
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
