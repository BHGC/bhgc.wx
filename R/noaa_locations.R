#' @importFrom utils file_test
noaa_locations <- local({
  locations <- NULL
  
  function(paths = c(".", "inst", system.file(package = "bhgc.wx"))) {
    if (is.null(locations)) {
      stopifnot(length(paths) > 0L)
      paths <- paths[file_test("-d", paths)]
      stopifnot(length(paths) > 0L)
      pathnames <- file.path(paths, "locations.R")
      pathnames <- pathnames[file_test("-f", pathnames)]
      stopifnot(length(pathnames) > 0L)
      pathname <- pathnames[1]
      env <- new.env()			      
      eval(quote(source(pathname, local=TRUE)), envir = env)
      stopifnot("locations" %in% names(env))
      locations <<- env$locations
      env <- NULL
    }
    locations
  }
})

