#' Reference data: sources and versions
#'
#' Every gazetteer the package uses is pinned to a source file, a version and a
#' retrieval date, and the flag output records which reference produced it.
#'
#' With `reference = "natural_earth"` (the default of [flag_occurrences()]) the
#' package uses its own gazetteers built in `data-raw/`: capitals, country and
#' province centroids, land, urban areas and country polygons from Natural Earth
#' (public domain), and biodiversity institutions from GBIF's Global Registry of
#' Scientific Collections (GRSciColl). With `reference = "CoordinateCleaner"` the
#' point gazetteers are read from the user's CoordinateCleaner installation
#' (`countryref`, `institutions`) and the polygon layers are downloaded through
#' rnaturalearth exactly as that package does, which reproduces its flags.
#'
#' @return A data frame with one row per layer: `layer`, `source`, `file`,
#'   `version`, `url`, `sha256`, `retrieved`, `licence`.
#' @examples
#' reference_info()
#' @export
reference_info <- function() {
  ref_meta
}

#' Download the 1:10m land layer
#'
#' The 1:10m Natural Earth land polygons (2.3 MB compressed) are not bundled
#' with the package. This fetches the pinned zip from Natural Earth, verifies
#' its SHA-256 against [reference_info()], converts it and stores the result in
#' the user cache directory (`tools::R_user_dir("OccurrenceCleaner", "cache")`).
#' [flag_occurrences()] calls it when `land_scale = 10` is requested and the
#' layer is not cached yet.
#'
#' @param layer Layer to download; only `"land_10"` is not bundled.
#' @param cache_dir Directory for the converted layer.
#' @param quiet Suppress the download message.
#' @return The path of the cached layer, invisibly.
#' @export
download_reference <- function(layer = "land_10",
                               cache_dir = tools::R_user_dir("OccurrenceCleaner", "cache"),
                               quiet = FALSE) {
  layer <- match.arg(layer)
  meta <- ref_meta[ref_meta$layer == layer, ]
  dest <- file.path(cache_dir, paste0(layer, "_v", meta$version, ".rds"))
  if (file.exists(dest)) return(invisible(dest))
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  zip <- tempfile(fileext = ".zip")
  if (!quiet) message("Downloading Natural Earth ", meta$file, " (version ", meta$version, ")")
  utils::download.file(meta$url, zip, mode = "wb", quiet = TRUE)
  got <- sha256_file(zip)
  if (!identical(got, meta$sha256))
    stop("downloaded ", meta$file, " has SHA-256 ", got, ", expected ", meta$sha256,
         "; Natural Earth may have published a new version. Not using it.")
  exdir <- tempfile("ne_")
  utils::unzip(zip, exdir = exdir)
  shp <- list.files(exdir, "[.]shp$", full.names = TRUE)
  rings <- read_shp_polygons(shp)
  compact <- list(x = as.integer(round(rings$x * 1e7)), y = as.integer(round(rings$y * 1e7)),
                  ring_start = rings$ring_start, ring_feature = rings$ring_feature,
                  features = data.frame(id = seq_len(max(rings$ring_feature))))
  saveRDS(compact, dest, compress = "xz")
  unlink(c(zip, exdir), recursive = TRUE)
  invisible(dest)
}

sha256_file <- function(path) {
  # R >= 4.5 ships sha256 in tools; fall back to the command line otherwise.
  if (exists("sha256sum", asNamespace("tools"), inherits = FALSE))
    return(unname(get("sha256sum", asNamespace("tools"))(path)))
  if (.Platform$OS.type == "windows") {
    out <- system2("certutil", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)
    return(tolower(gsub(" ", "", out[2])))
  }
  strsplit(system2("sha256sum", shQuote(path), stdout = TRUE), " ")[[1]][1]
}

# ---- compiled indices, cached per session -----------------------------------

# Point gazetteer (data frame with lon, lat) for a test under a reference.
point_gazetteer <- function(test, reference) {
  if (reference == "natural_earth") {
    return(switch(test,
      cap = ref_capitals[, c("lon", "lat")],
      cen = ref_centroids[, c("lon", "lat")],
      inst = ref_institutions[, c("lon", "lat")],
      gbif = data.frame(lon = 12.58, lat = 55.67)))
  }
  if (test == "gbif") return(data.frame(lon = 12.58, lat = 55.67))
  need_coordinatecleaner()
  cr <- get_cc_data("countryref")
  switch(test,
    cap = {
      d <- unique(cr[!is.na(cr$capital.lon) & !is.na(cr$capital.lat), c("capital.lon", "capital.lat")])
      data.frame(lon = d$capital.lon, lat = d$capital.lat)
    },
    cen = {
      d <- cr[!is.na(cr$centroid.lon) & !is.na(cr$centroid.lat), ]
      data.frame(lon = d$centroid.lon, lat = d$centroid.lat)
    },
    inst = {
      d <- get_cc_data("institutions")
      d <- d[!is.na(d$decimalLongitude) & !is.na(d$decimalLatitude), ]
      data.frame(lon = d$decimalLongitude, lat = d$decimalLatitude)
    })
}

point_index <- function(test, reference) {
  key <- paste("points", test, reference, sep = "/")
  if (!is.null(.occ_cache[[key]])) return(.occ_cache[[key]])
  g <- point_gazetteer(test, reference)
  ok <- is.finite(g$lon) & is.finite(g$lat) & abs(g$lon) <= 180 & abs(g$lat) <= 90
  idx <- cpp_point_index(as.numeric(g$lon[ok]), as.numeric(g$lat[ok]))
  .occ_cache[[key]] <- idx
  idx
}

# Polygon layer (compact ring list) for a test under a reference.
polygon_layer <- function(test, reference, land_scale) {
  if (reference == "natural_earth") {
    return(switch(test,
      sea = switch(as.character(land_scale),
        "110" = ref_land_110, "50" = ref_land_50,
        "10" = readRDS(download_reference("land_10"))),
      urb = ref_urban_50,
      coun = ref_countries_50))
  }
  if (!requireNamespace("rnaturalearth", quietly = TRUE))
    stop("reference = \"CoordinateCleaner\" needs the rnaturalearth package for polygon layers")
  sf <- switch(test,
    sea = rnaturalearth::ne_download(scale = land_scale, type = "land", category = "physical",
                                    returnclass = "sf", load = TRUE),
    urb = rnaturalearth::ne_download(scale = "medium", type = "urban_areas", returnclass = "sf",
                                    load = TRUE),
    coun = rnaturalearth::ne_countries(scale = "medium", returnclass = "sf"))
  features <- if (test == "coun") {
    d <- as.data.frame(sf)
    a3 <- as.character(d$iso_a3); a3[a3 == "-99"] <- NA
    a2 <- as.character(d$iso_a2); a2[a2 == "-99"] <- NA
    data.frame(name = as.character(d$admin), adm0_a3 = as.character(d$adm0_a3), iso_a3 = a3, iso_a2 = a2,
               stringsAsFactors = FALSE)
  } else data.frame(id = seq_len(nrow(sf)))
  rings <- rings_from_sfc(sf[[attr(sf, "sf_column")]])
  list(x = as.integer(round(rings$x * 1e7)), y = as.integer(round(rings$y * 1e7)),
       ring_start = rings$ring_start, ring_feature = rings$ring_feature, features = features)
}

polygon_index <- function(test, reference, land_scale) {
  key <- paste("polygons", test, reference, if (test == "sea") land_scale else "", sep = "/")
  if (!is.null(.occ_cache[[key]])) return(.occ_cache[[key]])
  layer <- polygon_layer(test, reference, land_scale)
  n_edges <- length(layer$x)
  cell <- min(2, max(0.1, sqrt(64800 / n_edges)))
  idx <- cpp_polygon_index(layer$x / 1e7, layer$y / 1e7, as.integer(layer$ring_start),
                           as.integer(layer$ring_feature), cell)
  .occ_cache[[key]] <- list(index = idx, features = layer$features)
  .occ_cache[[key]]
}

# Walk an sfc geometry list (POLYGON / MULTIPOLYGON) without sf, into the
# compact ring representation.
rings_from_sfc <- function(g) {
  xs <- list(); ys <- list(); starts <- integer(); feats <- integer(); off <- 0L
  for (f in seq_along(g)) {
    geom <- g[[f]]
    polys <- if (inherits(geom, "POLYGON")) list(geom) else geom
    for (poly in polys) for (ring in poly) {
      m <- unclass(ring)
      n <- nrow(m)
      if (n >= 4 && m[1, 1] == m[n, 1] && m[1, 2] == m[n, 2]) n <- n - 1L
      if (n < 3) next
      xs[[length(xs) + 1L]] <- m[seq_len(n), 1]
      ys[[length(ys) + 1L]] <- m[seq_len(n), 2]
      starts <- c(starts, off)
      feats <- c(feats, f)
      off <- off + n
    }
  }
  list(x = unlist(xs), y = unlist(ys), ring_start = c(starts, off), ring_feature = feats)
}

need_coordinatecleaner <- function() {
  if (!requireNamespace("CoordinateCleaner", quietly = TRUE))
    stop("reference = \"CoordinateCleaner\" needs the CoordinateCleaner package installed")
}

get_cc_data <- function(name) {
  e <- new.env()
  utils::data(list = name, package = "CoordinateCleaner", envir = e)
  get(name, envir = e)
}

# Version label written into flag output.
reference_label <- function(reference, land_scale) {
  if (reference == "natural_earth") {
    m <- ref_meta
    paste0("natural_earth (land ", land_scale, "; ",
           paste(sprintf("%s %s", m$layer, m$version), collapse = ", "), ")")
  } else {
    paste0("CoordinateCleaner ",
           if (requireNamespace("CoordinateCleaner", quietly = TRUE))
             as.character(utils::packageVersion("CoordinateCleaner")) else "(not installed)",
           " (land ", land_scale, ")")
  }
}
