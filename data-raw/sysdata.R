# Assemble R/sysdata.rda from the layers built by natural_earth.R, capitals.R,
# centroids.R, institutions.R, aohi.R and habitat.R. The 1:10m land layer is
# not bundled (2.3 MB compressed); it is downloaded on demand, so only its
# metadata row is kept here.
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

ref_land_110 <- ne$land_110
ref_land_50 <- ne$land_50
ref_countries_50 <- ne$countries_50
ref_urban_50 <- ne$urban_50
ref_capitals <- cap$capitals
ref_centroids <- cen$centroids
ref_institutions <- inst$institutions
ref_aohi <- aohi$aohi
ref_habitat <- hab$habitat

save(ref_meta, ref_land_110, ref_land_50, ref_countries_50, ref_urban_50, ref_capitals,
     ref_centroids, ref_institutions, ref_aohi, ref_habitat, file = "R/sysdata.rda", compress = "xz",
     version = 2)
cat("R/sysdata.rda:", round(file.size("R/sysdata.rda") / 1024), "KB\n")
