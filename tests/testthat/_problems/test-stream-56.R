# Extracted from test-stream.R:56

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
src <- tempfile("src")
dir.create(src)
d1 <- make_table(300, 1)
d2 <- make_table(250, 2)
vectra::write_vtr(d1, file.path(src, "a.vtr"))
vectra::write_vtr(d2, file.path(src, "b.vtr"))
out <- tempfile("out")
tests <- c("invalid", "zero", "gbif_headquarters", "capital", "sea", "duplicate")
res <- flag_occurrences(src, tests = tests, out = out, keep = c("kingdom", "year"), part_rows = 100, verbose = FALSE)
expect_s3_class(res, "occ_flagged")
expect_identical(res$n, 550)
expect_length(res$parts, 2L)
expect_identical(res$tests, tests)
expect_true(file.exists(file.path(out, "flags_meta.rds")))
expect_output(print(res), "550 records in 2 part")
got <- vectra::collect(flagged_table(out))
want <- rbind(flag_occurrences(d1, tests = tests), flag_occurrences(d2, tests = tests))
expect_identical(names(got), c("gbifid", "kingdom", "year", "flags"))
expect_identical(got$gbifid, want$gbifid)
expect_identical(got$flags, want$flags)
res2 <- flag_occurrences(src, tests = tests, out = out, keep = c("kingdom", "year"), part_rows = 100, verbose = FALSE)
expect_identical(res2$n, 550)
expect_identical(res2$parts, res$parts)
expect_message(flag_occurrences(src, tests = tests, out = out, keep = c("kingdom", "year"), part_rows = 100), "skipped")
expect_error(flag_occurrences(src, tests = "invalid", out = out, verbose = FALSE), "different tests")
rules <- list(strict = c("zero", "gbif_headquarters", "capital", "sea"))
t_disk <- tally_flags(out, by = "kingdom", rules = rules, bins = list(year = c(1950, 2000)))
t_mem <- tally_flags(want, by = "kingdom", rules = rules, bins = list(year = c(1950, 2000)))
expect_equal(t_disk, t_mem, ignore_attr = TRUE)
expect_error(tally_flags(out, by = "species"), "not kept")
res3 <- flag_occurrences(vectra::tbl(file.path(src, "a.vtr")), tests = "zero", out = tempfile(), verbose = FALSE)
expect_identical(res3$n, 300)
expect_identical(res3$units, "stream")
res4 <- flag_occurrences(file.path(src, "b.vtr"), tests = "zero", out = tempfile(), verbose = FALSE)
expect_identical(res4$units, "b")
expect_error(flag_occurrences(src, tests = "zero"), "`out`")
expect_error(flag_occurrences(src, tests = "zero", out = tempfile(), keep = "nope", verbose = FALSE), "keep")
expect_error(flag_occurrences(tempfile(), tests = "zero", out = tempfile()), "not found")
