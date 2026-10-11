# Build the genus habitat table for the habitat tests from the Interim Register
# of Marine and Nonmarine Genera (IRMNG), Darwin Core Archive of 2026-10-06,
# https://www.irmng.org/export/2026/IRMNG_genera_DwCA_2026-10-06.zip
# Licence CC BY 4.0 (eml.xml intellectualRights). Citation (eml.xml):
# Rees, T. (compiler) (2026). The Interim Register of Marine and Nonmarine
# Genera. Available from https://www.irmng.org at VLIZ. Accessed 2026-10-06.
#
# speciesprofile.txt holds isMarine, isBrackish, isFreshwater, isTerrestrial
# and isExtinct (0, 1 or empty) per name. A name that is not accepted takes the
# profile of its accepted name. Each genus is classed:
#   nonmarine  isMarine 0 and isBrackish not 1: the genus does not live in the sea;
#   marine     isMarine 1, isTerrestrial 0 and isFreshwater 0, and not extinct:
#              the genus lives only in the sea (extinct marine genera are left
#              out, their fossils lie on land);
# anything else (missing flags, both habitats) is not classed. A genus name is
# keyed by kingdom; when several names share a kingdom and genus, the classes of
# the accepted names decide, and a genus whose names disagree is not classed.
#
# Run from the package root:  Rscript data-raw/habitat.R

source("data-raw/utils.R")
cache <-"data-raw/cache"
dir.create(cache, showWarnings = FALSE, recursive = TRUE)
retrieved <- "2026-10-10"
version <- "2026-10-06"
url <- "https://www.irmng.org/export/2026/IRMNG_genera_DwCA_2026-10-06.zip"
zip <- file.path(cache, basename(url))
if (!file.exists(zip)) download.file(url, zip, mode = "wb", quiet = TRUE)

exdir <- file.path(cache, "irmng")
utils::unzip(zip, files = c("taxon.txt", "speciesprofile.txt"), exdir = exdir, overwrite = TRUE)
read_tab <- function(f) read.delim(file.path(exdir, f), quote = "", na.strings = "", colClasses = "character",
                                   encoding = "UTF-8", comment.char = "")
tx <- read_tab("taxon.txt")[, c("taxonID", "genus", "kingdom", "taxonomicStatus", "acceptedNameUsageID")]
sp <- read_tab("speciesprofile.txt")
m <- merge(tx, sp, by = "taxonID")
for (v in c("isMarine", "isFreshwater", "isTerrestrial", "isBrackish", "isExtinct")) m[[v]] <- as.integer(m[[v]])

acc <- match(m$acceptedNameUsageID, m$taxonID)
p <- m[ifelse(!is.na(acc) & m$taxonomicStatus != "accepted", acc, seq_len(nrow(m))), ]
class <- ifelse(p$isMarine %in% 0L & !(p$isBrackish %in% 1L), "nonmarine",
         ifelse(p$isMarine %in% 1L & p$isTerrestrial %in% 0L & p$isFreshwater %in% 0L &
                  !(p$isExtinct %in% 1L), "marine", NA_character_))

kingdoms <- c("Animalia", "Archaea", "Bacteria", "Chromista", "Fungi", "Plantae", "Protozoa", "Viruses")
g <- data.frame(kingdom = m$kingdom, genus = m$genus, class = class,
                accepted = m$taxonomicStatus == "accepted", stringsAsFactors = FALSE)
g <- g[!is.na(g$genus) & nzchar(g$genus) & g$kingdom %in% kingdoms, ]
pick <- function(h, a) {
  v <- unique(h[a & !is.na(h)])
  if (!length(v)) v <- unique(h[!is.na(h)])
  if (length(v) == 1L) v else NA_character_
}
groups <- split(seq_len(nrow(g)), paste(g$kingdom, g$genus, sep = "\t"))
res <- vapply(groups, function(i) pick(g$class[i], g$accepted[i]), character(1))
key <- do.call(rbind, strsplit(names(res), "\t", fixed = TRUE))
habitat <- data.frame(kingdom = key[, 1], genus = key[, 2], marine = unname(res) == "marine",
                      stringsAsFactors = FALSE)[!is.na(res), ]
habitat <- habitat[order(habitat$kingdom, habitat$genus), ]
rownames(habitat) <- NULL

meta <-data.frame(layer = "habitat",
                   source = "IRMNG, Rees, T. (compiler) (2026). The Interim Register of Marine and Nonmarine Genera",
                   file = basename(zip), version = version, url = url, sha256 = sha256(zip),
                   retrieved = retrieved, licence = "CC BY 4.0", stringsAsFactors = FALSE)
saveRDS(list(habitat = habitat, meta = meta), file.path(cache, "habitat.rds"), compress = "xz")
unlink(exdir, recursive = TRUE)
print(table(habitat$kingdom, ifelse(habitat$marine, "marine", "nonmarine")))
cat("xz size KB:", file.size(file.path(cache, "habitat.rds")) / 1024, "\n")
