# scripts for generating current and future Species Distribution Models

#### Start Current SDM ######
# 0. Load packages
source("src/packages.R")

# 1. Get occurrence Data 

# start with our data


occurrenceCoords<-read_csv("data/cleanedData.csv") %>%
  dplyr::select( decimalLongitude, decimalLatitude)


occurrenceSpatialPts <- SpatialPoints(occurrenceCoords, 
                                      proj4string = CRS("+proj=longlat"))


# now get the climate data
# make sure RAM is bumped up


worldclim_global(var="bio", res=2.5, path="data/", version="2.1") 

# update .gitignore to prevent huge files getting pushed to github

#Here are the meanings of the bioclimatic variables (bio1 to bio19) provided by WorldClim:
#bio1: Mean annual temperature
#bio2: Mean diurnal range (mean of monthly (max temp - min temp))
#bio3: Isothermality (bio2/bio7) (* 100)
#bio4: Temperature seasonality (standard deviation *100)
#bio5: Max temperature of warmest month
#bio6: Min temperature of coldest month
#bio7: Temperature annual range (bio5-bio6)
#bio8: Mean temperature of wettest quarter
#bio9: Mean temperature of driest quarter
#bio10: Mean temperature of warmest quarter
#bio11: Mean temperature of coldest quarter
#bio12: Annual precipitation
#bio13: Precipitation of wettest month
#bio14: Precipitation of driest month
#bio15: Precipitation seasonality (coefficient of variation)
#bio16: Precipitation of wettest quarter
#bio17: Precipitation of driest quarter
#bio18: Precipitation of warmest quarter
#bio19: Precipitation of coldest quarter





#Raster stack

climList <- list.files(path = "data/wc2.1_2.5m/", 
                       pattern = ".tif$", 
                       full.names = T)




currentClimRasterStack <- raster::stack(climList)


plot(currentClimRasterStack[[1]]) 


plot(occurrenceSpatialPts, add = TRUE) 




#2. Create pseudo-absence points


mask <- raster(climList[[1]]) 



#didn't zoom map in (point in Myanmar went back to cleanedData to fix, did, but still didn't zoom)
geographicExtent <- extent(x = occurrenceSpatialPts)



set.seed(45) 


backgroundPoints <- randomPoints(mask = mask, 
                                 n = nrow(occurrenceCoords), #same n 
                                 ext = geographicExtent, 
                                 extf = 1.25, # draw a slightly larger area 
                                 warn = 0) 



colnames(backgroundPoints) <- c("longitude", "latitude")


# 3. Convert occurrence and environmental data into format for model

# Data for observation sites (presence and background), with climate data



occEnv <- na.omit(raster::extract(x = currentClimRasterStack, y = occurrenceCoords))


absenceEnv<- na.omit(raster::extract(x = currentClimRasterStack, y = backgroundPoints))



presenceAbsenceV <- c(rep(1, nrow(occEnv)), rep(0, nrow(absenceEnv))) 


presenceAbsenceEnvDf <- as.data.frame(rbind(occEnv, absenceEnv))


# 4. Create Current SDM with maxent


# If you get a Java error, restart R, and reload the packages
pekaniaCurrentSDM <- dismo::maxent(x = presenceAbsenceEnvDf, ## env conditions
                                       p = presenceAbsenceV,   ## 1:presence or 0:absence
                                       path=paste("maxent_outputs"), #maxent output dir 
)                              


# 5. Plot the current SDM with ggplot



predictExtent <- 1.25 * geographicExtent 

geographicArea <- crop(currentClimRasterStack, predictExtent, snap = "in")



pekaniaPredictPlot <- raster::predict(pekaniaCurrentSDM, geographicArea) 



raster.spdf <- as(pekaniaPredictPlot, "SpatialPixelsDataFrame")

pekaniaPredictDf <- as.data.frame(raster.spdf)


wrld <- ggplot2::map_data("world")



xmax <- max(pekaniaPredictDf$x)
xmin <- min(pekaniaPredictDf$x)
ymax <- max(pekaniaPredictDf$y)
ymin <- min(pekaniaPredictDf$y)


ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = pekaniaPredictDf, aes(x = x, y = y, fill = layer)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) +#expand=F fixes margin
  scale_size_area() +
  borders("state") +
  borders("world", colour = "black", fill = NA) + 
  labs(title = "SDM of Pekania pennanti Under Current Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Environmental Suitability")+ 
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5), legend.position = "bottom") 


ggsave("output/pekaniaCurrentSdm.jpg",  width = 8, height = 6)

#### End Current SDM #########


#### Start Future SDM ########


# 6. Get Future Climate Projections

# CMIP6 is the most current and accurate modeling data
# More info: https://pcmdi.llnl.gov/CMIP6/

futureClimateRaster <- cmip6_world("CNRM-CM6-1", "585", "2061-2080", var = "bioc", res=2.5, path="data/cmip6")

# 7. Prep for the model


names(futureClimateRaster)=names(currentClimRasterStack)


geographicAreaFutureC6 <- crop(futureClimateRaster, predictExtent)


# 8. Run the future SDM

pekaniaFutureSDM <- raster::predict(pekaniaCurrentSDM, geographicAreaFutureC6)


# 9. Plot the future SDM


pekaniaFutureSDMDf <- as.data.frame(pekaniaFutureSDM, xy=TRUE)


xmax <- max(pekaniaFutureSDMDf$x)
xmin <- min(pekaniaFutureSDMDf$x)
ymax <- max(pekaniaFutureSDMDf$y)
ymin <- min(pekaniaFutureSDMDf$y)


ggplot() +
  geom_polygon(data = wrld, mapping = aes(x = long, y = lat, group = group),
               fill = "grey75") +
  geom_raster(data = pekaniaFutureSDMDf, aes(x = x, y = y, fill = maxent)) + 
  scale_fill_gradientn(colors = terrain.colors(10, rev = T)) +
  coord_fixed(xlim = c(xmin, xmax), ylim = c(ymin, ymax), expand = F) +
  scale_size_area() +
  borders("state") +
  borders("world", colour = "black", fill = NA) + 
  labs(title = "Future SDM of Pekania pennanti Under CMIP6 Climate Conditions",
       x = "longitude",
       y = "latitude",
       fill = "Env Suitability") +
  theme(legend.box.background=element_rect(),legend.box.margin=margin(5,5,5,5)) 

ggsave("output/pekaniaFutureSdm.jpg",  width = 8, height = 6)


##### END FUTURE SDM ######
