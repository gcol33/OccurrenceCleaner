# Fetch the Overpass museum tiles of the given longitude columns into the
# cache, so that several processes share the server's slots.
#
# Run from the package root:  Rscript data-raw/osm_prefetch.R 30 60 90

ua <- "OccurrenceCleaner data-raw (https://github.com/gcol33/OccurrenceCleaner)"
cache <- "data-raw/cache"
source("data-raw/overpass.R")
for (w in as.numeric(commandArgs(trailingOnly = TRUE))) {
  for (s in seq(-90, 60, 30)) osm_fetch("tourism=museum", s, w, s + 30, w + 30)
}
