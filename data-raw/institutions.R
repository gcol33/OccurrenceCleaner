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
# English list; BGCI; GeoNames) and TRUE for the points only this gazetteer
# holds.
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
  for (n in setdiff(nm, have$name)) {
    tf <- tempfile()
    download.file(paste0("https://www.wikidata.org/w/api.php?action=wbsearchentities&format=json&type=item",
                         "&limit=20&language=", lang, "&search=", utils::URLencode(n, reserved = TRUE)),
                  tf, quiet = TRUE, headers = c(`User-Agent` = ua))
    s <- jsonlite::fromJSON(tf, simplifyVector = FALSE)$search
    hit <- vapply(s, function(h) if (name_key(h$match$text) == name_key(n)) h$id else NA_character_, character(1))
    hit <- unique(hit[!is.na(hit)])
    have <- rbind(have, data.frame(name = n, item = if (length(hit)) hit else NA_character_))
  }
  write.csv(have, f, row.names = FALSE, na = "", fileEncoding = "UTF-8")
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

institutions <- rbind(institutions, wikidata, wikipedia, geonames, bgci)
# A point that only an extension source adds, at coordinates another row
# already has, adds nothing to the test.
institutions <- institutions[order(institutions$extension), ]
ext_dup <- institutions$extension & duplicated(institutions[, c("lon", "lat")])
institutions <- institutions[!ext_dup, ]
institutions <- institutions[order(institutions$country, institutions$name), ]
rownames(institutions) <- NULL

sha256 <- function(path) {
  if (requireNamespace("digest", quietly = TRUE)) return(digest::digest(path, algo = "sha256", file = TRUE))
  tolower(strsplit(system2("certutil", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE)[2], " ")[[1]][1])
}
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
             stringsAsFactors = FALSE))
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
