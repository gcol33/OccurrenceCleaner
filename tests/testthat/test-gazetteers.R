square <- function(x0, y0, w, crs = 4326) {
  m <- matrix(c(x0, y0, x0 + w, y0, x0 + w, y0 + w, x0, y0 + w, x0, y0), ncol = 2, byrow = TRUE)
  structure(list(m), class = c("XY", "POLYGON", "sfg"))
}
as_sfc <- function(polys, epsg = 4326) {
  structure(polys, class = c("sfc_POLYGON", "sfc"), crs = list(epsg = epsg))
}

test_that("a point gazetteer replaces the reference points of one test", {
  g <- data.frame(Longitude = 10, Latitude = 50)
  x <- data.frame(decimalLongitude = c(10, 10.05, 16.37), decimalLatitude = c(50, 50, 48.21))
  f <- flag_occurrences(x, tests = c("capital", "centroid"), gazetteers = list(capital = g))
  # 10.05 E is about 3.6 km east of the custom point at 50 N
  expect_identical(f$flag_capital, c(TRUE, TRUE, FALSE))
  expect_match(attr(f, "occ_reference"), "custom: capital 1 points md5 [0-9a-f]{32}")
  f2 <- flag_occurrences(x, tests = "capital", gazetteers = list(capital = g), buffers = list(capital = 1000))
  expect_identical(f2$flag_capital, c(TRUE, FALSE, FALSE))
})

test_that("polygon gazetteers replace land, urban areas and countries", {
  land <- as_sfc(list(square(0, 0, 10)))
  x <- data.frame(decimalLongitude = c(5, 15, -5), decimalLatitude = c(5, 5, 5), code = c("XA", "XA", "XB"))
  f <- flag_occurrences(x, tests = c("sea", "urban"), gazetteers = list(sea = land, urban = land))
  expect_identical(f$flag_sea, c(FALSE, TRUE, TRUE))
  expect_identical(f$flag_urban, c(TRUE, FALSE, FALSE))

  countries <- structure(data.frame(Code = c("XA", "XB")), class = c("sf", "data.frame"), sf_column = "geometry")
  countries$geometry <- as_sfc(list(square(0, 0, 10), square(-10, 0, 10)))
  f <- flag_occurrences(x, tests = "country_mismatch", columns = occ_columns(country = "code"),
                        gazetteers = list(country_mismatch = countries))
  expect_identical(f$flag_country_mismatch, c(FALSE, TRUE, FALSE))
})

test_that("gazetteers are validated", {
  x <- data.frame(decimalLongitude = 1, decimalLatitude = 1)
  expect_error(flag_occurrences(x, tests = "capital", gazetteers = data.frame(lon = 1, lat = 1)), "named list")
  expect_error(flag_occurrences(x, tests = "zero", gazetteers = list(zero = data.frame(lon = 1, lat = 1))),
               "no reference layer")
  expect_error(flag_occurrences(x, tests = "capital", gazetteers = list(capital = data.frame(a = 1))),
               "longitude and latitude")
  expect_error(flag_occurrences(x, tests = "sea", gazetteers = list(sea = data.frame(lon = 1, lat = 1))),
               "sf or sfc")
  expect_error(flag_occurrences(x, tests = "sea", gazetteers = list(sea = as_sfc(list(square(0, 0, 1)), 3035))),
               "EPSG:4326")
  expect_error(flag_occurrences(x, tests = "country_mismatch", columns = occ_columns(country = "decimalLongitude"),
                                gazetteers = list(country_mismatch = as_sfc(list(square(0, 0, 1))))),
               "code column")
})

test_that("streamed output refuses a different custom gazetteer", {
  src <- tempfile("src"); dir.create(src)
  vectra::write_vtr(data.frame(decimalLongitude = c(10, 20), decimalLatitude = c(50, 50)), file.path(src, "a.vtr"))
  out <- tempfile("out")
  f <- flag_occurrences(src, tests = "capital", out = out, verbose = FALSE,
                        gazetteers = list(capital = data.frame(lon = 10, lat = 50)))
  expect_match(f$reference, "custom: capital")
  expect_error(flag_occurrences(src, tests = "capital", out = out, verbose = FALSE,
                                gazetteers = list(capital = data.frame(lon = 20, lat = 50))),
               "different configuration \\(reference")
})

test_that("custom gazetteers give CoordinateCleaner's flags with the same ref", {
  skip_if_not_installed("CoordinateCleaner")
  skip_if_not_installed("geosphere")
  skip_if_not_installed("sf")
  cc <- function(fn, x, ...) !suppressWarnings(suppressMessages(fn(x, value = "flagged", verbose = FALSE, ...)))
  set.seed(11)
  ref <- data.frame(lon = runif(30, -20, 40), lat = runif(30, 30, 60))
  i <- sample(30, 1500, TRUE)
  p <- geosphere::destPoint(as.matrix(ref[i, ]), runif(1500, 0, 360), runif(1500, 0, 2000))
  x <- data.frame(species = "a", decimalLongitude = p[, 1], decimalLatitude = p[, 2])
  ours <- flag_occurrences(x, tests = "institution", gazetteers = list(institution = ref),
                           buffers = list(institution = 1000))$flag_institution
  theirs <- cc(CoordinateCleaner::cc_inst, x, buffer = 1000,
               ref = data.frame(decimalLongitude = ref$lon, decimalLatitude = ref$lat))
  expect_true(all(ours[theirs]))
  extra <- which(ours & !theirs)
  d <- apply(geosphere::distm(cbind(x$decimalLongitude[extra], x$decimalLatitude[extra]), as.matrix(ref)), 1, min)
  expect_true(all(d >= 1000 * cos(pi / 40) * (1 - 1e-6)))

  land <- sf::st_sf(geometry = sf::st_sfc(sf::st_polygon(list(rbind(c(0, 0), c(20, 0), c(20, 10), c(0, 0)))),
                                          crs = 4326))
  y <- data.frame(species = "a", decimalLongitude = runif(800, -5, 25), decimalLatitude = runif(800, -5, 15))
  expect_identical(flag_occurrences(y, tests = "sea", gazetteers = list(sea = land))$flag_sea,
                   cc(CoordinateCleaner::cc_sea, y, ref = land))
})

test_that("no shipped institution lies at coordinates the zero test flags", {
  inst <- reference_points("institution")
  f <- flag_occurrences(data.frame(decimalLongitude = inst$lon, decimalLatitude = inst$lat), tests = "zero")
  expect_false(any(f$flag_zero))
})
