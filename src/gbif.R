#Installing packages 
packages<-c("tidyverse","rgbif","usethis", "CoordinateCleaner", "leaflet", "mapview", "webshot2")
installed_packages<-packages %in% rownames(installed.packages())

if(any(installed_packages==FALSE)){
  install.packages(packages[!installed_packages])
}

library(rgbif)
# Packages loading, with libray function 
invisible(lapply(packages, library, character.only=TRUE))

usethis::edit_r_environ()

fisherBackbone<-name_backbone(name="Pekania pennanti")
speciesKey<-fisherBackbone$usageKey

occ_download(pred("taxonKey", speciesKey), format="SIMPLE_CSV")

# <<gbif download>>
# Your download is being processed by GBIF:
#   https://www.gbif.org/occurrence/download/0022361-240216155721649
# Most downloads finish within 15 min.
# Check status with
# occ_download_wait('0022361-240216155721649')
# After it finishes, use
# d <- occ_download_get('0022361-240216155721649') %>%
#   occ_download_import()
# to retrieve your download.
# Download Info:
#   Username: maggiegiardello
# E-mail: lc21-0528@lclark.edu
# Format: SIMPLE_CSV
# Download key: 0022361-240216155721649
# Created: 2024-02-27T20:59:51.589+00:00
# Citation Info:  
#   Please always cite the download DOI when using this data.
# https://www.gbif.org/citation-guidelines
# DOI: 10.15468/dl.ump7ff
# Citation:
#   GBIF Occurrence Download https://doi.org/10.15468/dl.ump7ff Accessed from R via rgbif (https://github.com/ropensci/rgbif) on 2024-02-27

#
d <- occ_download_get('0022361-240216155721649', path="data/") %>%
  occ_download_import()

write_csv(d, "data/rawData.csv")



#cleaning
fData<-d %>%
  filter(!is.na(decimalLatitude), !is.na(decimalLongitude))

fData<-fData %>%
  filter(countryCode %in% c("US", "CA", "MX"))

fData<-fData %>%
  filter(!basisOfRecord %in% c("FOSSIL_SPECIMEN", "LIVING_SPECIMEN"))

fData<-fData %>%
  cc_sea(lon="decimalLongitude", lat = "decimalLatitude")

#remove duplicates
fData<-fData %>%
  distinct(decimalLongitude, decimalLatitude, speciesKey, datasetKey, .keep_all = TRUE)

#The initial mapping attempt showed a point in Myanmar, that seems to have been miss classified as being in the US
fData<-fData%>%
  filter(decimalLongitude<0)

#one fell swoop:
#cleanData <-d %>%
  #filter(!is.na(decimalLatitude), !is.na(decimalLongitude)) %>%
  #filter(countryCode %in% c("US", "CA", "MX") %>%
           #filter(!basisOfRecord %in% c("FOSSIL_SPECIMEN", "LIVING_SPECIMEN")) %>%
           #cc_sea(lon="decimalLongitude", lat = "decimalLatitude") %>%
           #distinct(decimalLongitude, decimalLatitude, speciesKey, datasetKey, .keep_all = TRUE)
         
write.csv(fData, "data/cleanedData.csv")
         
 