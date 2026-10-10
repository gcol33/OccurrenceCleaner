# Build the biodiversity-institution gazetteer from GBIF's Global Registry of
# Scientific Collections (GRSciColl), Wikidata, Wikipedia's list of natural
# history museums, GeoNames and BGCI GardenSearch.
# GRSciColl bulk export
# https://api.gbif.org/v1/grscicoll/institution/export?format=TSV
#
# GRSciColl is synchronised weekly with Index Herbariorum (masterSourceType
# "IH") and absorbed the Global Registry of Biodiversity Repositories (GRBio)
# in 2018. Only institutions with coordinates are kept, and of those only the
# ones the zero test would not flag (longitude or latitude exactly zero, or
# within 0.5 degrees of (0, 0)): such entries are geocoding failures, and
# keeping them would flag every zero-coordinate record as an institution too.
#
# Run from the package root:  Rscript data-raw/institutions.R

cache <- "data-raw/cache"
dir.create(cache, showWarnings = FALSE, recursive = TRUE)
retrieved <- "2026-10-09"
url <- "https://api.gbif.org/v1/grscicoll/institution/export?format=TSV"
tsv <- file.path(cache, "grscicoll_institutions.tsv")
if (!file.exists(tsv)) download.file(url, tsv, mode = "wb", quiet = TRUE)

d <- read.delim(tsv, quote = "", comment.char = "", na.strings = "", stringsAsFactors = FALSE,
                encoding = "UTF-8", check.names = FALSE)
lon <- suppressWarnings(as.numeric(d$longitude))
lat <- suppressWarnings(as.numeric(d$latitude))
valid <- is.finite(lon) & is.finite(lat) & lon >= -180 & lon <= 180 & lat >= -90 & lat <= 90
zero <- valid & (lon == 0 | lat == 0 | sqrt(lon^2 + lat^2) <= 0.5)
keep <- valid & !zero
institutions <- data.frame(key = d$key[keep], code = d$code[keep], name = d$name[keep],
                           country = d$country[keep], city = d$city[keep], type = d$type[keep],
                           active = d$active[keep] == "true", master_source = d$masterSourceType[keep],
                           lon = lon[keep], lat = lat[keep], stringsAsFactors = FALSE)
institutions$source <- "GRSciColl"
n_grscicoll <- nrow(institutions)

# Wikidata (CC0): botanical gardens (Q167346, arboreta are a subclass), natural
# history museums (Q1970365), zoos (Q43501), herbaria (Q181916) and public
# aquaria (Q2281788), every item that is an instance of the class or of a
# subclass and has a coordinate location (P625) on Earth. These cover the
# botanic gardens (BGCI), museums (Wikipedia) and zoos that CoordinateCleaner's
# table holds beside GRBio and Index Herbariorum, typed with the GRSciColl
# institution types. One query per class keeps
# each under the query service time limit.
#
# CoordinateCleaner's Wikipedia rows are the museums of Wikipedia's "List of
# natural history museums". Each entry of the list reads "name, place, ..."
# under its country heading. An entry whose name links an article is placed at
# the Wikidata coordinates of that article's item. Otherwise it is placed at
# the first place it links that has Wikidata coordinates and is not a country
# or first-level unit (by the place's GeoNames id), or at the GeoNames
# populated place of that name in the country. A first-level unit is replaced
# by its seat when the seat carries the same name, and an entry naming no
# place by a populated place named at the start or end of the museum's name.
wd_retrieved <- "2026-10-10"
ua <- "OccurrenceCleaner data-raw (https://github.com/gcol33/OccurrenceCleaner)"
wd_endpoint <- "https://query.wikidata.org/sparql"
wd_select <- paste0("SELECT ?item ?label ?coord ?iso2 ?cls WHERE { %s ?item wdt:P31/wdt:P279* ?cls . ",
                    "?item wdt:P625 ?coord . ",
                    "OPTIONAL { ?item wdt:P17 ?c . ?c wdt:P297 ?iso2 . } ",
                    "OPTIONAL { ?item rdfs:label ?label . FILTER(lang(?label) = \"en\") } }")
wd_fetch <- function(query, f) {
  if (!file.exists(f))
    download.file(paste0(wd_endpoint, "?query=", utils::URLencode(query, reserved = TRUE)), f, mode = "wb",
                  quiet = TRUE, headers = c(Accept = "text/csv", `User-Agent` = ua))
  x <- read.csv(f, stringsAsFactors = FALSE, na.strings = "", encoding = "UTF-8", colClasses = "character")
  x[] <- lapply(x, function(v) sub("^http://www.wikidata.org/entity/", "", v))
  x
}
wd_classes <- c(Q167346 = "BotanicalGarden", Q1970365 = "Museum", Q43501 = "ZooAquarium",
                Q181916 = "Herbarium", Q2281788 = "ZooAquarium")
wd_files <- character()
wd <- NULL
for (q in names(wd_classes)) {
  f <- file.path(cache, paste0("wikidata_", q, "_v2.csv"))
  x <- wd_fetch(sprintf(wd_select, paste0("VALUES ?cls { wd:", q, " }")), f)
  x$type <- wd_classes[[q]]
  wd <- rbind(wd, x)
  wd_files <- c(wd_files, f)
}

gn_dump <- "https://download.geonames.org/export/dump/"
gn_get <- function(name) {
  f <- file.path(cache, paste0("geonames_", name))
  if (!file.exists(f)) download.file(paste0(gn_dump, name), f, mode = "wb", quiet = TRUE)
  f
}
gn_read <- function(con) read.delim(con, header = FALSE, quote = "", comment.char = "", na.strings = "",
                                    colClasses = "character", encoding = "UTF-8")
gn_country <- read.delim(gn_get("countryInfo.txt"), header = FALSE, quote = "", comment.char = "#",
                         na.strings = "", colClasses = "character", encoding = "UTF-8")
gn_admin1 <- gn_read(gn_get("admin1CodesASCII.txt"))
gn_cities <- gn_read(unz(gn_get("cities500.zip"), "cities500.txt"))
wp_gn_files <- file.path(cache, paste0("geonames_", c("countryInfo.txt", "admin1CodesASCII.txt", "cities500.zip")))

ascii_key <- function(x) trimws(tolower(gsub("[^A-Za-z0-9]+", " ", iconv(x, "UTF-8", "ASCII//TRANSLIT", sub = ""))))
gn_alt <- strsplit(ifelse(is.na(gn_cities$V4), "", gn_cities$V4), ",", fixed = TRUE)
gn_row <- c(seq_len(nrow(gn_cities)), seq_len(nrow(gn_cities)), rep(seq_len(nrow(gn_cities)), lengths(gn_alt)))
gn_index <- data.frame(key = paste(gn_cities$V9[gn_row],
                                   ascii_key(c(gn_cities$V2, gn_cities$V3, unlist(gn_alt)))), row = gn_row)
gn_index <- gn_index[order(gn_index$key, -as.numeric(gn_cities$V15[gn_index$row])), ]
gn_index <- gn_index[!duplicated(gn_index$key), ]
populated_place <- function(text, iso2, seat = FALSE) {
  j <- gn_index$row[match(paste(iso2, ascii_key(text)), gn_index$key)]
  if (is.na(j) || (seat && !gn_cities$V8[j] %in% c("PPLC", "PPLA"))) return(NULL)
  c(as.numeric(gn_cities$V6[j]), as.numeric(gn_cities$V5[j]))
}
country_iso2 <- c(setNames(gn_country$V1, gn_country$V5), `Czech Republic` = "CZ", Macedonia = "MK",
                  `The Netherlands` = "NL", Palestine = "PS", `Canary Islands` = "ES")

wp_title <- "List_of_natural_history_museums"
wp_file <- file.path(cache, "wikipedia_natural_history_museums_wikitext.json")
if (!file.exists(wp_file))
  download.file(paste0("https://en.wikipedia.org/w/api.php?action=parse&format=json&formatversion=2&page=",
                       wp_title, "&prop=wikitext|revid"), wp_file, quiet = TRUE, headers = c(`User-Agent` = ua))
wp_page <- jsonlite::fromJSON(wp_file)$parse
wp_lines <- strsplit(wp_page$wikitext, "\n", fixed = TRUE)[[1]]
wp_clean <- function(s) {
  s <- gsub("\\{\\{lang\\|[^|{}]*\\|([^{}]*)\\}\\}", "\\1", s, perl = TRUE)
  s <- gsub("<ref[^>]*/>", "", s, perl = TRUE)
  s <- gsub("<ref[^>]*>.*?</ref>", "", s, perl = TRUE)
  s <- sub("<ref.*$", "", s, perl = TRUE)
  repeat { t <- gsub("\\{\\{[^{}]*\\}\\}", "", s, perl = TRUE); if (identical(t, s)) break; s <- t }
  gsub("'{2,}", "", gsub("<[^>]+>", "", s, perl = TRUE), perl = TRUE)
}
wp_links <- function(s) {
  if (!length(s)) return(character())
  l <- regmatches(s, gregexpr("\\[\\[[^]]*\\]\\]", s, perl = TRUE))[[1]]
  sub("#.*$", "", sub("\\|.*$", "", gsub("^\\[\\[|\\]\\]$", "", l)))
}
wp_text <- function(s) {
  s <- gsub("\\[\\[[^]|]*\\|([^]]*)\\]\\]", "\\1", s, perl = TRUE)
  trimws(gsub("\\s+", " ", gsub("\\[\\[([^]]*)\\]\\]", "\\1", s, perl = TRUE)))
}
wp_split <- function(s) {
  m <- gregexpr("\\[\\[[^]]*\\]\\]", s, perl = TRUE)
  regmatches(s, m) <- lapply(regmatches(s, m), function(x) gsub(",", "\001", x, fixed = TRUE))
  seg <- trimws(gsub("\001", ",", strsplit(s, ",", fixed = TRUE)[[1]], fixed = TRUE))
  seg[nzchar(seg)]
}
wpl <- list(); heading <- NA_character_; parent <- NULL
for (i in seq_along(wp_lines)) {
  ln <- wp_lines[i]
  if (grepl("^===[^=]", ln)) { heading <- trimws(gsub("=", "", ln)); next }
  if (grepl("^==[^=]", ln)) { heading <- NA_character_; next }
  if (!grepl("^\\*", ln) || is.na(heading)) next
  seg <- wp_split(wp_clean(sub("^\\*+\\s*", "", ln)))
  if (!length(seg)) next
  article <- if (startsWith(seg[1], "[[")) wp_links(seg[1])[1] else
    wp_links(regmatches(seg[1], regexpr("\\(\\[\\[[^]]*\\]\\]\\)", seg[1], perl = TRUE)))[1]
  e <- list(line = i, iso2 = unname(country_iso2[heading]), name = wp_text(gsub("\\([^()]*\\)", "", seg[1])),
            article = article, places = seg[-1])
  if (startsWith(ln, "**") && !length(e$places) && !is.null(parent))
    e$places <- c(if (!is.na(parent$article)) paste0("[[", parent$article, "]]"), parent$places)
  if (!startsWith(ln, "**")) parent <- e
  wpl[[length(wpl) + 1]] <- e
}
stopifnot(!anyNA(vapply(wpl, function(e) e$iso2, character(1))))

wp_titles <- unique(c(vapply(wpl, function(e) e$article, character(1)),
                      unlist(lapply(wpl, function(e) unlist(lapply(e$places, wp_links))))))
wp_titles <- wp_titles[!is.na(wp_titles) & nzchar(wp_titles)]
wp_items_file <- file.path(cache, "wikipedia_natural_history_museums_titles.csv")
if (!file.exists(wp_items_file)) {
  lang <- ifelse(grepl("^:[a-z-]+:", wp_titles), sub("^:([a-z-]+):.*$", "\\1", wp_titles), "en")
  bare <- sub("^:[a-z-]+:", "", wp_titles)
  out <- NULL
  for (lg in unique(lang)) for (b in split(unique(bare[lang == lg]), ceiling(seq_along(unique(bare[lang == lg])) / 50))) {
    f <- tempfile()
    download.file(paste0("https://", lg, ".wikipedia.org/w/api.php?action=query&format=json&redirects=1",
                         "&prop=pageprops&ppprop=wikibase_item&titles=",
                         utils::URLencode(paste(b, collapse = "|"), reserved = TRUE)),
                  f, quiet = TRUE, headers = c(`User-Agent` = ua))
    q <- jsonlite::fromJSON(f, simplifyVector = FALSE)$query
    to <- setNames(b, b)
    for (n in q$normalized) to[to == n$from] <- n$to
    for (r in q$redirects) to[to == r$from] <- r$to
    pg <- setNames(vapply(q$pages, function(p) if (is.null(p$pageprops$wikibase_item)) NA_character_
                          else p$pageprops$wikibase_item, character(1)),
                   vapply(q$pages, function(p) p$title, character(1)))
    out <- rbind(out, data.frame(title = if (lg == "en") b else paste0(":", lg, ":", b), item = unname(pg[to])))
  }
  write.csv(out, wp_items_file, row.names = FALSE, fileEncoding = "UTF-8")
}
wp_items <- read.csv(wp_items_file, stringsAsFactors = FALSE, encoding = "UTF-8")
wp_item <- setNames(wp_items$item, wp_items$title)
wp_q <- sort(unique(na.omit(wp_items$item)))
wp_coord <- NULL
for (b in split(wp_q, ceiling(seq_along(wp_q) / 100))) {
  f <- file.path(cache, sprintf("wikidata_wplist_coords_%s.csv", b[1]))
  wp_coord <- rbind(wp_coord, wd_fetch(paste0("SELECT ?item ?coord ?gn WHERE { VALUES ?item { ",
                                              paste0("wd:", b, collapse = " "), " } ?item p:P625/ps:P625 ?coord . ",
                                              "OPTIONAL { ?item wdt:P1566 ?gn } }"), f))
  wd_files <- c(wd_files, f)
}
wp_coord <- wp_coord[grepl("^Point\\(", wp_coord$coord), ]
wp_coarse <- tapply(wp_coord$gn %in% c(gn_country$V17, gn_admin1$V4), wp_coord$item, any) &
  !tapply(wp_coord$gn %in% gn_cities$V1, wp_coord$item, any)
wp_coord <- wp_coord[!duplicated(wp_coord$item), ]
wp_point <- function(q) {
  j <- match(q, wp_coord$item)
  if (is.na(j)) NULL else as.numeric(strsplit(sub("^Point\\(([^ ]+) ([^)]+)\\)$", "\\1 \\2", wp_coord$coord[j]), " ")[[1]])
}

wp_located <- do.call(rbind, lapply(wpl, function(e) {
  xy <- NULL; how <- NA_character_; place <- NA_character_
  q <- if (is.na(e$article)) NA_character_ else unname(wp_item[e$article])
  if (!is.na(q)) { xy <- wp_point(q); if (!is.null(xy)) how <- "museum" }
  if (is.null(xy)) for (p in e$places) {
    pq <- unname(wp_item[wp_links(p)])
    if (length(pq) && all(!is.na(pq) & wp_coarse[pq] %in% TRUE)) {
      xy <- populated_place(wp_text(p), e$iso2, seat = TRUE)
      if (!is.null(xy)) { how <- "GeoNames populated place"; place <- wp_text(p); break }
      next
    }
    for (pp in pq[!is.na(pq) & !wp_coarse[pq] %in% TRUE]) {
      xy <- wp_point(pp)
      if (!is.null(xy)) { how <- "Wikidata linked place"; place <- wp_text(p); break }
    }
    if (!is.null(xy)) break
    txt <- sub("^(located )?(at|in) (the )?", "", wp_text(gsub("\\([^()]*\\)", "", p)))
    xy <- populated_place(txt, e$iso2)
    if (!is.null(xy)) { how <- "GeoNames populated place"; place <- txt; break }
  }
  if (is.null(xy) && !length(e$places)) {
    w <- strsplit(e$name, "[ ,]+")[[1]]
    for (k in 3:1) for (g in unique(list(w[seq_len(min(k, length(w)))], w[max(1, length(w) - k + 1):length(w)]))) {
      if (is.null(xy) && grepl("^[[:upper:]]", g[1]) && grepl("^[[:upper:]]", g[length(g)])) {
        xy <- populated_place(paste(g, collapse = " "), e$iso2)
        if (!is.null(xy)) { how <- "GeoNames populated place"; place <- paste(g, collapse = " ") }
      }
    }
  }
  data.frame(line = e$line, name = e$name, iso2 = e$iso2, item = q, how = how, place = place,
             lon = if (is.null(xy)) NA_real_ else xy[1], lat = if (is.null(xy)) NA_real_ else xy[2])
}))
wp_museum <- wp_located[wp_located$how %in% "museum" & !wp_located$item %in% wd$item, ]
wd <- rbind(wd, data.frame(item = wp_museum$item, label = wp_museum$name,
                           coord = sprintf("Point(%s %s)", wp_museum$lon, wp_museum$lat), iso2 = wp_museum$iso2,
                           cls = NA_character_, type = "Museum"))
wp_placed <- wp_located[!is.na(wp_located$how) & wp_located$how != "museum", ]
wp_zero <- wp_placed$lon == 0 | wp_placed$lat == 0 | sqrt(wp_placed$lon^2 + wp_placed$lat^2) <= 0.5
wp_placed <- wp_placed[!wp_zero, ]
wp_placed <- wp_placed[!duplicated(wp_placed[, c("name", "lon", "lat")]), ]
wikipedia <- data.frame(key = paste0("wikipedia:", wp_page$revid, ":", wp_placed$line), code = NA_character_,
                        name = wp_placed$name, country = wp_placed$iso2, city = wp_placed$place, type = "Museum",
                        active = NA, master_source = wp_placed$how, lon = wp_placed$lon, lat = wp_placed$lat,
                        source = "Wikipedia", stringsAsFactors = FALSE)
earth <- grepl("^Point\\(", wd$coord)
xy <- do.call(rbind, strsplit(sub("^Point\\(([^ ]+) ([^)]+)\\)$", "\\1 \\2", wd$coord[earth]), " ", fixed = TRUE))
wd <- wd[earth, ]
wd$lon <- as.numeric(xy[, 1])
wd$lat <- as.numeric(xy[, 2])
wd$key <- sub("^http://www.wikidata.org/entity/", "", wd$item)
wd_valid <- is.finite(wd$lon) & is.finite(wd$lat) & abs(wd$lon) <= 180 & abs(wd$lat) <= 90
wd_zero <- wd_valid & (wd$lon == 0 | wd$lat == 0 | sqrt(wd$lon^2 + wd$lat^2) <= 0.5)
wd <- wd[wd_valid & !wd_zero, ]
wd <- wd[!duplicated(wd[, c("key", "lon", "lat")]), ]
wikidata <- data.frame(key = wd$key, code = NA_character_, name = wd$label, country = wd$iso2, city = NA_character_,
                       type = wd$type, active = NA, master_source = NA_character_, lon = wd$lon, lat = wd$lat,
                       source = "Wikidata", stringsAsFactors = FALSE)

# GeoNames (CC BY 4.0, https://www.geonames.org): the three places
# CoordinateCleaner's table attributes to GeoNames, by GeoNames id from the
# country dumps of https://download.geonames.org/export/dump/.
gn_ids <- c(`10280522` = "ZooAquarium", `10125927` = "BotanicalGarden", `10375777` = "Museum")
gn_files <- character()
gn <- NULL
for (cc in c("MC", "PT", "IT")) {
  z <- gn_get(paste0(cc, ".zip"))
  gn_files <- c(gn_files, z)
  x <- gn_read(unz(z, paste0(cc, ".txt")))
  gn <- rbind(gn, x[x$V1 %in% names(gn_ids), c(1, 2, 5, 6, 9)])
}
stopifnot(nrow(gn) == length(gn_ids))
geonames <- data.frame(key = paste0("geonames:", gn$V1), code = NA_character_, name = gn$V2, country = gn$V9,
                       city = NA_character_, type = unname(gn_ids[gn$V1]), active = NA, master_source = NA_character_,
                       lon = as.numeric(gn$V6), lat = as.numeric(gn$V5), source = "GeoNames",
                       stringsAsFactors = FALSE)

# Botanic Gardens Conservation International (BGCI) GardenSearch: the garden
# map at https://tools.bgci.org/map.php, requested for all countries, lists
# every garden as "id;name;address 1;address 2;city;region;postcode;country;
# latitude;longitude" (3,765 gardens on 2026-10-10). The country select of the same page maps BGCI's
# country names to ISO 3166 alpha-2 codes. Terms of use:
# https://www.bgci.org/terms-and-conditions/
bgci_retrieved <- "2026-10-10"
bgci_url <- "https://tools.bgci.org/map.php"
bgci_file <- file.path(cache, "bgci_map_all.html")
if (!file.exists(bgci_file)) {
  h <- curl::new_handle(useragent = ua, postfields = "mode=&ftrCountry=All")
  curl::curl_download(bgci_url, bgci_file, handle = h)
}
bg_lines <- readLines(bgci_file, warn = FALSE, encoding = "UTF-8")
bg_rows <- sub("^\\s*_arrCountryList\\[[0-9]+\\]=\\('(.*)'\\);\\s*$", "\\1",
               grep("^\\s*_arrCountryList\\[[0-9]+\\]=\\('", bg_lines, value = TRUE))
bg <- read.table(text = bg_rows, sep = ";", quote = "", comment.char = "", fill = TRUE, col.names =
                   c("id", "name", "address1", "address2", "city", "region", "postcode", "country", "lat", "lon"),
                 colClasses = "character", na.strings = "", encoding = "UTF-8")
# The list writes apostrophes as "+" to keep them out of the JavaScript quotes.
bg[] <- lapply(bg, function(v) gsub("+", "'", v, fixed = TRUE))
bg_opts <- regmatches(bg_lines, regexpr("<option value='[A-Z]{2}' *>[^<]+", bg_lines))
bg_iso <- setNames(sub("^<option value='([A-Z]{2})'.*$", "\\1", bg_opts), trimws(sub("^[^>]*>", "", bg_opts)))
bg$iso2 <- unname(bg_iso[bg$country])
bg_lon <- suppressWarnings(as.numeric(bg$lon))
bg_lat <- suppressWarnings(as.numeric(bg$lat))
bg_valid <- is.finite(bg_lon) & is.finite(bg_lat) & abs(bg_lon) <= 180 & abs(bg_lat) <= 90
bg_zero <- bg_valid & (bg_lon == 0 | bg_lat == 0 | sqrt(bg_lon^2 + bg_lat^2) <= 0.5)
bg_keep <- bg_valid & !bg_zero
bgci <- data.frame(key = paste0("bgci:", bg$id[bg_keep]), code = NA_character_, name = bg$name[bg_keep],
                   country = bg$iso2[bg_keep], city = bg$city[bg_keep], type = "BotanicalGarden", active = NA,
                   master_source = NA_character_, lon = bg_lon[bg_keep], lat = bg_lat[bg_keep], source = "BGCI",
                   stringsAsFactors = FALSE)

institutions <- rbind(institutions, wikidata, wikipedia, geonames, bgci)
institutions <- institutions[order(institutions$country, institutions$name), ]
rownames(institutions) <- NULL

sha256 <- function(path) {
  if (requireNamespace("digest", quietly = TRUE)) return(digest::digest(path, algo = "sha256", file = TRUE))
  tolower(strsplit(system2("certutil", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)[2], " ")[[1]][1])
}
meta <- rbind(
  data.frame(layer = "institutions", source = "GBIF GRSciColl", file = basename(tsv),
             version = retrieved, url = url, sha256 = sha256(tsv), retrieved = retrieved,
             licence = "see dev_notes/reference_data.md", stringsAsFactors = FALSE),
  data.frame(layer = "institutions_wikidata", source = "Wikidata",
             file = paste(basename(wd_files), collapse = ", "), version = wd_retrieved, url = wd_endpoint,
             sha256 = paste(vapply(wd_files, sha256, character(1)), collapse = ", "), retrieved = wd_retrieved,
             licence = "CC0 1.0", stringsAsFactors = FALSE),
  data.frame(layer = "institutions_wikipedia", source = "Wikipedia, List of natural history museums",
             file = paste(basename(c(wp_file, wp_items_file, wp_gn_files)), collapse = ", "),
             version = paste0("revision ", wp_page$revid), url = paste0("https://en.wikipedia.org/wiki/", wp_title),
             sha256 = paste(vapply(c(wp_file, wp_items_file, wp_gn_files), sha256, character(1)), collapse = ", "),
             retrieved = wd_retrieved,
             licence = "list CC BY-SA 4.0; places from Wikidata (CC0 1.0) and GeoNames (CC BY 4.0)",
             stringsAsFactors = FALSE),
  data.frame(layer = "institutions_geonames", source = "GeoNames",
             file = paste(basename(gn_files), collapse = ", "), version = wd_retrieved,
             url = "https://download.geonames.org/export/dump/",
             sha256 = paste(vapply(gn_files, sha256, character(1)), collapse = ", "), retrieved = wd_retrieved,
             licence = "CC BY 4.0", stringsAsFactors = FALSE),
  data.frame(layer = "institutions_bgci", source = "BGCI GardenSearch", file = basename(bgci_file),
             version = bgci_retrieved, url = paste0(bgci_url, " (ftrCountry=All)"), sha256 = sha256(bgci_file),
             retrieved = bgci_retrieved, licence = "BGCI terms, https://www.bgci.org/terms-and-conditions/",
             stringsAsFactors = FALSE))
saveRDS(list(institutions = institutions, meta = meta), file.path(cache, "institutions.rds"), compress = "xz")
cat("GRSciColl institutions with coordinates:", sum(valid), "of", nrow(d), "- dropped as zero coordinates:",
    sum(zero), "- kept:", n_grscicoll, "\n")
print(d[zero, c("code", "name", "country", "longitude", "latitude")])
cat("Wikidata points:", sum(earth), "on Earth, dropped as zero coordinates:", sum(wd_zero), "- kept:",
    nrow(wikidata), "\n")
cat("Wikipedia list entries:", nrow(wp_located), "- located by:\n")
print(table(wp_located$how, useNA = "ifany"))
cat("Wikipedia rows placed by linked place or GeoNames:", nrow(wikipedia), "- dropped as zero coordinates:",
    sum(wp_zero), "\n")
print(geonames)
cat("BGCI gardens:", nrow(bg), "- with coordinates:", sum(bg_valid), "- dropped as zero coordinates:",
    sum(bg_zero), "- kept:", nrow(bgci), "- country names without ISO code:",
    paste(unique(bg$country[bg_keep & is.na(bg$iso2)]), collapse = ", "), "\n")
print(table(institutions$source, institutions$type, useNA = "ifany"))
print(table(institutions$master_source))
cat("xz size KB:", file.size(file.path(cache, "institutions.rds")) / 1024, "\n")
