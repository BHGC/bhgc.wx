#' Robustly Reads an RDS File
#'
#' @param pathname RDS file to read.
#'
#' @param \ldots (optional) Additional arguments passed to [base::readRDS()].
#'
#' @return The \R object read.
#'
#' @details
#' Uses [base::readRDS] internally but gives a more informative error message
#' on failure.
#'
#' @importFrom utils file_test
#' @export
#' @keywords internal
read_rds <- function(pathname, ...) {
  if (!file_test("-f", pathname)) {
    stop(sprintf("No such file: %s", sQuote(pathname)))
  }
  tryCatch({
    readRDS(pathname, ...)
  }, error = function(ex) {
    msg <- conditionMessage(ex)
    msg <- sprintf("readRDS() failed to read file %s (%.0f bytes). The reason was: %s",
                   sQuote(pathname), file.size(pathname), msg)
    ex$message <- msg
    stop(ex)
  })
}



#' Robustly Saves an Object to RDS File Atomically
#'
#' @param object The \R object to be save.
#'
#' @param pathname RDS file to written.
#'
#' @param \ldots (optional) Additional arguments passed to [base::saveRDS()].
#'
#' @return (invisible) The pathname of the RDS written.
#'
#' @details
#' Uses [base::saveRDS] internally but writes the object atomically by first
#' writing to a temporary file which is then renamed.
#'
#' @importFrom utils file_test
#' @export
#' @keywords internal
save_rds <- function(object, pathname, ...) {
  pathname_tmp <- sprintf("%s.tmp", pathname)
  if (file_test("-f", pathname_tmp)) {
    stop(sprintf("Cannot save RDS file because a temporary save file already exists: %s", sQuote(pathname_tmp)))
  }
  
  tryCatch({
    saveRDS(object, file = pathname_tmp, ...)
  }, error = function(ex) {
    msg <- conditionMessage(ex)
    msg <- sprintf("saveRDS() failed to save to temporary file %s (%.0f bytes). The reason was: %s",
                   sQuote(pathname_tmp), file.size(pathname_tmp), msg)
    ex$message <- msg
    stop(ex)
  })
  stopifnot(file_test("-f", pathname_tmp))

  file.rename(from = pathname_tmp, to = pathname)
  if (file_test("-f", pathname_tmp) || !file_test("-f", pathname)) {
    msg <- sprintf("save_rds() failed to rename temporary save file %s (%0.f bytes) to %s  (%0.f bytes)", sQuote(pathname_tmp), file.size(pathname_tmp), sQuote(pathname), file.size(pathname))
    stop(msg)
  }
  
  invisible(pathname)
}
