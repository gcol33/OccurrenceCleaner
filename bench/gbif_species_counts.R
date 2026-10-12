# Records with valid coordinates per species in a GBIF Parquet snapshot, to
# size the outlier test (exact below 10,000 records per species, raster above).
#
# Usage: Rscript gbif_species_counts.R <parquet dir> <out file .rds> <workers>

args <- commandArgs(TRUE)
snap <- args[1]; out <- args[2]; workers <- as.integer(args[3])
files <- sort(list.files(snap, full.names = TRUE))
files <- files[!grepl("^[._]", basename(files))]

one <- function(f) {
  d <- vectra::collect(vectra::select(vectra::tbl_parquet(f), species, decimallongitude, decimallatitude))
  ok <- !is.na(d$species) & is.finite(d$decimallongitude) & is.finite(d$decimallatitude) &
    abs(d$decimallongitude) <= 180 & abs(d$decimallatitude) <= 90
  tb <- table(d$species[ok])
  list(n = nrow(d), counts = stats::setNames(as.numeric(tb), names(tb)))
}

t0 <- Sys.time()
cl <- parallel::makeCluster(workers)
res <- parallel::parLapplyLB(cl, files, one)
parallel::stopCluster(cl)
all <- unlist(lapply(res, `[[`, "counts"))
counts <- rowsum(unname(all), names(all), reorder = FALSE)[, 1]
saveRDS(list(n = sum(vapply(res, `[[`, 0, "n")), counts = counts), out)
cat(format(Sys.time()), "records", sum(vapply(res, `[[`, 0, "n")), "species", length(counts),
    "minutes", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "\n")
writeLines(format(Sys.time()), paste0(out, ".DONE"))
