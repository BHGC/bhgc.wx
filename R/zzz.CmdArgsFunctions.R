# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Make functions callable from the command line
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#' @importFrom R.utils CmdArgsFunction
noaa_url <- CmdArgsFunction(noaa_url)
update_noaa <- CmdArgsFunction(update_noaa)
read_rds <- CmdArgsFunction(read_rds)
email_body <- CmdArgsFunction(email_body)
make_email <- CmdArgsFunction(make_email)
