make_flagged <- function() {
  set.seed(21)
  n <- 400
  x <- data.frame(species = sample(c("a", "b", "c"), n, TRUE), kingdom = sample(c("Animalia", "Plantae"), n, TRUE),
                  year = sample(c(1900:2020, NA), n, TRUE), unc = sample(c(5, 50, 500, 5000, NA), n, TRUE),
                  decimalLongitude = runif(n, -180, 180), decimalLatitude = runif(n, -90, 90))
  x$decimalLongitude[1:20] <- 0
  x[21:40, c("decimalLongitude", "decimalLatitude")] <- x[1:20, c("decimalLongitude", "decimalLatitude")]
  x$species[21:40] <- x$species[1:20]
  flag_occurrences(x, tests = c("invalid", "zero", "sea", "duplicate"))
}

test_that("tally_flags counts per group and per rule", {
  f <- make_flagged()
  t <- tally_flags(f, by = "kingdom", rules = list(strict = c("zero", "sea", "duplicate"), mild = "zero"))
  expect_identical(t$kingdom, c("Animalia", "Plantae"))
  expect_identical(sum(t$n), nrow(f))
  expect_identical(t$flagged_zero, as.integer(tapply(f$flag_zero, f$kingdom, sum)))
  expect_identical(t$removed_strict, as.integer(tapply(has_flag(f$flags, c("zero", "sea", "duplicate")), f$kingdom, sum)))
  expect_identical(t$kept_strict, t$n - t$removed_strict)
  expect_identical(t$removed_mild, t$flagged_zero)
  expect_identical(names(attr(t, "occ_rules")), c("strict", "mild"))
  # default rule is every test present
  t0 <- tally_flags(f)
  expect_identical(nrow(t0), 1L)
  expect_identical(t0$removed_all, sum(f$flags != 0L))
  expect_identical(t0$n_valid, sum(!f$flag_invalid))
})

test_that("missing grouping values form their own group", {
  f <- make_flagged()
  f$kingdom[1:10] <- NA
  t <- tally_flags(f, by = "kingdom")
  expect_identical(t$kingdom, c("Animalia", "Plantae", "missing"))
  expect_identical(t$n[t$kingdom == "missing"], 10L)
  expect_identical(sum(t$n), nrow(f))
})

test_that("bins cut numeric columns and label missing values", {
  f <- make_flagged()
  t <- tally_flags(f, bins = list(year = c(1950, 2000), unc = c(10, 100, 1000)))
  expect_true(all(c("year_bin", "unc_bin") %in% names(t)))
  expect_setequal(unique(t$year_bin), c("<1950", "1950-2000", ">=2000", "missing"))
  ty <- tally_flags(f, bins = list(year = c(2000, 1950)))
  expect_identical(ty$year_bin, c("<1950", "1950-2000", ">=2000", "missing"))
  tk <- tally_flags(f, by = "kingdom", bins = list(year = c(1950, 2000)))
  expect_identical(tk$year_bin[tk$kingdom == "Plantae"], c("<1950", "1950-2000", ">=2000", "missing"))
  expect_setequal(unique(t$unc_bin), c("<10", "10-100", "100-1000", ">=1000", "missing"))
  expect_identical(sum(t$n), nrow(f))
  yb <- OccurrenceCleaner:::bin_column(c(1949, 1950, 1999, 2000, NA), c(1950, 2000))
  expect_identical(yb, c("<1950", "1950-2000", "1950-2000", ">=2000", "missing"))
})

test_that("tallies merge across chunks exactly", {
  f <- make_flagged()
  rules <- list(all = c("invalid", "zero", "sea", "duplicate"))
  whole <- tally_flags(f, by = c("kingdom", "species"), rules = rules)
  parts <- split(f, rep(1:3, length.out = nrow(f)))
  acc <- NULL
  for (p in parts) acc <- OccurrenceCleaner:::merge_tally(acc, OccurrenceCleaner:::tally_chunk(p, c("kingdom", "species"), rules, NULL, rules$all))
  merged <- OccurrenceCleaner:::finish_tally(acc, c("kingdom", "species"), NULL, rules)
  expect_equal(merged, whole, ignore_attr = TRUE)
  expect_error(tally_flags(data.frame(a = 1)), "flags")
  expect_error(tally_flags(f, rules = list(c("zero"))), "named list")
})
