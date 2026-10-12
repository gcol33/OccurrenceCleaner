# Extracted from test-gazetteers.R:60

# prequel ----------------------------------------------------------------------
square <- function(x0, y0, w, crs = 4326) {
  m <- matrix(c(x0, y0, x0 + w, y0, x0 + w, y0 + w, x0, y0 + w, x0, y0), ncol = 2, byrow = TRUE)
  structure(list(m), class = c("XY", "POLYGON", "sfg"))
}
as_sfc <- function(polys, epsg = 4326) {
  structure(polys, class = c("sfc_POLYGON", "sfc"), crs = list(epsg = epsg))
}

# test -------------------------------------------------------------------------
src <- tempfile("src")
dir.create(src)
vectra::write_vtr(data.frame(decimalLongitude = c(10, 20), decimalLatitude = c(50, 50)), file.path(src, "a.vtr"))
out <- tempfile("out")
f <- flag_occurrences(src, tests = "capital", out = out, verbose = FALSE,
                        gazetteers = list(capital = data.frame(lon = 10, lat = 50)))
expect_match(f$reference, "custom: capital")
expect_error(flag_occurrences(src, tests = "capital", out = out, verbose = FALSE,
                                gazetteers = list(capital = data.frame(lon = 20, lat = 50))),
               "different tests, layout or reference")
