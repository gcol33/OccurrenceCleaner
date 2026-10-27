# Build the biodiversity-institution gazetteer from GBIF's Global Registry of
# Scientific Collections (GRSciColl), Wikidata, Wikipedia's list of natural
# history museums, GeoNames, BGCI GardenSearch, Index Herbariorum and the GBIF
# registry of publishing organisations, and place every further institution of
# CoordinateCleaner's table from Wikidata, OpenStreetMap or GeoNames.
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

source("data-raw/utils.R")
cache <-"data-raw/cache"
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
institutions$extension <- FALSE
n_grscicoll <- nrow(institutions)

# Wikidata (CC0): botanical gardens (Q167346, arboreta are a subclass), natural
# history museums (Q1970365), zoos (Q43501), herbaria (Q181916) and public
# aquaria (Q2281788), every item that is an instance of the class or of a
# subclass and has a coordinate location (P625) on Earth. These cover the
# botanic gardens (BGCI), museums (Wikipedia) and zoos that CoordinateCleaner's
# table holds beside GRBio and Index Herbariorum, typed with the GRSciColl
# institution types. One query per class keeps
# each under the query service time limit. Museums of any museum class whose
# main subject (P921) or field of work (P101) is a natural-history subject are
# added as museums.
#
# CoordinateCleaner's Wikipedia rows are the museums of the English Wikipedia
# "List of natural history museums"; the lists of the other language editions
# linked from it are read the same way. Each entry reads "name, place, ..."
# under country headings, or is a table row "name | country, place". An entry
# whose name links an article is placed at the Wikidata coordinates of that
# article's item; an entry without one, at the coordinates of the one museum,
# zoo, garden or herbarium item of the same country whose label or alias is
# the entry's name. Otherwise it is placed at the first place it links that
# has Wikidata coordinates and is not a country or first-level unit (by the
# place's GeoNames id), or at the GeoNames populated place of that name in the
# country. A first-level unit is replaced by its seat when the seat carries
# the same name, and an entry naming no place by a populated place named at
# the start or end of the museum's name. The country of an entry is that of
# its innermost heading (or table flag) that names a country, else that of the
# museum or place it links.
#
# `extension` is FALSE for points from the sources CoordinateCleaner's table
# draws on (GRSciColl, which absorbed GRBio and mirrors Index Herbariorum; the
# English list; BGCI; GeoNames; Index Herbariorum; the GBIF registry; the
# institutions of CoordinateCleaner's own list) and TRUE for the points only
# this gazetteer holds.
wd_retrieved <- "2026-10-10"
wp_retrieved <- "2026-10-11"
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
wd_subjects <- c("Q484591", "Q7991", "Q420", "Q431", "Q441", "Q1069", "Q7205", "Q83353", "Q40614", "Q430",
                 "Q7860", "Q44703", "Q39286", "Q7150", "Q7946", "Q243237", "Q1063", "Q3361737", "Q47041",
                 "Q60186", "Q2982911", "Q2114846", "Q7175", "Q853800", "Q9054789", "Q213096", "Q1390",
                 "Q11946202", "Q5113", "Q729", "Q841408", "Q641498")
f <- file.path(cache, "wikidata_museum_subjects.csv")
x <- wd_fetch(paste0("SELECT DISTINCT ?item ?label ?coord ?iso2 ?cls WHERE { hint:Query hint:optimizer \"None\" . ",
                     "VALUES ?cls { ",
                     paste0("wd:", wd_subjects, collapse = " "), " } { ?item wdt:P921 ?cls } UNION ",
                     "{ ?item wdt:P101 ?cls } ?item wdt:P31/wdt:P279* wd:Q33506 . ?item wdt:P625 ?coord . ",
                     "OPTIONAL { ?item wdt:P17 ?c . ?c wdt:P297 ?iso2 . } ",
                     "OPTIONAL { ?item rdfs:label ?label . FILTER(lang(?label) = \"en\") } }"), f)
x$type <- "Museum"
wd <- rbind(wd, x)
wd_files <- c(wd_files, f)

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
  if (is.na(iso2)) return(NULL)
  j <- gn_index$row[match(paste(iso2, ascii_key(text)), gn_index$key)]
  if (is.na(j) || (seat && !gn_cities$V8[j] %in% c("PPLC", "PPLA"))) return(NULL)
  c(as.numeric(gn_cities$V6[j]), as.numeric(gn_cities$V5[j]))
}
country_iso2 <- c(setNames(gn_country$V1, gn_country$V5), setNames(gn_country$V1, gn_country$V2),
                  `Czech Republic` = "CZ", Macedonia = "MK", `The Netherlands` = "NL", Palestine = "PS",
                  `Canary Islands` = "ES")
name_key <- function(x) trimws(gsub("[\\p{P}\\p{Z}\\p{S}]+", " ", tolower(x), perl = TRUE))

wp_lists <- data.frame(
  lang = c("en", "de", "fr", "nl", "pt", "ar", "eo"),
  title = c("List of natural history museums", "Liste naturhistorischer Museen",
            "Liste de musées d'histoire naturelle", "Lijst van natuurmusea",
            "Lista de museus de história natural",
            paste("قائمة متاحف",
                  "التاريخ الطبيعي"),
            "Listo de naturhistoriaj muzeoj"),
  layout = c("lines", "lines", "table", "lines", "table", "lines", "lines"), stringsAsFactors = FALSE)
wp_end <- paste0("^(See also|References|Notes|External links|Further reading|Siehe auch|Weblinks|",
                 "Einzelnachweise|Literatur|Voir aussi|Notes et références|Zie ook|Externe links|",
                 "Bronnen|Ver também|Referências|Ligações externas|Vidu ankaŭ|",
                 "Referencoj|Eksteraj ligiloj|انظر أيضا|",
                 "انظر أيضًا|مراجع|",
                 "وصلات خارجية)$")
wp_files <- character()
wp_pages <- list()
for (k in seq_len(nrow(wp_lists))) {
  f <- file.path(cache, sprintf("wikipedia_%s_museum_list.json", wp_lists$lang[k]))
  if (!file.exists(f))
    download.file(paste0("https://", wp_lists$lang[k], ".wikipedia.org/w/api.php?action=parse&format=json",
                         "&formatversion=2&prop=wikitext|revid&page=",
                         utils::URLencode(wp_lists$title[k], reserved = TRUE)),
                  f, quiet = TRUE, headers = c(`User-Agent` = ua))
  wp_files <- c(wp_files, f)
  wp_pages[[wp_lists$lang[k]]] <- jsonlite::fromJSON(f)$parse
}

# References and comments are blanked to their line breaks, so line numbers
# stay those of the page.
wp_unref <- function(w) {
  m <- gregexpr("(?s)<!--.*?-->|<ref(\\s[^>]*)?/>|<ref(\\s[^>]*)?>.*?</ref>", w, perl = TRUE)
  regmatches(w, m) <- lapply(regmatches(w, m), function(x) gsub("[^\n]", "", x))
  w
}
wp_clean <- function(s) {
  s <- gsub("\\{\\{lang\\|[^|{}]*\\|([^{}]*)\\}\\}", "\\1", s, perl = TRUE)
  s <- sub("<ref.*$", "", s, perl = TRUE)
  repeat { t <- gsub("\\{\\{[^{}]*\\}\\}", "", s, perl = TRUE); if (identical(t, s)) break; s <- t }
  gsub("'{2,}", "", gsub("<[^>]+>", "", s, perl = TRUE), perl = TRUE)
}
wp_markup <- function(s) regmatches(s, gregexpr("\\[\\[[^]]*\\]\\]", s, perl = TRUE))[[1]]
wp_links <- function(s) {
  if (!length(s)) return(character())
  sub("#.*$", "", sub("\\|.*$", "", gsub("^\\[\\[|\\]\\]$", "", wp_markup(s))))
}
wp_text <- function(s) {
  s <- gsub("\\[\\[[^]|]*\\|([^]]*)\\]\\]", "\\1", s, perl = TRUE)
  trimws(gsub("\\s+", " ", gsub("\\[\\[([^]]*)\\]\\]", "\\1", s, perl = TRUE)))
}
# Entries are split on commas (Latin or Arabic) outside links.
wp_split <- function(s) {
  m <- gregexpr("\\[\\[[^]]*\\]\\]", s, perl = TRUE)
  regmatches(s, m) <- lapply(regmatches(s, m), function(x) gsub("،", "\002", gsub(",", "\001", x, fixed = TRUE)))
  seg <- strsplit(s, "[,،]", perl = TRUE)[[1]]
  seg <- trimws(gsub("\002", "،", gsub("\001", ",", seg, fixed = TRUE), fixed = TRUE))
  seg[nzchar(seg)]
}
# The museum's article is the link that opens the entry, or a link in
# parentheses after an unlinked name; the other links of the name segment and
# the segments after it are the places, in reading order.
wp_entry <- function(lang, line, hints, flag, first, rest) {
  lead <- regmatches(first, regexpr("^\\[\\[[^]]*\\]\\]", first, perl = TRUE))
  paren <- wp_links(regmatches(first, regexpr("\\(\\[\\[[^]]*\\]\\]\\)", first, perl = TRUE)))
  article <- if (length(lead)) wp_links(lead) else if (length(paren)) paren[1] else NA_character_
  inner <- wp_markup(first)
  inner <- inner[!wp_links(paste(inner, collapse = "")) %in% article]
  list(lang = lang, line = line, hints = hints, flag = flag, article = article,
       name = if (length(lead)) wp_text(lead) else wp_text(gsub("\\([^()]*\\)", "", first)),
       places = c(inner, rest))
}
wp_heading <- function(ln) regmatches(ln, regexec("^(=+)\\s*(.*?)\\s*=+\\s*$", ln))[[1]]
wp_parse <- function(w, lang, layout) {
  lines <- strsplit(wp_unref(w), "\n", fixed = TRUE)[[1]]
  out <- list(); stack <- character(); skip <- NA; parent <- NULL; row <- NULL
  push <- function(r) {
    if (is.null(r) || length(r$cells) < 2) return(NULL)
    flag <- regmatches(r$cells[2], regexpr("(?<=\\{\\{)[^|{}]+", r$cells[2], perl = TRUE))
    wp_entry(lang, r$line, r$hints, if (length(flag)) trimws(flag) else NA_character_, wp_clean(r$cells[1]),
             wp_split(wp_clean(r$cells[2])))
  }
  for (i in seq_along(lines)) {
    ln <- lines[i]
    h <- wp_heading(ln)
    if (length(h)) {
      lvl <- nchar(h[2])
      txt <- wp_clean(h[3])
      if (grepl(wp_end, wp_text(txt))) skip <- min(skip, lvl, na.rm = TRUE) else if (!is.na(skip) && lvl <= skip) skip <- NA
      stack <- stack[seq_len(lvl - 1)]
      stack[lvl] <- txt
      next
    }
    if (!is.na(skip)) next
    hints <- stack[!is.na(stack)]
    if (layout == "table") {
      if (startsWith(ln, "{|")) { row <- NULL; next }
      if (startsWith(ln, "|-") || startsWith(ln, "|}")) {
        out[[length(out) + 1]] <- push(row)
        row <- if (startsWith(ln, "|-")) list(line = NA_integer_, hints = hints, cells = character())
        next
      }
      if (is.null(row) || !startsWith(ln, "|")) next
      if (is.na(row$line)) row$line <- i
      row$cells <- c(row$cells, sub("^\\|", "", strsplit(sub("^\\|", "", ln), "||", fixed = TRUE)[[1]]))
      next
    }
    if (!grepl("^\\*", ln)) next
    seg <- wp_split(wp_clean(sub("^\\*+\\s*", "", ln)))
    if (!length(seg)) next
    e <- wp_entry(lang, i, hints, NA_character_, seg[1], seg[-1])
    if (startsWith(ln, "**") && !length(e$places) && !is.null(parent))
      e$places <- c(if (!is.na(parent$article)) paste0("[[", parent$article, "]]"), parent$places)
    if (!startsWith(ln, "**")) parent <- e
    out[[length(out) + 1]] <- e
  }
  Filter(Negate(is.null), out)
}
wpl <- unlist(lapply(seq_len(nrow(wp_lists)), function(k)
  wp_parse(wp_pages[[k]]$wikitext, wp_lists$lang[k], wp_lists$layout[k])), recursive = FALSE)

# Table flags are templates ({{Afrique du Sud}}, {{ALE}}); their expansion
# links the country.
wp_flag_files <- character()
for (lang in unique(wp_lists$lang[wp_lists$layout == "table"])) {
  f <- file.path(cache, sprintf("wikipedia_%s_museum_list_flags.csv", lang))
  have <- if (file.exists(f)) read.csv(f, stringsAsFactors = FALSE, na.strings = "", encoding = "UTF-8", colClasses = "character")
          else data.frame(flag = character(), text = character())
  fl <- unique(na.omit(unlist(lapply(Filter(function(e) e$lang == lang, wpl), function(e) e$flag))))
  for (n in setdiff(fl, have$flag)) {
    h <- curl::new_handle(useragent = ua, postfields = paste0(
      "action=expandtemplates&format=json&formatversion=2&prop=wikitext&text=",
      utils::URLencode(paste0("{{", n, "}}"), reserved = TRUE)))
    r <- curl::curl_fetch_memory(paste0("https://", lang, ".wikipedia.org/w/api.php"), handle = h)
    have <- rbind(have, data.frame(flag = n, text = jsonlite::fromJSON(rawToChar(r$content))$expandtemplates$wikitext))
  }
  write.csv(have, f, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  wp_flag_files <- c(wp_flag_files, f)
  for (k in seq_along(wpl)) if (wpl[[k]]$lang == lang && !is.na(wpl[[k]]$flag))
    wpl[[k]]$flag <- wp_clean(have$text[match(wpl[[k]]$flag, have$flag)])
}

# Titles to Wikidata items, per list language (redirects followed; ":xx:"
# links are looked up on that language's Wikipedia).
wp_hint_titles <- function(h) if (grepl("[[", h, fixed = TRUE)) wp_links(h) else wp_text(h)
wp_title_files <- character()
wp_item <- list()
for (lang in wp_lists$lang) {
  e <- Filter(function(e) e$lang == lang, wpl)
  titles <- unique(c(vapply(e, function(e) e$article, character(1)),
                     unlist(lapply(e, function(e) unlist(lapply(e$places, wp_links)))),
                     unlist(lapply(e, function(e) unlist(lapply(c(e$hints, e$flag[!is.na(e$flag)]), wp_hint_titles))))))
  titles <- titles[!is.na(titles) & nzchar(titles)]
  f <- file.path(cache, sprintf("wikipedia_%s_museum_list_titles.csv", lang))
  have <- if (file.exists(f)) read.csv(f, stringsAsFactors = FALSE, na.strings = "", encoding = "UTF-8", colClasses = "character")
          else data.frame(title = character(), item = character())
  need <- setdiff(titles, have$title)
  if (length(need)) {
    ilang <- ifelse(grepl("^:[a-z-]+:", need), sub("^:([a-z-]+):.*$", "\\1", need), lang)
    bare <- sub("^:[a-z-]+:", "", need)
    for (lg in unique(ilang)) {
      bb <- unique(bare[ilang == lg])
      for (b in split(bb, ceiling(seq_along(bb) / 50))) {
        h <- curl::new_handle(useragent = ua, postfields = paste0(
          "action=query&format=json&redirects=1&prop=pageprops&ppprop=wikibase_item&titles=",
          utils::URLencode(paste(b, collapse = "|"), reserved = TRUE)))
        r <- curl::curl_fetch_memory(paste0("https://", lg, ".wikipedia.org/w/api.php"), handle = h)
        q <- jsonlite::fromJSON(rawToChar(r$content), simplifyVector = FALSE)$query
        to <- setNames(b, b)
        for (n in q$normalized) to[to == n$from] <- n$to
        for (r in q$redirects) to[to == r$from] <- r$to
        pg <- setNames(vapply(q$pages, function(p) if (is.null(p$pageprops$wikibase_item)) NA_character_
                              else p$pageprops$wikibase_item, character(1)),
                       vapply(q$pages, function(p) p$title, character(1)))
        have <- rbind(have, data.frame(title = if (lg == lang) b else paste0(":", lg, ":", b), item = unname(pg[to])))
      }
    }
    write.csv(have, f, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  }
  wp_title_files <- c(wp_title_files, f)
  wp_item[[lang]] <- setNames(have$item, have$title)
}
item_of <- function(lang, titles) unname(wp_item[[lang]][titles])

# Coordinates, GeoNames ids, own ISO code (P297), country ISO codes (P17) and
# classes (P31) of every linked item.
it_file <- file.path(cache, "wikidata_list_items.csv")
it <- NULL
it_fetch <- function(qs) {
  if (is.null(it) && file.exists(it_file))
    it <<- read.csv(it_file, stringsAsFactors = FALSE, na.strings = "", encoding = "UTF-8", colClasses = "character")
  need <- setdiff(sort(unique(qs[!is.na(qs)])), it$item)
  for (b in split(need, ceiling(seq_along(need) / 100))) {
    it <<- rbind(it, wd_fetch(paste0(
      "SELECT ?item (GROUP_CONCAT(DISTINCT ?c; separator=\"|\") AS ?coord) (GROUP_CONCAT(DISTINCT ?g) AS ?gn) ",
      "(GROUP_CONCAT(DISTINCT ?o) AS ?own) (GROUP_CONCAT(DISTINCT ?i) AS ?ciso) ",
      "(GROUP_CONCAT(DISTINCT STRAFTER(STR(?t), \"entity/\")) AS ?cls) WHERE { VALUES ?item { ",
      paste0("wd:", b, collapse = " "), " } OPTIONAL { ?item p:P625/ps:P625 ?c } OPTIONAL { ?item wdt:P1566 ?g } ",
      "OPTIONAL { ?item wdt:P297 ?o } OPTIONAL { ?item wdt:P17/wdt:P297 ?i } OPTIONAL { ?item wdt:P31 ?t } } ",
      "GROUP BY ?item"), tempfile(fileext = ".csv")))
  }
  if (length(need)) write.csv(it, it_file, row.names = FALSE, na = "", fileEncoding = "UTF-8")
}
it_fetch(unlist(wp_item))
it_words <- function(q, col) {
  v <- it[[col]][match(q, it$item)]
  if (is.na(v)) character() else strsplit(v, if (col == "coord") "|" else " ", fixed = TRUE)[[1]]
}
wp_point <- function(q) {
  if (is.na(q)) return(NULL)
  p <- it_words(q, "coord")
  p <- p[startsWith(p, "Point(")]
  if (!length(p)) NULL else as.numeric(strsplit(sub("^Point\\(([^ ]+) ([^)]+)\\)$", "\\1 \\2", p[1]), " ")[[1]])
}
wp_coarse <- function(q) {
  g <- it_words(q, "gn")
  any(g %in% c(gn_country$V17, gn_admin1$V4)) && !any(g %in% gn_cities$V1)
}
wp_country <- function(qs) unique(unlist(lapply(qs[!is.na(qs)], function(q) c(it_words(q, "own"), it_words(q, "ciso")))))

# Country of an entry: of the table flag and the headings that name a country
# (by GeoNames name or ISO3 code, or a linked or titled item with its own ISO
# code), the first, innermost first, that is a country of the museum or of a
# place the entry links, else the innermost; failing those, the same among
# headings that lie in exactly one country; else the one country of the
# museum or of the first place that has one.
wp_hint_iso <- function(lang, h, own) {
  t <- wp_hint_titles(h)
  iso <- unique(na.omit(country_iso2[t]))
  if (length(iso) == 1) return(iso)
  q <- item_of(lang, t)
  iso <- unique(unlist(lapply(q[!is.na(q)], it_words, col = if (own) "own" else "ciso")))
  if (length(iso) == 1) iso else NA_character_
}
wp_entry_iso <- function(e) {
  linked <- c(item_of(e$lang, e$article), unlist(lapply(e$places, function(p) item_of(e$lang, wp_links(p)))))
  linked_iso <- wp_country(linked)
  hs <- rev(e$hints)
  for (own in c(TRUE, FALSE)) {
    iso <- vapply(c(if (own) e$flag[!is.na(e$flag)], hs), wp_hint_iso, character(1), lang = e$lang, own = own)
    iso <- iso[!is.na(iso)]
    if (any(iso %in% linked_iso)) return(iso[iso %in% linked_iso][1])
    if (length(iso)) return(unname(iso[1]))
  }
  for (q in linked) {
    iso <- wp_country(q)
    if (length(iso) == 1) return(iso)
  }
  NA_character_
}
for (k in seq_along(wpl)) wpl[[k]]$iso2 <- wp_entry_iso(wpl[[k]])

# Entries without an article item: the museum, zoo, garden or herbarium item
# of the entry's country whose label or alias in the list language is the
# entry's name, when there is exactly one.
inst_file <- file.path(cache, "wikidata_institution_classes.csv")
inst_cls <- wd_fetch(paste0("SELECT DISTINCT ?c WHERE { VALUES ?r { wd:Q33506 wd:Q167346 wd:Q43501 wd:Q181916 ",
                            "wd:Q2281788 } ?c wdt:P279* ?r }"), inst_file)$c
wp_search_files <- character()
wp_search <- list()
for (lang in wp_lists$lang) {
  nm <- unique(unlist(lapply(Filter(function(e) e$lang == lang && is.na(item_of(lang, e$article)) && !is.na(e$iso2),
                                    wpl), function(e) e$name)))
  f <- file.path(cache, sprintf("wikidata_search_%s.csv", lang))
  have <- if (file.exists(f)) read.csv(f, stringsAsFactors = FALSE, na.strings = "", encoding = "UTF-8", colClasses = "character")
          else data.frame(name = character(), item = character())
  todo <- setdiff(nm[!is.na(nm) & nzchar(nm)], have$name)
  for (n in todo) {
    tf <- tempfile()
    download.file(paste0("https://www.wikidata.org/w/api.php?action=wbsearchentities&format=json&type=item",
                         "&limit=20&language=", lang, "&search=", utils::URLencode(n, reserved = TRUE)),
                  tf, quiet = TRUE, headers = c(`User-Agent` = ua))
    s <- jsonlite::fromJSON(tf, simplifyVector = FALSE)$search
    hit <- vapply(s, function(h) if (name_key(h$match$text) == name_key(n)) h$id else NA_character_, character(1))
    hit <- unique(hit[!is.na(hit)])
    have <- rbind(have, data.frame(name = n, item = if (length(hit)) hit else NA_character_))
  }
  if (length(todo) || !file.exists(f)) write.csv(have, f, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  wp_search_files <- c(wp_search_files, f)
  wp_search[[lang]] <- have
}
it_fetch(unlist(lapply(wp_search, function(s) s$item)))
wp_by_name <- function(e) {
  s <- wp_search[[e$lang]]
  q <- s$item[s$name == e$name & !is.na(s$item)]
  q <- q[vapply(q, function(q) !is.null(wp_point(q)) && any(it_words(q, "cls") %in% inst_cls) &&
                  e$iso2 %in% wp_country(q), logical(1))]
  if (length(q) == 1) q else NA_character_
}

# The town an entry names: a linked place in the entry's country, or a
# GeoNames populated place.
wp_town <- function(e) {
  for (p in e$places) {
    pq <- item_of(e$lang, wp_links(p))
    if (length(pq) && all(!is.na(pq) & vapply(pq, function(x) !is.na(x) && wp_coarse(x), logical(1)))) {
      xy <- populated_place(wp_text(p), e$iso2, seat = TRUE)
      if (!is.null(xy)) return(list(xy = xy, how = "GeoNames populated place", place = wp_text(p)))
      next
    }
    for (pp in pq[!is.na(pq)]) {
      if (wp_coarse(pp)) next
      cty <- wp_country(pp)
      if (!is.na(e$iso2) && length(cty) && !e$iso2 %in% cty) next
      xy <- wp_point(pp)
      if (!is.null(xy)) return(list(xy = xy, how = "Wikidata linked place", place = wp_text(p)))
    }
    txt <- sub("^(located )?(at|in) (the )?", "", wp_text(gsub("\\([^()]*\\)", "", p)))
    xy <- populated_place(txt, e$iso2)
    if (!is.null(xy)) return(list(xy = xy, how = "GeoNames populated place", place = txt))
  }
  if (length(e$places)) return(NULL)
  w <- strsplit(e$name, "[ ,]+")[[1]]
  for (k in 3:1) for (g in unique(list(w[seq_len(min(k, length(w)))], w[max(1, length(w) - k + 1):length(w)]))) {
    if (grepl("^[[:upper:]]", g[1]) && grepl("^[[:upper:]]", g[length(g)])) {
      xy <- populated_place(paste(g, collapse = " "), e$iso2)
      if (!is.null(xy)) return(list(xy = xy, how = "GeoNames populated place", place = paste(g, collapse = " ")))
    }
  }
  NULL
}
km <- function(a, b) 6371.0088 * 2 * asin(sqrt(sin((b[2] - a[2]) * pi / 360)^2 +
  cos(a[2] * pi / 180) * cos(b[2] * pi / 180) * sin((b[1] - a[1]) * pi / 360)^2))

# A museum matched by name is taken when the entry names no town, or names
# one within 25 km of it; branches of a museum are listed under the branch's
# town and keep that town.
wp_located <- do.call(rbind, lapply(wpl, function(e) {
  q <- if (is.na(e$article)) NA_character_ else item_of(e$lang, e$article)
  xy <- wp_point(q)
  how <- if (is.null(xy)) NA_character_ else "museum"
  place <- NA_character_
  if (is.null(xy)) {
    town <- wp_town(e)
    qn <- if (is.na(q) && !is.na(e$iso2)) wp_by_name(e) else NA_character_
    xn <- wp_point(qn)
    if (!is.null(xn) && (is.null(town) || km(xn, town$xy) <= 25)) {
      q <- qn; xy <- xn; how <- "museum by name"
    } else if (!is.null(town)) {
      xy <- town$xy; how <- town$how; place <- town$place
    }
  }
  data.frame(lang = e$lang, line = e$line, name = e$name, iso2 = e$iso2, item = q, how = how, place = place,
             lon = if (is.null(xy)) NA_real_ else xy[1], lat = if (is.null(xy)) NA_real_ else xy[2])
}))
wp_own <- wp_located$how %in% c("museum", "museum by name")
wp_cc_items <- unique(wp_located$item[wp_own & wp_located$lang == "en"])
wp_museum <- wp_located[wp_own & !wp_located$item %in% wd$item, ]
wp_museum <- wp_museum[!duplicated(wp_museum$item), ]
wd <- rbind(wd, data.frame(item = wp_museum$item, label = wp_museum$name,
                           coord = sprintf("Point(%s %s)", wp_museum$lon, wp_museum$lat), iso2 = wp_museum$iso2,
                           cls = NA_character_, type = "Museum"))
wp_placed <- wp_located[!is.na(wp_located$how) & !wp_own, ]
wp_zero <- wp_placed$lon == 0 | wp_placed$lat == 0 | sqrt(wp_placed$lon^2 + wp_placed$lat^2) <= 0.5
wp_placed <- wp_placed[!wp_zero, ]
wp_placed <- wp_placed[is.na(wp_placed$item) | !duplicated(wp_placed$item), ]
wp_placed <- wp_placed[!duplicated(wp_placed[, c("name", "lon", "lat")]), ]
wp_revid <- vapply(wp_pages, function(p) as.character(p$revid), character(1))
wikipedia <- data.frame(key = paste0("wikipedia:", wp_placed$lang, ":", wp_revid[wp_placed$lang], ":", wp_placed$line),
                        code = NA_character_, name = wp_placed$name, country = wp_placed$iso2, city = wp_placed$place,
                        type = "Museum", active = NA, master_source = wp_placed$how, lon = wp_placed$lon,
                        lat = wp_placed$lat, source = "Wikipedia", extension = wp_placed$lang != "en",
                        stringsAsFactors = FALSE)
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
                       source = "Wikidata", extension = !wd$key %in% wp_cc_items, stringsAsFactors = FALSE)

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
                       lon = as.numeric(gn$V6), lat = as.numeric(gn$V5), source = "GeoNames", extension = FALSE,
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
                   extension = FALSE, stringsAsFactors = FALSE)

zero_xy <- function(lon, lat) lon == 0 | lat == 0 | sqrt(lon^2 + lat^2) <= 0.5
valid_xy <- function(lon, lat) is.finite(lon) & is.finite(lat) & abs(lon) <= 180 & abs(lat) <= 90

# Index Herbariorum (New York Botanical Garden): every herbarium of the IH API
# with a location, except those GRSciColl already places under the same code.
ih_retrieved <- "2026-10-13"
ih_url <- "https://sweetgum.nybg.org/science/api/v1/institutions"
ih_file <- file.path(cache, "ih_institutions.json")
if (!file.exists(ih_file)) download.file(ih_url, ih_file, mode = "wb", quiet = TRUE, headers = c(`User-Agent` = ua))
ih <- jsonlite::fromJSON(ih_file)$data
ih_country_iso2 <- c(country_iso2, `U.S.A.` = "US", `U.K.` = "GB", `Türkiye` = "TR",
                     `Republic of South Africa` = "ZA", `Republic of Korea` = "KR", Netherlands = "NL",
                     `Guam, U.S.A.` = "GU", `Republic of Guinea` = "GN", `Republic of Palau` = "PW",
                     `Réunion` = "RE", `Brunei Darussalam` = "BN", Alderney = "GG", `Curaçao` = "CW",
                     `México` = "MX")
ih$iso2 <- unname(ih_country_iso2[gsub("\\s+", " ", trimws(ih$address$physicalCountry))])
ih_lon <- ih$location$lon
ih_lat <- ih$location$lat
ih_ok <- valid_xy(ih_lon, ih_lat) & !zero_xy(ih_lon, ih_lat)
ih_new <- ih_ok & !ih$code %in% institutions$code[institutions$master_source %in% "IH"]
ih_blank <- function(x) ifelse(is.na(x) | !nzchar(trimws(x)), NA_character_, trimws(x))
index_herbariorum <- data.frame(key = paste0("ih:", ih$irn[ih_new]), code = ih$code[ih_new],
                                name = ih$organization[ih_new], country = ih$iso2[ih_new],
                                city = ih_blank(ih$address$physicalCity[ih_new]), type = "Herbarium",
                                active = ih$currentStatus[ih_new] == "Active", master_source = NA_character_,
                                lon = ih_lon[ih_new], lat = ih_lat[ih_new], source = "Index Herbariorum",
                                extension = FALSE, stringsAsFactors = FALSE)

# GBIF registry: every publishing organisation with coordinates.
gbif_org_retrieved <- "2026-10-13"
gbif_org_url <- "https://api.gbif.org/v1/organization"
gbif_org_file <- file.path(cache, "gbif_organizations.csv")
if (!file.exists(gbif_org_file)) {
  out <- list(); off <- 0
  repeat {
    x <- jsonlite::fromJSON(sprintf("%s?limit=1000&offset=%d", gbif_org_url, off))
    r <- x$results
    col <- function(v) if (is.null(r[[v]])) NA else r[[v]]
    out[[length(out) + 1]] <- data.frame(key = r$key, title = r$title, country = col("country"), city = col("city"),
                                         lat = col("latitude"), lon = col("longitude"), stringsAsFactors = FALSE)
    off <- off + 1000
    if (isTRUE(x$endOfRecords) || off >= x$count) break
  }
  write.csv(do.call(rbind, out), gbif_org_file, row.names = FALSE, na = "", fileEncoding = "UTF-8")
}
org <- read.csv(gbif_org_file, stringsAsFactors = FALSE, na.strings = "", encoding = "UTF-8")
org_ok <- valid_xy(org$lon, org$lat) & !zero_xy(org$lon, org$lat)
gbif_registry <- data.frame(key = paste0("gbif-organization:", org$key[org_ok]), code = NA_character_,
                            name = org$title[org_ok], country = org$country[org_ok], city = org$city[org_ok],
                            type = NA_character_, active = NA, master_source = NA_character_, lon = org$lon[org_ok],
                            lat = org$lat[org_ok], source = "GBIF registry", extension = FALSE,
                            stringsAsFactors = FALSE)

institutions <- rbind(institutions, wikidata, wikipedia, geonames, bgci, index_herbariorum, gbif_registry)

# CoordinateCleaner's institution list: every institution of its table with
# coordinates that no row above holds under its name (or, for herbaria, under
# the full Index Herbariorum name, and for GRSciColl institutions, under an
# alternative or collection name) is placed from Wikidata, OpenStreetMap or
# GeoNames by its name, city and country. Where a source returns several
# candidates, the one nearest to CoordinateCleaner's point is taken; the
# coordinates come from the source, never from CoordinateCleaner.
cc_env <- new.env()
utils::data("institutions", package = "CoordinateCleaner", envir = cc_env)
cc_version <- as.character(utils::packageVersion("CoordinateCleaner"))
cc <- as.data.frame(cc_env$institutions)
cc$row <- seq_len(nrow(cc))
cc <- cc[is.finite(cc$decimalLongitude) & is.finite(cc$decimalLatitude), ]
cc$iso2 <- gn_country$V1[match(cc$country, gn_country$V2)]
cc_type <- c(Botanic_garden = "BotanicalGarden", Herbarium = "Herbarium", Museum = "Museum",
             Research_centre = "OtherTypeResearchInstitutionBiorepository", University = "UniversityCollege",
             Zoo = "ZooAquarium")
# About 90 names carry a substitute byte where an accented letter was; words
# holding it are left out of the searches.
cc$query <- trimws(gsub("[[:space:][:cntrl:]]+", " ", gsub("\\S*\032\\S*", "", cc$name, useBytes = TRUE)))
cc$first <- trimws(sub(",.*$", "", cc$query))

paste_some <- function(...) {
  a <- list(...)
  ok <- Reduce(`&`, lapply(a, function(v) !is.na(v) & nzchar(v)))
  ifelse(ok, do.call(paste, c(a, sep = ", ")), NA_character_)
}
g_add <- strsplit(ifelse(is.na(d$additional_names[keep]), "", d$additional_names[keep]), "|", fixed = TRUE)
co_file <- file.path(cache, "grscicoll_collections.tsv")
co_url <- "https://api.gbif.org/v1/grscicoll/collection/export?format=TSV"
if (!file.exists(co_file)) download.file(co_url, co_file, mode = "wb", quiet = TRUE)
co <- read.delim(co_file, quote = "", comment.char = "", na.strings = "", stringsAsFactors = FALSE,
                 encoding = "UTF-8", check.names = FALSE)
co <- co[co$institution_key %in% institutions$key, ]
ih_in <- ih_ok & (ih$code %in% institutions$code | paste0("ih:", ih$irn) %in% institutions$key)
ih_o <- ih_blank(ih$organization); ih_dv <- ih_blank(ih$division); ih_dp <- ih_blank(ih$department)
ih_hn <- ih_blank(ih$herbariumName)
ih_key <- ifelse(paste0("ih:", ih$irn) %in% institutions$key, paste0("ih:", ih$irn),
                 institutions$key[match(ih$code, institutions$code)])[ih_in]
known <- rbind(
  data.frame(iso2 = institutions$country, name = institutions$name, key = institutions$key),
  data.frame(iso2 = rep(d$country[keep], lengths(g_add)), name = unlist(g_add), key = rep(d$key[keep], lengths(g_add))),
  data.frame(iso2 = co$country, name = c(co$name, paste_some(co$institution_name, co$name)), key = co$institution_key),
  data.frame(iso2 = ih$iso2[ih_in], name = c(paste_some(ih_o, ih_dv)[ih_in], paste_some(ih_o, ih_dp)[ih_in],
                                             paste_some(ih_o, ih_dv, ih_dp)[ih_in], paste_some(ih_o, ih_hn)[ih_in],
                                             ih_hn[ih_in], paste_some(ih_o, ih_dp, ih_dv)[ih_in]), key = ih_key))
known <- known[!is.na(known$name) & nzchar(known$name), ]
cc_open <- cc[!paste(cc$iso2, ascii_key(cc$name)) %in% paste(known$iso2, ascii_key(known$name)), ]

nearest <- function(lon, lat, x, y) which.min(6371.0088 * 2 * asin(sqrt(sin((y - lat) * pi / 360)^2 +
  cos(lat * pi / 180) * cos(y * pi / 180) * sin((x - lon) * pi / 360)^2)))

# Wikidata: items whose label or alias in English is the full name or its
# part before the first comma, located in the country.
cc_search_file <- file.path(cache, "wikidata_search_cc.csv")
cc_search <- if (file.exists(cc_search_file))
  read.csv(cc_search_file, stringsAsFactors = FALSE, na.strings = "", encoding = "UTF-8", colClasses = "character") else
  data.frame(name = character(), item = character())
todo <- setdiff(unique(c(cc_open$query, cc_open$first)), c(cc_search$name, ""))
for (n in todo) {
  tf <- tempfile()
  download.file(paste0("https://www.wikidata.org/w/api.php?action=wbsearchentities&format=json&type=item",
                       "&limit=10&language=en&search=", utils::URLencode(n, reserved = TRUE)),
                tf, quiet = TRUE, headers = c(`User-Agent` = ua))
  s <- jsonlite::fromJSON(tf, simplifyVector = FALSE)$search
  hit <- unique(unlist(lapply(s, function(h) if (ascii_key(h$match$text) == ascii_key(n)) h$id)))
  cc_search <- rbind(cc_search, data.frame(name = n, item = if (length(hit)) hit else NA_character_))
}
if (length(todo) || !file.exists(cc_search_file))
  write.csv(cc_search, cc_search_file, row.names = FALSE, na = "", fileEncoding = "UTF-8")
stopifnot(all(is.na(cc_search$item) | grepl("^Q[0-9]+$", cc_search$item)))
it_fetch(cc_search$item)
cc_wikidata <- function(r) {
  for (n in unique(c(r$query, r$first))) {
    q <- cc_search$item[cc_search$name == n & !is.na(cc_search$item)]
    q <- q[vapply(q, function(z) !is.null(wp_point(z)) && (is.na(r$iso2) || r$iso2 %in% wp_country(z)), logical(1))]
    if (!length(q)) next
    xy <- t(vapply(q, wp_point, numeric(2)))
    k <- nearest(r$decimalLongitude, r$decimalLatitude, xy[, 1], xy[, 2])
    return(list(key = q[k], lon = xy[k, 1], lat = xy[k, 2], how = "Wikidata"))
  }
  NULL
}

# OpenStreetMap through Nominatim (single thread, at most one request per
# second, every answer cached): the name with the city, the name alone, and
# the part before the first comma with the city.
nominatim_file <- file.path(cache, "nominatim_cc.csv")
nominatim_cache <- if (file.exists(nominatim_file))
  read.csv(nominatim_file, stringsAsFactors = FALSE, na.strings = "", encoding = "UTF-8", colClasses = "character") else
  data.frame(query = character(), json = character())
nominatim <- function(q, iso2) {
  id <- paste(iso2, q, sep = "|")
  j <- match(id, nominatim_cache$query)
  if (is.na(j)) {
    Sys.sleep(1.1)
    u <- paste0("https://nominatim.openstreetmap.org/search?format=jsonv2&limit=5&q=", utils::URLencode(q, reserved = TRUE),
                if (!is.na(iso2)) paste0("&countrycodes=", tolower(iso2)))
    r <- curl::curl_fetch_memory(u, handle = curl::new_handle(useragent = ua))
    stopifnot(r$status_code == 200)
    nominatim_cache <<- rbind(nominatim_cache, data.frame(query = id, json = rawToChar(r$content)))
    if (nrow(nominatim_cache) %% 100 == 0) write.csv(nominatim_cache, nominatim_file, row.names = FALSE, na = "", fileEncoding = "UTF-8")
    j <- nrow(nominatim_cache)
  }
  jsonlite::fromJSON(nominatim_cache$json[j])
}
# Nominatim also returns loose matches; a result is taken when its name holds
# at least half the words of the institution's name (before the first comma),
# or when it lies within 25 km of CoordinateCleaner's point.
name_stop <- c("the", "of", "and", "de", "la", "del", "des", "du", "di", "der", "und", "e", "y", "et", "for", "at",
               "in", "d", "l", "")
name_words <- function(s) setdiff(strsplit(ascii_key(s), " ")[[1]], name_stop)
km_to <- function(lon, lat, x, y) 6371.0088 * 2 * asin(sqrt(sin((y - lat) * pi / 360)^2 +
  cos(lat * pi / 180) * cos(y * pi / 180) * sin((x - lon) * pi / 360)^2))
cc_osm <- function(r) {
  city <- if (is.na(r$city) || grepl("\032", r$city, useBytes = TRUE)) NA_character_ else r$city
  qs <- unique(na.omit(c(paste_some(r$query, city), r$query, paste_some(r$first, city))))
  want <- name_words(r$first)
  for (q in qs[nzchar(qs)]) {
    x <- nominatim(q, r$iso2)
    if (!length(x) || !nrow(x)) next
    lon <- as.numeric(x$lon); lat <- as.numeric(x$lat)
    words <- vapply(ifelse(is.na(x$name), "", x$name), function(s) mean(want %in% name_words(s)), numeric(1))
    ok <- (length(want) > 0 & words >= 0.5) | km_to(r$decimalLongitude, r$decimalLatitude, lon, lat) <= 25
    if (!any(ok)) next
    x <- x[ok, , drop = FALSE]; lon <- lon[ok]; lat <- lat[ok]
    k <- nearest(r$decimalLongitude, r$decimalLatitude, lon, lat)
    return(list(key = paste0("osm:", x$osm_type[k], "/", x$osm_id[k]), lon = lon[k], lat = lat[k], how = "OpenStreetMap"))
  }
  NULL
}
gn_place <- function(j, how) list(key = paste0("geonames:", gn_cities$V1[j]), lon = as.numeric(gn_cities$V6[j]),
                                  lat = as.numeric(gn_cities$V5[j]), how = how)
# The town of the institution: the city CoordinateCleaner lists, else the
# city GRSciColl lists for an institution of that name (with or without
# coordinates there).
g_city <- setNames(d$city, paste(d$country, ascii_key(d$name)))
g_city <- g_city[!is.na(g_city) & nzchar(g_city) & !duplicated(names(g_city))]
cc_town <- function(r) {
  for (city in c(r$city, unname(g_city[paste(r$iso2, ascii_key(r$name))]))) {
    if (is.na(city) || grepl("\032", city, useBytes = TRUE)) next
    j <- gn_index$row[match(paste(r$iso2, ascii_key(city)), gn_index$key)]
    if (!is.na(j)) return(gn_place(j, "GeoNames populated place"))
  }
  NULL
}
# An institution already held by a point within 25 km whose name holds at
# least 60 percent of its words gets no further point.
inst_words <- lapply(ifelse(is.na(institutions$name), "", institutions$name), name_words)
cc_held_near <- function(r) {
  near <- which(km_to(r$decimalLongitude, r$decimalLatitude, institutions$lon, institutions$lat) <= 25)
  want <- name_words(r$query)
  length(want) > 0 && length(near) > 0 &&
    max(vapply(near, function(j) mean(want %in% inst_words[[j]]), numeric(1))) >= 0.6
}
# A populated place named in the institution's name (up to three capitalised
# words), the one nearest CoordinateCleaner's point.
cc_name_town <- function(r) {
  w <- strsplit(r$first, "[ ,]+")[[1]]
  hits <- integer()
  for (k in 3:1) for (s in seq_len(max(0, length(w) - k + 1))) {
    g <- w[s:(s + k - 1)]
    if (!all(grepl("^[[:upper:]]", g))) next
    j <- gn_index$row[match(paste(r$iso2, ascii_key(paste(g, collapse = " "))), gn_index$key)]
    if (!is.na(j)) hits <- c(hits, j)
  }
  if (!length(hits)) return(NULL)
  j <- hits[nearest(r$decimalLongitude, r$decimalLatitude, as.numeric(gn_cities$V6[hits]), as.numeric(gn_cities$V5[hits]))]
  gn_place(j, "GeoNames populated place named in the institution's name")
}
# Last resort: the populated place of the country nearest CoordinateCleaner's
# point.
gn_by_country <- split(seq_len(nrow(gn_cities)), gn_cities$V9)
cc_nearest_town <- function(r) {
  cand <- if (is.na(r$iso2)) seq_len(nrow(gn_cities)) else gn_by_country[[r$iso2]]
  if (!length(cand)) return(NULL)
  j <- cand[nearest(r$decimalLongitude, r$decimalLatitude, as.numeric(gn_cities$V6[cand]), as.numeric(gn_cities$V5[cand]))]
  gn_place(j, "GeoNames populated place nearest CoordinateCleaner's point")
}
cc_held <- rep(FALSE, nrow(cc_open))
cc_placed <- lapply(seq_len(nrow(cc_open)), function(i) {
  r <- cc_open[i, ]
  p <- cc_wikidata(r)
  if (is.null(p)) p <- cc_osm(r)
  if (is.null(p)) p <- cc_town(r)
  if (is.null(p) && cc_held_near(r)) { cc_held[i] <<- TRUE; return(NULL) }
  if (is.null(p)) p <- cc_name_town(r)
  if (is.null(p)) p <- cc_nearest_town(r)
  p
})
write.csv(nominatim_cache, nominatim_file, row.names = FALSE, na = "", fileEncoding = "UTF-8")
cc_ok <- !vapply(cc_placed, is.null, logical(1))
n_held_near <- sum(cc_held)
cc_unplaced <- cc_open[!cc_ok & !cc_held, ]
cc_open <- cc_open[cc_ok, ]
cc_placed <- cc_placed[cc_ok]
pick <- function(f) vapply(cc_placed, function(p) p[[f]], if (f %in% c("lon", "lat")) numeric(1) else character(1))
coordinatecleaner <- data.frame(key = pick("key"), code = NA_character_,
                                name = gsub("\032", "?", cc_open$name, useBytes = TRUE), country = cc_open$iso2,
                                city = cc_open$city, type = unname(cc_type[cc_open$type]), active = NA,
                                master_source = pick("how"), lon = pick("lon"), lat = pick("lat"),
                                source = "CoordinateCleaner list", extension = FALSE, stringsAsFactors = FALSE)
coordinatecleaner <- coordinatecleaner[valid_xy(coordinatecleaner$lon, coordinatecleaner$lat) &
                                         !zero_xy(coordinatecleaner$lon, coordinatecleaner$lat), ]
coordinatecleaner <- coordinatecleaner[!duplicated(coordinatecleaner[, c("key", "lon", "lat")]), ]
coordinatecleaner <- coordinatecleaner[!paste(coordinatecleaner$lon, coordinatecleaner$lat) %in%
                                         paste(institutions$lon, institutions$lat), ]

institutions <- rbind(institutions, coordinatecleaner)

# Location check against OpenStreetMap. For every institution of
# CoordinateCleaner's table, the named OpenStreetMap feature of that
# institution (university, college, research institute or office, museum, zoo,
# aquarium, botanical garden) within 25 km of CoordinateCleaner's point is the
# reference: when CoordinateCleaner's point lies closer to the feature's extent
# than every point of this table that stands for the institution, the
# feature's own point is added.
osm_tags <- c("amenity=university", "amenity=college", "amenity=research_institute", "office=research",
              "tourism=museum", "tourism=zoo", "tourism=aquarium", "garden:type=botanical")
osm_retrieved <- "2026-10-13"
source("data-raw/overpass.R")
osm_tiles <- expand.grid(s = seq(-90, 60, 30), w = seq(-180, 150, 30))
osm_files <- c(unlist(lapply(setdiff(osm_tags, "tourism=museum"), osm_fetch)),
               unlist(Map(function(s, w) osm_fetch("tourism=museum", s, w, s + 30, w + 30), osm_tiles$s, osm_tiles$w)))
osm_name_tag <- "^(name|official_name|alt_name|short_name|old_name|int_name|loc_name)(:.*)?$"
osm <- do.call(rbind, lapply(osm_files, function(f) {
  el <- jsonlite::fromJSON(f, simplifyVector = FALSE)$elements
  pt <- function(e, a) as.numeric(if (!is.null(e[[a]])) e[[a]] else if (!is.null(e$center)) e$center[[a]] else NA)
  bb <- function(e, a, b) {
    v <- if (is.null(e$bounds)) e[[b]] else e$bounds[[a]]
    if (is.null(v)) NA_real_ else as.numeric(v)
  }
  data.frame(
    key = vapply(el, function(e) paste0("osm:", e$type, "/", e$id), character(1)),
    name = vapply(el, function(e) e$tags$name, character(1)),
    names = vapply(el, function(e) {
      t <- e$tags[grepl(osm_name_tag, names(e$tags))]
      paste(unique(trimws(unlist(strsplit(unlist(t), ";", fixed = TRUE)))), collapse = "|")
    }, character(1)),
    lon = vapply(el, pt, numeric(1), "lon"),
    lat = vapply(el, pt, numeric(1), "lat"),
    xmin = vapply(el, bb, numeric(1), "minlon", "lon"),
    xmax = vapply(el, bb, numeric(1), "maxlon", "lon"),
    ymin = vapply(el, bb, numeric(1), "minlat", "lat"),
    ymax = vapply(el, bb, numeric(1), "maxlat", "lat"),
    stringsAsFactors = FALSE)
}))
# A relation without a centre is placed at the middle of its extent.
mid <- is.na(osm$lon) & valid_xy(osm$xmin, osm$ymin) & valid_xy(osm$xmax, osm$ymax)
osm$lon[mid] <- (osm$xmin[mid] + osm$xmax[mid]) / 2
osm$lat[mid] <- (osm$ymin[mid] + osm$ymax[mid]) / 2
osm <- osm[!duplicated(osm$key) & valid_xy(osm$lon, osm$lat), ]
rownames(osm) <- NULL

# A feature is the institution when every distinctive word of one of its names
# (a word that is not a generic word for an institution, a field or a place
# rank) occurs in CoordinateCleaner's name, and its distinctive words cover at
# least half of those of CoordinateCleaner's name; a name of generic words only
# has to equal the part before the first comma. Of several such features the
# one sharing most words wins, then the one nearest CoordinateCleaner's point.
generic_words <- c(
  "university", "universidad", "universidade", "universite", "universita", "universitat", "universiteit",
  "uniwersytet", "univ", "college", "colegio", "faculty", "facultad", "faculdade", "school", "escuela", "national",
  "nacional", "nationale", "nazionale", "state", "estatal", "federal", "museum", "museo", "musee", "museu", "muzeum",
  "museet", "natural", "naturales", "naturelle", "naturale", "history", "historia", "histoire", "naturkunde",
  "science", "sciences", "ciencias", "scientific", "botanical", "botanic", "botanico", "botanique", "botanischer",
  "garden", "gardens", "jardin", "jardim", "giardino", "garten", "hortus", "arboretum", "herbarium", "herbario",
  "herbier", "herbar", "zoo", "zoological", "zoologico", "zoologique", "zoologischer", "aquarium", "institute",
  "institut", "instituto", "istituto", "research", "investigacion", "investigaciones", "pesquisa", "pesquisas",
  "recherche", "centre", "center", "centro", "station", "estacion", "laboratory", "laboratorio", "department",
  "departamento", "departement", "dept", "division", "section", "unit", "agricultural", "agriculture", "forest",
  "forestry", "fisheries", "marine", "biology", "biological", "biologia", "botany", "zoology", "geology", "society",
  "foundation", "fundacion", "campus", "city", "municipal", "regional", "provincial", "academy", "academia",
  "royal", "ministry", "public", "park", "parque", "parc", "i", "ii", "iii")
osm_names <- strsplit(osm$names, "|", fixed = TRUE)
osm_flat <- lapply(strsplit(ascii_key(unlist(osm_names)), " ", fixed = TRUE), setdiff, name_stop)
osm_words <- split(osm_flat, rep(seq_len(nrow(osm)), lengths(osm_names)))
osm_cell <- function(lat, lon) paste(floor(lat / 0.25), floor(lon / 0.25))
osm_cells <- split(seq_len(nrow(osm)), osm_cell(osm$lat, osm$lon))
osm_near <- function(lon, lat, km) {
  dy <- ceiling(km / 111 / 0.25)
  dx <- min(720, ceiling(km / (111 * max(cos(lat * pi / 180), 0.01)) / 0.25))
  i <- floor(lat / 0.25) + (-dy:dy)
  j <- (floor(lon / 0.25) + (-dx:dx) + 720) %% 1440 - 720
  f <- unlist(osm_cells[paste(rep(i, each = length(j)), rep(j, length(i)))], use.names = FALSE)
  f[km_to(lon, lat, osm$lon[f], osm$lat[f]) <= km]
}
osm_extent_km <- function(lon, lat, f) km_to(lon, lat, pmin(pmax(lon, osm$xmin[f]), osm$xmax[f]),
                                            pmin(pmax(lat, osm$ymin[f]), osm$ymax[f]))
osm_match <- function(r) {
  f <- osm_near(r$decimalLongitude, r$decimalLatitude, 25)
  wq <- name_words(r$query); dq <- setdiff(wq, generic_words); wfirst <- name_words(r$first)
  if (!length(f) || !length(wq)) return(NA_integer_)
  score <- vapply(f, function(j) max(vapply(osm_words[[j]], function(wf) {
    df <- setdiff(wf, generic_words)
    ok <- if (length(df)) all(df %in% wq) && mean(dq %in% df) >= 0.5 else length(wf) && setequal(wf, wfirst)
    if (ok) sum(wf %in% wq) else 0
  }, numeric(1))), numeric(1))
  if (max(score) == 0) return(NA_integer_)
  best <- f[score == max(score)]
  best[which.min(osm_extent_km(r$decimalLongitude, r$decimalLatitude, best))]
}
# The points of this table that stand for an institution of CoordinateCleaner's
# table: those it is held under by name, the point placed for it, and points
# within 25 km sharing at least 60 percent of its name's words.
held_key <- split(known$key, paste(known$iso2, ascii_key(known$name)))
inst_words <- lapply(ifelse(is.na(institutions$name), "", institutions$name), name_words)
cc_points <- function(r) {
  near <- which(km_to(r$decimalLongitude, r$decimalLatitude, institutions$lon, institutions$lat) <= 25)
  want <- name_words(r$query)
  share <- if (length(want)) vapply(near, function(j) mean(want %in% inst_words[[j]]), numeric(1)) else numeric()
  unique(c(which(institutions$key %in% held_key[[paste(r$iso2, ascii_key(r$name))]]),
           which(institutions$source == "CoordinateCleaner list" & institutions$name == r$shown &
                   institutions$country %in% r$iso2),
           near[share >= 0.6]))
}
cc$shown <- gsub("\032", "?", cc$name, useBytes = TRUE)
cc_check <- do.call(rbind, lapply(seq_len(nrow(cc)), function(i) {
  r <- cc[i, ]
  own <- cc_points(r)
  f <- osm_match(r)
  d_own <- if (length(own)) min(km_to(r$decimalLongitude, r$decimalLatitude, institutions$lon[own],
                                      institutions$lat[own])) else Inf
  data.frame(row = i, feature = f, d_own = d_own,
             ext_cc = if (is.na(f)) NA else osm_extent_km(r$decimalLongitude, r$decimalLatitude, f),
             ext_own = if (is.na(f) || !length(own)) NA else
               min(osm_extent_km(institutions$lon[own], institutions$lat[own], rep(f, length(own)))))
}))
cc_fix <- cc_check[!is.na(cc_check$feature) & (is.na(cc_check$ext_own) | cc_check$ext_own > cc_check$ext_cc), ]
osm_added <- data.frame(key = osm$key[cc_fix$feature], code = NA_character_, name = cc$shown[cc_fix$row],
                        country = cc$iso2[cc_fix$row], city = cc$city[cc_fix$row],
                        type = unname(cc_type[cc$type[cc_fix$row]]), active = NA,
                        master_source = "OpenStreetMap feature of that name", lon = osm$lon[cc_fix$feature],
                        lat = osm$lat[cc_fix$feature], source = "CoordinateCleaner list", extension = FALSE,
                        stringsAsFactors = FALSE)
osm_added <- osm_added[!duplicated(osm_added$key) & !zero_xy(osm_added$lon, osm_added$lat), ]
institutions <- rbind(institutions, osm_added)
# A point that only an extension source adds, at coordinates another row
# already has, adds nothing to the test.
institutions <- institutions[order(institutions$extension), ]
ext_dup <- institutions$extension & duplicated(institutions[, c("lon", "lat")])
institutions <- institutions[!ext_dup, ]

# Status of each point. A point of the sources above is "confirmed" when a
# check beyond its own source places it on the institution, and "unconfirmed"
# otherwise. data-raw/institution_checks.csv lists the checks: for every
# institution of CoordinateCleaner's table, the point of this table nearest
# CoordinateCleaner's point, with a Google Maps place of the institution's name
# within 300 m, or within 200 m of the extent of the OpenStreetMap feature of
# that name (not counted for points taken from OpenStreetMap); for every other
# point, a Google Maps place of its name, searched with its city and country,
# within 300 m, or the same OpenStreetMap test (`cc_row` empty).
checks <- read.csv("data-raw/institution_checks.csv", stringsAsFactors = FALSE, encoding = "UTF-8")
from_osm <- startsWith(institutions$key, "osm:") | grepl("OpenStreetMap", institutions$master_source)
at <- paste(institutions$lon, institutions$lat)
ok_google <- at %in% with(checks[checks$check == "Google Maps place of that name", ], paste(lon, lat))
ok_osm <- at %in% with(checks[checks$check == "OpenStreetMap feature of that name", ], paste(lon, lat)) & !from_osm
stopifnot(all(paste(checks$lon, checks$lat) %in% at))
institutions$status <- ifelse(ok_google | ok_osm, "confirmed", "unconfirmed")
institutions$evidence <- ifelse(ok_google & ok_osm, "Google Maps place and OpenStreetMap feature of that name",
                         ifelse(ok_google, "Google Maps place of that name",
                         ifelse(ok_osm, "OpenStreetMap feature of that name", NA_character_)))
institutions$cc_lon <- NA_real_
institutions$cc_lat <- NA_real_

# CoordinateCleaner's own points ship as it has them (status "cc"), except the
# ones data-raw/institution_overrides.csv proves wrong (decision "override"):
# a Google Maps place of the institution's name lies within 25 km of the city
# of CoordinateCleaner's record, and CoordinateCleaner's point and the nearest
# point of this table lie over 25 km from both. Those are moved to the Google
# Maps place (status "override"); `cc_lon` and `cc_lat` keep CoordinateCleaner's
# coordinates. An institution without a city of its own is placed at the place
# its own pages give. Where the Google Maps search gave no place, the site was
# looked up in Wikipedia, OpenStreetMap and the institution's own pages, and the
# point is moved when the site lies over 25 km from CoordinateCleaner's point.
# Every override names the source of its coordinates (`place_source`) and the
# page they were read from (`place_url`). Candidates whose place is another
# institution, a town or one site of an organisation with several, whose site
# no source confirms, or that have no site of their own stay as
# CoordinateCleaner has them (decision "kept", with the reason).
overrides <- read.csv("data-raw/institution_overrides.csv", stringsAsFactors = FALSE, encoding = "UTF-8")
stopifnot(all(overrides$cc_row %in% cc$row))
cc_points <- data.frame(key = paste0("cc:", cc$row), code = NA_character_, name = cc$shown, country = cc$iso2,
                        city = cc$city, type = unname(cc_type[cc$type]), active = NA,
                        master_source = cc$geocoding.source, lon = cc$decimalLongitude, lat = cc$decimalLatitude,
                        source = "CoordinateCleaner", extension = FALSE, status = "cc", evidence = NA_character_,
                        cc_lon = NA_real_, cc_lat = NA_real_, stringsAsFactors = FALSE)
ov <- overrides[overrides$decision == "override", ]
stopifnot(nzchar(ov$place_source), startsWith(ov$place_url, "https://"))
j <- match(ov$cc_row, cc$row)
stopifnot(isTRUE(all.equal(cc_points$lon[j], ov$cc_lon)), isTRUE(all.equal(cc_points$lat[j], ov$cc_lat)))
cc_points$cc_lon[j] <- cc_points$lon[j]
cc_points$cc_lat[j] <- cc_points$lat[j]
cc_points$lon[j] <- ov$lon
cc_points$lat[j] <- ov$lat
cc_points$status[j] <- "override"
cc_points$source[j] <- ov$place_source
cc_points$evidence[j] <- paste0(ov$place_source, " place \"", ov$place_name, "\", ",
                                ifelse(is.na(ov$city_to_place_km), "",
                                       paste0(ov$city_to_place_km, " km from the record's city; ")),
                                "CoordinateCleaner's point ", ov$cc_to_place_km, " km away; ", ov$place_url)
stopifnot(!any(zero_xy(cc_points$lon, cc_points$lat)))
# A point of the other sources at the coordinates of one of CoordinateCleaner's
# adds nothing to the test.
n_at_cc <- sum(paste(institutions$lon, institutions$lat) %in% paste(cc_points$lon, cc_points$lat))
institutions <- institutions[!paste(institutions$lon, institutions$lat) %in% paste(cc_points$lon, cc_points$lat), ]
institutions <- rbind(cc_points, institutions)
institutions <- institutions[order(institutions$country, institutions$name), ]
rownames(institutions) <- NULL

wp_all_files <- c(wp_files, wp_flag_files, wp_title_files, it_file, inst_file, wp_search_files, wp_gn_files)
meta <- rbind(
  data.frame(layer = "institutions", source = "GBIF GRSciColl", file = basename(tsv),
             version = retrieved, url = url, sha256 = sha256(tsv), retrieved = retrieved,
             licence = "see dev_notes/reference_data.md", stringsAsFactors = FALSE),
  data.frame(layer = "institutions_wikidata", source = "Wikidata",
             file = paste(basename(wd_files), collapse = ", "), version = wd_retrieved, url = wd_endpoint,
             sha256 = paste(vapply(wd_files, sha256, character(1)), collapse = ", "), retrieved = wd_retrieved,
             licence = "CC0 1.0", stringsAsFactors = FALSE),
  data.frame(layer = "institutions_wikipedia", source = "Wikipedia, lists of natural history museums",
             file = paste(basename(wp_all_files), collapse = ", "),
             version = paste(names(wp_revid), "revision", wp_revid, collapse = "; "),
             url = paste0("https://", wp_lists$lang, ".wikipedia.org/wiki/",
                          utils::URLencode(gsub(" ", "_", wp_lists$title)), collapse = ", "),
             sha256 = paste(vapply(wp_all_files, sha256, character(1)), collapse = ", "),
             retrieved = wp_retrieved,
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
             stringsAsFactors = FALSE),
  data.frame(layer = "institutions_index_herbariorum", source = "Index Herbariorum (New York Botanical Garden)",
             file = basename(ih_file), version = ih_retrieved, url = ih_url, sha256 = sha256(ih_file),
             retrieved = ih_retrieved, licence = "see dev_notes/reference_data.md", stringsAsFactors = FALSE),
  data.frame(layer = "institutions_gbif_registry", source = "GBIF registry, publishing organisations",
             file = basename(gbif_org_file), version = gbif_org_retrieved, url = gbif_org_url,
             sha256 = sha256(gbif_org_file), retrieved = gbif_org_retrieved,
             licence = "see dev_notes/reference_data.md", stringsAsFactors = FALSE),
  data.frame(layer = "institutions_coordinatecleaner_list",
             source = paste("CoordinateCleaner", cc_version, "institution list, placed by Wikidata, OpenStreetMap",
                            "(Nominatim) and GeoNames"),
             file = paste(basename(c(cc_search_file, nominatim_file)), collapse = ", "), version = cc_version,
             url = "https://nominatim.openstreetmap.org/search",
             sha256 = paste(vapply(c(cc_search_file, nominatim_file), sha256, character(1)), collapse = ", "),
             retrieved = gbif_org_retrieved,
             licence = "see dev_notes/reference_data.md", stringsAsFactors = FALSE),
  data.frame(layer = "institutions_openstreetmap", source = "OpenStreetMap, Overpass API (named institution features)",
             file = paste(basename(osm_files), collapse = ", "), version = osm_retrieved,
             url = "https://overpass-api.de/api/interpreter",
             sha256 = paste(vapply(osm_files, sha256, character(1)), collapse = ", "), retrieved = osm_retrieved,
             licence = "ODbL 1.0, (c) OpenStreetMap contributors", stringsAsFactors = FALSE),
  data.frame(layer = "institutions_status", source = paste("CoordinateCleaner", cc_version,
                                                           "institutions; overrides and checks by Google Maps and OpenStreetMap"),
             file = "institution_overrides.csv, institution_checks.csv", version = "2026-10-27",
             url = "https://github.com/gcol33/OccurrenceCleaner/tree/main/data-raw",
             sha256 = paste(sha256("data-raw/institution_overrides.csv"), sha256("data-raw/institution_checks.csv"),
                            sep = ", "),
             retrieved = "2026-10-27", licence = "see dev_notes/reference_data.md", stringsAsFactors = FALSE))
saveRDS(list(institutions = institutions, meta = meta), file.path(cache, "institutions.rds"), compress = "xz")
cat("GRSciColl institutions with coordinates:", sum(valid), "of", nrow(d), "- dropped as zero coordinates:",
    sum(zero), "- kept:", n_grscicoll, "\n")
print(d[zero, c("code", "name", "country", "longitude", "latitude")])
cat("Wikidata points:", sum(earth), "on Earth, dropped as zero coordinates:", sum(wd_zero), "- kept:",
    nrow(wikidata), "\n")
cat("Wikipedia list entries:", nrow(wp_located), "- located by:\n")
print(table(wp_located$lang, wp_located$how, useNA = "ifany"))
cat("Wikipedia entries without a country:", sum(is.na(wp_located$iso2)), "\n")
cat("Wikipedia rows placed by linked place or GeoNames:", nrow(wikipedia), "- dropped as zero coordinates:",
    sum(wp_zero), "\n")
print(geonames)
cat("BGCI gardens:", nrow(bg), "- with coordinates:", sum(bg_valid), "- dropped as zero coordinates:",
    sum(bg_zero), "- kept:", nrow(bgci), "- country names without ISO code:",
    paste(unique(bg$country[bg_keep & is.na(bg$iso2)]), collapse = ", "), "\n")
print(table(institutions$source, institutions$type, useNA = "ifany"))
print(table(institutions$master_source))
print(table(institutions$source, institutions$extension))
cat("extension rows dropped at coordinates another row has:", sum(ext_dup), "
")
cat("xz size KB:", file.size(file.path(cache, "institutions.rds")) / 1024, "\n")
cat("Index Herbariorum herbaria with a location:", sum(ih_ok), "- not placed by GRSciColl:", nrow(index_herbariorum), "\n")
cat("GBIF registry organisations:", nrow(org), "- with coordinates:", nrow(gbif_registry), "\n")
cat("CoordinateCleaner institutions with coordinates:", nrow(cc), "- held under their name:", nrow(cc) -
      nrow(cc_open) - nrow(cc_unplaced) - n_held_near, "- held by a nearby point sharing its name words:",
    n_held_near, "- placed by:\n")
print(table(pick("how")))
cat("not placed:", nrow(cc_unplaced), "\n")
print(cc_unplaced[, c("source", "iso2", "city", "name")], row.names = FALSE)
cat("OpenStreetMap features:", nrow(osm), "- CoordinateCleaner institutions with a matching feature within 25 km:",
    sum(!is.na(cc_check$feature)), "- feature nearer than every point of this table (added):", nrow(cc_fix),
    "- kept after dropping duplicates and zero coordinates:", nrow(osm_added), "
")
print(table(osm_added$type, useNA = "ifany"))
cat("Points of other sources at CoordinateCleaner's coordinates (dropped):", n_at_cc, "\n")
print(table(institutions$source, institutions$status))
print(table(institutions$status))
print(summary(cc_check$d_own[is.finite(cc_check$d_own)]))
