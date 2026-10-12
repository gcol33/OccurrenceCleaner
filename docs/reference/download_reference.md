# Download the 1:10 million land layer

The 1:10 million Natural Earth land polygons (2.3 MB compressed) are not
bundled with the package. This fetches the pinned zip from Natural
Earth, verifies its SHA-256 against
[`reference_info()`](https://gillescolling.com/OccurrenceCleaner/reference/reference_info.md),
converts it and stores the result in the user cache directory
(`tools::R_user_dir("OccurrenceCleaner", "cache")`).
[`flag_occurrences()`](https://gillescolling.com/OccurrenceCleaner/reference/flag_occurrences.md)
calls it when `land_scale = 10` is requested and the layer is not cached
yet.

## Usage

``` r
download_reference(
  layer = "land_10",
  cache_dir = tools::R_user_dir("OccurrenceCleaner", "cache"),
  quiet = FALSE
)
```

## Arguments

- layer:

  Layer to download; only `"land_10"` is not bundled.

- cache_dir:

  Directory for the converted layer.

- quiet:

  Suppress the download message.

## Value

The path of the cached layer, invisibly.

## Examples

``` r
if (interactive()) {
  download_reference()
  x <- data.frame(decimalLongitude = c(12.58, -30), decimalLatitude = c(55.67, 40))
  flag_occurrences(x, tests = "sea", land_scale = 10)$flag_sea
}
```
