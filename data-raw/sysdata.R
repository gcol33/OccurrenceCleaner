# Assemble R/sysdata.rda from the layers built by natural_earth.R, capitals.R,
# centroids.R, institutions.R, aohi.R and habitat.R. Polygon coordinates are
# stored as successive differences wrapped to 32 bits (unpack_rings() in
# R/reference.R restores them).
#
# Run from the package root:  Rscript data-raw/sysdata.R

ne <- readRDS("data-raw/cache/natural_earth_layers.rds")
cap <- readRDS("data-raw/cache/capitals.rds")
cen <- readRDS("data-raw/cache/centroids.rds")
inst <- readRDS("data-raw/cache/institutions.rds")
aohi <- readRDS("data-raw/cache/aohi.rds")
hab <- readRDS("data-raw/cache/habitat.rds")

# A source used by several layers (the Factbook) has one row.
ref_meta <- rbind(ne$meta, cap$meta, cen$meta, inst$meta, aohi$meta, hab$meta)
stopifnot(!anyDuplicated(ref_meta[!duplicated(ref_meta), "layer"]))
ref_meta <- ref_meta[!duplicated(ref_meta), ]
rownames(ref_meta) <- NULL

pack_rings <- function(layer) {
  wrap <- function(v) {
    d <- c(as.double(v[1]), diff(as.double(v)))
    as.integer((d + 2^31) %% 2^32 - 2^31)
  }
  layer$x <- wrap(layer$x)
  layer$y <- wrap(layer$y)
  layer
}

ref_land_110 <- pack_rings(ne$land_110)
ref_land_50 <- pack_rings(ne$land_50)
ref_land_10 <- pack_rings(ne$land_10)
ref_countries_50 <- pack_rings(ne$countries_50)
ref_urban_50 <- pack_rings(ne$urban_50)
ref_capitals <- cap$capitals
ref_centroids <- cen$centroids
ref_institutions <- inst$institutions
ref_aohi <- aohi$aohi
ref_habitat <- hab$habitat

save(ref_meta, ref_land_110, ref_land_50, ref_land_10, ref_countries_50, ref_urban_50, ref_capitals,
     ref_centroids, ref_institutions, ref_aohi, ref_habitat, file = "R/sysdata.rda", compress = "xz",
     version = 2)
# The packed layers restore exactly.
source("R/reference.R", local = TRUE)
for (k in c("land_110", "land_50", "land_10", "countries_50", "urban_50"))
  stopifnot(identical(unpack_rings(get(paste0("ref_", k)))[c("x", "y")], ne[[k]][c("x", "y")]))
cat("R/sysdata.rda:", round(file.size("R/sysdata.rda") / 1024), "KB\n")
