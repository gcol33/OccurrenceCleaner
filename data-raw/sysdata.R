# Assemble R/sysdata.rda from the layers built by natural_earth.R,
# institutions.R and aohi.R. The 1:10m land layer is not bundled (2.3 MB compressed); it is
# downloaded on demand, so only its metadata row is kept here.
#
# Run from the package root:  Rscript data-raw/sysdata.R

ne <- readRDS("data-raw/cache/natural_earth_layers.rds")
inst <- readRDS("data-raw/cache/institutions.rds")
aohi <- readRDS("data-raw/cache/aohi.rds")

ref_meta <- rbind(ne$meta, inst$meta, aohi$meta)
rownames(ref_meta) <- NULL

ref_land_110 <- ne$land_110
ref_land_50 <- ne$land_50
ref_countries_50 <- ne$countries_50
ref_urban_50 <- ne$urban_50
ref_capitals <- ne$capitals
ref_centroids <- ne$centroids
ref_institutions <- inst$institutions
ref_aohi <- aohi$aohi

save(ref_meta, ref_land_110, ref_land_50, ref_countries_50, ref_urban_50, ref_capitals,
     ref_centroids, ref_institutions, ref_aohi, file = "R/sysdata.rda", compress = "xz", version = 2)
cat("R/sysdata.rda:", round(file.size("R/sysdata.rda") / 1024), "KB\n")
