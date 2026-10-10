# Streamed flagging of on-disk tables through vectra.

# Turn the input into a list of units, each a function returning a fresh
# vectra node, with a name for its output.
stream_units <- function(x) {
  if (inherits(x, "vectra_node")) {
    return(list(list(name = "stream", open = function() x)))
  }
  if (!is.character(x) || length(x) < 1L) stop("`x` must be a data frame, a vectra_node or a path")
  files <- unlist(lapply(x, function(p) {
    if (!file.exists(p)) stop("path not found: ", p)
    if (!dir.exists(p)) return(p)
    fs <- list.files(p, full.names = TRUE, recursive = TRUE)
    fs <- fs[!grepl("^[._]", basename(fs)) & !dir.exists(fs)]
    sort(fs)
  }))
  if (!length(files)) stop("no files found under ", paste(x, collapse = ", "))
  lapply(files, function(f) {
    list(name = tools::file_path_sans_ext(basename(f)), open = function() open_table(f))
  })
}

open_table <- function(f) {
  ext <- tolower(tools::file_ext(f))
  if (ext == "vtr") return(vectra::tbl(f))
  if (ext %in% c("csv", "gz")) return(vectra::tbl_csv(f, delim = if (grepl("[.]tsv([.]gz)?$", f)) "\t" else ","))
  if (ext %in% c("tsv", "txt")) return(vectra::tbl_csv(f, delim = "\t"))
  vectra::tbl_parquet(f)
}

flag_stream <- function(x, cfg, out, keep, part_rows, resume, verbose) {
  if (is.null(out) || !is.character(out) || length(out) != 1L) stop("`out` (an output directory) is required for streamed input")
  dir.create(out, showWarnings = FALSE, recursive = TRUE)
  units <- stream_units(x)
  meta_path <- file.path(out, "flags_meta.rds")
  if (file.exists(meta_path)) {
    old <- readRDS(meta_path)
    if (!identical(old$tests, cfg$tests) || !identical(old$layout_version, cfg$layout_version) ||
        !identical(old$reference, cfg$reference_label))
      stop("`out` holds flags produced with different tests, layout or reference; use a new directory")
  }
  total <- 0
  parts <- character()
  for (u in units) {
    done_marker <- file.path(out, paste0(u$name, ".done"))
    if (resume && file.exists(done_marker)) {
      info <- readRDS(done_marker)
      total <- total + info$n
      parts <- c(parts, info$parts)
      if (verbose) message(u$name, ": done (", info$n, " rows), skipped")
      next
    }
    unlink(list.files(out, paste0("^part-", u$name, "-"), full.names = TRUE))
    t0 <- Sys.time()
    node <- u$open()
    acc <- vectra::collect_chunked(node, function(acc, chunk) {
      if (is.null(acc$cols)) {
        acc$cols <- resolve_columns(cfg$columns, names(chunk), fields_for(cfg$tests))
        acc$id <- resolve_columns(cfg$columns, names(chunk), "id", optional = "id")$id
        missing <- setdiff(keep, names(chunk))
        if (length(missing)) stop("`keep` column(s) not in the input: ", paste(missing, collapse = ", "))
      }
      r <- flag_chunk(chunk, cfg, acc$cols)
      o <- chunk[, c(acc$id, keep), drop = FALSE]
      o$flags <- r$flags
      acc$buf[[length(acc$buf) + 1L]] <- o
      acc$n_buf <- acc$n_buf + nrow(o)
      acc$n <- acc$n + nrow(o)
      if (acc$n_buf >= part_rows) acc <- flush_part(acc, out, u$name)
      acc
    }, .init = list(buf = list(), n_buf = 0, n = 0, k = 0L, parts = character(), cols = NULL, id = NULL))
    if (acc$n_buf > 0 || acc$k == 0L) acc <- flush_part(acc, out, u$name)
    saveRDS(list(n = acc$n, parts = acc$parts), done_marker)
    total <- total + acc$n
    parts <- c(parts, acc$parts)
    if (verbose) message(u$name, ": ", acc$n, " rows in ", length(acc$parts), " part(s) [",
                         format(round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)), " s]")
  }
  meta <- list(out = normalizePath(out), tests = cfg$tests, layout_version = cfg$layout_version,
               reference = cfg$reference_label, columns = unclass(cfg$columns), keep = keep,
               buffers = cfg$buffers, duplicate_by = cfg$duplicate_by,
               duplicate_cell = cfg$duplicate_cell,
               n = total, parts = parts, units = vapply(units, `[[`, "", "name"),
               package_version = as.character(utils::packageVersion("OccurrenceCleaner")),
               finished = Sys.time())
  saveRDS(meta, meta_path)
  structure(meta, class = "occ_flagged")
}

flush_part <- function(acc, out, name) {
  acc$k <- acc$k + 1L
  part <- file.path(out, sprintf("part-%s-%04d.vtr", name, acc$k))
  d <- if (length(acc$buf)) do.call(rbind, acc$buf) else data.frame(flags = integer())
  vectra::write_vtr(d, part, col_types = c(flags = "int32"))
  acc$parts <- c(acc$parts, basename(part))
  acc$buf <- list()
  acc$n_buf <- 0
  acc
}

#' @export
print.occ_flagged <- function(x, ...) {
  cat("<occ_flagged> ", format(x$n, big.mark = ","), " records in ", length(x$parts), " part(s)\n", sep = "")
  cat("  out:       ", x$out, "\n", sep = "")
  cat("  tests:     ", paste(x$tests, collapse = ", "), "\n", sep = "")
  cat("  layout:    v", x$layout_version, "\n", sep = "")
  cat("  reference: ", x$reference, "\n", sep = "")
  if (length(x$keep)) cat("  keep:      ", paste(x$keep, collapse = ", "), "\n", sep = "")
  invisible(x)
}

#' Read flag output written by flag_occurrences()
#'
#' @param x An `occ_flagged` object or the output directory it describes.
#' @return The `occ_flagged` metadata (`read_flagged()`), or a `vectra_node`
#'   over all parts (`flagged_table()`), to be used with vectra verbs and
#'   `vectra::collect()`.
#' @examples
#' \dontrun{
#' f <- flag_occurrences("snapshot/occurrence.parquet", out = "flags", keep = "kingdom")
#' vectra::collect(flagged_table(f))
#' }
#' @export
read_flagged <- function(x) {
  if (inherits(x, "occ_flagged")) return(x)
  if (!is.character(x) || length(x) != 1L) stop("`x` must be an occ_flagged object or a directory")
  p <- file.path(x, "flags_meta.rds")
  if (!file.exists(p)) stop("no flags_meta.rds in ", x)
  m <- readRDS(p)
  m$out <- normalizePath(x)
  structure(m, class = "occ_flagged")
}

#' @rdname read_flagged
#' @export
flagged_table <- function(x) {
  m <- read_flagged(x)
  nodes <- lapply(file.path(m$out, m$parts), vectra::tbl)
  if (length(nodes) == 1L) return(nodes[[1]])
  do.call(vectra::bind_rows, nodes)
}
