#' Reference data: sources and versions
#'
#' Every gazetteer the package uses is pinned to a source file, a version and a
#' retrieval date, and the flag output records which reference produced it.
#'
#' With `reference = "natural_earth"` (the default of [flag_occurrences()]) the
#' package uses its own gazetteers built in `data-raw/`: capitals, country and
#' province centroids, land, urban areas and country polygons from Natural Earth
#' (public domain), and biodiversity institutions from GBIF's Global Registry of
#' Scientific Collections (GRSciColl), Wikidata, GeoNames and BGCI GardenSearch. With `reference = "CoordinateCleaner"` the
#' point gazetteers are read from the user's CoordinateCleaner installation
#' (`countryref`, `institutions`) and the polygon layers are downloaded through
#' rnaturalearth exactly as that package does, which gives its flags up to the
#' differences documented in [flag_occurrences()].
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

#' Reference points of a proximity test
#'
#' Returns the points a proximity test measures distance to: capitals,
#' country and province centroids, biodiversity institutions, the GBIF
#' headquarters, or the points of the Artificial Hotspot Occurrence Inventory
#' (Park et al. 2023). The table can be inspected, filtered or extended and passed
#' back through the `gazetteers` argument of [flag_occurrences()].
#'
#' @param test One of `"capital"`, `"centroid"`, `"institution"`,
#'   `"gbif_headquarters"`, `"aohi"`.
#' @param reference `"natural_earth"` (the package's own gazetteers) or
#'   `"CoordinateCleaner"` (that package's tables, which must be installed).
#' @return A data frame with columns `lon` and `lat` and, for the package's
#'   own gazetteers, the attributes of each point: `name`, `country`,
#'   `adm0_a3`, `iso_a2`, `class` for capitals; `name`, `adm0_a3`, `code`,
#'   `type`, `method` for centroids; `key`, `code`, `name`, `country`, `city`,
#'   `type`, `active`, `master_source`, `source` for institutions (`source`
#'   is GRSciColl, Wikidata, GeoNames or BGCI, `key` the GRSciColl key, Wikidata
#'   item, or the GeoNames or BGCI id with its prefix); `id`,
#'   `taxon` (the group the hotspot was found in: Aves, Insecta, Mammalia,
#'   Plantae), `frequency` (records at the point), `category`,
#'   `determination` (TRUE for a real observation site, FALSE for an
#'   artificial aggregate of records) and `notes` for the inventory. For
#'   `reference = "CoordinateCleaner"` the columns are `lon` and `lat` only.
#' @examples
#' head(reference_points("capital"))
#' table(reference_points("centroid")$type)
#' @export
reference_points <- function(test = c("capital", "centroid", "institution", "gbif_headquarters", "aohi"),
                             reference = c("natural_earth", "CoordinateCleaner")) {
  test <- match.arg(test)
  reference <- match.arg(reference)
  if (test == "gbif_headquarters") return(data.frame(lon = 12.58, lat = 55.67))
  if (reference == "natural_earth") {
    return(switch(test, capital = ref_capitals, centroid = ref_centroids, institution = ref_institutions,
                  aohi = ref_aohi))
  }
  need_coordinatecleaner()
  cr <- get_cc_data("countryref")
  switch(test,
    capital = {
      d <- unique(cr[!is.na(cr$capital.lon) & !is.na(cr$capital.lat), c("capital.lon", "capital.lat")])
      data.frame(lon = d$capital.lon, lat = d$capital.lat)
    },
    centroid = {
      d <- cr[!is.na(cr$centroid.lon) & !is.na(cr$centroid.lat), ]
      data.frame(lon = d$centroid.lon, lat = d$centroid.lat)
    },
    institution = {
      d <- get_cc_data("institutions")
      d <- d[!is.na(d$decimalLongitude) & !is.na(d$decimalLatitude), ]
      data.frame(lon = d$decimalLongitude, lat = d$decimalLatitude)
    },
    aohi = {
      d <- as.data.frame(get_cc_data("aohi"))
      data.frame(lon = d$decimalLongitude, lat = d$decimalLatitude)
    })
}

# Point gazetteer (data frame with lon, lat) for a test under a reference.
point_gazetteer <- function(test, reference) {
  reference_points(test, reference)[, c("lon", "lat")]
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
      urban = ref_urban_50,
      country_mismatch = ref_countries_50))
  }
  if (!requireNamespace("rnaturalearth", quietly = TRUE))
    stop("reference = \"CoordinateCleaner\" needs the rnaturalearth package for polygon layers")
  sf <- switch(test,
    sea = rnaturalearth::ne_download(scale = land_scale, type = "land", category = "physical",
                                    returnclass = "sf", load = TRUE),
    urban = rnaturalearth::ne_download(scale = "medium", type = "urban_areas", returnclass = "sf",
                                    load = TRUE),
    country_mismatch = rnaturalearth::ne_countries(scale = "medium", returnclass = "sf"))
  features <- if (test == "country_mismatch") {
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

# ---- user-supplied gazetteers --------------------------------------------------

.point_tests <- c("capital", "centroid", "institution", "gbif_headquarters", "aohi")
.polygon_tests <- c("sea", "urban", "country_mismatch", "range")

# Index each user layer once: list(index = per-test index, label = text for
# the reference label, or NULL when none is given).
prepare_gazetteers <- function(gazetteers, columns = occ_columns()) {
  if (is.null(gazetteers)) return(list(index = list(), label = NULL))
  if (!is.list(gazetteers) || inherits(gazetteers, c("data.frame", "sf", "sfc")) ||
      is.null(names(gazetteers)) || any(!nzchar(names(gazetteers))))
    stop("`gazetteers` must be a named list of reference layers, one per test")
  bad <- setdiff(names(gazetteers), c(.point_tests, .polygon_tests, "sampling", "habitat"))
  if (length(bad)) stop("`gazetteers` has no reference layer for test(s): ", paste(bad, collapse = ", "))
  index <- list()
  label <- character()
  for (t in names(gazetteers)) {
    g <- gazetteers[[t]]
    if (t == "sampling") {
      index$sampling <- gazetteer_sampling(g)
      label <- c(label, sprintf("sampling %d countries md5 %s", nrow(index$sampling), checksum(index$sampling)))
    } else if (t == "habitat") {
      h <- gazetteer_habitat(g)
      index$habitat <- habitat_lookup(h)
      label <- c(label, sprintf("habitat %d genera md5 %s", nrow(h), checksum(h)))
    } else if (t %in% .point_tests) {
      p <- gazetteer_points(g, t)
      index[[t]] <- cpp_point_index(p$lon, p$lat)
      label <- c(label, sprintf("%s %d points md5 %s", t, length(p$lon), checksum(p)))
    } else if (t == "range") {
      r <- gazetteer_ranges(g, columns$species)
      index[[t]] <- r$index
      label <- c(label, sprintf("range %d species md5 %s", length(r$index), r$md5))
    } else {
      layer <- gazetteer_polygons(g, t)
      cell <- min(2, max(0.1, sqrt(64800 / length(layer$x))))
      index[[t]] <- list(index = cpp_polygon_index(layer$x / 1e7, layer$y / 1e7, as.integer(layer$ring_start),
                                                   as.integer(layer$ring_feature), cell),
                         features = layer$features)
      label <- c(label, sprintf("%s %d features md5 %s", t, nrow(layer$features),
                                checksum(layer[c("x", "y", "ring_start", "ring_feature")])))
    }
  }
  list(index = index, label = paste(label, collapse = ", "))
}

# A point layer: data frame to finite lon/lat vectors.
gazetteer_points <- function(g, test) {
  if (!is.data.frame(g)) stop("`gazetteers$", test, "` must be a data frame of points")
  nm <- tolower(names(g))
  lon <- match(c("lon", "longitude", "decimallongitude"), nm)
  lat <- match(c("lat", "latitude", "decimallatitude"), nm)
  lon <- lon[!is.na(lon)][1]
  lat <- lat[!is.na(lat)][1]
  if (is.na(lon) || is.na(lat))
    stop("`gazetteers$", test, "` needs longitude and latitude columns ",
         "(lon/lat, longitude/latitude or decimalLongitude/decimalLatitude)")
  x <- to_numeric(g[[lon]])
  y <- to_numeric(g[[lat]])
  ok <- is.finite(x) & is.finite(y) & abs(x) <= 180 & abs(y) <= 90
  if (!any(ok)) stop("`gazetteers$", test, "` has no valid coordinates")
  list(lon = x[ok], lat = y[ok])
}

# A polygon layer: sf or sfc to the compact ring representation, plus the code
# columns for country_mismatch.
gazetteer_polygons <- function(g, test) {
  if (inherits(g, "sf")) {
    geom <- g[[attr(g, "sf_column")]]
    d <- as.data.frame(g)
    d[[attr(g, "sf_column")]] <- NULL
  } else if (inherits(g, "sfc")) {
    geom <- g
    d <- data.frame(row.names = seq_along(g))
  } else {
    stop("`gazetteers$", test, "` must be an sf or sfc object of polygons")
  }
  epsg <- attr(geom, "crs")$epsg
  if (!is.null(epsg) && !is.na(epsg) && epsg != 4326)
    stop("`gazetteers$", test, "` must be in longitude and latitude (EPSG:4326), not EPSG:", epsg)
  if (!all(vapply(geom, function(p) inherits(p, c("POLYGON", "MULTIPOLYGON")), logical(1))))
    stop("`gazetteers$", test, "` must hold POLYGON or MULTIPOLYGON geometries")
  rings <- rings_from_sfc(geom)
  features <- if (test == "country_mismatch") gazetteer_codes(d) else data.frame(id = seq_along(geom))
  list(x = as.integer(round(rings$x * 1e7)), y = as.integer(round(rings$y * 1e7)),
       ring_start = rings$ring_start, ring_feature = rings$ring_feature, features = features)
}

# Country codes per feature: iso_a3, iso_a2 and adm0_a3 columns, and a generic
# `code` column sorted into alpha-2 or alpha-3 by length.
gazetteer_codes <- function(d) {
  code_col <- function(name) {
    i <- match(name, tolower(names(d)))
    if (is.na(i)) return(rep(NA_character_, nrow(d)))
    v <- toupper(trimws(as.character(d[[i]])))
    v[is.na(v) | v %in% c("", "-99")] <- NA_character_
    v
  }
  f <- data.frame(iso_a3 = code_col("iso_a3"), iso_a2 = code_col("iso_a2"),
                  adm0_a3 = code_col("adm0_a3"), stringsAsFactors = FALSE)
  generic <- code_col("code")
  if (all(is.na(unlist(f))) && all(is.na(generic)))
    stop("`gazetteers$country_mismatch` needs a code column: iso_a2, iso_a3, adm0_a3 or code")
  fill3 <- is.na(f$iso_a3) & !is.na(generic) & nchar(generic) == 3L
  fill2 <- is.na(f$iso_a2) & !is.na(generic) & nchar(generic) == 2L
  f$iso_a3[fill3] <- generic[fill3]
  f$iso_a2[fill2] <- generic[fill2]
  f
}

# Range polygons: one small polygon index per species, each covering only the
# bounding box of that species' polygons. The species column is the record
# species column's name, `species`, `binomial` or `sci_name` (any case).
gazetteer_ranges <- function(g, species_col) {
  if (!inherits(g, "sf")) stop("`gazetteers$range` must be an sf object with a species column")
  geom <- g[[attr(g, "sf_column")]]
  d <- as.data.frame(g)
  i <- match(tolower(c(species_col, "species", "binomial", "sci_name")), tolower(names(d)))
  i <- i[!is.na(i)][1]
  if (is.na(i)) stop("`gazetteers$range` needs a species column (", species_col, ", species, binomial or sci_name)")
  sp <- as.character(d[[i]])
  layer <- gazetteer_polygons(geom, "range")
  index <- list()
  for (k in unique(sp[!is.na(sp)])) {
    feats <- which(sp == k)
    rings <- which(layer$ring_feature %in% feats)
    if (!length(rings)) next
    v <- unlist(lapply(rings, function(r) seq.int(layer$ring_start[r] + 1L, layer$ring_start[r + 1L])))
    x <- layer$x[v] / 1e7; y <- layer$y[v] / 1e7
    len <- layer$ring_start[rings + 1L] - layer$ring_start[rings]
    starts <- c(0L, cumsum(len))
    ext <- c(min(x), max(x), min(y), max(y))
    cell <- max(0.01, min(2, sqrt((ext[2] - ext[1] + 1e-9) * (ext[4] - ext[3] + 1e-9) / max(1, length(x)))))
    index[[k]] <- cpp_polygon_index(x, y, as.integer(starts), rep(1L, length(rings)), cell, ext)
  }
  list(index = index, md5 = checksum(list(sp, layer[c("x", "y", "ring_start", "ring_feature")])))
}

# Records per country for the outlier sampling correction: a data frame with
# an ISO alpha-2 country column (country, iso_a2 or code) and a record count
# (records, count or n).
gazetteer_sampling <- function(g) {
  if (!is.data.frame(g)) stop("`gazetteers$sampling` must be a data frame of records per country")
  nm <- tolower(names(g))
  ci <- match(c("country", "iso_a2", "code"), nm); ci <- ci[!is.na(ci)][1]
  ri <- match(c("records", "count", "n"), nm); ri <- ri[!is.na(ri)][1]
  if (is.na(ci) || is.na(ri)) stop("`gazetteers$sampling` needs a country column and a records column")
  out <- data.frame(country = toupper(trimws(as.character(g[[ci]]))), records = to_numeric(g[[ri]]),
                    stringsAsFactors = FALSE)
  out[!is.na(out$country) & is.finite(out$records) & out$records > 0, , drop = FALSE]
}

checksum <- function(obj) {
  f <- tempfile()
  on.exit(unlink(f))
  writeBin(serialize(unname(obj), NULL, version = 3), f)
  unname(tools::md5sum(f))
}

# Version label written into flag output.
reference_label <- function(reference, land_scale, custom = NULL) {
  base <- reference_label_base(reference, land_scale)
  if (is.null(custom)) base else paste0(base, "; custom: ", custom)
}

reference_label_base <- function(reference, land_scale) {
  if (reference == "natural_earth") {
    m <- ref_meta
    paste0("natural_earth (land ", land_scale, "; ",
           paste(sprintf("%s %s", m$layer, m$version), collapse = ", "), ")")
  } else {
    paste0("CoordinateCleaner ",
           if (requireNamespace("CoordinateCleaner", quietly = TRUE))
             as.character(utils::packageVersion("CoordinateCleaner")) else "(not installed)",
           " (land ", land_scale, "; habitat ", ref_meta$version[ref_meta$layer == "habitat"], ")")
  }
}
