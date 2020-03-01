library(bhgc.wx)
check_offline <- as.logical(Sys.getenv("R_CHECK_OFFLINE", "FALSE"))

coord <- c(lat=37.475400, lon=-121.861300)
url <- noaa_url(lat = coord["lat"], lon = coord["lon"])
print(url)

url2 <- noaa_url(coord)
print(url2)
stopifnot(identical(url2, url))

if (!check_offline) {
  wx <- read_noaa(url)
  print(wx)

  path <- tempdir()
  pathname <- save_noaa(wx, path = path)
  print(pathname)
  stopifnot(!isTRUE(attr(pathname, "skipped")))

  pathname2 <- save_noaa(wx, path = path)
  stopifnot(isTRUE(attr(pathname2, "skipped")))
  stopifnot(all.equal(pathname2, pathname, check.attributes = FALSE))

  wx2 <- read_rds(pathname)
  stopifnot(identical(wx2, wx))
}
