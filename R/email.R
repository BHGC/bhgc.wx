# Example:
# Rscript -e R.rsp::rcat --args --file=wx.md.rsp --timestamp="2020-10-08T13:26:25-07:00" --wfo="mtr" --imgfile="imgs/lakecourt,2020-10-10T15_02_14-07_00,mtr.png" --label="Blue Rock, Vallejo, CA" --lat="38.1384" --lon="-122.1956"
#' @importFrom R.utils cmdArg
#' @importFrom R.rsp rstring
#' @importFrom lubridate as_datetime
#' @importFrom utils file_test
#' @export
email_body <- function(label = NULL, lat = NULL, lon = NULL, wfo = NULL, timestamp = NULL, imgfile = NULL, xmlfile = NULL) {
  if (is.null(imgfile)) imgfile <- cmdArg("imgfile")
  if (is.null(label)) label <- toupper(cmdArg("label", ""))
  if (is.null(lat)) lat <- toupper(cmdArg("lat", NA_real_))
  if (is.null(lon)) lon <- toupper(cmdArg("lon", NA_real_))
  if (is.null(timestamp)) timestamp <- cmdArg("timestamp")
  if (is.null(wfo)) wfo <- toupper(cmdArg("wfo", ""))
  if (is.null(xmlfile)) xmlfile <- cmdArg("xmlfile", NA_character_)
  if (!is.na(xmlfile)) {
    stopifnot(file_test(xmlfile))
    bfr <- readLines(xmlfile, warn = FALSE)
    
    pattern <- pattern <- ".*<creation-date[^>]*>([^<]*)</creation-date>.*"
    value <- grep(pattern, bfr, value = TRUE)
    stopifnot(length(value) == 1L)
    value <- gsub(pattern, "\\1", value)
    stopifnot(length(value) == 1L)
  
    pattern <- ".*<credit[^>]*>([^<]*)</credit>.*"
    value <- grep(pattern, bfr, value = TRUE)
    stopifnot(length(value) == 1L)
    value <- gsub(pattern, "\\1", value)
    stopifnot(length(value) == 1L)
    value <- basename(value)
    wfo <- toupper(value)
  }

  timestamp <- as_datetime(timestamp, tz = Sys.timezone())
  if (is.na(timestamp)) stop("Unknown timestamp format: ", sQuote(value))

  args <- list(
    label = label,
    timestamp = timestamp,
    lat = lat,
    lon = lon,
    wfo = wfo,
    imgfile = imgfile
  )

  rspfile <- system.file("email", "body.html.rsp", package = .packageName, mustWork = TRUE)
  body <- rstring(file = rspfile, args = args)
  body <- structure(body, class = "html", html = TRUE)

  attr(body, "args") <- args
  
  body
}


#' @importFrom utils file_test
#' @importFrom blastula compose_email creds_file smtp_send
#' @export
send_email <- function(..., to, from, subject = NULL, cc = NULL, bcc = NULL, credentials = NULL) {
  if (is.null(credentials)) {
    credentials <- Sys.getenv("R_BHGC_NOAA_EMAIL_CREDENTIALS", NA_character_)
    if (is.na(credentials)) credentials <- NULL
  }
  if (file_test("-f", credentials)) {
    credentials <- creds_file(credentials)
  }
  body <- email_body(...)
  args <- attr(body, "args")
  if (is.null(subject)) {
    subject <- sprintf("NOAA Forecast for %s", args$label)
  }
  email <- compose_email(body = body)
  smtp_send(email, to = to, from = from, subject = subject, cc = cc, bcc = bcc, credentials = credentials)
}
