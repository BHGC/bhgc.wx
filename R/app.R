#' Creates a NOAA Shiny App
#'
#' @param selected_location (character) ...
#'
#' @param as (character) Whether to return a list or a Shiny App.
#'
#' @return A named list or a Shiny App.
#'
#' @import shiny
#' @importFrom cowplot plot_grid
#' @export
noaa_app <- function(selected_location = "Ed Levin, CA (1750 ft)", as = c("shiny", "list")) {
  as <- match.arg(as)
  
  locations <- noaa_locations()

  timezone("America/Los_Angeles")
  stopifnot(timezone() == "America/Los_Angeles")

  options(flavor = "narrow")

  if (!exists("db")) db <- list()

  if (is.null(db[[selected_location]])) {
    location <- locations[[selected_location]]
    url <- noaa_url(location$launch_gps)
    db[[selected_location]] <- read_noaa(url)
  }

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
        plotOutput(outputId = "wind", height = "500px")
      )
    )
  )
  
  # Define server logic required to draw a histogram ----
  server <- function(input, output, session) {
    observe({
      query <- parseQueryString(session$clientData$url_search)
      site_idx <- query[['site_idx']]
      site_idx <- as.integer(site_idx)
      if (length(site_idx) > 0 && !is.na(site_idx)) {
        value <- names(locations)[site_idx]
        updateTextInput(session, "site", value = value)
      }
    })
  
    output$data_source <- renderUI({
      location <- locations[[input$site]]
      list("Source: ", a("NOAA", href = noaa_url(location$launch_gps, format = "html")), sprintf(" (%s)", as.character(db[[input$site]]$last_updated[1], usetz = TRUE)))
    })
  
    output$wind <- renderPlot({
      if (is.null(db[[input$site]])) {
        location <- locations[[input$site]]
        url <- noaa_url(location$launch_gps)
        db[[input$site]] <<- read_noaa(url)
      }
  
      gg <- ggplot_noaa_wind_direction(db[[input$site]], days = input$days, windows_size = input$dimension)
  #    gg <- gg + xlab("")
  #    gg <- gg + theme(axis.text.x=element_blank(), axis.ticks.x=element_blank())
  #    gg <- gg + scale_x_datetime(position = "top")
      gg1 <- gg
    
      gg2 <- ggplot_noaa_surface_wind(db[[input$site]], days = input$days, windows_size = input$dimension)
  
      theme_set(theme_gray())
  
      res <- plot_grid(gg1, gg2, ncol = 1L, rel_heights = c(1,2), align = "v")
      
      res
    })
  }

  app <- list(ui = ui, server = server)
  
  if (as == "shiny") {
    app <- shinyApp(ui = app$ui, server = app$server)
  }
  
  app
}
