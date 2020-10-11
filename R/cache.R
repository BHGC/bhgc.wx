#' @importFrom R.cache getCachePath
cache_path <- function(wx) {
  stopifnot(inherits(wx, "data.frame"))
  
  gps <- wx[, c("latitude", "longitude", "altitude")]
  gps <- unique(gps)
  stopifnot(nrow(gps) == 1L)
  gps <- as.list(gps)
  
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


cached <- function(wx) {
  stopifnot(inherits(wx, "data.frame"))

  cache_name <- cache_pathname(wx)
  pathname <- paste(cache_name, "tibble.rds", sep = ".")
  
  ## Used cached version, if it exists, otherwise cache
  if (file_test("-f", pathname)) {
    wx <- readRDS(pathname)
    attr(wx, "cache_name") <- cache_name
  } else {
    saveRDS(wx, file = pathname)
  }
  
  wx  
}
