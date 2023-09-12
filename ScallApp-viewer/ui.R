# This is the user-interface definition of a Shiny web application. 
## Load the necessary libraries
library(httr)
library(leaflet)
library(lubridate)
library(marmap)
library(rjson)
library(shiny)
shinyUI(
  fluidPage(
    ## Application title
    titlePanel("ScallApp Data Viewer"),
    ## Page layout with sidebar
    sidebarLayout(
        ## Sidebar includes all user inputs
        sidebarPanel(
          selectInput(
            inputId='category',
            label='Select Data to View',
            choices=c(
              'Gonad Status',
              'Gray Meat',
              'Nematodes',
              'Shell Blisters'
            ),
            selected=NULL,
            multiple=FALSE
          ),
          dateInput(
            inputId = "startdate",
            label = "Start Date",
            format = "yyyy-mm-dd"
          ),
          dateInput(
            inputId = "enddate",
            label = "End Date",
            format="yyyy-mm-dd"
          )
        ),
        ## Main panel includes data displays
        mainPanel(
          leafletOutput(
            outputId = "dataMap"
          )
        )
    )
))
