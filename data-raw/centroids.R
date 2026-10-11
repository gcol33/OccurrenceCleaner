# Build the country and province centroid gazetteer shipped in R/sysdata.rda.
#
# Country centroids come from the three sources CoordinateCleaner's
# `countryref` is compiled from, each taken from the source itself:
#   - CIA World Factbook "Geographic coordinates" (public domain), through the
#     factbook.json mirror of the Factbook country profiles (CC0 1.0);
#   - thematicmapping.org World Borders Dataset 0.3 label points (LON/LAT),
#     Bjorn Sandvik, CC BY-SA, through the GeoJSON conversion at
#     github.com/jeffaudi/world-borders-geojson (thematicmapping.org refused
#     connections on 2026-10-11);
#   - the GEOLocate georeferencing web service (geo-locate.org), queried with
#     each country name as country and locality, every point it returns.
# Province centroids are the Natural Earth admin-1 label points built by
# natural_earth.R. Natural Earth country polygon centroids and label points are
# kept as `extension` TRUE; an extension point at the coordinates of another
# row is dropped.
#
# Run from the package root after natural_earth.R:  Rscript data-raw/centroids.R

source("data-raw/utils.R")
source("data-raw/country_sources.R")
ne <- readRDS(file.path(cache, "natural_earth_layers.rds"))

# thematicmapping World Borders 0.3 label points
cen_tm <- data.frame(name = tm$NAME, adm0_a3 = tm_a3, code = tm$ISO3, type = "country",
                     method = "label point", lon = tm$LON, lat = tm$LAT, source = "thematicmapping",
                     key = paste0("tm:", tm$ISO3), extension = FALSE, stringsAsFactors = FALSE)

# CIA World Factbook "Geographic coordinates", every pair a profile gives.
cen_fb <- do.call(rbind, Map(function(j, gec) {
  p <- fb_dms(j$Geography$`Geographic coordinates`$text)
  if (is.null(p)) return(NULL)
  data.frame(name = fb_country(j, gec), adm0_a3 = NA_character_, code = gec, type = "country",
             method = "Factbook geographic coordinates", lon = p$lon, lat = p$lat,
             source = "CIA World Factbook", key = paste0("factbook:", gec), extension = FALSE,
             stringsAsFactors = FALSE)
}, fb_profiles, names(fb_profiles)))
cen_fb$adm0_a3 <- gec_a3(cen_fb$code, cen_fb$lon, cen_fb$lat)

# GEOLocate: every country name of the three tables (Natural Earth with its
# short, sort, alternative, formal, geounit and subunit names), as country and
# locality.
glc_dir <- file.path(cache, "geolocate")
dir.create(glc_dir, showWarnings = FALSE)
glc_base <- "https://www.geo-locate.org/webservices/geolocatesvcv2/glcwrap.aspx"
q <- unique(rbind(
  data.frame(query = a0$ADMIN, adm0_a3 = a0$ADM0_A3), data.frame(query = a0$NAME, adm0_a3 = a0$ADM0_A3),
  data.frame(query = a0$NAME_LONG, adm0_a3 = a0$ADM0_A3), data.frame(query = a0$NAME_SORT, adm0_a3 = a0$ADM0_A3),
  data.frame(query = a0$NAME_ALT, adm0_a3 = a0$ADM0_A3), data.frame(query = a0$FORMAL_EN, adm0_a3 = a0$ADM0_A3),
  data.frame(query = a0$GEOUNIT, adm0_a3 = a0$ADM0_A3), data.frame(query = a0$SUBUNIT, adm0_a3 = a0$ADM0_A3),
  data.frame(query = tm$NAME, adm0_a3 = tm_a3),
  data.frame(query = cen_fb$name, adm0_a3 = cen_fb$adm0_a3)))
q <- q[!duplicated(q$query) & !is.na(q$query) & nzchar(q$query), ]
glc_query <- function(nm) {
  f <- file.path(glc_dir, paste0(gsub("[^A-Za-z0-9]+", "_", nm), ".json"))
  if (!file.exists(f)) {
    e <- utils::URLencode(nm, reserved = TRUE)
    txt <- paste(readLines(paste0(glc_base, "?Country=", e, "&Locality=", e, "&fmt=geojson"),
                           warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    writeLines(txt, f, useBytes = TRUE)
    Sys.sleep(1)
  }
  f
}
glc_files <- vapply(q$query, glc_query, character(1))
glc_features <- function(f) {
  if (file.size(f) < 10) return(list())
  jsonlite::fromJSON(f, simplifyVector = FALSE)$features
}
cen_glc <- do.call(rbind, Map(function(f, nm, a3) {
  j <- list(features = glc_features(f))
  if (!length(j$features)) return(NULL)
  data.frame(name = nm, adm0_a3 = a3, code = NA_character_, type = "country",
             method = "GEOLocate country query",
             lon = vapply(j$features, function(ft) ft$geometry$coordinates[[1]], numeric(1)),
             lat = vapply(j$features, function(ft) ft$geometry$coordinates[[2]], numeric(1)),
             source = "GEOLocate", key = paste0("geolocate:", nm), extension = FALSE,
             stringsAsFactors = FALSE)
}, glc_files, q$query, q$adm0_a3))
cen_glc <- cen_glc[!duplicated(cen_glc[, c("lon", "lat")]), ]
# GEOLocate answers a country name with any place of that name. A point inside
# another country's polygon and more than 100 km from the queried country is
# such a place (the query "Niger" also returns Niger State, Nigeria) and is
# dropped. Points at sea are kept, as the centroids of island states lie at
# sea, and so are points near the queried country, as Natural Earth draws
# overseas departments inside their sovereign (Reunion is part of FRA).
glc_in <- in_country(cen_glc$lon, cen_glc$lat)
cen_glc$adm0_a3 <- ifelse(is.na(cen_glc$adm0_a3), glc_in, cen_glc$adm0_a3)
glc_other <- !is.na(glc_in) & glc_in != cen_glc$adm0_a3
own <- match(cen_glc$adm0_a3[glc_other], a0$ADM0_A3)
glc_km <- rep(Inf, length(own))
glc_km[!is.na(own)] <- as.numeric(st_distance(
  st_as_sf(cen_glc[glc_other, ][!is.na(own), ], coords = c("lon", "lat"), crs = 4326),
  a0_sf[own[!is.na(own)], ], by_element = TRUE)) / 1000
glc_other[glc_other] <- glc_km > 100
cat("GEOLocate points inside another country, dropped:", sum(glc_other), "\n")
print(data.frame(query = cen_glc$name, lon = cen_glc$lon, lat = cen_glc$lat, in_country = glc_in)[glc_other, ],
      row.names = FALSE)
cen_glc <- cen_glc[!glc_other, ]

# Natural Earth rows built by natural_earth.R.
cn <- ne$centroids
cn$source <- "Natural Earth"
cn$key <- paste0("ne:", cn$code)
cn$extension <- cn$type == "country"

centroids <- rbind(cen_fb, cen_tm, cen_glc, cn)
centroids <- centroids[is.finite(centroids$lon) & is.finite(centroids$lat), ]
centroids <- centroids[!duplicated(centroids[, c("source", "lon", "lat")]), ]
centroids <- centroids[order(centroids$extension), ]
centroids <- centroids[!(centroids$extension & duplicated(centroids[, c("lon", "lat")])), ]
centroids <- centroids[order(centroids$type, centroids$adm0_a3, centroids$source, centroids$code), ]
rownames(centroids) <- NULL

meta <- rbind(
  fb_meta, tm_meta,
  data.frame(layer = "geolocate", source = "GEOLocate web service", file = "geolocate/*.json",
             version = retrieved, url = paste0(glc_base, "?Country=<name>&Locality=<name>&fmt=geojson"),
             sha256 = digest::digest(paste(vapply(glc_files, sha256, character(1)), collapse = ""),
                                     algo = "sha256", serialize = FALSE),
             retrieved = retrieved, licence = "no terms stated by geo-locate.org", stringsAsFactors = FALSE))

saveRDS(list(centroids = centroids, meta = meta), file.path(cache, "centroids.rds"), compress = "xz")
cat("GEOLocate queries:", nrow(q), " answered:", sum(vapply(glc_files, function(f)
  length(glc_features(f)) > 0, logical(1))), "\n")
print(table(centroids$source, centroids$extension, centroids$type))
cat("country rows without adm0_a3:", sum(centroids$type == "country" & is.na(centroids$adm0_a3)), "\n")
