SHELL:=/bin/bash

start: app.R main.R utils.R
	Rscript -e "shiny::runApp()"

deploy:
	Rscript -e "rsconnect::deployApp()"
