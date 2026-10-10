# Build the biodiversity-institution gazetteer from GBIF's Global Registry of
# Scientific Collections (GRSciColl) and from Wikidata. GRSciColl bulk export
# https://api.gbif.org/v1/grscicoll/institution/export?format=TSV
#
# GRSciColl is synchronised weekly with Index Herbariorum (masterSourceType
# "IH") and absorbed the Global Registry of Biodiversity Repositories (GRBio)
# in 2018. Only institutions with coordinates are kept, and of those only the
# ones the zero test would not flag (longitude or latitude exactly zero, or
# within 0.5 degrees of (0, 0)): such entries are geocoding failures, and
# keeping them would flag every zero-coordinate record as an institution too.
#
# Run from the package root:  Rscript data-raw/institutions.R

cache <- "data-raw/cache"
dir.create(cache, showWarnings = FALSE, recursive = TRUE)
retrieved <- "2026-10-09"
url <- "https://api.gbif.org/v1/grscicoll/institution/export?format=TSV"
tsv <- file.path(cache, "grscicoll_institutions.tsv")
if (!file.exists(tsv)) download.file(url, tsv, mode = "wb", quiet = TRUE)

d <- read.delim(tsv, quote = "", comment.char = "", na.strings = "", stringsAsFactors = FALSE,
                encoding = "UTF-8", check.names = FALSE)
lon <- suppressWarnings(as.numeric(d$longitude))
lat <- suppressWarnings(as.numeric(d$latitude))
valid <- is.finite(lon) & is.finite(lat) & lon >= -180 & lon <= 180 & lat >= -90 & lat <= 90
zero <- valid & (lon == 0 | lat == 0 | sqrt(lon^2 + lat^2) <= 0.5)
keep <- valid & !zero
institutions <- data.frame(key = d$key[keep], code = d$code[keep], name = d$name[keep],
                           country = d$country[keep], city = d$city[keep], type = d$type[keep],
                           active = d$active[keep] == "true", master_source = d$masterSourceType[keep],
                           lon = lon[keep], lat = lat[keep], stringsAsFactors = FALSE)
institutions$source <- "GRSciColl"
n_grscicoll <- nrow(institutions)

# Wikidata (CC0): botanical gardens (Q167346, arboreta are a subclass), natural
# history museums (Q1970365), zoos (Q43501), herbaria (Q181916) and public
# aquaria (Q2281788), every item that is an instance of the class or of a
# subclass and has a coordinate location (P625) on Earth. These cover the
# botanic gardens (BGCI), museums (Wikipedia) and zoos that CoordinateCleaner's
# table holds beside GRBio and Index Herbariorum, typed with the GRSciColl
# institution types. One query per class keeps
# each under the query service time limit.
#
# CoordinateCleaner's Wikipedia rows are the museums of Wikipedia's "List of
# natural history museums". The same list is read here through the Wikipedia
# API, and each linked article's Wikidata item that is a museum (Q33506), zoo,
# botanical garden, research institute (Q31855) or university (Q3918) is kept
# with its Wikidata coordinates, so the list decides which institutions and
# Wikidata (CC0) gives where they are.
wd_retrieved <- "2026-10-10"
ua <- "OccurrenceCleaner data-raw (https://github.com/gcol33/OccurrenceCleaner)"
wd_endpoint <- "https://query.wikidata.org/sparql"
wd_select <- paste0("SELECT ?item ?label ?coord ?iso2 ?cls WHERE { %s ?item wdt:P31/wdt:P279* ?cls . ",
                    "?item wdt:P625 ?coord . ",
                    "OPTIONAL { ?item wdt:P17 ?c . ?c wdt:P297 ?iso2 . } ",
                    "OPTIONAL { ?item rdfs:label ?label . FILTER(lang(?label) = \"en\") } }")
wd_fetch <- function(query, f) {
  if (!file.exists(f))
    download.file(paste0(wd_endpoint, "?query=", utils::URLencode(query, reserved = TRUE)), f, mode = "wb",
                  quiet = TRUE, headers = c(Accept = "text/csv", `User-Agent` = ua))
  x <- read.csv(f, stringsAsFactors = FALSE, na.strings = "", encoding = "UTF-8")
  x$cls <- sub("^http://www.wikidata.org/entity/", "", x$cls)
  x
}
wd_classes <- c(Q167346 = "BotanicalGarden", Q1970365 = "Museum", Q43501 = "ZooAquarium",
                Q181916 = "Herbarium", Q2281788 = "ZooAquarium")
wd_files <- character()
wd <- NULL
for (q in names(wd_classes)) {
  f <- file.path(cache, paste0("wikidata_", q, "_v2.csv"))
  x <- wd_fetch(sprintf(wd_select, paste0("VALUES ?cls { wd:", q, " }")), f)
  x$type <- wd_classes[[q]]
  wd <- rbind(wd, x)
  wd_files <- c(wd_files, f)
}

wp_title <- "List_of_natural_history_museums"
wp_file <- file.path(cache, "wikipedia_natural_history_museums_items.txt")
if (!file.exists(wp_file)) {
  items <- character(); cont <- ""
  repeat {
    f <- tempfile()
    download.file(paste0("https://en.wikipedia.org/w/api.php?action=query&format=json&titles=", wp_title,
                         "&generator=links&gplnamespace=0&gpllimit=max&prop=pageprops&ppprop=wikibase_item", cont),
                  f, quiet = TRUE, headers = c(`User-Agent` = ua))
    d <- jsonlite::fromJSON(f, simplifyVector = FALSE)
    items <- c(items, unlist(lapply(d$query$pages, function(p) p$pageprops$wikibase_item)))
    if (is.null(d$continue)) break
    cont <- paste0("&gplcontinue=", utils::URLencode(d$continue$gplcontinue, reserved = TRUE),
                   "&continue=", utils::URLencode(d$continue$continue, reserved = TRUE))
  }
  writeLines(sort(unique(items)), wp_file)
}
wp_items <- readLines(wp_file)
wp_classes <- c(Q33506 = "Museum", Q43501 = "ZooAquarium", Q167346 = "BotanicalGarden",
                Q31855 = "OtherTypeResearchInstitutionBiorepository", Q3918 = "UniversityCollege")
wp <- NULL
for (b in split(wp_items, ceiling(seq_along(wp_items) / 200))) {
  f <- file.path(cache, sprintf("wikidata_wplist_%s.csv", b[1]))
  values <- paste0("VALUES ?item { ", paste0("wd:", b, collapse = " "), " } VALUES ?cls { ",
                   paste0("wd:", names(wp_classes), collapse = " "), " }")
  wp <- rbind(wp, wd_fetch(sprintf(wd_select, values), f))
  wd_files <- c(wd_files, f)
}
wp$type <- unname(wp_classes[wp$cls])
wp <- wp[order(match(wp$cls, names(wp_classes))), ]
wp <- wp[!duplicated(wp$item), ]
n_wplist <- length(unique(wp$item))
wd <- rbind(wd, wp)
earth <- grepl("^Point\\(", wd$coord)
xy <- do.call(rbind, strsplit(sub("^Point\\(([^ ]+) ([^)]+)\\)$", "\\1 \\2", wd$coord[earth]), " ", fixed = TRUE))
wd <- wd[earth, ]
wd$lon <- as.numeric(xy[, 1])
wd$lat <- as.numeric(xy[, 2])
wd$key <- sub("^http://www.wikidata.org/entity/", "", wd$item)
wd_valid <- is.finite(wd$lon) & is.finite(wd$lat) & abs(wd$lon) <= 180 & abs(wd$lat) <= 90
wd_zero <- wd_valid & (wd$lon == 0 | wd$lat == 0 | sqrt(wd$lon^2 + wd$lat^2) <= 0.5)
wd <- wd[wd_valid & !wd_zero, ]
wd <- wd[!duplicated(wd[, c("key", "lon", "lat")]), ]
wikidata <- data.frame(key = wd$key, code = NA_character_, name = wd$label, country = wd$iso2, city = NA_character_,
                       type = wd$type, active = NA, master_source = NA_character_, lon = wd$lon, lat = wd$lat,
                       source = "Wikidata", stringsAsFactors = FALSE)

# GeoNames (CC BY 4.0, https://www.geonames.org): the three places
# CoordinateCleaner's table attributes to GeoNames, by GeoNames id from the
# country dumps of https://download.geonames.org/export/dump/.
gn_ids <- c(`10280522` = "ZooAquarium", `10125927` = "BotanicalGarden", `10375777` = "Museum")
gn_files <- character()
gn <- NULL
for (cc in c("MC", "PT", "IT")) {
  z <- file.path(cache, paste0("geonames_", cc, ".zip"))
  if (!file.exists(z)) download.file(paste0("https://download.geonames.org/export/dump/", cc, ".zip"), z,
                                     mode = "wb", quiet = TRUE)
  gn_files <- c(gn_files, z)
  x <- read.delim(unz(z, paste0(cc, ".txt")), header = FALSE, quote = "", comment.char = "", na.strings = "",
                  colClasses = "character", encoding = "UTF-8")
  gn <- rbind(gn, x[x$V1 %in% names(gn_ids), c(1, 2, 5, 6, 9)])
}
stopifnot(nrow(gn) == length(gn_ids))
geonames <- data.frame(key = paste0("geonames:", gn$V1), code = NA_character_, name = gn$V2, country = gn$V9,
                       city = NA_character_, type = unname(gn_ids[gn$V1]), active = NA, master_source = NA_character_,
                       lon = as.numeric(gn$V6), lat = as.numeric(gn$V5), source = "GeoNames",
                       stringsAsFactors = FALSE)
institutions <- rbind(institutions, wikidata, geonames)
institutions <- institutions[order(institutions$country, institutions$name), ]
rownames(institutions) <- NULL

sha256 <- function(path) {
  if (requireNamespace("digest", quietly = TRUE)) return(digest::digest(path, algo = "sha256", file = TRUE))
  tolower(strsplit(system2("certutil", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)[2], " ")[[1]][1])
}
meta <- rbind(
  data.frame(layer = "institutions", source = "GBIF GRSciColl", file = basename(tsv),
             version = retrieved, url = url, sha256 = sha256(tsv), retrieved = retrieved,
             licence = "see dev_notes/reference_data.md", stringsAsFactors = FALSE),
  data.frame(layer = "institutions_wikidata", source = "Wikidata",
             file = paste(basename(wd_files), collapse = ", "), version = wd_retrieved, url = wd_endpoint,
             sha256 = paste(vapply(wd_files, sha256, character(1)), collapse = ", "), retrieved = wd_retrieved,
             licence = "CC0 1.0", stringsAsFactors = FALSE),
  data.frame(layer = "institutions_geonames", source = "GeoNames",
             file = paste(basename(gn_files), collapse = ", "), version = wd_retrieved,
             url = "https://download.geonames.org/export/dump/",
             sha256 = paste(vapply(gn_files, sha256, character(1)), collapse = ", "), retrieved = wd_retrieved,
             licence = "CC BY 4.0", stringsAsFactors = FALSE))
saveRDS(list(institutions = institutions, meta = meta), file.path(cache, "institutions.rds"), compress = "xz")
cat("GRSciColl institutions with coordinates:", sum(valid), "of", nrow(d), "- dropped as zero coordinates:",
    sum(zero), "- kept:", n_grscicoll, "\n")
print(d[zero, c("code", "name", "country", "longitude", "latitude")])
cat("Wikidata points:", sum(earth), "on Earth, dropped as zero coordinates:", sum(wd_zero), "- kept:",
    nrow(wikidata), "- Wikipedia list items with coordinates:", n_wplist, "\n")
print(geonames)
print(table(institutions$source, institutions$type, useNA = "ifany"))
print(table(institutions$master_source))
cat("xz size KB:", file.size(file.path(cache, "institutions.rds")) / 1024, "\n")
