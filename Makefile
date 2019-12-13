SHELL:=/bin/bash

start:
	Rscript -e 'shiny::runApp(bhgc.wx.shiny::noaa_app())'

deploy:
	Rscript -e "rsconnect::deployApp()"
