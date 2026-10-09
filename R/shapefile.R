# Minimal ESRI shapefile reader for polygon layers (shape type 5, or 15/25
# whose Z/M values are skipped). Returns the compact ring representation used
# by the polygon index: each record is one feature, each part one ring.
read_shp_polygons <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  size <- file.size(path)
  hdr <- readBin(con, "integer", n = 7, size = 4, endian = "big")
  if (hdr[1] != 9994L) stop("not a shapefile: ", path)
  file_len <- hdr[7] * 2  # 16-bit words
  version <- readBin(con, "integer", n = 1, size = 4, endian = "little")
  shape_type <- readBin(con, "integer", n = 1, size = 4, endian = "little")
  if (!shape_type %in% c(5L, 15L, 25L)) stop("shapefile is not a polygon layer (type ", shape_type, ")")
  readBin(con, "double", n = 8, size = 8, endian = "little")  # bounding box, skipped
  pos <- 100
  xs <- list(); ys <- list(); starts <- integer(); feats <- integer(); off <- 0L; feature <- 0L
  while (pos < min(file_len, size)) {
    rec <- readBin(con, "integer", n = 2, size = 4, endian = "big")
    if (length(rec) < 2) break
    content_len <- rec[2] * 2
    type <- readBin(con, "integer", n = 1, size = 4, endian = "little")
    feature <- feature + 1L
    if (type == 0L) {  # null shape
      pos <- pos + 8 + content_len
      next
    }
    readBin(con, "double", n = 4, size = 8, endian = "little")
    counts <- readBin(con, "integer", n = 2, size = 4, endian = "little")
    n_parts <- counts[1]; n_points <- counts[2]
    parts <- readBin(con, "integer", n = n_parts, size = 4, endian = "little")
    pts <- readBin(con, "double", n = 2 * n_points, size = 8, endian = "little")
    consumed <- 4 + 32 + 8 + 4 * n_parts + 16 * n_points
    if (content_len > consumed) readBin(con, "raw", n = content_len - consumed)  # Z/M ranges
    pos <- pos + 8 + content_len
    x <- pts[seq(1, 2 * n_points, by = 2)]
    y <- pts[seq(2, 2 * n_points, by = 2)]
    bounds <- c(parts, n_points)
    for (p in seq_len(n_parts)) {
      i0 <- bounds[p] + 1L; i1 <- bounds[p + 1]
      n <- i1 - i0 + 1L
      if (n >= 4 && x[i0] == x[i1] && y[i0] == y[i1]) n <- n - 1L
      if (n < 3) next
      xs[[length(xs) + 1L]] <- x[i0:(i0 + n - 1L)]
      ys[[length(ys) + 1L]] <- y[i0:(i0 + n - 1L)]
      starts <- c(starts, off)
      feats <- c(feats, feature)
      off <- off + n
    }
  }
  list(x = unlist(xs), y = unlist(ys), ring_start = c(starts, off), ring_feature = feats)
}
