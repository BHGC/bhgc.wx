SHELL:=/bin/bash

start:
	Rscript -e 'shiny::runApp(bhgc.wx.shiny::noaa_app())'

deploy:
	Rscript -e 'rsconnect::deployApp("inst/apps/noaa/", account=Sys.getenv("SHINYAPPS_ACCOUNT"))'


#update: .FORCE
#	Rscript -e "bhgc.weather::noaa_download_all()"
#	git commit -am "NOAA data updated"
#	git push

.FORCE:


