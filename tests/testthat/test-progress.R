test_that("the estimate times the current step and scales the steps ahead", {
  now <- 0
  p <- new_progress(c("pass1", "record"), clock = function() now)
  p$steps$cost <- c(1, 2)
  progress_size(p, "pass1", 100)
  progress_size(p, "record", 100)
  progress_start(p, "pass1")
  now <- 10
  progress_tick(p, 50)
  e <- progress_estimate(p)
  expect_equal(e$step_eta, 10)
  # 10 s for 50 reference seconds: the record step's 200 reference seconds take 40 s
  expect_equal(e$run_eta, 50)
  expect_equal(e$fraction, 50 / 300)

  # items done before a resume count as done but are not timed
  q <- new_progress(c("pass1", "record"), clock = function() now)
  q$steps$cost <- c(1, 2)
  progress_size(q, "pass1", 100)
  progress_size(q, "record", 100)
  now <- 0
  progress_start(q, "pass1", done = 50)
  now <- 5
  progress_tick(q, 25)
  e <- progress_estimate(q)
  expect_equal(e$step_eta, 5)
  expect_equal(e$run_eta, 5 + 200 * 5 / 25)
  expect_equal(e$fraction, 75 / 300)

  progress_end(q)
  expect_equal(q$steps$total[1], 75)
})

test_that("a streamed run writes its progress file and finishes at the whole run", {
  skip_if_not_installed("vectra")
  src <- tempfile("src"); dir.create(src)
  set.seed(1)
  for (k in 1:2) vectra::write_vtr(
    data.frame(species = sample(c("a", "b"), 200, TRUE), decimallongitude = runif(200, -10, 10),
               decimallatitude = runif(200, -10, 10)), file.path(src, paste0(k, ".vtr")))
  out <- tempfile("out")
  expect_message(flag_occurrences(src, tests = c("zero", "duplicate", "outlier"), out = out, verbose = TRUE),
                 "progress: record pass")
  line <- strsplit(readLines(file.path(out, "progress.txt")), " ")[[1]]
  expect_identical(line[1], "record")
  expect_identical(line[2:3], c("400", "400"))
  expect_identical(as.numeric(line[6]), 0)
  expect_identical(as.numeric(line[7]), 1)
})
