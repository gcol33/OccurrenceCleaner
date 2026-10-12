# Streamed flagging of on-disk tables through vectra.

# Turn the input into a list of units, each with a function returning a
# vectra node and a name for its output. A file can be opened again for every
# pass; a vectra_node given by the user runs once (`reopen` FALSE).
stream_units <- function(x) {
  if (inherits(x, "vectra_node")) {
    return(list(list(name = "stream", open = function() x, reopen = FALSE)))
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
    list(name = tools::file_path_sans_ext(basename(f)), path = normalizePath(f), open = function() open_table(f),
         reopen = TRUE)
  })
}

# Column names of an on-disk table, read from its first row.
table_names <- function(node) names(vectra::collect(vectra::slice_head(node, n = 1)))

# The node reduced to the named columns, so each chunk reads only the columns
# the tests use.
project <- function(node, cols) do.call(vectra::select, c(list(node), lapply(unique(cols), as.name)))

open_table <- function(f) {
  ext <- tolower(tools::file_ext(f))
  if (ext == "vtr") return(vectra::tbl(f))
  if (ext %in% c("csv", "gz")) return(vectra::tbl_csv(f, delim = if (grepl("[.]tsv([.]gz)?$", f)) "\t" else ","))
  if (ext %in% c("tsv", "txt")) return(vectra::tbl_csv(f, delim = "\t"))
  vectra::tbl_parquet(f)
}

flag_stream <- function(x, cfg, out, keep, part_rows, resume, verbose, checkpoint_secs = 300) {
  if (is.null(out) || !is.character(out) || length(out) != 1L) stop("`out` (an output directory) is required for streamed input")
  dir.create(out, showWarnings = FALSE, recursive = TRUE)
  units <- stream_units(x)
  if (!resume) clear_output(out)
  # Without `tests`, the tests follow the columns of the first unit; a
  # single-run node is planned on its first chunk instead.
  if (is.null(cfg$tests) && units[[1]]$reopen)
    cfg <- apply_plan(cfg, plan_tests(table_names(units[[1]]$open()), cfg$columns, cfg$has_range))
  if (!is.null(cfg$tests)) check_config(out, config_record(cfg, keep, units))
  if (verbose && length(cfg$tests)) message(plan_message(cfg$plan))
  done_markers <- file.path(out, paste0(vapply(units, `[[`, "", "name"), ".done"))
  gdir <- file.path(out, ".group")
  group <- NULL
  if (any(cfg$tests %in% .group_tests)) {
    if (!all(vapply(units, `[[`, TRUE, "reopen")))
      stop("the grouped tests (", paste(intersect(cfg$tests, .group_tests), collapse = ", "),
           ") read the input more than once, and a vectra_node runs once; pass the file or directory path instead")
    if (!all(file.exists(done_markers))) {
      avail <- table_names(units[[1]]$open())
      check_stream_columns(avail, keep, cfg$duplicate_by)
      cols0 <- resolve_test_columns(cfg$columns, avail, cfg$tests)
      t0 <- Sys.time()
      group <- group_pass(units, cfg, cols0, dir = gdir, checkpoint_secs = checkpoint_secs, verbose = verbose)
      if (verbose) message("group tests: done [", format(round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)), " s]")
    }
  }
  total <- 0
  parts <- character()
  for (ui in seq_along(units)) {
    u <- units[[ui]]
    done_marker <- done_markers[ui]
    if (resume && file.exists(done_marker)) {
      info <- readRDS(done_marker)
      total <- total + info$n
      parts <- c(parts, info$parts)
      if (verbose) message(u$name, ": done (", info$n, " rows), skipped")
      next
    }
    unlink(list.files(out, paste0("^part-", u$name, "-"), full.names = TRUE))
    t0 <- Sys.time()
    resolve <- function(avail, cfg) {
      check_stream_columns(avail, keep, cfg$duplicate_by)
      list(cols = resolve_test_columns(cfg$columns, avail, cfg$tests),
           id = resolve_columns(cfg$columns, avail, "id", optional = "id")$id)
    }
    # A reopenable unit is read with only the columns the tests and keep use;
    # a single-run node is resolved on its first chunk.
    if (u$reopen) {
      rc <- resolve(table_names(u$open()), cfg)
      node <- project(u$open(), c(unlist(rc$cols), rc$id, keep))
    } else {
      rc <- list(cols = NULL, id = NULL)
      node <- u$open()
    }
    reader <- hits_reader(group$hits)
    acc <- vectra::collect_chunked(node, function(acc, chunk) {
      if (is.null(acc$cols)) {
        if (is.null(acc$cfg$tests)) {
          acc$cfg <- apply_plan(acc$cfg, plan_tests(names(chunk), acc$cfg$columns, acc$cfg$has_range,
                                                    reopen = FALSE))
          check_config(out, config_record(acc$cfg, keep, units))
          if (verbose) message(plan_message(acc$cfg$plan))
        }
        rc <- resolve(names(chunk), acc$cfg)
        acc$cols <- rc$cols
        acc$id <- rc$id
      }
      r <- flag_chunk(chunk, acc$cfg, acc$cols)
      if (!is.null(group)) r$flags <- bitwOr(r$flags, group_bits(group, chunk, ui, acc$n + 1L, acc$cols, reader))
      o <- chunk[, c(acc$id, keep), drop = FALSE]
      o$flags <- r$flags
      acc$buf[[length(acc$buf) + 1L]] <- o
      acc$n_buf <- acc$n_buf + nrow(o)
      acc$n <- acc$n + nrow(o)
      if (acc$n_buf >= part_rows) acc <- flush_part(acc, out, u$name)
      acc
    }, .init = list(buf = list(), n_buf = 0, n = 0, k = 0L, parts = character(), cols = rc$cols, id = rc$id,
                    cfg = cfg))
    cfg <- acc$cfg
    if (is.null(cfg$tests)) stop("the input has no rows, so no test could be chosen; name them with `tests`")
    if (acc$n_buf > 0 || acc$k == 0L) acc <- flush_part(acc, out, u$name)
    save_atomic(list(n = acc$n, parts = acc$parts), done_marker)
    total <- total + acc$n
    parts <- c(parts, acc$parts)
    if (verbose) message(u$name, ": ", acc$n, " rows in ", length(acc$parts), " part(s) [",
                         format(round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)), " s]")
  }
  if (is.null(cfg$tests)) cfg <- c(cfg[setdiff(names(cfg), c("tests", "plan"))],
                                   readRDS(file.path(out, "flags_config.rds"))[c("tests", "plan")])
  unlink(gdir, recursive = TRUE)
  meta <- list(out = normalizePath(out), tests = cfg$tests, test_plan = cfg$plan,
               layout_version = cfg$layout_version,
               reference = cfg$reference_label, columns = unclass(cfg$columns), keep = keep,
               buffers = cfg$buffers, duplicate_by = cfg$duplicate_by,
               duplicate_cell = cfg$duplicate_cell,
               n = total, parts = parts, units = vapply(units, `[[`, "", "name"),
               package_version = as.character(utils::packageVersion("OccurrenceCleaner")),
               finished = Sys.time())
  save_atomic(meta, file.path(out, "flags_meta.rds"))
  structure(meta, class = "occ_flagged")
}

check_stream_columns <- function(avail, keep, duplicate_by) {
  missing <- setdiff(c(keep, duplicate_by), avail)
  if (length(missing)) stop("`keep` or `duplicate_by` column(s) not in the input: ",
                            paste(missing, collapse = ", "))
  invisible()
}

# Everything that decides the flags of a run: the settings, the package
# version and the input files in order, each with its size and modification
# time. These detect a replaced, grown or touched file; they are not a hash of
# the file contents.
config_record <- function(cfg, keep, units) {
  inputs <- data.frame(unit = vapply(units, `[[`, "", "name"),
                       path = vapply(units, function(u) u$path %||% NA_character_, ""),
                       stringsAsFactors = FALSE)
  info <- file.info(inputs$path[!is.na(inputs$path)])
  inputs$size <- NA_real_
  inputs$mtime <- NA_real_
  inputs$size[!is.na(inputs$path)] <- info$size
  inputs$mtime[!is.na(inputs$path)] <- as.numeric(info$mtime)
  list(tests = cfg$tests, plan = cfg$plan, columns = unclass(cfg$columns), keep = keep,
       reference = cfg$reference_label, land_scale = cfg$land_scale, buffers = cfg$buffers,
       settings = cfg$settings, duplicate_by = cfg$duplicate_by, duplicate_cell = cfg$duplicate_cell,
       layout_version = cfg$layout_version,
       package_version = as.character(utils::packageVersion("OccurrenceCleaner")),
       inputs = inputs)
}

# The configuration of an output directory is recorded before its first
# output; a later call into the same directory must match it.
check_config <- function(out, rec) {
  p <- file.path(out, "flags_config.rds")
  if (!file.exists(p)) {
    if (length(list.files(out, "^part-|[.]done$|^flags_meta[.]rds$")) || dir.exists(file.path(out, ".group")))
      stop("`out` holds flags without a record of their configuration; use a new directory or resume = FALSE", call. = FALSE)
    save_atomic(rec, p)
    return(invisible())
  }
  old <- readRDS(p)
  fields <- setdiff(names(rec), c("inputs", "plan"))
  differ <- fields[!vapply(fields, function(f) identical(old[[f]], rec[[f]]), TRUE)]
  a <- old$inputs; b <- rec$inputs
  if (!identical(a$unit, b$unit)) {
    differ <- c(differ, "input files")
  } else {
    same <- mapply(identical, a$size, b$size) & mapply(identical, a$mtime, b$mtime)
    changed <- a$unit[!same]
    if (length(changed)) differ <- c(differ, paste0("input file(s) changed: ", paste(changed, collapse = ", ")))
  }
  if (length(differ))
    stop("`out` holds flags from a different configuration (", paste(differ, collapse = "; "),
         "); use a new directory or resume = FALSE", call. = FALSE)
  invisible()
}

# Remove the output of an earlier run from `out`.
clear_output <- function(out) {
  unlink(list.files(out, "^part-.*[.]vtr$|[.]done$|^flags_(meta|config)[.]rds$", full.names = TRUE))
  unlink(file.path(out, ".group"), recursive = TRUE)
  invisible()
}

# Recompute the duplicate bit of finished streamed output over the whole
# input: a group stage over the same input files, in the same order, then
# each part rewritten with the bit cleared and set again from that stage.
# Rewriting a part is idempotent, and finished units are marked in
# out/.repair, so an interrupted repair is resumed by calling it again.
repair_duplicates <- function(out, x, checkpoint_secs = 300, verbose = TRUE) {
  m <- read_flagged(out)
  if (!"duplicate" %in% m$tests) stop("the flags in `out` have no duplicate test")
  units <- stream_units(x)
  if (!identical(vapply(units, `[[`, "", "name"), m$units))
    stop("the input files are not the units of `out`, in the same order")
  cfg <- flag_config(tests = "duplicate", columns = structure(m$columns, class = "occ_columns"),
                     duplicate_by = m$duplicate_by, duplicate_cell = m$duplicate_cell)
  rdir <- file.path(out, ".repair")
  dir.create(rdir, showWarnings = FALSE)
  avail <- table_names(units[[1]]$open())
  check_stream_columns(avail, NULL, cfg$duplicate_by)
  cols <- resolve_test_columns(cfg$columns, avail, cfg$tests)
  g <- group_pass(units, cfg, cols, dir = file.path(rdir, "group"), checkpoint_secs = checkpoint_secs,
                  verbose = verbose)
  mask <- flag_mask("duplicate")
  for (ui in seq_along(units)) {
    name <- units[[ui]]$name
    marker <- file.path(rdir, paste0(name, ".fixed"))
    if (file.exists(marker)) next
    info <- readRDS(file.path(out, paste0(name, ".done")))
    n_in <- unit_rows(units[[ui]])
    if (info$n != n_in) stop("unit ", name, " has ", n_in, " input rows but ", info$n, " flagged rows")
    reader <- hits_reader(g$hits)
    first <- 1L
    for (p in file.path(out, info$parts)) {
      d <- as.data.frame(vectra::collect(vectra::tbl(p)))
      bits <- hits_lookup(reader, ui, first, nrow(d))
      d$flags <- bitwOr(bitwAnd(d$flags, bitwNot(mask)), bits)
      tmp <- paste0(p, ".tmp")
      vectra::write_vtr(d, tmp, col_types = c(flags = "int32"))
      if (!file.rename(tmp, p)) stop("could not replace ", p)
      first <- first + nrow(d)
    }
    save_atomic(TRUE, marker)
    if (verbose) message(name, ": duplicate bit recomputed")
  }
  m$duplicate_repair <- list(package_version = as.character(utils::packageVersion("OccurrenceCleaner")),
                             finished = Sys.time())
  m$out <- NULL
  save_atomic(unclass(m), file.path(out, "flags_meta.rds"))
  unlink(rdir, recursive = TRUE)
  read_flagged(out)
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
  absent <- unavailable_summary(x$test_plan)
  if (!is.null(absent)) cat("  not run:   missing input: ", absent, "; test_plan() lists them\n", sep = "")
  cat("  layout:    v", x$layout_version, "\n", sep = "")
  cat("  reference: ", reference_short(x$reference), "\n", sep = "")
  if (length(x$keep)) cat("  keep:      ", paste(x$keep, collapse = ", "), "\n", sep = "")
  invisible(x)
}

#' Read flag output written by flag_occurrences()
#'
#' @param x An `occ_flagged` object or the output directory it describes.
#' @return The `occ_flagged` metadata (`read_flagged()`), or a `vectra_node`
#'   over all parts (`flagged_table()`), to be used with [vectra](https://gillescolling.com/vectra/) verbs and
#'   `vectra::collect()`.
#' @examples
#' x <- data.frame(gbifID = 1:4, kingdom = c("Plantae", "Plantae", "Animalia", "Animalia"),
#'                 decimalLongitude = c(12.58, 0, 16.37, 2.35),
#'                 decimalLatitude = c(55.67, 0, 48.21, 48.85))
#' input <- file.path(tempdir(), "occurrence.csv")
#' utils::write.csv(x, input, row.names = FALSE)
#' out <- file.path(tempdir(), "flags")
#' flag_occurrences(input, tests = c("zero", "capital"), out = out, keep = "kingdom",
#'                  verbose = FALSE)
#' f <- read_flagged(out)
#' f
#' vectra::collect(flagged_table(f))
#' unlink(c(input, out), recursive = TRUE)
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
