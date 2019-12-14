#' Get NOAA Weather Forcast URL for a Location
#'
#' @param lat,lon (numeric) A lattitude and the longitude.
#'
#' @param format (character) Should an XML or an HTML document be retrieved?
#'
#' @return `noaa_url()` returns a URL (character).
#'
#' @rdname read_noaa
#' @export
noaa_url <- function(lat, lon, format = c("xml", "html")) {
  gps <- lat
  if (length(gps) == 2) {
    lat <- gps[1]
    lon <- gps[2]
  }
  lat <- as.numeric(lat)
  lon <- as.numeric(lon)
  format <- match.arg(format)
  if (format == "xml") {
    sprintf("https://forecast.weather.gov/MapClick.php?lat=%f&lon=%f&FcstType=digitalDWML", lat, lon)
  } else {
    sprintf("https://forecast.weather.gov/MapClick.php?w0=t&w1=td&w2=wc&w3=sfcwind&w3u=1&w4=sky&w5=pop&w6=rh&w7=thunder&w8=rain&w9=snow&w10=fzg&w11=sleet&Submit=Submit&FcstType=digital&site=mtr&unit=0&dd=0&bw=0&textField1=%f&textField2=%f", lat, lon)
  }
}


#' Get NOAA Weather Forcast for a Location
#'
#' @param url (character) A NOAA URL to download and parse.
#'
#' @param tz (character) The timezone for all retrieved timestamps.
#'
#' @return `read_noaa()` returns a [tibble::tibble] [base::data.frame] with
#' forecasted weather data.
#'
#' @example incl/read_noaa.R
#'
#' @importFrom dplyr rename
#' @importFrom magrittr %>%
#' @importFrom lubridate as_datetime with_tz
#' @importFrom utils file_test
#' @importFrom tibble as_tibble
#' @importFrom xml2 read_xml xml_attr xml_attrs xml_children xml_find_all xml_name xml_text
#' @export
read_noaa <- function(url, tz = timezone()) {
##  message(sprintf("read_noaa(): tz=%s", tz))
  
  doc <- read_xml(url)

  times <- xml_find_all(doc, ".//time-layout")
  stopifnot(length(times) == 1)

  last_updated <- xml_find_all(doc, ".//creation-date")
  stopifnot(length(last_updated) == 1)
  last_updated <- xml_text(last_updated)
  last_updated <- with_tz(as_datetime(last_updated), tzone = tz)

  ## Extract (latitute, longitude, altitude)
  location <- xml_find_all(doc, ".//location")
  stopifnot(length(location) == 1)
  data <- xml_children(location[[1]])
  names <- xml_name(data)
  point <- data[[which("point" == names)]]
  point <- xml_attrs(point)
  stopifnot(all(c("latitude", "longitude") == names(point)))
  point <- as.numeric(point)
  height <- data[[which("height" == names)]]
  units <- xml_attrs(height)[["height-units"]]
  altitude <- as.numeric(xml_text(height))
  gps <- c(latitude = point[1], longitude = point[2], altitude = altitude)

  start <- unlist(lapply(times, FUN = function(x) xml_find_all(doc, ".//start-valid-time") %>% xml_text))
  end <- unlist(lapply(times, FUN = function(x) xml_find_all(doc, ".//end-valid-time") %>% xml_text))
  
  times <- data.frame(
    start = with_tz(as_datetime(start), tzone = tz),
    end = with_tz(as_datetime(end), tzone = tz),
    stringsAsFactors = FALSE
  )
  
  params <- xml_find_all(doc, ".//parameters")
  stopifnot(length(params) == 1)
  
  data <- xml_children(params[[1]])
  names <- xml_name(data)
  types <- xml_attr(data, "type")
  
  keys <- sprintf("%s (%s)", names, types)
  keys[is.na(types)] <- names[is.na(types)]
  
  wx <- lapply(data, FUN = function(x) xml_children(x) %>% xml_text %>% as.numeric)
  names(wx) <- keys

  wx <- as.data.frame(wx, check.names = FALSE, stringsAsFactors = FALSE)
  wx <- cbind(times, wx)
  wx <- as_tibble(wx)

  wx$last_updated <- rep(last_updated, times = nrow(wx))
  wx$gps <- rep(list(gps), times = nrow(wx))

  wx <- rename(wx, dewpoint = "temperature (dew point)", heat_index = "temperature (hourly)", surface_wind = "wind-speed (sustained)", cloud_cover = "cloud-amount (total)", precipitation_potential = "probability-of-precipitation (floating)", relative_humidity = "humidity (relative)", wind_direction = "direction (wind)", gust = "wind-speed (gust)", temperature = "temperature (hourly)", forecast = "hourly-qpf (floating)")

  if (getOption("debug", FALSE)) {
    print(colnames(wx))
    print(wx)
  }

  wx
} ## read_noaa()
