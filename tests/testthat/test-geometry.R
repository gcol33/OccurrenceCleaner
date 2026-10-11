geodesic <- function(lon1, lat1, lon2, lat2) OccurrenceCleaner:::cpp_geodesic_m(lon1, lat1, lon2, lat2)

test_that("geodesic distance matches geosphere::distGeo", {
  skip_if_not_installed("geosphere")
  set.seed(11)
  n <- 2000
  lon1 <- runif(n, -180, 180); lat1 <- runif(n, -89, 89)
  # mostly short distances, as the tests use them, plus some long ones
  d <- c(runif(n / 2, 1, 20000), runif(n / 2, 1e5, 1.5e7))
  p2 <- geosphere::destPoint(cbind(lon1, lat1), runif(n, 0, 360), d)
  got <- geodesic(lon1, lat1, p2[, 1], p2[, 2])
  want <- geosphere::distGeo(cbind(lon1, lat1), p2)
  expect_true(all(abs(got - want) < 1e-3))
  expect_identical(geodesic(0, 0, 0, 0), 0)
  expect_true(is.na(geodesic(NA, 0, 0, 0)))
})

test_that("point index flags closed geodesic balls, including the antimeridian and poles", {
  ref_lon <- c(179.9999, -179.9999, 0, 30, 12.58)
  ref_lat <- c(0, 60, 89.999, -89.9, 55.67)
  idx <- OccurrenceCleaner:::cpp_point_index(ref_lon, ref_lat)
  skip_if_not_installed("geosphere")
  for (i in seq_along(ref_lon)) for (b in c(0, 90, 180, 270, 45.5)) {
    r <- 1000
    inside <- geosphere::destPoint(c(ref_lon[i], ref_lat[i]), b, r - 0.01)
    outside <- geosphere::destPoint(c(ref_lon[i], ref_lat[i]), b, r + 0.01)
    expect_true(OccurrenceCleaner:::cpp_point_within(idx, inside[1], inside[2], r), info = paste(i, b))
    expect_false(OccurrenceCleaner:::cpp_point_within(idx, outside[1], outside[2], r), info = paste(i, b))
  }
  # longitude wrap: a point just across the antimeridian from reference 1
  expect_true(OccurrenceCleaner:::cpp_point_within(idx, -179.9999, 0, 100))
  expect_false(OccurrenceCleaner:::cpp_point_within(idx, NA, 0, 100))
  expect_false(OccurrenceCleaner:::cpp_point_within(idx, 0, NA, 100))
  nn <- OccurrenceCleaner:::cpp_point_nearest(idx, c(12.6, NA), c(55.7, 1))
  expect_identical(nn$index, c(5L, NA))
  expect_equal(nn$distance_m[1], geosphere::distGeo(c(12.6, 55.7), c(12.58, 55.67)), tolerance = 1e-6)
})

test_that("point index agrees with brute force on random points", {
  skip_if_not_installed("geosphere")
  set.seed(5)
  ref <- cbind(runif(300, -180, 180), runif(300, -90, 90))
  idx <- OccurrenceCleaner:::cpp_point_index(ref[, 1], ref[, 2])
  # queries near references so that hits occur
  q <- geosphere::destPoint(ref[sample(300, 3000, TRUE), ], runif(3000, 0, 360), runif(3000, 0, 20000))
  r <- 10000
  got <- OccurrenceCleaner:::cpp_point_within(idx, q[, 1], q[, 2], r)
  want <- vapply(seq_len(nrow(q)), function(i) any(geosphere::distGeo(q[i, , drop = FALSE], ref) <= r), logical(1))
  expect_identical(got, want)
})

# Even-odd brute force used to check the polygon index.
pip <- function(px, py, vx, vy) {
  n <- length(vx); j <- n; inside <- FALSE
  for (i in seq_len(n)) {
    if ((vy[i] > py) != (vy[j] > py) && px < (vx[j] - vx[i]) * (py - vy[i]) / (vy[j] - vy[i]) + vx[i]) inside <- !inside
    j <- i
  }
  inside
}

test_that("polygon index resolves holes, shared borders and boundaries", {
  x <- c(0, 10, 10, 0,  4, 6, 6, 4,  10, 30, 30, 10)
  y <- c(0, 0, 10, 10,  4, 4, 6, 6,  -5, -5, 5, 5)
  rs <- c(0L, 4L, 8L, 12L); rf <- c(1L, 1L, 2L)
  q <- data.frame(lon = c(5, 1, 9.9, 5, 0, 10, 5, 25, 10, 30.1, 15, 0.001, 9.999, 4.5, 3.9, 6.1, 10, 10),
                  lat = c(1, 9, 9.9, 5, 5, 7, 0, 0, -5, 0, 0, 0.001, 9.999, 4.5, 5, 5, 3, -3))
  want <- c(1, 1, 1, 0, 1, 1, 1, 2, 2, 0, 2, 1, 1, 0, 1, 1, 1, 2)
  for (cell in c(0.5, 1, 3, 7)) {
    p <- OccurrenceCleaner:::cpp_polygon_index(x, y, rs, rf, cell)
    expect_identical(OccurrenceCleaner:::cpp_polygon_locate(p, q$lon, q$lat), as.integer(want), info = cell)
  }
  set.seed(2)
  rl <- runif(20000, -2, 32); rt <- runif(20000, -7, 12)
  want <- vapply(seq_along(rl), function(i) {
    a <- pip(rl[i], rt[i], x[1:4], y[1:4]); h <- pip(rl[i], rt[i], x[5:8], y[5:8]); b <- pip(rl[i], rt[i], x[9:12], y[9:12])
    if (a != h) 1L else if (b) 2L else 0L
  }, 1L)
  for (cell in c(0.37, 1, 2.5)) {
    p <- OccurrenceCleaner:::cpp_polygon_index(x, y, rs, rf, cell)
    expect_identical(OccurrenceCleaner:::cpp_polygon_locate(p, rl, rt), want, info = cell)
  }
  p <- OccurrenceCleaner:::cpp_polygon_index(x, y, rs, rf, 1)
  expect_identical(OccurrenceCleaner:::cpp_polygon_locate(p, c(NA, 200, 5), c(1, 1, NA)), c(0L, 0L, 0L))
  expect_error(OccurrenceCleaner:::cpp_polygon_index(x, y, rs, rf, 0), "positive")
  expect_error(OccurrenceCleaner:::cpp_polygon_index(x, y, rs[-1], rf, 1), "one more")
})

test_that("land index agrees with brute force on the bundled 1:110m layer", {
  L <- OccurrenceCleaner:::ref_land_110
  xs <- L$x / 1e7; ys <- L$y / 1e7
  set.seed(3)
  n <- 3000
  rl <- runif(n, -180, 180); rt <- runif(n, -90, 90)
  want <- logical(n)
  for (r in seq_along(L$ring_feature)) {
    i0 <- L$ring_start[r] + 1; i1 <- L$ring_start[r + 1]
    vx <- xs[i0:i1]; vy <- ys[i0:i1]
    bb <- range(vx); bby <- range(vy)
    for (i in which(rl >= bb[1] & rl <= bb[2] & rt >= bby[1] & rt <= bby[2]))
      if (pip(rl[i], rt[i], vx, vy)) want[i] <- !want[i]
  }
  idx <- OccurrenceCleaner:::polygon_index("sea", "OccurrenceCleaner", 110)$index
  got <- OccurrenceCleaner:::cpp_polygon_locate(idx, rl, rt) > 0
  expect_identical(got, want)
  # the poles and the antimeridian
  expect_true(OccurrenceCleaner:::cpp_polygon_locate(idx, 0, -89.99) > 0)   # Antarctica
  expect_identical(OccurrenceCleaner:::cpp_polygon_locate(idx, 0, 89.99), 0L)  # Arctic ocean
  expect_true(OccurrenceCleaner:::cpp_polygon_locate(idx, 179.99, 66) > 0)   # Chukotka
  expect_true(OccurrenceCleaner:::cpp_polygon_locate(idx, -179.99, 66) > 0)
})

# A minimal shapefile writer (polygon type 5) to test the reader.
write_shp <- function(path, rings) {
  con <- file(path, "wb"); on.exit(close(con))
  recs <- lapply(rings, function(parts) {
    pts <- do.call(rbind, parts)
    starts <- c(0L, cumsum(vapply(parts, nrow, 1L))[-length(parts)])
    content_words <- (4 + 32 + 8 + 4 * length(parts) + 16 * nrow(pts)) / 2
    list(pts = pts, starts = starts, words = content_words)
  })
  total_words <- 50 + sum(vapply(recs, function(r) 4 + r$words, 1))
  writeBin(as.integer(c(9994, 0, 0, 0, 0, 0, total_words)), con, size = 4, endian = "big")
  writeBin(as.integer(c(1000, 5)), con, size = 4, endian = "little")
  all <- do.call(rbind, lapply(recs, `[[`, "pts"))
  writeBin(c(min(all[, 1]), min(all[, 2]), max(all[, 1]), max(all[, 2]), 0, 0, 0, 0), con, size = 8, endian = "little")
  for (i in seq_along(recs)) {
    r <- recs[[i]]
    writeBin(as.integer(c(i, r$words)), con, size = 4, endian = "big")
    writeBin(5L, con, size = 4, endian = "little")
    writeBin(c(min(r$pts[, 1]), min(r$pts[, 2]), max(r$pts[, 1]), max(r$pts[, 2])), con, size = 8, endian = "little")
    writeBin(as.integer(c(length(r$starts), nrow(r$pts))), con, size = 4, endian = "little")
    writeBin(as.integer(r$starts), con, size = 4, endian = "little")
    writeBin(as.vector(t(r$pts)), con, size = 8, endian = "little")
  }
}

test_that("the shapefile reader returns rings per feature", {
  sq <- function(x0, y0, s) cbind(c(x0, x0 + s, x0 + s, x0, x0), c(y0, y0, y0 + s, y0 + s, y0))
  f <- tempfile(fileext = ".shp")
  write_shp(f, list(list(sq(0, 0, 10), sq(4, 4, 2)), list(sq(20, -5, 10))))
  r <- OccurrenceCleaner:::read_shp_polygons(f)
  expect_identical(r$ring_feature, c(1L, 1L, 2L))
  expect_identical(r$ring_start, c(0L, 4L, 8L, 12L))
  expect_identical(r$x[1:4], c(0, 10, 10, 0))
  p <- OccurrenceCleaner:::cpp_polygon_index(r$x, r$y, r$ring_start, r$ring_feature, 1)
  expect_identical(OccurrenceCleaner:::cpp_polygon_locate(p, c(1, 5, 25, 50), c(1, 5, 0, 0)), c(1L, 0L, 2L, 0L))
  expect_error(suppressWarnings(OccurrenceCleaner:::read_shp_polygons(tempfile())), "cannot open")
  bad <- tempfile(fileext = ".shp")
  writeBin(as.integer(rep(0, 25)), bad, size = 4)
  expect_error(OccurrenceCleaner:::read_shp_polygons(bad), "not a shapefile")
})
