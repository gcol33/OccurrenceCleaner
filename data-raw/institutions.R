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
wd_retrieved <- "2026-10-10"
wd_classes <- c(Q167346 = "BotanicalGarden", Q1970365 = "Museum", Q43501 = "ZooAquarium",
                Q181916 = "Herbarium", Q2281788 = "ZooAquarium")
wd_endpoint <- "https://query.wikidata.org/sparql"
wd_files <- character()
for (q in names(wd_classes)) {
  f <- file.path(cache, paste0("wikidata_", q, ".csv"))
  if (!file.exists(f)) {
    query <- paste0(
      "SELECT ?item ?label ?coord ?iso2 WHERE { ?item wdt:P31/wdt:P279* wd:", q, " . ",
      "?item wdt:P625 ?coord . ",
      "OPTIONAL { ?item wdt:P17 ?c . ?c wdt:P297 ?iso2 . } ",
      "OPTIONAL { ?item rdfs:label ?label . FILTER(lang(?label) = \"en\") } }")
    download.file(paste0(wd_endpoint, "?query=", utils::URLencode(query, reserved = TRUE)), f, mode = "wb",
                  quiet = TRUE, headers = c(Accept = "text/csv",
                                            `User-Agent` = "OccurrenceCleaner data-raw (https://github.com/gcol33/OccurrenceCleaner)"))
  }
  wd_files <- c(wd_files, f)
}
wd <- do.call(rbind, Map(function(f, q) {
  x <- read.csv(f, stringsAsFactors = FALSE, na.strings = "", encoding = "UTF-8")
  x$type <- wd_classes[[q]]
  x
}, wd_files, names(wd_classes)))
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
institutions <- rbind(institutions, wikidata)
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
             licence = "CC0 1.0", stringsAsFactors = FALSE))
saveRDS(list(institutions = institutions, meta = meta), file.path(cache, "institutions.rds"), compress = "xz")
cat("GRSciColl institutions with coordinates:", sum(valid), "of", nrow(d), "- dropped as zero coordinates:",
    sum(zero), "- kept:", n_grscicoll, "\n")
print(d[zero, c("code", "name", "country", "longitude", "latitude")])
cat("Wikidata points:", sum(earth), "on Earth, dropped as zero coordinates:", sum(wd_zero), "- kept:",
    nrow(wikidata), "\n")
print(table(institutions$source, institutions$type, useNA = "ifany"))
print(table(institutions$master_source))
cat("xz size KB:", file.size(file.path(cache, "institutions.rds")) / 1024, "\n")
