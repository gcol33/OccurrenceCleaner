# Builds data/gentiana.rda: the GBIF records of the genus Gentiana with
# country code AT and a CC0 or CC BY 4.0 licence, from the GBIF snapshot of
# 2026-10-01 (GBIF.org (1 October 2026) GBIF Occurrence Download
# https://doi.org/10.15468/dl.tup2g6).
#
# Input: the records of six genera extracted from the snapshot by
# bench/gbif_extract.R (run on worky, 2026-10-12), copied to
# E:/research/projects/occurrencecleaner-paper/genera_2026-10-01.rds.

src <- "E:/research/projects/occurrencecleaner-paper/genera_2026-10-01.rds"
d <- readRDS(src)
g <- d[d$genus %in% "Gentiana" & d$countrycode %in% "AT" &
         d$license %in% c("CC0_1_0", "CC_BY_4_0") & !is.na(d$species), ]
gentiana <- data.frame(
  gbifid = as.character(g$gbifid),
  datasetkey = g$datasetkey,
  kingdom = g$kingdom,
  genus = g$genus,
  species = g$species,
  countrycode = g$countrycode,
  decimallongitude = g$decimallongitude,
  decimallatitude = g$decimallatitude,
  coordinateuncertaintyinmeters = g$coordinateuncertaintyinmeters,
  year = as.integer(g$year),
  basisofrecord = g$basisofrecord,
  institutioncode = g$institutioncode,
  establishmentmeans = g$establishmentmeans,
  issue = g$issue,
  license = g$license,
  stringsAsFactors = FALSE)
gentiana <- gentiana[order(as.numeric(gentiana$gbifid)), ]
rownames(gentiana) <- NULL
stopifnot(nrow(gentiana) == 33025L)
save(gentiana, file = "data/gentiana.rda", compress = "xz")
