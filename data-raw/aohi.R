# Build the Artificial Hotspot Occurrence Inventory (AHOI) gazetteer from the
# original deposit of Park, Xie, Thammavong, Tulaiha & Feng (2023), Journal of
# Biogeography 50:441-449, doi:10.1111/jbi.14543. The data are on Dryad,
# doi:10.5061/dryad.v41ns1s0p (CC0), mirrored on Zenodo record 7268229, from
# which the files are fetched (the Dryad download endpoint refuses scripts).
#
# One CSV per taxon: the most recurrent coordinates in GBIF plant, bird,
# insect and mammal records, with the reason each point recurs and whether it
# marks a real observation site (determination TRUE) or an artificial
# aggregate of records (FALSE). Rows without coordinates are
# dropped.
#
# Run from the package root:  Rscript data-raw/aohi.R

source("data-raw/utils.R")
cache <-"data-raw/cache/aohi"
dir.create(cache, showWarnings = FALSE, recursive = TRUE)
retrieved <- "2026-10-10"
base <- "https://zenodo.org/api/records/7268229/files/"
files <- c(Aves = "birds_20221010.csv", Insecta = "insects_20221010.csv",
           Mammalia = "mammals_20221010.csv", Plantae = "plants_20221010.csv")
md5 <- c(Aves = "3c0ec069dcc4929702371ef913ccb4fa", Insecta = "c5304cccc8dceb3beff98300b56fa985",
         Mammalia = "81d665f27757313af8ce1dc8f7045a54", Plantae = "60105fce9a2401126f4459f2a2997757")

parts <- lapply(names(files), function(taxon) {
  path <- file.path(cache, files[[taxon]])
  if (!file.exists(path)) download.file(paste0(base, files[[taxon]], "/content"), path, mode = "wb", quiet = TRUE)
  got <- unname(tools::md5sum(path))
  if (!identical(got, md5[[taxon]])) stop(files[[taxon]], " has MD5 ", got, ", expected ", md5[[taxon]])
  # The files mix encodings: some text is UTF-8, some Mac Roman (where byte 0xCA
  # is a non-breaking space). Each string is decoded on its own.
  d <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, encoding = "bytes")
  text <- function(v) {
    v <- as.character(v)
    utf8 <- validUTF8(v)
    out <- ifelse(utf8, v, iconv(v, "macintosh", "UTF-8"))
    Encoding(out) <- "UTF-8"
    trimws(gsub("[[:space:]\\x{00a0}]+", " ", out, perl = TRUE))
  }
  lon <- suppressWarnings(as.numeric(d$decimal_longitude))
  lat <- suppressWarnings(as.numeric(d$decimal_latitude))
  ok <- is.finite(lon) & is.finite(lat)
  data.frame(id = paste0(taxon, "_", d$ID[ok]), taxon = taxon, frequency = as.numeric(d$frequency[ok]),
             category = text(d$category[ok]), determination = toupper(d$determination[ok]) == "TRUE",
             notes = text(d$notes[ok]), lon = lon[ok], lat = lat[ok],
             stringsAsFactors = FALSE)
})
aohi <- do.call(rbind, parts)
rownames(aohi) <- NULL

meta <-data.frame(layer = "aohi", source = "Park et al. 2023, AHOI (Dryad doi:10.5061/dryad.v41ns1s0p)",
                   file = paste(files, collapse = ", "), version = "2022-10-10",
                   url = "https://doi.org/10.5061/dryad.v41ns1s0p",
                   sha256 = paste(vapply(file.path(cache, files), sha256, ""), collapse = ", "),
                   retrieved = retrieved, licence = "CC0 1.0", stringsAsFactors = FALSE)
saveRDS(list(aohi = aohi, meta = meta), file.path("data-raw/cache", "aohi.rds"), compress = "xz")
cat("AHOI points:", nrow(aohi), "\n")
print(table(aohi$taxon, aohi$determination))
