records <- function() {
  data.frame(species = c("a", "a", "b", "c", "c", "d"),
             kingdom = c("P", "P", "A", "A", "A", "P"),
             decimalLongitude = c(12.58, 0, 16.37, 2.35, 2.35, -30),
             decimalLatitude = c(55.67, 0, 48.21, 48.85, 48.85, 40))
}

test_that("flagged data frames and tallies carry their classes", {
  f <- flag_occurrences(records())
  expect_s3_class(f, c("occ_flags", "data.frame"))
  expect_s3_class(f[1:3, ], "occ_flags")
  expect_s3_class(tally_flags(f), c("occ_tally", "data.frame"))
})

test_that("only counts are records whose sole rule flag is that test", {
  f <- flag_occurrences(records())
  rule <- c("zero", "capital", "sea", "duplicate")
  t <- tally_flags(f, rules = list(r = rule))
  in_rule <- bitwAnd(f$flags, flag_mask(rule))
  for (x in rule) expect_identical(t[[paste0("only_r_", x)]], sum(in_rule == flag_mask(x)))
})

test_that("summary gives percentages of records per test and rule", {
  f <- flag_occurrences(records())
  rule <- c("zero", "capital", "gbif_headquarters", "sea", "duplicate")
  s <- summary(f, rules = list(strict = rule))
  expect_s3_class(s, "occ_summary")
  expect_identical(s$test, c(rule, "(any)"))
  expect_identical(s$flagged[s$test == "(any)"], sum(has_flag(f$flags, rule)))
  for (x in rule) expect_identical(s$flagged[s$test == x], sum(has_flag(f$flags, x)))
  expect_equal(s$pct, 100 * s$flagged / nrow(f))
  only <- s$only[s$test != "(any)"]
  expect_lte(sum(only), s$flagged[s$test == "(any)"])
  expect_true(is.na(s$only[s$test == "(any)"]))
  expect_output(print(s), "removes")
})

test_that("grouped summaries keep one block per group and match the tally", {
  f <- flag_occurrences(records())
  t <- tally_flags(f, by = "kingdom", rules = list(strict = c("zero", "capital")))
  s <- summary(t)
  expect_identical(s, summary(f, by = "kingdom", rules = list(strict = c("zero", "capital"))))
  expect_identical(unique(s$kingdom), c("A", "P"))
  a <- s[s$kingdom == "A" & s$test == "capital", ]
  expect_identical(a$flagged, t$flagged_capital[t$kingdom == "A"])
  expect_equal(a$pct, 100 * a$flagged / t$n[t$kingdom == "A"])
})

test_that("summary of a row subset falls back to the flag columns", {
  f <- flag_occurrences(records(), tests = c("zero", "capital", "equal"))
  s <- summary(f[1:2, ])
  expect_identical(unique(s$test[s$test != "(any)"]), c("zero", "capital", "equal"))
})

test_that("print is short: header, first records, failed tests by name", {
  f <- flag_occurrences(records(), tests = c("zero", "capital"))
  out <- capture.output(print(f, n = 3))
  expect_match(out[1], "<occ_flags> 6 records, 2 tests, reference OccurrenceCleaner [0-9.]+, land 110$")
  expect_false(any(grepl("flag_zero", out)))
  expect_true(any(grepl("zero$", out)))
  expect_match(out[length(out)], "3 more records")
  expect_output(print(f[1:2, ]), "<occ_flags> 2 records, 2 tests")
  expect_output(print(f[, c("species", "flag_zero")]), "flag_zero")
  t <- tally_flags(f, by = "kingdom", rules = list(strict = c("zero", "capital")))
  out <- capture.output(print(t))
  expect_match(out[1], "<occ_tally> 6 records in 2 groups of kingdom, rules: strict")
  expect_false(any(grepl("only_", out)))
  expect_output(print(occ_columns(lon = "x")), "lon +x")
})

test_that("plots draw without error", {
  f <- flag_occurrences(records())
  pdf(NULL)
  on.exit(grDevices::dev.off())
  expect_invisible(plot(f))
  expect_invisible(plot(f, by = "kingdom"))
  expect_invisible(plot(f, type = "map", rules = list(strict = c("capital", "sea"))))
  expect_invisible(plot(tally_flags(f, by = "kingdom")))
  expect_error(plot(summary(f), rule = "nope"), "no rule")
})
