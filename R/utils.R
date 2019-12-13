timezone <- local({
  tz <- Sys.timezone()
  function(new = NULL) {
    if (!is.null(new)) tz <<- new
    tz
  }
})


#' @importFrom lubridate floor_date ceiling_date
date_range <- function(values, tz = timezone()) {
  first <- min(values$start, na.rm = TRUE)
  last <- max(values$end, na.rm = TRUE)
  start <- floor_date(first, unit = "12 hours")
  end <- ceiling_date(last, unit = "12 hours")
  range <- start
  range[2] <- end
  range
}
