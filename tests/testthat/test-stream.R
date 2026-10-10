make_table <- function(n, seed) {
  set.seed(seed)
  data.frame(gbifid = as.character(seq_len(n) + seed * 1e6), species = sample(c("a", "b", "c"), n, TRUE),
             kingdom = sample(c("Animalia", "Plantae"), n, TRUE), year = sample(1900:2020, n, TRUE),
             decimallongitude = c(runif(n - 5, -180, 180), 0, 12.58, 2.35, NA, 16.37),
             decimallatitude = c(runif(n - 5, -90, 90), 0, 55.67, 48.85, 1, 48.21), stringsAsFactors = FALSE)
}

test_that("streamed flags equal in-memory flags, resume skips done units, tally matches", {
  skip_if_not_installed("vectra")
  src <- tempfile("src"); dir.create(src)
  d1 <- make_table(300, 1); d2 <- make_table(250, 2)
  vectra::write_vtr(d1, file.path(src, "a.vtr"))
  vectra::write_vtr(d2, file.path(src, "b.vtr"))
  out <- tempfile("out")
  tests <- c("invalid", "zero", "gbif_headquarters", "capital", "sea", "duplicate")
  res <- flag_occurrences(src, tests = tests, out = out, keep = c("kingdom", "year"), part_rows = 100, verbose = FALSE)
  expect_s3_class(res, "occ_flagged")
  expect_identical(res$n, 550)
  # each unit arrives as one vectra batch, so one part per unit
  expect_length(res$parts, 2L)
  expect_identical(res$tests, tests)
  expect_true(file.exists(file.path(out, "flags_meta.rds")))
  expect_output(print(res), "550 records in 2 part")

  got <- vectra::collect(flagged_table(out))
  want <- rbind(flag_occurrences(d1, tests = tests), flag_occurrences(d2, tests = tests))
  expect_identical(names(got), c("gbifid", "kingdom", "year", "flags"))
  expect_identical(got$gbifid, want$gbifid)
  expect_identical(got$flags, want$flags)

  # resume: a second run touches nothing and reports the same counts
  res2 <- flag_occurrences(src, tests = tests, out = out, keep = c("kingdom", "year"), part_rows = 100, verbose = FALSE)
  expect_identical(res2$n, 550)
  expect_identical(res2$parts, res$parts)
  expect_message(flag_occurrences(src, tests = tests, out = out, keep = c("kingdom", "year"), part_rows = 100), "skipped")
  # different tests into the same directory is refused
  expect_error(flag_occurrences(src, tests = "invalid", out = out, verbose = FALSE), "different tests")

  # tally on disk equals tally in memory
  rules <- list(strict = c("zero", "gbif_headquarters", "capital", "sea"))
  t_disk <- tally_flags(out, by = "kingdom", rules = rules, bins = list(year = c(1950, 2000)))
  t_mem <- tally_flags(want, by = "kingdom", rules = rules, bins = list(year = c(1950, 2000)))
  expect_equal(t_disk, t_mem, ignore_attr = TRUE)
  expect_error(tally_flags(out, by = "species"), "not kept")

  # a vectra node as input, and a single file as input
  res3 <- flag_occurrences(vectra::tbl(file.path(src, "a.vtr")), tests = "zero", out = tempfile(), verbose = FALSE)
  expect_identical(res3$n, 300)
  expect_identical(res3$units, "stream")
  res4 <- flag_occurrences(file.path(src, "b.vtr"), tests = "zero", out = tempfile(), verbose = FALSE)
  expect_identical(res4$units, "b")
  expect_error(flag_occurrences(src, tests = "zero"), "`out`")
  expect_error(flag_occurrences(src, tests = "zero", out = tempfile(), keep = "nope", verbose = FALSE), "keep")
  expect_error(flag_occurrences(tempfile(), tests = "zero", out = tempfile()), "not found")
})

test_that("a slice of the GBIF snapshot streams through tbl_parquet", {
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
  # in-memory flags on the first part agree
  d <- vectra::collect(vectra::tbl_parquet(parts[1]))
  want <- flag_occurrences(d, tests = res$tests)
  expect_identical(got$flags[seq_len(nrow(d))], want$flags)
  t <- tally_flags(res, by = "kingdom", bins = list(coordinateuncertaintyinmeters = c(10, 100, 1000)),
                   rules = list(cc = c("zero", "equal", "capital", "centroid", "institution", "gbif_headquarters", "sea")))
  expect_identical(sum(t$n), as.integer(res$n))
})
