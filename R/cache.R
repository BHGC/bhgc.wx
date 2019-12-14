#' @importFrom R.cache getCachePath
cache_path <- function(wx) {
  stopifnot(inherits(wx, "data.frame"))
  gps <- wx$gps[[1]]
  dir <- paste(sprintf("%s=%s", names(gps), gps), collapse=",")
  path <- getCachePath(dirs = c("bhgc.wx", dir))
  path
}

cache_pathname <- function(wx, ext = NULL) {
  path <- cache_path(wx)
  time <- wx$last_updated[[1]]
  time <- format(time, "%Y-%M-%dT%H:%m:%S")
  name <- gsub(":", "_", time)
  file.path(path, paste(c(name, ext), collapse = "."))
}

#' @importFrom utils file_test
has_cache <- function(wx, ext = "rds") {
  pathname <- cache_pathname(wx, ext = ext)
  file_test("-f", pathname)
}
