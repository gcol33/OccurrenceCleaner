# Ages per taxon per replicate, read back from a PyRate input file.
parse_pyrate <- function(path) {
  lines <- readLines(path)
  out <- list()
  for (l in lines) {
    if (grepl("^data_[0-9]+=\\[", l)) out[[length(out) + 1L]] <- list()
    for (a in regmatches(l, gregexpr("array\\(\\[[^]]*\\]\\)", l))[[1]]) {
      v <- as.numeric(strsplit(gsub("array\\(\\[|\\]\\)", "", a), ",")[[1]])
      out[[length(out)]][[length(out[[length(out)]]) + 1L]] <- sort(v)
    }
  }
  out
}

fossils <- function() {
  data.frame(accepted_name = c("Equus caballus", "Equus caballus", "Hipparion sp", "Hipparion sp", "Mesohippus"),
             min_ma = c(0, 1.2, 5, 7.5, 30), max_ma = c(1, 2.6, 11, 9, 37),
             status = c("extant", "extant", "extinct", "extinct", "extinct"))
}

test_that("export_pyrate writes the arrays, taxa and status of write_pyrate", {
  skip_if_not_installed("CoordinateCleaner")
  x <- fossils()
  d <- tempfile("pyrate"); dir.create(d)
  ours <- export_pyrate(x, file.path(d, "ours"), status = "status",
                        columns = occ_columns(species = "accepted_name"), random = FALSE)
  suppressMessages(utils::capture.output(
    CoordinateCleaner::write_pyrate(x, status = x$status, fname = "theirs", path = d, random = FALSE)))
  expect_identical(parse_pyrate(ours[1]), parse_pyrate(file.path(d, "theirs_PyRate.py")))
  py <- readLines(ours[1])
  expect_true("taxa_names=['Equus_caballus','Hipparion_sp','Mesohippus']" %in% py)
  tl <- utils::read.delim(ours[2])
  expect_identical(tl$Status, c("extant", "extinct", "extinct"))
})

test_that("export_pyrate draws ages within the ranges, reproducibly with a seed", {
  x <- fossils()
  cols <- occ_columns(species = "accepted_name")
  a <- export_pyrate(x, tempfile("p"), status = "status", columns = cols, replicates = 3, seed = 4)
  ages <- parse_pyrate(a[1])
  expect_length(ages, 3)
  meso <- vapply(ages, function(r) r[[3]], 0)
  expect_true(all(meso >= 30 & meso <= 37))
  b <- export_pyrate(x, tempfile("p"), status = "status", columns = cols, replicates = 3, seed = 4)
  expect_identical(parse_pyrate(b[1]), ages)
  expect_true("d=[data_1,data_2,data_3]" %in% readLines(a[1]))
})

test_that("export_pyrate checks status, missing values and traits", {
  x <- fossils()
  cols <- occ_columns(species = "accepted_name")
  expect_error(export_pyrate(x, tempfile(), status = c("extant", "extinct", "extinct", "extinct", "extinct"),
                             columns = cols), "both extinct and extant")
  y <- x
  y$min_ma[2] <- NA
  expect_error(export_pyrate(y, tempfile(), status = "status", columns = cols), "missing")
  t <- export_pyrate(x, tempfile(), status = "status", columns = cols, trait = c(1, 3, 2, 2, 5), random = FALSE)
  expect_true("trait1=array([2, 2, 5])" %in% readLines(t[1]))
})
