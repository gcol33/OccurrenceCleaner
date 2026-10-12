# Extracted from test-stream.R:77

# prequel ----------------------------------------------------------------------
make_table <- function(n, seed) {
  set.seed(seed)
  data.frame(gbifid = as.character(seq_len(n) + seed * 1e6), species = sample(c("a", "b", "c"), n, TRUE),
             kingdom = sample(c("Animalia", "Plantae"), n, TRUE), year = sample(1900:2020, n, TRUE),
             decimallongitude = c(runif(n - 5, -180, 180), 0, 12.58, 2.35, NA, 16.37),
             decimallatitude = c(runif(n - 5, -90, 90), 0, 55.67, 48.85, 1, 48.21), stringsAsFactors = FALSE)
}

# test -------------------------------------------------------------------------
skip_if_not_installed("vectra")
snap <- Sys.getenv("OCC_GBIF_SNAPSHOT", "E:/research/raw/occurrences/gbif_snapshot/2026-10-01/occurrence.parquet")
skip_if_not(dir.exists(snap), "GBIF snapshot not available")
parts <- head(sort(list.files(snap, full.names = TRUE)), 3)
out <- tempfile("gbif")
res <- flag_occurrences(parts, tests = c(default_tests(), "country_mismatch", "issue_rounded", "basis_fossil"), out = out,
                          keep = c("kingdom", "year", "coordinateuncertaintyinmeters"), verbose = FALSE)
expect_gt(res$n, 0)
got <- vectra::collect(flagged_table(res))
expect_identical(nrow(got), as.integer(res$n))
expect_true("gbifid" %in% names(got))
d <- vectra::collect(vectra::tbl_parquet(parts[1]))
want <- flag_occurrences(d, tests = res$tests)
expect_identical(got$flags[seq_len(nrow(d))], want$flags)
t <- tally_flags(res, by = "kingdom", bins = list(coordinateuncertaintyinmeters = c(10, 100, 1000)),
                   rules = list(cc = c("zero", "equal", "capital", "centroid", "institution", "gbif_headquarters", "sea")))
expect_identical(sum(t$n), as.integer(res$n))
