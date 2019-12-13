library(bhgc.wx)
timezone <- bhgc.wx:::timezone

timezone("America/Los_Angeles")
stopifnot(timezone() == "America/Los_Angeles")

#url <- noaa_url(lat=37.4611, lon=-121.8646)
url <- noaa_url(lat = 34.210000, lon =-117.302900)

if (!exists("db")) db <- list()
if (is.null(db$values)) db$values <- read_noaa(url)

gg <- ggplot_noaa_wind_direction(db$values)
#print(gg)

gg <- ggplot_noaa_surface_wind(db$values)
print(gg)


## NOTE: plotly ignores/does not support 'sec.axis'
#pp <- plotly::ggplotly(gg)
#print(pp)
