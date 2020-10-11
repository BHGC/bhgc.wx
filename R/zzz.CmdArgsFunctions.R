# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Make functions callable from the command line
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#' @importFrom R.utils CmdArgsFunction
noaa_url <- CmdArgsFunction(noaa_url)
update_noaa <- CmdArgsFunction(update_noaa)
read_rds <- CmdArgsFunction(read_rds)

