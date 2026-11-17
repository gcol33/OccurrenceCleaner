# Measure alternative settings on the complete saved POC and snapshot tallies.
library(OccurrenceCleaner)
out <- "dev_notes/results_0.3.0"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
src <- "E:/research/derived/occurrences/gbif_2026-10-01_poc25"
paths <- file.path("bench/results", paste0("snapshot_worky_", c("own2", "cc")), "tally.rds")
snapshot <- lapply(paths, readRDS)
for (i in seq_along(snapshot)) {
  t <- snapshot[[i]]
  stopifnot(t$n == 3762210648, sum(t$grouped$n) == t$n)
  write.csv(as.data.frame(t$total), file.path(out, paste0("snapshot_", c("own2", "cc")[i], ".csv")), row.names = FALSE)
  g <- as.data.frame(t$grouped)
  counts <- c("n", "flagged_issue_rounded", "flagged_sea", "flagged_duplicate")
  for (by in c("kingdom", "year_bin", "coordinateuncertaintyinmeters_bin")) {
    a <- aggregate(g[counts], g[by], sum)
    write.csv(a, file.path(out, paste0("snapshot_", c("own2", "cc")[i], "_", by, ".csv")), row.names = FALSE)
  }
}
published <- read.csv("C:/GillesC/Documents/writing/papers/paper_occurrencecleaner_2026/for_ali/by_kingdom_year_uncertainty.csv")
stopifnot(sum(published$n) == 3762210648)
f <- readRDS(file.path(src, "flags.rds"))
stopifnot(nrow(f) == 12439653, length(unique(f$card)) == 25L,
          !any(f$occurrencestatus %in% "ABSENT"))
cat(format(Sys.time()), "loaded", nrow(f), "records in", length(unique(f$card)), "cards\n")
writeLines(capture.output(sessionInfo()), file.path(out, "session.txt"))
writeLines(c(paste("POC reference:", attr(f, "occ_reference")),
             paste("POC input MD5:", tools::md5sum(file.path(src, "flags.rds"))),
             paste("eventDate available:", any(tolower(names(f)) == "eventdate"))),
           file.path(out, "provenance.txt"))
rules <- list(cc = c("invalid", "zero", "equal", "capital", "centroid", "institution", "gbif_headquarters", "sea"))
rules$cc_country <- c(rules$cc, "country_mismatch")
rules$cc_gbif <- c(rules$cc_country, "issue_coordinate", "issue_taxon")
rules$wild <- c(rules$cc_gbif, "basis_fossil", "basis_living", "establishment_managed")
rules$strict <- unique(c(rules$wild, "urban", "duplicate", "outlier", "dataset_ddmm", "dataset_rounded", "aohi", "sea_nonmarine", "land_marine", "issue_date"))
rounded <- f$flag_issue_rounded
stopifnot(all(vapply(unique(unlist(rules)), function(t)
  identical(has_flag(f$flags, t), f[[paste0("flag_", t)]]), logical(1))))
marginals <- do.call(rbind, lapply(names(rules), function(r) {
  removed <- has_flag(f$flags, rules[[r]])
  data.frame(rule = r, n = nrow(f), removed = sum(removed), rounded = sum(rounded),
             extra_rounded = sum(rounded & !removed))
}))
write.csv(marginals, file.path(out, "poc_rounding.csv"), row.names = FALSE)
small <- data.frame(species = f$species, decimalLongitude = f$decimallongitude,
                    decimalLatitude = f$decimallatitude, year = f$year)
results <- data.frame(card = f$card, n = 1L, rounded = rounded, old_duplicate = f$flag_duplicate)
for (scale in c(110, 50, 10)) {
  t <- system.time(z <- flag_occurrences(small[c("decimalLongitude", "decimalLatitude")],
                                         tests = "sea", land_scale = scale, n_threads = 8))
  results[[paste0("sea_", scale)]] <- z$flag_sea
  cat("sea", scale, "flagged", sum(z$flag_sea), "elapsed", t[["elapsed"]], "\n")
}
stopifnot(identical(results$sea_110, f$flag_sea))
results$sea_110_only <- results$sea_110 & !results$sea_10
results$sea_10_only <- results$sea_10 & !results$sea_110
for (variant in c("exact", "year", "cell_0.01", "cell_1_120")) {
  args <- list(x = small, tests = "duplicate", verbose = FALSE, n_threads = 8)
  if (variant == "year") args$duplicate_by <- "year"
  if (variant == "cell_0.01") args$duplicate_cell <- 0.01
  if (variant == "cell_1_120") args$duplicate_cell <- 1 / 120
  t <- system.time(z <- do.call(flag_occurrences, args))
  results[[paste0("duplicate_", variant)]] <- z$flag_duplicate
  cat("duplicate", variant, "flagged", sum(z$flag_duplicate), "elapsed", t[["elapsed"]], "\n")
}
stopifnot(all(!results$duplicate_year | results$duplicate_exact))
results$missing_year <- is.na(f$year)
results$duplicate_year_missing <- results$duplicate_year & is.na(f$year)
results$duplicate_exact_different_year <- results$duplicate_exact & !results$duplicate_year
write.csv(aggregate(results[-1L], results["card"], sum), file.path(out, "poc_by_card.csv"), row.names = FALSE)
write.csv(as.data.frame(as.list(colSums(results[-1L]))), file.path(out, "poc_total.csv"), row.names = FALSE)
islands <- list(azores = c(-32, -24, 36, 40), reunion = c(55, 56, -22, -20))
island_counts <- do.call(rbind, lapply(names(islands), function(nm) {
  b <- islands[[nm]]
  sel <- small$decimalLongitude >= b[1] & small$decimalLongitude <= b[2] &
    small$decimalLatitude >= b[3] & small$decimalLatitude <= b[4]
  sel[is.na(sel)] <- FALSE
  x <- results[sel, c("card", "n", "sea_110", "sea_50", "sea_10", "sea_110_only", "sea_10_only")]
  a <- aggregate(x[-1L], x["card"], sum)
  a$region <- nm
  a
}))
write.csv(island_counts, file.path(out, "poc_island_boxes.csv"), row.names = FALSE)
writeLines("done", file.path(out, "DONE"))
