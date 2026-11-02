# Helpers sourced by the build scripts in data-raw/.

sha256 <- function(path) digest::digest(path, algo = "sha256", file = TRUE)

# Great-circle distance in km from (lon, lat) to each of (x, y), haversine on
# the mean Earth radius.
km_to <- function(lon, lat, x, y) 6371.0088 * 2 * asin(sqrt(sin((y - lat) * pi / 360)^2 +
  cos(lat * pi / 180) * cos(y * pi / 180) * sin((x - lon) * pi / 360)^2))

# Download `url` to `file` unless it is already there; returns `file`.
download_once <- function(url, file) {
  if (!file.exists(file)) download.file(url, file, mode = "wb", quiet = TRUE)
  file
}
