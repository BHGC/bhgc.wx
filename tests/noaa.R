library(bhgc.wx)

coord <- c(lat=37.475400, lon=-121.861300)
url <- noaa_url(lat = coord["lat"], lon = coord["lon"])
print(url)

url2 <- noaa_url(coord)
print(url2)
stopifnot(identical(url2, url))
