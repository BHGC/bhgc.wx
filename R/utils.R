#' Get or Set Time Zone used by this Package 
#'
#' @param new (character) If non-NULL, new timezone to be set.
#'
#' @return (character) The current timezone set.
#'
#' @export
timezone <- local({
  tz <- Sys.timezone()
  function(new = NULL) {
    if (!is.null(new)) {
      tz <<- new
      tz
    } else {
      invisible(tz)
    }
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
