library(shiny)

source("utils.R")

timezone("America/Los_Angeles")
stopifnot(timezone() == "America/Los_Angeles")

locations <- list(
  ## "https://forecast.weather.gov/MapClick.php?lat=37.461100&lon=-121.864600&FcstType=digitalDWML"
  "Ed Levin, CA (300 ft)" = list(
    name = "Ed Levin, CA (300 ft & 600 ft)",
    seealso = c(
      BHGC = "http://bhgc.org/sites/",
      WindSlammer = "http://router.hang-gliding.com/WindSlammer/"
    ),
    lat=  37.4611,
    lon=-121.8646
  ),

  ## "https://forecast.weather.gov/MapClick.php?lat=37.475389&lon=-121.861305&FcstType=digitalDWML"
  "Ed Levin, CA (1750 ft)" = list(
    name = "Ed Levin, CA (1750 ft)",
    seealso = c(
      BHGC = "http://bhgc.org/sites/",
      WindSlammer = "http://router.hang-gliding.com/WindSlammer/"
    ),
    lat=  37.4754,
    lon=-121.8613
  )
)

selected_location <- "Ed Levin, CA (1750 ft)"
if (!exists("db")) db <- list()

if (is.null(db[[selected_location]])) {
  location <- locations[[selected_location]]
  url <- noaa_url(lat=location$lat, lon=location$lon)
  db[[selected_location]] <- read_noaa(url)
}

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
    
      selectInput("site", "Choose a flying site:", names(locations), selected = selected_location),
      strong(sprintf("Site: %s", location$name)), br(),
      "Source: ", a("NOAA", href = noaa_url(lat=location$lat, lon=location$lon, format = "html")), sprintf("(%s)", as.character(attr(db[[selected_location]], "last_updated"), usetz = TRUE)), br(),
      "See also: ", lapply(names(location$seealso), function(name) a(name, href = location$seealso[name])), br(),
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
    if (is.null(db[[input$site]])) {
      location <- locations[[input$site]]
      url <- noaa_url(lat=location$lat, lon=location$lon)
      db[[input$site]] <<- read_noaa(url)
    }
    ggplot_noaa_wind_direction(db[[input$site]], days = input$days, windows_size = input$dimension)
  })

  output$surface_wind <- renderPlot({
    if (is.null(db[[input$site]])) {
      location <- locations[[input$site]]
      url <- noaa_url(lat=location$lat, lon=location$lon)
      db[[input$site]] <<- read_noaa(url)
    }
    ggplot_noaa_surface_wind(db[[input$site]], days = input$days, windows_size = input$dimension)
  })
}

shinyApp(ui = ui, server = server)
