# Helpers sourced by the build scripts in data-raw/.

sha256 <- function(path) digest::digest(path, algo = "sha256", file = TRUE)

# Download `url` to `file` unless it is already there; returns `file`.
download_once <- function(url, file) {
  if (!file.exists(file)) download.file(url, file, mode = "wb", quiet = TRUE)
  file
}
