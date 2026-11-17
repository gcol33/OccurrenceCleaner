library(OccurrenceCleaner)
rv <- read.csv("data-raw/institution_review_2026-11-17.csv", encoding = "UTF-8")
p <- reference_points("institution")
j <- vapply(seq_len(nrow(rv)), function(k) {
  hit <- which(p$key == rv$key[k] & abs(p$lon - rv$lon[k]) < 1e-6 & abs(p$lat - rv$lat[k]) < 1e-6)
  stopifnot(length(hit) == 1L)
  hit
}, 1L)
expected <- ifelse(rv$decision == "confirm", "confirmed", "unconfirmed")
stopifnot(identical(p$status[j], expected))
accepted <- rv$decision == "confirm"
at_site <- data.frame(decimalLongitude = p$lon[j[accepted]], decimalLatitude = p$lat[j[accepted]])
stopifnot(all(flag_occurrences(at_site, tests = "institution")$flag_institution))
cat(sum(accepted), "confirmed review rows;", sum(!accepted), "rejected review rows\n")
print(table(p$status))
