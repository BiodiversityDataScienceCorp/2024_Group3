
library(leaflet)
library(mapview)
library(webshot2)

cleanedData<-read.csv("data/cleanedData.csv")
map<-leaflet()%>%
  addProviderTiles("Esri.WorldTopoMap")%>%
  addCircleMarkers(data=cleanedData,
                   lat= ~decimalLatitude,
                   lng= ~decimalLongitude,
                   radius= 3,
                   color="purple",
                   fillOpacity = 0.8)%>%
  addLegend(position= "topright",
            title= "Species Occurance from GBIF",
            labels= "Pekania pennanti",
            color= "purple",
            opacity= 0)

#The initial mapping attempt gave a point that was not in North America (Myanmar) went back to filtering to filter that point out (it was the only one with a positive longitude)

#to save map
mapshot2(map, file = "output/fisherOccurances.png")
