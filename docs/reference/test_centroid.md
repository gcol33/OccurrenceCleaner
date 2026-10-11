# Test: country and province centroids

Flags records within 1 km of a country or province centroid (WGS84
geodesic distance, closed ball), where records georeferenced to a
country or province name end up. The default gazetteer holds the country
points of the three sources CoordinateCleaner's table is compiled from,
each taken from the source: the "Geographic coordinates" of the CIA
World Factbook (public domain; 275 points, through the factbook.json
mirror retrieved 2026-10-11), the label points of the
thematicmapping.org World Borders Dataset 0.3 (Bjorn Sandvik, CC BY-SA;
246 points), and every point the GEOLocate georeferencing service
(geo-locate.org) returns for a country name, queried 2026-10-11 (548
points; a place of that name more than 100 km away inside another
country is left out). Province centroids are the Natural Earth 5.1.1
admin-1 label points (4,594), the current release of the layer
CoordinateCleaner's province centroids come from. The column `extension`
marks the 516 Natural Earth country polygon centroids and label points,
which CoordinateCleaner's table does not hold; passing the points with
`extension` FALSE as `gazetteers = list(centroid = ...)` leaves them
out.

## Fields

`lon`, `lat`.

## Buffer

`buffers = list(centroid = 1000)`, in metres.

## CoordinateCleaner

Equivalent to `cc_cen()` with `test = "both"`. Its 72-gon buffer edge
lies within 0.95 m of the 1 km circle. Of its 660 country centroids, 645
are points of the default gazetteer at distance 0. Of the other 15,
India, Italy and the United Kingdom hold World Borders values that
version 0.3 of the dataset changed; three GEOLocate points for Macedonia
and one for Guinea, at sea at 10 W 5 N, are not returned by GEOLocate
today; eight (Aland, Caribbean Netherlands, DR Congo, Kuwait,
Martinique, Monaco, Saint Martin, San Marino) lie 5 m to 68 km from a
default point. Its province centroids are the admin-1 label points of
older Natural Earth releases (4,566 of 4,645 rows match release 3.3.0,
4.0.0 or 4.1.0 exactly); 4,591 are default points at distance 0, and 50
lie more than 10 km from any, where Natural Earth has since changed the
unit or the row matches no tagged release.

## Custom gazetteer

`gazetteers = list(centroid = points)`, a data frame of longitude and
latitude; see
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md).

## See also

[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md),
[`flag_tests()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_tests.md),
[`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md)

Other tests:
[`test_age_equal`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_equal.md),
[`test_age_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_outlier.md),
[`test_age_range_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_age_range_outlier.md),
[`test_aohi`](https://gillescolling.com/OccurrenceCleaner/reference/test_aohi.md),
[`test_basis`](https://gillescolling.com/OccurrenceCleaner/reference/test_basis.md),
[`test_capital`](https://gillescolling.com/OccurrenceCleaner/reference/test_capital.md),
[`test_country_mismatch`](https://gillescolling.com/OccurrenceCleaner/reference/test_country_mismatch.md),
[`test_dataset_ddmm`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_ddmm.md),
[`test_dataset_rounded`](https://gillescolling.com/OccurrenceCleaner/reference/test_dataset_rounded.md),
[`test_duplicate`](https://gillescolling.com/OccurrenceCleaner/reference/test_duplicate.md),
[`test_equal`](https://gillescolling.com/OccurrenceCleaner/reference/test_equal.md),
[`test_establishment`](https://gillescolling.com/OccurrenceCleaner/reference/test_establishment.md),
[`test_gbif_headquarters`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_headquarters.md),
[`test_gbif_issue`](https://gillescolling.com/OccurrenceCleaner/reference/test_gbif_issue.md),
[`test_habitat`](https://gillescolling.com/OccurrenceCleaner/reference/test_habitat.md),
[`test_institution`](https://gillescolling.com/OccurrenceCleaner/reference/test_institution.md),
[`test_invalid`](https://gillescolling.com/OccurrenceCleaner/reference/test_invalid.md),
[`test_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_outlier.md),
[`test_range`](https://gillescolling.com/OccurrenceCleaner/reference/test_range.md),
[`test_sea`](https://gillescolling.com/OccurrenceCleaner/reference/test_sea.md),
[`test_spatiotemporal_outlier`](https://gillescolling.com/OccurrenceCleaner/reference/test_spatiotemporal_outlier.md),
[`test_urban`](https://gillescolling.com/OccurrenceCleaner/reference/test_urban.md),
[`test_zero`](https://gillescolling.com/OccurrenceCleaner/reference/test_zero.md)

## Examples

``` r
x <- data.frame(decimalLongitude = c(14.1307, 10), decimalLatitude = c(47.5857, 50))
flag_occurrences(x, tests = "centroid")$flag_centroid
g <- reference_points("centroid")
flag_occurrences(x, tests = "centroid",
                 gazetteers = list(centroid = g[!g$extension, ]))$flag_centroid
```
