library(shiny)
source("utils.R")

timezone("America/Los_Angeles")
stopifnot(timezone() == "America/Los_Angeles")

## "https://forecast.weather.gov/MapClick.php?lat=37.461100&lon=-121.864600&FcstType=digitalDWML"
location <- list(
  name = "Ed Levin, CA",
  lat=37.4611,
  lon=-121.8646
)

url <- noaa_url(lat=location$lat, lon=location$lon)

if (!exists("db")) db <- list()
if (is.null(db$values)) db$values <- read_noaa(url)

# Define UI for app that draws a histogram ----
ui <- fluidPage(

  # App title ----
  tags$head(tags$title(sprintf("NOAA: %s", location$name))),

  # Sidebar layout with input and output definitions ----
  sidebarLayout(

    # Sidebar panel for inputs ----
    sidebarPanel(
      strong(sprintf("Site: %s", location$name)), br(),
      "Data: ", a("NOAA Forecast", href = noaa_url(lat=location$lat, lon=location$lon, format = "html")), br(),
      "Last updated: ", as.character(attr(db$values, "last_updated"), usetz = TRUE), br(),
      sliderInput("ndays", "Days ahead: ",
                     min = 1L, max = 8L, value = 3L,
		     step = 1L, round = TRUE)
    ),

    # Main panel for displaying outputs ----
    mainPanel(    
      plotOutput(outputId = "wind_direction", height = "300px"),
      plotOutput(outputId = "surface_wind", height = "300px")
    )
  )
)

# Define server logic required to draw a histogram ----
server <- function(input, output) {

  # Histogram of the Old Faithful Geyser Data ----
  # with requested number of bins
  # This expression that generates a histogram is wrapped in a call
  # to renderPlot to indicate that:
  #
  # 1. It is "reactive" and therefore should be automatically
  #    re-executed when inputs (input$bins) change
  # 2. Its output type is a plot
  output$wind_direction <- renderPlot({
    ggplot_noaa_wind_direction(db$values, ndays = input$ndays)
  })

  output$surface_wind <- renderPlot({
    ggplot_noaa_surface_wind(db$values, ndays = input$ndays)
  })
}

shinyApp(ui = ui, server = server)
