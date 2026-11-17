local({
  before_file <- tempfile(fileext = ".rda")
  on.exit(unlink(before_file))
  stopifnot(system2("git", c("show", "v0.2.4:R/sysdata.rda"), stdout = before_file) == 0L)
  before <- new.env()
  after <- new.env()
  load(before_file, envir = before)
  load("R/sysdata.rda", envir = after)
  a <- before$ref_institutions
  b <- after$ref_institutions
  key <- function(d) paste(d$key, d$source, d$name, d$lon, d$lat)
  stopifnot(!anyDuplicated(key(a)), !anyDuplicated(key(b)), setequal(key(a), key(b)))
  j <- match(key(b), key(a))
  changed_columns <- names(b)[vapply(names(b), function(n) !identical(b[[n]], a[[n]][j]), logical(1))]
  stopifnot(all(changed_columns %in% c("status", "evidence")))
  changed <- b$status != a$status[j]
  stopifnot(all(a$status[j][changed] == "unconfirmed"), all(b$status[changed] == "confirmed"))
  write.csv(b[changed, ], "dev_notes/results_0.3.0/institution_changes.csv", row.names = FALSE)
  cat(nrow(b), "unchanged row identities;", sum(changed), "new confirmations; changed columns:",
      paste(changed_columns, collapse = ", "), "\n")
})
