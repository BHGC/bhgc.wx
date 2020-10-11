# Example:
# Rscript -e R.rsp::rcat --args --file=wx.md.rsp --timestamp="2020-10-08T13:26:25-07:00" --wfo="mtr" --imgfile="imgs/lakecourt,2020-10-10T15_02_14-07_00,mtr.png" --label="Blue Rock, Vallejo, CA" --lat="38.1384" --lon="-122.1956"

library(R.utils)
library(R.rsp)
library(blastula)
library(lubridate)

# Input arguments
imgfile <- R.utils::cmdArg("imgfile")
label <- toupper(R.utils::cmdArg("label", ""))
lat <- toupper(R.utils::cmdArg("lat", NA_real_))
lon <- toupper(R.utils::cmdArg("lon", NA_real_))

args <- list(
  label     = "Blue Rock, Vallejo, CA",
  lat       = "38.1384",
  lon       = "-122.1956",
  timestamp = "2020-10-08T13:26:25-07:00",
  wfo       = "mtr",
  imgfile   = "imgs/lakecourt,2020-10-10T15_02_14-07_00,mtr.png"
)

xmlfile <- R.utils::cmdArg("xmlfile", NA_character_)
if (!is.na(xmlfile)) {
  stopifnot(utils::file_test(xmlfile))
  bfr <- readLines(xmlfile)
  
  pattern <- pattern <- ".*<creation-date[^>]*>([^<]*)</creation-date>.*"
  value <- grep(pattern, bfr, value = TRUE)
  stopifnot(length(value) == 1L)
  value <- gsub(pattern, "\\1", value)
  stopifnot(length(value) == 1L)
  timestamp <- lubridate::as_datetime(value, tz = Sys.timezone())
  if (is.na(timestamp)) stop("Unknown timestamp format: ", sQuote(value))

  pattern <- ".*<credit[^>]*>([^<]*)</credit>.*"
  value <- grep(pattern, bfr, value = TRUE)
  stopifnot(length(value) == 1L)
  value <- gsub(pattern, "\\1", value)
  stopifnot(length(value) == 1L)
  value <- basename(value)
  wfo <- toupper(value)
} else {
  timestamp <- R.utils::cmdArg("timestamp")
  timestamp <- lubridate::as_datetime(timestamp, tz = Sys.timezone())
  if (is.na(timestamp)) stop("Unknown timestamp format: ", sQuote(value))
  wfo <- toupper(R.utils::cmdArg("wfo", ""))
}


body <- R.rsp::rstring(file = "body.html.rsp", args = args)
body <- structure(body, class = "html", html = TRUE)
email <- blastula::compose_email(body = body)

writeLines(email$html_str,  con = "email.html")
