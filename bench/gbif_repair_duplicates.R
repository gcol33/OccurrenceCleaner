# Recompute the duplicate bit of a finished gbif_snapshot_run.R output over the
# whole snapshot, then redo its tallies. The input files and their order must
# be those of the run: the same sorted list without hidden files. The earlier
# tally.rds is kept as tally_provisional.rds. Rerunning the script after an
# interruption resumes the repair.
#
# Usage: Rscript gbif_repair_duplicates.R <parquet dir> <out dir> [max files]

args <- commandArgs(TRUE)
snap <- args[1]; out <- args[2]
max_files <- if (length(args) >= 3) as.integer(args[3]) else Inf
suppressMessages(library("OccurrenceCleaner"))

files <- sort(list.files(snap, full.names = TRUE))
files <- files[!grepl("^[._]", basename(files))]
if (is.finite(max_files)) files <- head(files, max_files)
flag_dir <- file.path(out, "flags")

stamp <- function(stage, t0) {
  s <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  cat(format(Sys.time()), stage, round(s, 1), "s\n")
  write.table(data.frame(stage = stage, seconds = s, files = length(files)),
              file.path(out, "timing.csv"), sep = ",", row.names = FALSE,
              col.names = !file.exists(file.path(out, "timing.csv")), append = TRUE)
}

cat(paste("OccurrenceCleaner", utils::packageVersion("OccurrenceCleaner"), "RemoteSha:",
          utils::packageDescription("OccurrenceCleaner")$RemoteSha %||% "none"),
    file = file.path(out, "repair_session.txt"), sep = "\n")

t0 <- Sys.time()
f <- OccurrenceCleaner:::repair_duplicates(flag_dir, files, verbose = TRUE)
stamp("repair_duplicates", t0)
print(f)

tally_path <- file.path(out, "tally.rds")
if (file.exists(tally_path) && !file.exists(file.path(out, "tally_provisional.rds")))
  file.copy(tally_path, file.path(out, "tally_provisional.rds"))
old <- readRDS(file.path(out, "tally_provisional.rds"))
rules <- list(
  cc = c("zero", "equal", "capital", "centroid", "institution", "gbif_headquarters", "sea",
         "outlier"),
  cc_gbif = c("zero", "equal", "capital", "centroid", "institution", "gbif_headquarters", "sea",
              "outlier", "country_mismatch", "issue_coordinate", "issue_taxon"))
t0 <- Sys.time()
tl <- tally_flags(f, rules = rules)
stamp("tally_repaired", t0)
t0 <- Sys.time()
tk <- tally_flags(f, by = "kingdom", rules = rules,
                  bins = list(year = c(1900, 1950, 2000),
                              coordinateuncertaintyinmeters = c(100, 1000, 10000)))
stamp("tally_grouped_repaired", t0)
saveRDS(list(total = tl, grouped = tk, n = f$n, tests = old$tests,
             duplicate_repair = f$duplicate_repair), tally_path)
print(summary(tl))
writeLines(format(Sys.time()), file.path(out, "REPAIRED"))
