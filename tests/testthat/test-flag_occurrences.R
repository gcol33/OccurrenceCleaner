pts <- function(...) {
  d <- data.frame(..., stringsAsFactors = FALSE)
  if (!"species" %in% names(d)) d$species <- "sp"
  d
}

test_that("record-field tests follow their definitions", {
  x <- pts(decimalLongitude = c(0, 5, 0.3, 0.36, 10, -10, 181, NA, "x", 0.001),
           decimalLatitude = c(5, 0, 0.3, 0.36, 10, 10, 0, 0, 1, -0.001))
  f <- flag_occurrences(x, tests = c("val", "zero", "equ"))
  expect_identical(f$flag_val, c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, FALSE))
  # zero: exact zeros, and within 0.5 degrees of the origin (0.36, 0.36 is 0.509 away)
  expect_identical(f$flag_zero, c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE))
  expect_identical(f$flag_equ, c(FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, TRUE))
  # invalid records carry only the val flag
  expect_identical(f$flags[7:9], rep(flag_mask("val"), 3))
  expect_identical(attr(f, "occ_tests"), c("val", "zero", "equ"))
  expect_identical(attr(f, "occ_layout_version"), 1L)
  expect_match(attr(f, "occ_reference"), "natural_earth")
})

test_that("proximity tests use the default buffers and the own gazetteers", {
  skip_if_not_installed("geosphere")
  cap <- OccurrenceCleaner:::ref_capitals
  vienna <- cap[cap$name == "Vienna", ]
  cen <- OccurrenceCleaner:::ref_centroids
  tirol <- cen[!is.na(cen$code) & cen$code == "AUT-2320", ][1, ]  # Vorarlberg label point
  inst <- OccurrenceCleaner:::ref_institutions
  nhm <- inst[grepl("Naturhistorisches Museum Wien", inst$name), ][1, ]
  near <- function(p, d, b = 37) geosphere::destPoint(c(p$lon, p$lat), b, d)
  x <- pts(decimalLongitude = c(near(vienna, 9990)[1], near(vienna, 10010)[1], near(tirol, 990)[1], near(tirol, 1010)[1],
                                near(nhm, 99)[1], near(nhm, 101)[1], 12.58, near(data.frame(lon = 12.58, lat = 55.67), 1001)[1]),
           decimalLatitude = c(near(vienna, 9990)[2], near(vienna, 10010)[2], near(tirol, 990)[2], near(tirol, 1010)[2],
                               near(nhm, 99)[2], near(nhm, 101)[2], 55.67, near(data.frame(lon = 12.58, lat = 55.67), 1001)[2]))
  f <- flag_occurrences(x, tests = c("cap", "cen", "inst", "gbif"))
  expect_identical(f$flag_cap[1:2], c(TRUE, FALSE))
  expect_identical(f$flag_cen[3:4], c(TRUE, FALSE))
  expect_identical(f$flag_inst[5:6], c(TRUE, FALSE))
  expect_identical(f$flag_gbif[7:8], c(TRUE, FALSE))
  # custom buffers
  f2 <- flag_occurrences(x, tests = c("cap", "gbif"), buffers = list(cap = 20000, gbif = 2000))
  expect_true(all(f2$flag_cap[1:2]))
  expect_true(all(f2$flag_gbif[7:8]))
  expect_error(flag_occurrences(x, tests = "cap", buffers = list(foo = 1)), "no entry")
  expect_error(flag_occurrences(x, tests = "cap", buffers = list(cap = -1)), "non-negative")
})

test_that("polygon tests: sea, urban and country", {
  # Copenhagen as 12.50/55.70: the GBIF HQ point (12.58/55.67) falls outside the
  # 1:50m coastline (CoordinateCleaner's cc_coun and cc_sea at scale 50 agree)
  x <- pts(decimalLongitude = c(2.35, -30, 12.50, 16.37, 69.18, 0, NA),
           decimalLatitude = c(48.85, 40, 55.70, 48.21, 34.52, 0, 1),
           countryCode = c("FR", "FR", "DNK", "DE", "AF", NA, "FR"))
  f <- flag_occurrences(x, tests = c("val", "sea", "urb", "coun"))
  expect_identical(f$flag_sea, c(FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, FALSE))
  expect_identical(f$flag_urb, c(TRUE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE))
  # Paris FR ok; at sea flagged; alpha-3 accepted; Vienna with DE flagged; Kabul AF ok; missing code flagged
  expect_identical(f$flag_coun, c(FALSE, TRUE, FALSE, TRUE, FALSE, TRUE, FALSE))
  expect_identical(f$flags[7], flag_mask("val"))
  f50 <- flag_occurrences(x[1:5, ], tests = "sea", land_scale = 50)
  expect_identical(f50$flag_sea, c(FALSE, TRUE, FALSE, FALSE, FALSE))
  expect_error(flag_occurrences(x, tests = "sea", land_scale = 25), "110, 50 or 10")
  expect_error(flag_occurrences(x[, 1:2], tests = "coun"), "countryCode")
})

test_that("duplicates: exact, with additions, and by cell", {
  x <- pts(decimalLongitude = c(1, 1, 1, 2, 2, 1.001, NA, NA), decimalLatitude = c(1, 1, 1, 2, 2, 1.001, 1, 1),
           species = c("a", "a", "b", "a", "a", "a", "a", "a"), eventDate = c(1, 2, 2, 1, 1, 1, 1, 1))
  f <- flag_occurrences(x, tests = "dupl")
  expect_identical(f$flag_dupl, c(FALSE, TRUE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE))
  f <- flag_occurrences(x, tests = "dupl", dupl_by = "eventDate")
  expect_identical(f$flag_dupl, c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE))
  f <- flag_occurrences(x, tests = "dupl", dupl_cell = 0.01)
  expect_identical(f$flag_dupl, c(FALSE, TRUE, FALSE, FALSE, TRUE, TRUE, FALSE, FALSE))
  expect_error(flag_occurrences(x, tests = "dupl", dupl_by = "nope"), "not found")
})

test_that("GBIF field additions read issue, basis and establishment columns", {
  x <- pts(decimalLongitude = 1, decimalLatitude = 1,
           issue = c("COORDINATE_ROUNDED;TAXON_MATCH_FUZZY", "RECORDED_DATE_INVALID", "GEODETIC_DATUM_INVALID", NA, ""),
           basisOfRecord = c("FOSSIL_SPECIMEN", "LIVING_SPECIMEN", "HUMAN_OBSERVATION", NA, "fossil_specimen"),
           establishmentMeans = c("introduced", "MANAGED", "native", NA, "Naturalised"))
  f <- flag_occurrences(x, tests = c("issue_geo", "issue_tax", "issue_date", "rounded", "fossil", "living", "introduced", "managed"))
  expect_identical(f$flag_rounded, c(TRUE, FALSE, FALSE, FALSE, FALSE))
  expect_identical(f$flag_issue_tax, c(TRUE, FALSE, FALSE, FALSE, FALSE))
  expect_identical(f$flag_issue_date, c(FALSE, TRUE, FALSE, FALSE, FALSE))
  expect_identical(f$flag_issue_geo, c(FALSE, FALSE, TRUE, FALSE, FALSE))
  expect_identical(f$flag_fossil, c(TRUE, FALSE, FALSE, FALSE, TRUE))
  expect_identical(f$flag_living, c(FALSE, TRUE, FALSE, FALSE, FALSE))
  expect_identical(f$flag_introduced, c(TRUE, FALSE, FALSE, FALSE, TRUE))
  expect_identical(f$flag_managed, c(FALSE, TRUE, FALSE, FALSE, FALSE))
  # list column for issues
  x$issue <- list(c("COORDINATE_ROUNDED"), character(), "TAXON_MATCH_HIGHERRANK", NULL, "x")
  f <- flag_occurrences(x, tests = c("rounded", "issue_tax"))
  expect_identical(f$flag_rounded, c(TRUE, FALSE, FALSE, FALSE, FALSE))
  expect_identical(f$flag_issue_tax, c(FALSE, FALSE, TRUE, FALSE, FALSE))
})

test_that("lower-case GBIF snapshot columns are found by the defaults", {
  x <- data.frame(decimallongitude = c(12.58, 0), decimallatitude = c(55.67, 0), species = "a")
  f <- flag_occurrences(x, tests = c("zero", "gbif"))
  expect_identical(f$flag_gbif, c(TRUE, FALSE))
  expect_identical(f$flag_zero, c(FALSE, TRUE))
  y <- data.frame(x = 12.58, y = 55.67, taxon = "a")
  f <- flag_occurrences(y, tests = c("gbif", "dupl"), columns = occ_columns(lon = "x", lat = "y", species = "taxon"))
  expect_true(f$flag_gbif)
  expect_error(flag_occurrences(y, tests = "gbif"), "decimalLongitude")
  expect_error(flag_occurrences(y, tests = "bogus"), "unknown test")
})

test_that("the flag word is the OR of the per-test bits and nothing is dropped", {
  set.seed(9)
  x <- pts(decimalLongitude = runif(500, -180, 180), decimalLatitude = runif(500, -90, 90), species = sample(letters[1:3], 500, TRUE))
  f <- flag_occurrences(x)
  expect_identical(nrow(f), 500L)
  expect_identical(f$decimalLongitude, x$decimalLongitude)
  recon <- Reduce(bitwOr, lapply(default_tests(), function(t) ifelse(f[[paste0("flag_", t)]], flag_mask(t), 0L)))
  expect_identical(f$flags, recon)
  expect_true(any(f$flag_sea))
})
