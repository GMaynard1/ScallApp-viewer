## Load the necessary libraries
library(leaflet)
library(lubridate)
library(marmap)
library(shiny)
# Define server logic required for the map
shinyServer(
  function(input, output,session){
    ## Use the start date and end date inputs to form the url for the GET request
    url=reactive({
      req(input$startdate,input$enddate)
      paste0(
        'http://api.ondeckdata.com/get_scallapp?start_date=',
        input$startdate,
        '&end_date=',
        input$enddate
      )
    })
    ## Anytime a new url is formed, download the data and reformat it from a .json
    ## to a data frame, then clear all data where lat or lon = 0
    dat=reactive({
      req(url)
      auth=readLines("../auth.txt")
      response = rawToChar(
        GET(
          url(),
          add_headers(
            Authorization = auth
          )
        )$content
      )
      print(response)
      if(response!="[]\n"){
        json=fromJSON(response)
        data=as.data.frame(json[[1]])
        for(i in 2:length(json)){
          new_row=as.data.frame(json[[i]])
          data=rbind(data,new_row)
        }
        subset(data,data$lat*data$lon!=0)
      } else {
        data.frame(
          lat=0,
          lon=0,
          nematodes=1,
          shell_blister=1,
          gray_meats=1,
          gonad_state="DUMMY"
        )
      }
    })
    ## If a new dataset has been downloaded or a new category has been selected,
    ## subset the data as appropriate
    subdat=reactive({
      req(dat,input$category)
      if(input$category=="Gonad Status"){
        dat()
      } else {
        if(input$category=="Gray Meat"){
          subset(dat(),dat()$gray_meats==1)
        } else {
          if(input$category=="Nematodes"){
            subset(dat(),dat()$nematodes==1)
          } else {
            if(input$category=="Shell Blisters"){
              subset(dat(),dat()$shell_blister==1)
            }
          }
        }
      }
    })
    output$dataMap=renderLeaflet({
      gre_url="https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-green.png"
      gra_url="https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-grey.png"
      gol_url="https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-gold.png"
      red_url="https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-red.png"
      blu_url="https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-blue.png"
      greenIcon=makeIcon(gre_url)
      grayIcon=makeIcon(gra_url)
      goldIcon=makeIcon(gol_url)
      redIcon=makeIcon(red_url)
      blueIcon=makeIcon(blu_url)
      html_legend=paste0(
        "<img src='",
        blu_url,
        "'>developing<br/><img src='",
        gre_url,
        "'>ripe<br/><img src='",
        gol_url,
        "'>spent<br/><img src='",
        gra_url,
        "'>resting"
      )
      if(sum(grepl("DUMMY",subdat()$gonad_state))>0){
        leaflet(subdat()) %>%
          addProviderTiles("Esri.WorldGrayCanvas")%>%
          setView(lng = -71.18, lat = 41.19, zoom = 6)
      } else {
        if(input$category=="Gonad Status"){
          dev=subset(subdat(),subdat()$gonad_state=="Developing")
          res=subset(subdat(),subdat()$gonad_state=="Resting")
          rip=subset(subdat(),subdat()$gonad_state=="Ripe")
          spe=subset(subdat(),subdat()$gonad_state=="Spent")
          leaflet() %>%
            addProviderTiles("Esri.WorldTopoMap")%>%
            setView(lng = -71.18, lat = 41.19, zoom = 6)%>%
            addMarkers(lng=dev$lon,lat=dev$lat,popup=dev$gonad_state)%>%
            addMarkers(lng=rip$lon,lat=rip$lat,popup=rip$gonad_state,icon=greenIcon)%>%
            addMarkers(lng=spe$lon,lat=spe$lat,popup=spe$gonad_state,icon=goldIcon)%>%
            addMarkers(lng=res$lon,lat=res$lat,popup=res$gonad_state,icon=grayIcon)%>%
            addControl(html = html_legend, position = "bottomleft")
        } else {
          leaflet(subdat()) %>%
            addProviderTiles("Esri.WorldTopoMap") %>%
            setView(lng = -71.18, lat = 41.19, zoom = 6) %>%
            addMarkers(lng=~lon,lat=~lat,icon=redIcon)
        }
      }
    })
})
