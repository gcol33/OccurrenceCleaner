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
  want <- flag_occurrences(rbind(d1, d2), tests = tests)
  expect_identical(names(got), c("gbifid", "kingdom", "year", "flags"))
  expect_identical(got$gbifid, want$gbifid)
  expect_identical(got$flags, want$flags)

  # resume: a second run touches nothing and reports the same counts
  res2 <- flag_occurrences(src, tests = tests, out = out, keep = c("kingdom", "year"), part_rows = 100, verbose = FALSE)
  expect_identical(res2$n, 550)
  expect_identical(res2$parts, res$parts)
  expect_message(flag_occurrences(src, tests = tests, out = out, keep = c("kingdom", "year"), part_rows = 100), "skipped")
  # different tests into the same directory is refused
  expect_error(flag_occurrences(src, tests = "invalid", out = out, keep = c("kingdom", "year"), verbose = FALSE),
               "different configuration \\(tests\\)")

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
  expect_error(flag_occurrences(vectra::tbl(file.path(src, "a.vtr")), tests = c("zero", "outlier"),
                                out = tempfile(), verbose = FALSE), "pass the file or directory path")
  expect_error(flag_occurrences(file.path(src, "b.vtr"), tests = "duplicate", duplicate_by = "nope",
                                out = tempfile(), verbose = FALSE), "duplicate_by")
  expect_error(flag_occurrences(src, tests = "zero"), "`out`")
  expect_error(flag_occurrences(src, tests = "zero", out = tempfile(), keep = "nope", verbose = FALSE), "keep")
  expect_error(flag_occurrences(tempfile(), tests = "zero", out = tempfile()), "not found")
})

test_that("worker processes write the same parts and markers as one process", {
  skip_if_not_installed("vectra")
  skip_on_cran()
  skip_if_not(file.exists(file.path(find.package("OccurrenceCleaner"), "Meta", "package.rds")),
              "workers load the installed package")
  src <- tempfile("wsrc"); dir.create(src)
  for (i in 1:5) {
    d <- make_table(400, i)
    d$species[1:40] <- make_table(400, 1)$species[1:40]
    d[1:40, c("decimallongitude", "decimallatitude")] <- make_table(400, 1)[1:40, c("decimallongitude", "decimallatitude")]
    d$countrycode <- sample(c("AT", "FR", "BR", ""), 400, TRUE)
    vectra::write_vtr(d, file.path(src, sprintf("p%d.vtr", i)), batch_size = 150)
  }
  tests <- c("invalid", "zero", "capital", "institution", "sea", "urban", "country_mismatch", "duplicate",
             "outlier")
  run <- function(out, workers) flag_occurrences(src, tests = tests, out = out, keep = c("kingdom", "year"),
                                                 part_rows = 200, verbose = FALSE, workers = workers)
  one <- run(tempfile("w1"), 1)
  two <- run(tempfile("w2"), 2)
  files <- function(o) sort(list.files(o$out, "^part-|[.]done$"))
  expect_identical(files(two), files(one))
  md5 <- function(o) unname(tools::md5sum(file.path(o$out, files(o))))
  expect_identical(md5(two), md5(one))
  drop <- c("out", "finished")
  expect_identical(unclass(two)[setdiff(names(two), drop)], unclass(one)[setdiff(names(one), drop)])
  expect_true(any(has_flag(vectra::collect(flagged_table(one))$flags, "duplicate")))

  # a resumed run hands only the files without a marker to the workers
  unlink(file.path(two$out, c("p2.done", "p4.done")))
  three <- run(two$out, 2)
  expect_identical(md5(three), md5(one))
  expect_error(flag_occurrences(src, tests = "zero", out = tempfile(), workers = 0), "at least 1")
})

test_that("duplicates are found across chunks and files, as in the whole table", {
  skip_if_not_installed("vectra")
  set.seed(3)
  x <- data.frame(gbifid = as.character(1:400), species = sample(c("a", "b"), 400, TRUE),
                  decimallongitude = sample(1:20, 400, TRUE) + 0.5, decimallatitude = sample(1:5, 400, TRUE) + 0.5,
                  eventdate = sample(c("2001", "2002"), 400, TRUE), stringsAsFactors = FALSE)
  src <- tempfile("dsrc"); dir.create(src)
  vectra::write_vtr(x[1:200, ], file.path(src, "p1.vtr"), batch_size = 37)
  vectra::write_vtr(x[201:400, ], file.path(src, "p2.vtr"), batch_size = 37)
  chunks <- vectra::collect_chunked(vectra::tbl(file.path(src, "p1.vtr")), function(acc, ch) acc + 1L, .init = 0L)
  expect_gt(chunks, 1L)
  for (args in list(list(), list(duplicate_by = "eventdate"), list(duplicate_cell = 2))) {
    whole <- do.call(flag_occurrences, c(list(x, tests = c("invalid", "duplicate")), args))
    # copies of a record from another chunk of the same file, and from the other file
    expect_gt(sum(whole$flag_duplicate[38:200]), 0)
    expect_gt(sum(whole$flag_duplicate[201:400]), 0)
    o <- do.call(flag_occurrences, c(list(src, tests = c("invalid", "duplicate"), out = tempfile(),
                                          verbose = FALSE), args))
    got <- vectra::collect(flagged_table(o))
    expect_identical(got$gbifid, x$gbifid)
    expect_identical(got$flags, whole$flags)
  }
  expect_message(flag_occurrences(src, tests = "duplicate", out = tempfile()), "duplicate: [0-9]+ bucket")
})

test_that("repair_duplicates replaces chunk-local duplicate bits with whole-input ones", {
  skip_if_not_installed("vectra")
  set.seed(5)
  x <- data.frame(gbifid = as.character(1:300), species = sample(c("a", "b"), 300, TRUE),
                  decimallongitude = sample(1:15, 300, TRUE) + 0.5, decimallatitude = sample(1:4, 300, TRUE) + 0.5,
                  stringsAsFactors = FALSE)
  src <- tempfile("rsrc"); dir.create(src)
  vectra::write_vtr(x[1:150, ], file.path(src, "p1.vtr"), batch_size = 40)
  vectra::write_vtr(x[151:300, ], file.path(src, "p2.vtr"), batch_size = 40)
  tests <- c("invalid", "zero", "duplicate")
  out <- tempfile("rout")
  o <- flag_occurrences(src, tests = tests, out = out, part_rows = 60, verbose = FALSE)
  whole <- flag_occurrences(x, tests = tests)
  # the bits a chunk-local test leaves: duplicates only within each chunk of 40
  local <- unlist(lapply(split(x, (seq_len(300) - 1) %/% 40), function(d)
    duplicated(d[, c("decimallongitude", "decimallatitude", "species")])))
  expect_false(identical(local, whole$flag_duplicate))
  for (p in file.path(out, o$parts)) {
    d <- as.data.frame(vectra::collect(vectra::tbl(p)))
    i <- match(d$gbifid, x$gbifid)
    d$flags <- bitwOr(bitwAnd(d$flags, bitwNot(flag_mask("duplicate"))),
                      ifelse(local[i], flag_mask("duplicate"), 0L))
    vectra::write_vtr(d, p, col_types = c(flags = "int32"))
  }
  r <- repair_duplicates(out, src, verbose = FALSE)
  got <- vectra::collect(flagged_table(r))
  expect_identical(got$flags, whole$flags)
  expect_false(dir.exists(file.path(out, ".repair")))
  expect_false(is.null(r$duplicate_repair))
  # a second repair changes nothing
  r <- repair_duplicates(out, src, verbose = FALSE)
  expect_identical(vectra::collect(flagged_table(r))$flags, whole$flags)
})

test_that("an output directory refuses a rerun with other settings or changed input", {
  skip_if_not_installed("vectra")
  src <- tempfile("csrc"); dir.create(src)
  vectra::write_vtr(make_table(100, 1), file.path(src, "a.vtr"))
  vectra::write_vtr(make_table(100, 2), file.path(src, "b.vtr"))
  out <- tempfile("cout")
  run <- function(...) flag_occurrences(src, tests = c("zero", "capital"), out = out, keep = "kingdom",
                                        verbose = FALSE, ...)
  run()
  expect_true(file.exists(file.path(out, "flags_config.rds")))
  expect_error(flag_occurrences(src, tests = c("zero", "capital"), out = out, keep = "year", verbose = FALSE),
               "different configuration \\(keep\\)")
  expect_error(run(buffers = list(capital = 5000)), "different configuration \\(buffers\\)")
  expect_error(run(columns = occ_columns(id = "kingdom")), "different configuration \\(columns\\)")
  Sys.setFileTime(file.path(src, "b.vtr"), Sys.time() + 60)
  expect_error(run(), "input file\\(s\\) changed: b")
  vectra::write_vtr(make_table(10, 3), file.path(src, "c.vtr"))
  expect_error(run(), "input files")
  # resume = FALSE starts the directory over with the new input
  expect_identical(run(resume = FALSE)$n, 210)
  expect_identical(run()$n, 210)

  # the record is written before the first output, so an interrupted first run is checked too
  out2 <- tempfile("cout2")
  with_mocked_bindings(
    expect_error(flag_occurrences(src, tests = "zero", out = out2, verbose = FALSE), "interrupted"),
    flush_part = function(...) stop("interrupted"))
  expect_true(file.exists(file.path(out2, "flags_config.rds")))
  expect_error(flag_occurrences(src, tests = "capital", out = out2, verbose = FALSE), "different configuration")
  expect_identical(flag_occurrences(src, tests = "zero", out = out2, verbose = FALSE)$n, 210)
})

test_that("a slice of the GBIF snapshot streams through tbl_parquet", {
  skip_if_not_installed("vectra")
  snap <- Sys.getenv("OCC_GBIF_SNAPSHOT", "E:/research/raw/occurrences/gbif_snapshot/2026-10-01/occurrence.parquet")
  skip_if_not(dir.exists(snap), "GBIF snapshot not available")
  parts <- head(sort(list.files(snap, full.names = TRUE)), 3)
  out <- tempfile("gbif")
  res <- flag_occurrences(parts, tests = c(cc_default, "country_mismatch", "issue_rounded", "basis_fossil"), out = out,
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
