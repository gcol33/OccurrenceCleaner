# Overpass fetches for the institution build, shared by institutions.R and
# osm_prefetch.R. Needs `cache` (the cache directory) and `ua` (the user agent).
# Overpass answers a query that is too large with a server error. Museums, the
# largest class, are fetched in tiles of 30 by 30 degrees; a tile the server
# cannot answer is split into four, down to tiles of under one degree.
osm_servers <- c("https://overpass-api.de/api/interpreter", "https://overpass.openstreetmap.fr/api/interpreter")
osm_get <- function(tag, bbox, file) {
  kv <- strsplit(tag, "=")[[1]]
  q <- sprintf('[out:json][timeout:%d];nwr["%s"="%s"]["name"]%s;out tags center bb;', if (nzchar(bbox)) 80L else 800L, kv[1], kv[2], bbox)
  tf <- tempfile(fileext = ".json")
  tiled <- nzchar(bbox)
  too_big <- 0L
  for (try in 1:8) {
    h <- curl::new_handle(useragent = ua, timeout = if (tiled) 90 else 900, post = TRUE,
                          postfields = paste0("data=", utils::URLencode(q, reserved = TRUE)))
    r <- tryCatch(curl::curl_fetch_disk(osm_servers[(try - 1) %% 2 + 1], tf, handle = h), error = function(e) NULL)
    x <- if (!is.null(r) && r$status_code == 200) tryCatch(jsonlite::fromJSON(tf), error = function(e) NULL)
    if (!is.null(x$elements) && is.null(x$remark)) {
      file.copy(tf, file)
      Sys.sleep(1)
      return(TRUE)
    }
    # A timeout or a server-side remark means the tile is too large; any other
    # failure is a busy server and is retried.
    if (is.null(r) || !is.null(x$remark)) too_big <- too_big + 1L
    if (tiled && too_big >= 2L) break
    Sys.sleep(5)
  }
  FALSE
}
osm_fetch <- function(tag, s = NULL, w = NULL, n = NULL, e = NULL) {
  tagname <- sub("=", "_", sub(":", "_", tag))
  if (is.null(s)) {
    f <- file.path(cache, paste0("osm_", tagname, ".json"))
    if (!file.exists(f)) stopifnot(osm_get(tag, "", f))
    return(f)
  }
  f <- file.path(cache, sprintf("osm_%s_s%g_w%g_n%g_e%g.json", tagname, s, w, n, e))
  if (file.exists(f)) return(f)
  if (osm_get(tag, sprintf("(%g,%g,%g,%g)", s, w, n, e), f)) return(f)
  stopifnot(n - s >= 1, e - w >= 1)
  ms <- (s + n) / 2; mw <- (w + e) / 2
  c(osm_fetch(tag, s, w, ms, mw), osm_fetch(tag, s, mw, ms, e), osm_fetch(tag, ms, w, n, mw), osm_fetch(tag, ms, mw, n, e))
}
