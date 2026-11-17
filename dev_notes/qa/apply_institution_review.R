# Apply reviewed identities using the full-precision coordinates of the cached table.
rv <- read.csv("data-raw/institution_review_2026-11-17.csv", encoding = "UTF-8")
i <- readRDS("data-raw/cache/institutions.rds")$institutions
k <- vapply(seq_len(nrow(rv)), function(j) {
  hit <- which(i$key == rv$key[j] & abs(i$lon - rv$lon[j]) < 1e-6 & abs(i$lat - rv$lat[j]) < 1e-6)
  stopifnot(length(hit) == 1L)
  hit
}, 1L)
rv$lon <- i$lon[k]
rv$lat <- i$lat[k]
rv$name <- i$name[k]
ch <- read.csv("data-raw/institution_checks.csv", encoding = "UTF-8")
yes <- rv[rv$decision == "confirm", ]
new <- data.frame(lon = yes$lon, lat = yes$lat, check = yes$check,
                  evidence = paste(yes$osm_feature, yes$evidence, yes$url, sep = "; "),
                  distance_m = yes$osm_ext_m, cc_row = NA_integer_)
key <- function(d) paste(d$lon, d$lat, d$check)
new <- new[!duplicated(key(new)) & !key(new) %in% key(ch), ]
ch <- rbind(ch, new)
ch <- ch[order(ch$lon, ch$lat, ch$check), ]
write.csv(ch, "data-raw/institution_checks.csv", row.names = FALSE, fileEncoding = "UTF-8")
rj <- read.csv("data-raw/institution_rejections.csv", encoding = "UTF-8")
no <- rv[rv$decision == "reject", ]
add <- data.frame(lon = no$lon, lat = no$lat, name = no$name,
                  check = "identity of the OpenStreetMap parent site", reason = paste(no$evidence, no$url), checked = no$checked)
key <- function(d) paste(d$lon, d$lat, d$name)
add <- add[!key(add) %in% key(rj), ]
write.csv(rbind(rj, add), "data-raw/institution_rejections.csv", row.names = FALSE, fileEncoding = "UTF-8")
cat("Checks added:", nrow(new), "rejections added:", nrow(add), "\n")
