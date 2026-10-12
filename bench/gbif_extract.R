# Extract the records of a set of genera from the GBIF snapshot, for the case
# study dataset shipped with the package (data-raw/gentiana.R reduces it).
#
# Usage: Rscript gbif_extract.R <parquet dir> <out file .rds> <workers>

args <- commandArgs(TRUE)
snap <- args[1]; out <- args[2]; workers <- as.integer(args[3])
genera <- c("Gentiana", "Gentianella", "Primula", "Soldanella", "Androsace", "Saxifraga")
keep <- c("gbifid", "datasetkey", "publishingorgkey", "license", "kingdom", "family", "genus",
          "species", "taxonrank", "countrycode", "stateprovince", "locality",
          "decimallongitude", "decimallatitude", "coordinateuncertaintyinmeters", "year",
          "basisofrecord", "institutioncode", "establishmentmeans", "occurrencestatus", "issue")

files <- sort(list.files(snap, full.names = TRUE))
files <- files[!grepl("^[._]", basename(files))]
parts_dir <- paste0(out, ".parts")
dir.create(parts_dir, showWarnings = FALSE, recursive = TRUE)

one <- function(f) {
  o <- file.path(parts_dir, paste0(basename(f), ".rds"))
  if (file.exists(o)) return(invisible(NULL))
  node <- do.call(vectra::select, c(list(vectra::tbl_parquet(f)), lapply(keep, as.name)))
  d <- vectra::collect(vectra::filter(node, genus %in% genera))
  d <- as.data.frame(d)
  tmp <- paste0(o, ".tmp")
  saveRDS(d, tmp)
  file.rename(tmp, o)
  invisible(NULL)
}

t0 <- Sys.time()
cat(format(t0), "files:", length(files), "workers:", workers, "\n")
cl <- parallel::makeCluster(workers)
parallel::clusterExport(cl, c("parts_dir", "genera", "keep", "one"))
res <- parallel::parLapplyLB(cl, files, function(f) tryCatch(one(f), error = function(e) conditionMessage(e)))
parallel::stopCluster(cl)
err <- Filter(is.character, res)
if (length(err)) { print(head(err)); stop(length(err), " files failed") }
d <- do.call(rbind, lapply(list.files(parts_dir, "[.]rds$", full.names = TRUE), readRDS))
saveRDS(d, out)
cat(format(Sys.time()), "records:", nrow(d), " minutes:",
    round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "\n")
writeLines(format(Sys.time()), paste0(out, ".DONE"))
