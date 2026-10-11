# Build the capital gazetteer shipped in R/sysdata.rda.
#
# CoordinateCleaner's `countryref` capitals are the CIA World Factbook capital
# "geographic coordinates" rounded to 0.01 degree. Here they are taken from the
# Factbook itself (country_sources.R), unrounded: one point per profile, named
# after the first capital the profile lists (Akrotiri and Dhekelia share one). Natural Earth populated places of
# the classes admin-0 capital, alternative capital and admin-0 region capital
# (natural_earth.R) are kept as `extension` TRUE; an extension point at the
# coordinates of another row is dropped.
#
# Run from the package root after natural_earth.R:  Rscript data-raw/capitals.R

source("data-raw/utils.R")
source("data-raw/country_sources.R")
ne <- readRDS(file.path(cache, "natural_earth_layers.rds"))

cap_fb <- do.call(rbind, Map(function(j, gec) {
  cap <- j$Government$Capital
  p <- fb_dms(cap$`geographic coordinates`$text)
  if (is.null(p)) return(NULL)
  data.frame(name = trimws(sub("[(;,].*", "", fb_text(cap$name$text))), country = fb_country(j, gec),
             adm0_a3 = NA_character_, iso_a2 = NA_character_, class = "Factbook capital",
             lon = p$lon, lat = p$lat, source = "CIA World Factbook", key = paste0("factbook:", gec),
             extension = FALSE, stringsAsFactors = FALSE)
}, fb_profiles, names(fb_profiles)))
cap_fb$adm0_a3 <- gec_a3(sub("^factbook:", "", cap_fb$key), cap_fb$lon, cap_fb$lat)
iso2 <- setNames(a0$ISO_A2_EH, a0$ADM0_A3)
cap_fb$iso_a2 <- unname(iso2[cap_fb$adm0_a3])
cap_fb$iso_a2[cap_fb$iso_a2 %in% "-99"] <- NA

cap_ne <- ne$capitals
cap_ne$source <- "Natural Earth"
cap_ne$key <- paste0("ne:", cap_ne$adm0_a3, ":", cap_ne$name)
cap_ne$extension <- TRUE

capitals <- rbind(cap_fb, cap_ne)
capitals <- capitals[!duplicated(capitals[, c("source", "lon", "lat")]), ]
capitals <- capitals[order(capitals$extension), ]
capitals <- capitals[!(capitals$extension & duplicated(capitals[, c("lon", "lat")])), ]
capitals <- capitals[order(capitals$adm0_a3, capitals$source, capitals$name), ]
rownames(capitals) <- NULL

saveRDS(list(capitals = capitals, meta = fb_meta), file.path(cache, "capitals.rds"), compress = "xz")
print(table(capitals$source, capitals$extension))
cat("rows without adm0_a3:", sum(is.na(capitals$adm0_a3)), "\n")
