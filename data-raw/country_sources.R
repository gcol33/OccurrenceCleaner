# Country sources shared by centroids.R and capitals.R: the Natural Earth
# admin-0 polygons, the thematicmapping.org World Borders Dataset 0.3 and the
# CIA World Factbook country profiles, with the mapping of their codes to
# Natural Earth's ADM0_A3.
#
# Sourced after utils.R, from the package root, after natural_earth.R has
# filled data-raw/cache.

suppressMessages(library(sf))
cache <- "data-raw/cache"
retrieved <- "2026-10-11"

d0 <- file.path(tempdir(), "admin0_10")
unzip(file.path(cache, "ne_10m_admin_0_countries.zip"), exdir = d0)
a0_sf <- st_make_valid(st_read(list.files(d0, "[.]shp$", full.names = TRUE), quiet = TRUE))
a0 <- st_drop_geometry(a0_sf)
fips_a3 <- setNames(a0$ADM0_A3, a0$FIPS_10)[a0$FIPS_10 != "-99"]
# Natural Earth country whose polygon holds each point (NA at sea).
in_country <- function(lon, lat) {
  if (!length(lon)) return(character())
  hit <- st_intersects(st_as_sf(data.frame(lon = lon, lat = lat), coords = c("lon", "lat"), crs = 4326), a0_sf)
  vapply(hit, function(i) if (length(i)) a0$ADM0_A3[i[1]] else NA_character_, character(1))
}

# thematicmapping.org World Borders Dataset 0.3, Bjorn Sandvik, CC BY-SA,
# through the GeoJSON conversion at github.com/jeffaudi/world-borders-geojson
# (thematicmapping.org refused connections on 2026-10-11).
tm_commit <- "8875a24e51da04da23d51c31808fa01339f9b7a8"
tm_url <- paste0("https://raw.githubusercontent.com/jeffaudi/world-borders-geojson/", tm_commit,
                 "/TM_WORLD_BORDERS-0.3/geojson/WORLD.json")
tm_file <- download_once(tm_url, file.path(cache, "tm_world_borders_0.3.json"))
tm <- jsonlite::fromJSON(tm_file, simplifyVector = TRUE)$features$properties
tm_a3 <- ifelse(tm$ISO3 %in% a0$ADM0_A3, tm$ISO3, in_country(tm$LON, tm$LAT))
tm_a3 <- ifelse(is.na(tm_a3), tm$ISO3, tm_a3)
tm_meta <- data.frame(layer = "world_borders", source = "thematicmapping.org World Borders Dataset",
                      file = basename(tm_file), version = "0.3 (2008-07-30)", url = tm_url,
                      sha256 = sha256(tm_file), retrieved = retrieved,
                      licence = "CC BY-SA, Bjorn Sandvik, thematicmapping.org", stringsAsFactors = FALSE)

# CIA World Factbook (public domain), factbook.json mirror (CC0 1.0); one
# profile per Factbook (GEC) code, oceans and the world profile left out.
fb_commit <- "144d6977b2b01ac1cbd220de754c0a005616760b"
fb_url <- paste0("https://github.com/factbook/factbook.json/archive/", fb_commit, ".zip")
fb_file <- download_once(fb_url, file.path(cache, "factbook_json.zip"))
fb_files <- utils::unzip(fb_file, list = TRUE)$Name
fb_files <- fb_files[grepl("/[a-z-]+/[a-z0-9]{2}[.]json$", fb_files) & !grepl("/(oceans|world)/", fb_files)]
fb_dir <- file.path(tempdir(), "factbook")
utils::unzip(fb_file, files = fb_files, exdir = fb_dir)
fb_profiles <- setNames(lapply(file.path(fb_dir, fb_files), jsonlite::fromJSON, simplifyVector = FALSE),
                        toupper(sub("[.]json$", "", basename(fb_files))))
fb_meta <- data.frame(layer = "factbook", source = "CIA World Factbook (factbook.json)", file = basename(fb_file),
                      version = paste("factbook.json", fb_commit), url = fb_url, sha256 = sha256(fb_file),
                      retrieved = retrieved, licence = "public domain (mirror CC0 1.0)", stringsAsFactors = FALSE)

# Factbook text with its HTML entities and tags resolved.
fb_text <- function(x) xml2::xml_text(xml2::read_html(paste0("<p>", x, "</p>")))
# Every "47 20 N, 13 20 E" pair of a Factbook text, as decimal degrees.
fb_dms <- function(txt) {
  dms <- "([0-9]+) ([0-9]+) ([NS]), ([0-9]+) ([0-9]+) ([EW])"
  if (is.null(txt)) return(NULL)
  m <- regmatches(txt, gregexpr(dms, txt))[[1]]
  if (!length(m)) return(NULL)
  p <- do.call(rbind, regmatches(m, regexec(dms, m)))
  data.frame(lon = (as.numeric(p[, 5]) + as.numeric(p[, 6]) / 60) * ifelse(p[, 7] == "W", -1, 1),
             lat = (as.numeric(p[, 2]) + as.numeric(p[, 3]) / 60) * ifelse(p[, 4] == "S", -1, 1))
}
# Country name of a profile: conventional short form, else long form, else the
# GEC code.
fb_country <- function(j, gec) {
  nm <- j$Government$`Country name`$`conventional short form`$text
  if (is.null(nm) || nm == "none") nm <- j$Government$`Country name`$`conventional long form`$text
  if (is.null(nm) || nm == "none") nm <- gec
  trimws(sub("[(].*", "", fb_text(nm)))
}
# ADM0_A3 of a Factbook code: Natural Earth's FIPS code, else the
# thematicmapping FIPS/ISO3 pair, else the Natural Earth country holding the
# point.
tm_fips_a3 <- setNames(tm_a3, tm$FIPS)
gec_a3 <- function(gec, lon, lat) {
  a3 <- unname(fips_a3[gec])
  miss <- is.na(a3)
  a3[miss] <- unname(tm_fips_a3[gec[miss]])
  miss <- is.na(a3)
  a3[miss] <- in_country(lon[miss], lat[miss])
  a3
}
