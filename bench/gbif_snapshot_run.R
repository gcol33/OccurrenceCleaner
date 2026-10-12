# One flag_occurrences() pass over a GBIF Parquet snapshot with every test the
# snapshot's columns support, then tally_flags() over the on-disk output.
# Writes timing.csv (stage, seconds), tally.rds and session.txt to <out>.
#
# Usage: Rscript gbif_snapshot_run.R <parquet dir> <out dir> [max files]

args <- commandArgs(TRUE)
snap <- args[1]; out <- args[2]
max_files <- if (length(args) >= 3) as.integer(args[3]) else Inf
suppressMessages(library("OccurrenceCleaner"))

files <- sort(list.files(snap, full.names = TRUE))
files <- files[!grepl("^[._]", basename(files))]
if (is.finite(max_files)) files <- head(files, max_files)
dir.create(out, showWarnings = FALSE, recursive = TRUE)
flag_dir <- file.path(out, "flags")

tests <- c(flag_tests()$test[flag_tests()$bit <= 18], "outlier", "dataset_ddmm",
           "dataset_rounded", "aohi", "sea_nonmarine", "land_marine")
cols <- occ_columns(id = "gbifid")
keep <- c("kingdom", "class", "year", "coordinateuncertaintyinmeters", "basisofrecord")

stamp <- function(stage, t0) {
  s <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  cat(format(Sys.time()), stage, round(s, 1), "s\n")
  write.table(data.frame(stage = stage, seconds = s, files = length(files)),
              file.path(out, "timing.csv"), sep = ",", row.names = FALSE,
              col.names = !file.exists(file.path(out, "timing.csv")), append = TRUE)
}

writeLines(c(capture.output(sessionInfo()),
             paste("OccurrenceCleaner RemoteSha:", utils::packageDescription("OccurrenceCleaner")$RemoteSha %||% "none"),
             paste("files:", length(files)), paste("tests:", paste(tests, collapse = ", "))),
           file.path(out, "session.txt"))

t0 <- Sys.time()
f <- flag_occurrences(files, tests = tests, columns = cols, out = flag_dir, keep = keep,
                      verbose = TRUE)
stamp("flag", t0)
print(f)

rules <- list(
  cc = c("zero", "equal", "capital", "centroid", "institution", "gbif_headquarters", "sea",
         "outlier"),
  cc_gbif = c("zero", "equal", "capital", "centroid", "institution", "gbif_headquarters", "sea",
              "outlier", "country_mismatch", "issue_coordinate", "issue_taxon"))
t0 <- Sys.time()
tl <- tally_flags(f, rules = rules)
stamp("tally", t0)
t0 <- Sys.time()
tk <- tally_flags(f, by = "kingdom", rules = rules,
                  bins = list(year = c(1900, 1950, 2000),
                              coordinateuncertaintyinmeters = c(100, 1000, 10000)))
stamp("tally_grouped", t0)
saveRDS(list(total = tl, grouped = tk, n = f$n, tests = tests), file.path(out, "tally.rds"))
print(summary(tl))
writeLines(format(Sys.time()), file.path(out, "DONE"))
