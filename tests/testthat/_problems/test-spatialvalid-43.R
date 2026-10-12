# Extracted from test-spatialvalid.R:43

# prequel ----------------------------------------------------------------------
recs <- function() {
  data.frame(species = c("a", "a", "b", "b"),
             decimalLongitude = c(0, 16.37, 10, 10),
             decimalLatitude = c(0, 48.21, 50, 50))
}

# test -------------------------------------------------------------------------
src <- tempfile("src")
dir.create(src)
out <- tempfile("flags")
on.exit(unlink(c(src, out), recursive = TRUE), add = TRUE)
x <- recs()
vectra::write_vtr(x, file.path(src, "a.vtr"))
m <- flag_occurrences(src, tests = c("zero", "capital"), out = out, keep = "species", verbose = FALSE)
sv <- as_spatialvalid(out)
expect_identical(names(sv), c("species", ".zer", ".cap", ".summary"))
expect_identical(sv$.summary, !has_flag(flag_occurrences(x, tests = c("zero", "capital"))$flags,
                                          c("zero", "capital")))
