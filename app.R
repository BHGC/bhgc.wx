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

options(flavor = "narrow")

# Define UI for app that draws a histogram ----
ui <- fluidPage(

  # App title ----
  tags$head(tags$title(sprintf("NOAA: %s", location$name))),

  # Sidebar layout with input and output definitions ----
  sidebarLayout(

    # Sidebar panel for inputs ----
    sidebarPanel(
      ## Get windows width and height
      ## Source: https://stackoverflow.com/a/37060206/1072091
      tags$head(tags$script('
                                var dimension = [0, 0];
                                $(document).on("shiny:connected", function(e) {
                                    dimension[0] = window.innerWidth;
                                    dimension[1] = window.innerHeight;
                                    Shiny.onInputChange("dimension", dimension);
                                });
                                $(window).resize(function(e) {
                                    dimension[0] = window.innerWidth;
                                    dimension[1] = window.innerHeight;
                                    Shiny.onInputChange("dimension", dimension);
                                });
                            ')),
    
      strong(sprintf("Site: %s", location$name)), br(),
      "Data: ", a("NOAA Forecast", href = noaa_url(lat=location$lat, lon=location$lon, format = "html")), br(),
      "Last updated: ", as.character(attr(db$values, "last_updated"), usetz = TRUE), br(),
      sliderInput("days", "Forecast: ",
                     min = Sys.Date(), max = Sys.Date() + 7L,
		     value = Sys.Date() + c(0L, 3L),
		     step = 1L,
		     timeFormat = "%a %b %e",
		     round = TRUE,
		     ticks = FALSE)
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
  output$wind_direction <- renderPlot({
    ggplot_noaa_wind_direction(db$values, days = input$days, windows_size = input$dimension)
  })

  output$surface_wind <- renderPlot({
    ggplot_noaa_surface_wind(db$values, days = input$days, windows_size = input$dimension)
  })
}

shinyApp(ui = ui, server = server)
