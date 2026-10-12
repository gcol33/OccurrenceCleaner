# Check that gbif_repair_duplicates.R changed nothing but the duplicate bit.
# "before" records, per part file, the row count, a checksum of every column
# other than the flags (identifier and kept columns), a checksum of the flags
# with the duplicate bit cleared, and the number of duplicate bits. "after"
# computes the same and compares: everything but the duplicate count must be
# identical. Writes verify_before.rds, verify_after.rds, verify_report.txt and,
# when all checks pass, VERIFIED.
#
# Usage: Rscript gbif_verify_repair.R <out dir> before|after

args <- commandArgs(TRUE)
out <- args[1]; mode <- match.arg(args[2], c("before", "after"))
suppressMessages(library("OccurrenceCleaner"))
flag_dir <- file.path(out, "flags")
m <- readRDS(file.path(flag_dir, "flags_meta.rds"))
mask <- flag_mask("duplicate")
md5 <- function(x) unname(tools::md5sum(bytes = serialize(x, NULL, xdr = FALSE)))

summarise_part <- function(p) {
  d <- as.data.frame(vectra::collect(vectra::tbl(file.path(flag_dir, p))))
  other <- setdiff(names(d), "flags")
  data.frame(part = p, n = nrow(d), columns = paste(names(d), collapse = ";"),
             types = paste(vapply(d, typeof, ""), collapse = ";"),
             md5_other = md5(lapply(d[other], unname)),
             md5_nondup = md5(bitwAnd(d$flags, bitwNot(mask))),
             n_dup = sum(bitwAnd(d$flags, mask) != 0))
}

t0 <- Sys.time()
s <- do.call(rbind, lapply(m$parts, summarise_part))
units_n <- vapply(m$units, function(u) readRDS(file.path(flag_dir, paste0(u, ".done")))$n, 0)
res <- list(parts = s, n = m$n, units_n = units_n, mask = mask, at = Sys.time())
saveRDS(res, file.path(out, paste0("verify_", mode, ".rds")))
cat(mode, ":", nrow(s), "parts,", format(sum(s$n), big.mark = ","), "rows,",
    format(sum(s$n_dup), big.mark = ","), "duplicate bits,",
    round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min\n")

if (mode == "after") {
  b <- readRDS(file.path(out, "verify_before.rds"))
  a <- res
  checks <- c(
    same_parts = identical(b$parts$part, a$parts$part),
    same_total_rows = identical(b$n, a$n) && sum(b$parts$n) == sum(a$parts$n),
    same_unit_rows = identical(b$units_n, a$units_n),
    same_part_rows = identical(b$parts$n, a$parts$n),
    same_columns = identical(b$parts$columns, a$parts$columns) && identical(b$parts$types, a$parts$types),
    same_ids_and_kept_columns = identical(b$parts$md5_other, a$parts$md5_other),
    same_non_duplicate_flags = identical(b$parts$md5_nondup, a$parts$md5_nondup),
    rows_match_flag_meta = sum(a$parts$n) == a$n && sum(a$units_n) == a$n)
  bad <- which(b$parts$md5_other != a$parts$md5_other | b$parts$md5_nondup != a$parts$md5_nondup)
  report <- c(paste("verified:", format(Sys.time())),
              paste(names(checks), checks, sep = ": "),
              paste("rows:", format(a$n, big.mark = ",")),
              paste("duplicate bits before:", format(sum(b$parts$n_dup), big.mark = ",")),
              paste("duplicate bits after:", format(sum(a$parts$n_dup), big.mark = ",")),
              if (length(bad)) paste("parts differing:", paste(head(a$parts$part[bad], 20), collapse = ", ")))
  writeLines(report, file.path(out, "verify_report.txt"))
  cat(report, sep = "\n")
  if (!all(checks)) stop("repair verification failed: ", paste(names(checks)[!checks], collapse = ", "))
  writeLines(format(Sys.time()), file.path(out, "VERIFIED"))
}
