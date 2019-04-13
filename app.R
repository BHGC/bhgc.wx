library(shiny)
source("utils.R")
source("locations.R")

timezone("America/Los_Angeles")
stopifnot(timezone() == "America/Los_Angeles")

selected_location <- "Ed Levin, CA (1750 ft)"
if (!exists("db")) db <- list()

if (is.null(db[[selected_location]])) {
  location <- locations[[selected_location]]
  url <- noaa_url(lat=location$launch_gps[1], lon=location$launch_gps[2])
  db[[selected_location]] <- read_noaa(url)
}

options(flavor = "narrow")

# Define UI for app that draws a histogram ----
ui <- fluidPage(

  # App title ----
#  tags$head(tags$title(sprintf("NOAA: %s", location$name))),

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
##      htmlOutput("site_description", inline = TRUE), br(),
      htmlOutput("data_source", inline = TRUE), br(),
#      "See also: ", lapply(names(location$seealso), function(name) a(name, href = location$seealso[name])), br(),
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
  output$data_source <- renderUI({
    location <- locations[[input$site]]
    list("Source: ", a("NOAA", href = noaa_url(lat=location$launch_gps[1], lon=location$launch_gps[2], format = "html")), sprintf(" (%s)", as.character(attr(db[[input$site]], "last_updated"), usetz = TRUE)))
  })

  output$wind_direction <- renderPlot({
    if (is.null(db[[input$site]])) {
      location <- locations[[input$site]]
      url <- noaa_url(lat=location$launch_gps[1], lon=location$launch_gps[2])
      db[[input$site]] <<- read_noaa(url)
    }
    ggplot_noaa_wind_direction(db[[input$site]], days = input$days, windows_size = input$dimension)
  })

  output$surface_wind <- renderPlot({
    if (is.null(db[[input$site]])) {
      location <- locations[[input$site]]
      url <- noaa_url(lat=location$launch_gps[1], lon=location$launch_gps[2])
      db[[input$site]] <<- read_noaa(url)
    }
    ggplot_noaa_surface_wind(db[[input$site]], days = input$days, windows_size = input$dimension)
  })
}

shinyApp(ui = ui, server = server)
