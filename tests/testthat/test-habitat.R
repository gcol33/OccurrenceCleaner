test_that("the habitat table classes known genera by IRMNG's flags", {
  h <- reference_habitat()
  expect_named(h, c("kingdom", "genus", "marine"))
  expect_false(anyDuplicated(paste(h$kingdom, h$genus)) > 0)
  cls <- function(k, g) h$marine[h$kingdom == k & h$genus == g]
  expect_false(cls("Plantae", "Quercus"))
  expect_false(cls("Animalia", "Homo"))
  expect_true(cls("Animalia", "Asterias"))
  expect_true(cls("Animalia", "Acropora"))
  expect_length(cls("Animalia", "Larus"), 0L)
  expect_false(cls("Plantae", "Asterias"))
})

test_that("sea_nonmarine and land_marine combine the land test with the genus habitat", {
  x <- data.frame(kingdom = c("Plantae", "Animalia", "Animalia", "Plantae", "Animalia"),
                  genus = c("Quercus", "Asterias", "Asterias", "Quercus", "Larus"),
                  decimalLongitude = c(-30, 16.37, -30, 16.37, -30),
                  decimalLatitude = c(40, 48.21, 40, 48.21, 40))
  f <- flag_occurrences(x, tests = c("sea", "sea_nonmarine", "land_marine"))
  expect_identical(f$flag_sea, c(TRUE, FALSE, TRUE, FALSE, TRUE))
  expect_identical(f$flag_sea_nonmarine, c(TRUE, FALSE, FALSE, FALSE, FALSE))
  expect_identical(f$flag_land_marine, c(FALSE, TRUE, FALSE, FALSE, FALSE))
})

test_that("the kingdom resolves homonyms and a binomial works as the genus", {
  x <- data.frame(kingdom = c("Animalia", "Plantae", "", NA),
                  species = c("Asterias rubens", "Asterias x", "Asterias rubens", "Quercus robur"),
                  decimalLongitude = 16.37, decimalLatitude = 48.21)
  f <- flag_occurrences(x, tests = "land_marine", columns = occ_columns(genus = "species"))
  expect_identical(f$flag_land_marine, c(TRUE, FALSE, FALSE, FALSE))
  no_kingdom <- flag_occurrences(x[, -1], tests = "land_marine", columns = occ_columns(genus = "species"))
  expect_identical(no_kingdom$flag_land_marine, rep(FALSE, 4))
})

test_that("records with invalid coordinates or an unknown genus are not flagged", {
  x <- data.frame(genus = c("Quercus", "Notagenusatall", NA),
                  decimalLongitude = c(NA, -30, -30), decimalLatitude = c(40, 40, 40))
  f <- flag_occurrences(x, tests = c("sea_nonmarine", "land_marine"))
  expect_identical(f$flag_sea_nonmarine, rep(FALSE, 3))
  expect_identical(f$flag_land_marine, rep(FALSE, 3))
})

test_that("the buffers leave records near the coast untested", {
  z <- data.frame(genus = c("Quercus", "Quercus"), decimalLongitude = c(-9.6, -30),
                  decimalLatitude = c(38.7, 40))
  f0 <- flag_occurrences(z, tests = c("sea", "sea_nonmarine"), land_scale = 50)
  expect_identical(f0$flag_sea_nonmarine, c(TRUE, TRUE))
  f1 <- flag_occurrences(z, tests = "sea_nonmarine", land_scale = 50,
                         buffers = list(sea_nonmarine = 50000))
  expect_identical(f1$flag_sea_nonmarine, c(FALSE, TRUE))
  inland <- data.frame(kingdom = "Animalia", genus = c("Asterias", "Asterias"), decimalLongitude = c(-9.1, 16.37),
                       decimalLatitude = c(38.75, 48.21))
  f2 <- flag_occurrences(inland, tests = "land_marine", land_scale = 50,
                         buffers = list(land_marine = 50000))
  expect_identical(f2$flag_land_marine, c(FALSE, TRUE))
})

test_that("a user habitat table replaces the shipped one and is recorded", {
  y <- data.frame(genus = c("Foo", "Bar", "Quercus"), decimalLongitude = c(-30, 16.37, -30),
                  decimalLatitude = c(40, 48.21, 40))
  h <- data.frame(genus = c("Foo", "Bar"), marine = c(FALSE, TRUE))
  f <- flag_occurrences(y, tests = c("sea_nonmarine", "land_marine"), gazetteers = list(habitat = h))
  expect_identical(f$flag_sea_nonmarine, c(TRUE, FALSE, FALSE))
  expect_identical(f$flag_land_marine, c(FALSE, TRUE, FALSE))
  expect_match(attr(f, "occ_reference"), "custom: habitat 2 genera md5")
  expect_error(flag_occurrences(y, tests = "land_marine", gazetteers = list(habitat = data.frame(genus = "Foo"))),
               "genus column and a logical marine column")
  expect_error(flag_occurrences(y, tests = "land_marine",
                                gazetteers = list(habitat = data.frame(genus = "Foo", marine = "yes"))),
               "must be logical")
})

test_that("the habitat tests need a genus column", {
  x <- data.frame(decimalLongitude = 0, decimalLatitude = 0)
  expect_error(flag_occurrences(x, tests = "sea_nonmarine"), "field `genus`")
})
