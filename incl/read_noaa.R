coord <- c(lat=37.475400, lon=-121.861300)
url <- noaa_url(coord)
print(url)
wx <- read_noaa(url)
print(wx)

