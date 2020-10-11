ggplot_datetime_labels <- function(t, tz = timezone(), flavor = getOption("flavor", "wide")) {
  flavor <- match.arg(flavor, choices = c("wide", "narrow"))
  
##  message(sprintf("ggplot_datetime_labels(): tz=%s", tz))

  hours <- strftime(t, format = "%H", tz = tz)
  uhours <- sort(unique(hours))
  near_noon <- uhours[which.min(abs(as.integer(uhours) - 12L))]

  if (flavor == "wide") {
    times <- strftime(t, format = "%H:%M", tz = tz)
    dates <- strftime(t, format = "%a %b %d", tz = tz)
    dates[hours != near_noon] <- NA_character_
    last <- rev(which(!is.na(dates)))[1]
    dates[last] <- strftime(t[last], format = "%a %b %d (%Z)", tz = tz)
    labels <- ifelse(is.na(dates), times, paste0(times, "\n", dates))
  } else if (flavor == "narrow") {
    times <- strftime(t, format = "%H", tz = tz)
    days <- strftime(t, format = "%a", tz = tz)
    days[hours != near_noon] <- NA_character_
    dates <- strftime(t, format = "%b %d", tz = tz)
    dates[hours != near_noon] <- NA_character_
    last <- rev(which(!is.na(dates)))[1]
    dates[last] <- strftime(t[last], format = "%a %b %d (%Z)", tz = tz)
    labels <- ifelse(is.na(dates), times, paste0(times, "\n", days))
  }

  labels
}

#' @importFrom lubridate as_datetime ceiling_date floor_date
#' @import ggplot2
ggplot_noaa_wind_direction <- function(values, x_limits = date_range(values), days = NULL, windows_size = Inf) {
  ## To please R CMD check
  start <- wind_direction <- NULL

  if (is.null(windows_size)) windows_size <- 1024
  
  ## https://clrs.cc/
  color_map <- c(black = "#111111", gray = "#AAAAAA", green = "#2ECC40", yellow = "#FFDC00", red = "#FF4136")
  bins <- cut(values$wind_direction, breaks = c(-Inf, 135, 180-1, 270, 300, Inf))
  cols <- color_map[c("red", "yellow", "green", "yellow", "red")[bins]]

  if (!is.null(days)) {
    stopifnot(all(is.finite(days)), all(days > 0))
    if (length(days) == 1L) {
      days <- seq(from = Sys.Date(), by = 1L, length.out = as.integer(days))
    } else {
      stopifnot(length(days) == 2L)
    }
    tz <- timezone()
    x_limits[1] <- floor_date(as_datetime(days[1] + 1L, tz = tz), unit = "days")
    x_limits[2] <- ceiling_date(as_datetime(days[2] + 1L, tz = tz), unit = "days")
  }
  
  x_breaks <- seq(from = x_limits[1], to = x_limits[2], by = "12 hours")

  ndays <- length(x_breaks) / 2
  flavor <- if (8/ndays * windows_size[1] < 1000) "narrow" else "wide"
  options(flavor = flavor)

  gg <- ggplot(values, aes(start, wind_direction)) + geom_point(color = cols, size = 2.0)

  wind_dirs <- c(N = 0, E = 90, S = 180, W = 270, N = 360)
  
  gg <- gg + scale_y_continuous(limits = c(0, 360), breaks = wind_dirs, labels = names(wind_dirs), minor_breaks = seq(0, 360, by = 30), sec.axis = sec_axis(~., breaks = as.integer(wind_dirs)))

  gg <- gg + labs(y = "Wind direction")
  
  gg <- gg + scale_x_datetime(limits = x_limits, breaks = x_breaks, labels = ggplot_datetime_labels, position = "top")
  
  gg <- gg + theme(axis.title.x = element_blank())

#  rect <- data.frame(xmin = -Inf, xmax = +Inf, ymin = 180, ymax = 270)
#  gg <- gg + geom_rect(data=rect, aes(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax), color = "green", alpha = 0.3, inherit.aes = FALSE)
  gg
}

#' @importFrom lubridate as_datetime ceiling_date floor_date
#' @import ggplot2
ggplot_noaa_surface_wind <- function(values, x_limits = date_range(values), days = NULL, windows_size = Inf) {
  ## To please R CMD check
  start <- surface_wind <- gust <- NULL
   
  if (is.null(windows_size)) windows_size <- 1024

  if (!is.null(days)) {
    stopifnot(all(is.finite(days)), all(days > 0))
    if (length(days) == 1L) {
      days <- seq(from = Sys.Date(), by = 1L, length.out = as.integer(days))
    } else {
      stopifnot(length(days) == 2L)
    }
    tz <- timezone()
    x_limits[1] <- floor_date(as_datetime(days[1] + 1L, tz = tz), unit = "days")
    x_limits[2] <- ceiling_date(as_datetime(days[2] + 1L, tz = tz), unit = "days	")
  }

  x_breaks <- seq(from = x_limits[1], to = x_limits[2], by = "12 hours")
  y_limits <- c(0, 25)

  ndays <- length(x_breaks) / 2
  flavor <- if (8/ndays * windows_size[1] < 1000) "narrow" else "wide"
  options(flavor = flavor)

  gg <- ggplot(values)

  gg <- gg + scale_y_continuous(limits = y_limits, minor_breaks = seq(0, 20, by = 1), sec.axis = sec_axis(~ 0.44704 * .))
  
  gg <- gg + labs(y = "Wind speed (mph <-> m/s)")

  gg <- gg + scale_x_datetime(limits = x_limits, breaks = x_breaks, labels = ggplot_datetime_labels)  ## , date_minor_breaks = "6 hours"

  rain <- values$precipitation_potential/100
  rain[rain == 0] <- NA_real_
  
##  gg <- gg + geom_point(aes(start, diff(y_limits)*rain, color = rain), size = 2.0) + scale_colour_gradient(low = "white", high = "blue")
  gg <- gg + geom_bar(stat = "identity", aes(start, diff(y_limits)*rain), fill = "blue", alpha = 0.25, size = 2.0)

  gg <- gg + geom_point(aes(start, surface_wind), size = 2.0)

  gg <- gg + geom_point(aes(start, gust), size = 2.0, shape = 4L, color = "red")

  gg <- gg + theme(axis.title.x = element_blank())

  gg
}
