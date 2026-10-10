# Build the biodiversity-institution gazetteer from GBIF's Global Registry of
# Scientific Collections (GRSciColl), bulk export endpoint
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
institutions <- institutions[order(institutions$country, institutions$name), ]
rownames(institutions) <- NULL

sha256 <- function(path) {
  if (requireNamespace("digest", quietly = TRUE)) return(digest::digest(path, algo = "sha256", file = TRUE))
  tolower(strsplit(system2("certutil", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)[2], " ")[[1]][1])
}
meta <- data.frame(layer = "institutions", source = "GBIF GRSciColl", file = basename(tsv),
                   version = retrieved, url = url, sha256 = sha256(tsv), retrieved = retrieved,
                   licence = "see dev_notes/reference_data.md", stringsAsFactors = FALSE)
saveRDS(list(institutions = institutions, meta = meta), file.path(cache, "institutions.rds"), compress = "xz")
cat("institutions with coordinates:", sum(valid), "of", nrow(d), "- dropped as zero coordinates:",
    sum(zero), "- kept:", nrow(institutions), "\n")
print(d[zero, c("code", "name", "country", "longitude", "latitude")])
print(table(institutions$master_source))
cat("xz size KB:", file.size(file.path(cache, "institutions.rds")) / 1024, "\n")
