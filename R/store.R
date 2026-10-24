# Partitioned row stores of the group stage. Rows are appended under a
# partition key and kept in input order within each partition. With a
# directory, rows are buffered in memory and appended to one .vtr file per
# partition once `flush_rows` rows are held; without one, everything stays in
# memory (data frame input).

new_parts <- function(dir = NULL, prefix = "part", flush_rows = 2e6) {
  p <- new.env()
  p$dir <- dir
  p$prefix <- prefix
  p$flush_rows <- flush_rows
  p$buf <- list()
  p$held <- 0
  p$rows <- stats::setNames(numeric(), character())
  p$mem <- list()
  if (!is.null(dir)) dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  p
}

parts_file <- function(p, key) file.path(p$dir, paste0(p$prefix, "-", key, ".vtr"))

# Append the rows of d under the partition keys in `key` (one per row).
parts_add <- function(p, d, key) {
  if (!nrow(d)) return(invisible())
  d$.key <- as.character(key)
  p$buf[[length(p$buf) + 1L]] <- d
  p$held <- p$held + nrow(d)
  if (!is.null(p$dir) && p$held >= p$flush_rows) parts_flush(p)
  invisible()
}

# Write the buffered rows: one append per partition, rows of a partition in
# the order they were added (radix order is stable).
parts_flush <- function(p) {
  if (!length(p$buf)) return(invisible())
  d <- do.call(rbind, p$buf)
  p$buf <- list()
  p$held <- 0
  by_key <- split(seq_len(nrow(d)), d$.key)
  d$.key <- NULL
  if (is.null(p$dir)) {
    for (k in names(by_key)) {
      p$mem[[k]] <- c(p$mem[[k]], list(d[by_key[[k]], , drop = FALSE]))
      p$rows[k] <- (if (is.na(p$rows[k])) 0 else p$rows[k]) + length(by_key[[k]])
    }
    return(invisible())
  }
  for (k in names(by_key)) {
    part <- d[by_key[[k]], , drop = FALSE]
    path <- parts_file(p, k)
    if (file.exists(path)) vectra::append_vtr(part, path) else vectra::write_vtr(part, path)
    p$rows[k] <- (if (is.na(p$rows[k])) 0 else p$rows[k]) + nrow(part)
  }
  invisible()
}

# Rows written per partition, after writing what is buffered: the checkpoint
# of a store.
parts_state <- function(p) {
  parts_flush(p)
  p$rows
}

# Return a store to a checkpoint: partitions written after it are removed, and a partition grown since is cut back to
# its rows at the checkpoint.
parts_restore <- function(p, state) {
  p$buf <- list()
  p$held <- 0
  p$rows <- state
  if (is.null(p$dir)) return(invisible())
  files <- list.files(p$dir, paste0("^", p$prefix, "-.*[.]vtr$"), full.names = TRUE)
  keys <- sub(paste0("^", p$prefix, "-(.*)[.]vtr$"), "\\1", basename(files))
  for (i in seq_along(files)) {
    want <- if (keys[i] %in% names(state)) state[[keys[i]]] else 0
    if (want == 0) {
      unlink(files[i])
      next
    }
    have <- vectra::collect(vectra::tally(vectra::tbl(files[i])))$n
    if (have > want) {
      tmp <- paste0(files[i], ".tmp")
      vectra::write_vtr(vectra::slice_head(vectra::tbl(files[i]), n = want), tmp)
      file.rename(tmp, files[i])
    } else if (have < want) {
      stop("checkpoint of ", files[i], " records ", want, " rows but the file has ", have)
    }
  }
  invisible()
}

parts_keys <- function(p) {
  parts_flush(p)
  names(p$rows)
}

# All rows of one partition as a data frame, in the order they were added.
parts_read <- function(p, key) {
  if (is.null(p$dir)) return(do.call(rbind, p$mem[[key]]))
  as.data.frame(vectra::collect(vectra::tbl(parts_file(p, key))))
}

# Call f(chunk) on the rows of one partition in order, a chunk at a time.
parts_each <- function(p, key, f) {
  if (is.null(p$dir)) {
    f(parts_read(p, key))
    return(invisible())
  }
  vectra::collect_chunked(vectra::tbl(parts_file(p, key)), function(acc, chunk) {
    f(as.data.frame(chunk))
    acc
  }, .init = NULL)
  invisible()
}

parts_drop <- function(p) {
  p$buf <- list()
  p$mem <- list()
  p$rows <- stats::setNames(numeric(), character())
  if (!is.null(p$dir)) unlink(p$dir, recursive = TRUE)
  invisible()
}

# Remove the rows of partitions that will not be read again; their row counts
# stay, so the checkpoint and the progress of the store are unchanged. Returns
# the bytes removed from disk.
parts_release <- function(p, keys) {
  if (is.null(p) || !length(keys)) return(invisible(0))
  if (is.null(p$dir)) {
    p$mem[keys] <- NULL
    return(invisible(0))
  }
  files <- parts_file(p, keys)
  bytes <- sum(file.size(files), na.rm = TRUE)
  unlink(files)
  invisible(bytes)
}

# Rewrite each partition file in one write. Every append to a .vtr file adds a
# row-group index after the previous one, so a file filled by many small
# appends is mostly indexes.
parts_compact <- function(p) {
  parts_flush(p)
  if (is.null(p$dir)) return(invisible())
  for (k in names(p$rows)) {
    path <- parts_file(p, k)
    if (!file.exists(path)) next
    tmp <- paste0(path, ".tmp")
    vectra::write_vtr(vectra::tbl(path), tmp)
    if (!file.rename(tmp, path)) stop("could not write ", path)
  }
  invisible()
}

# ---- hits of the group tests ---------------------------------------------------

# Flagged rows are stored by unit and block of rows, so the record pass loads
# the bits of one block at a time.
.hit_block <- 1048576

hits_add <- function(h, unit, row, test) {
  if (!length(row)) return(invisible())
  parts_add(h, data.frame(row = as.integer(row), bits = rep(flag_mask(test), length(row))),
            paste0(unit, "-", (row - 1) %/% .hit_block))
}

# A reader that returns the group bits of rows first..first+n-1 of unit u,
# holding the blocks of the current rows only.
hits_reader <- function(h) {
  r <- new.env()
  r$keys <- if (is.null(h)) character() else parts_keys(h)
  r$cache <- list()
  r$h <- h
  r
}

hits_lookup <- function(r, u, first, n) {
  bits <- integer(n)
  if (!length(r$keys) || !n) return(bits)
  rows <- first + seq_len(n) - 1L
  blocks <- unique((rows - 1) %/% .hit_block)
  keys <- paste0(u, "-", blocks)
  r$cache <- r$cache[intersect(names(r$cache), keys)]
  for (k in intersect(keys, r$keys)) {
    if (is.null(r$cache[[k]])) {
      d <- parts_read(r$h, k)
      d <- d[!duplicated(d), , drop = FALSE]
      s <- rowsum(d$bits, d$row)
      r$cache[[k]] <- list(row = as.integer(rownames(s)), bits = as.integer(s[, 1]))
    }
    e <- r$cache[[k]]
    m <- match(rows, e$row)
    bits[!is.na(m)] <- bitwOr(bits[!is.na(m)], e$bits[m[!is.na(m)]])
  }
  bits
}

# ---- checkpoints -----------------------------------------------------------------

# Write an object so that a reader sees either the old or the new file.
save_atomic <- function(x, path) {
  tmp <- paste0(path, ".tmp")
  saveRDS(x, tmp)
  if (!file.rename(tmp, path)) stop("could not write ", path)
  invisible()
}
