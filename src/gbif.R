#Installing packages 
packages<-c("tidyverse","rgbif","usethis", "CoordinateCleaner", "leaflet", "mapview", "webshot2")
installed_packages<-packages %in% rownames(installed.packages())
if(any(installed_packages==FALSE)){
  install.packages(packages[!installed_packages])
}
# Packages loading, with libray function 
invisible(lapply(packages, library, character.only=TRUE))