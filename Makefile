SHELL:=/bin/bash

shellcheck:
	shellcheck inst/bin/*

start:
	Rscript -e 'shiny::runApp(bhgc.wx::noaa_app(), port = 4042L)'

deploy:
	Rscript -e 'devtools::install_github("BHGC/bhgc.wx")'
	Rscript -e 'rsconnect::deployApp("inst/apps/noaa/", account=Sys.getenv("SHINYAPPS_ACCOUNT"))'


#update: .FORCE
#	Rscript -e "bhgc.wx::noaa_download_all()"
#	git commit -am "NOAA data updated"
#	git push

.FORCE:


