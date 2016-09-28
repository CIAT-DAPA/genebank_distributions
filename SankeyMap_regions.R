library(tidyr)
library(dplyr)
library(xlsx)

## Remove scientific notation
options(scipen = 999); options(warn = -1)

## Read data in
a <- read.xlsx2("ALL_Origincountry-Tocountry_circosfinal_2016_7_7_avannualwgenebank_share.xlsx",1)
str(a)
a[,1] <- as.character(a[,1])
a[,2] <- as.character(a[,2])
a[,3] <- as.character(a[,3])
a[,4] <- as.numeric(as.character(a[,4]))

GeneBanks <- a[,2] %>% unique
# # Step 0, make 3 levels
# a[,1] <- paste(a[,1]," >",sep="")
# a[,3] <- paste("> ",a[,3],sep="")

## Step 1, get SOURCE -> Genebank relationships
a %>%
  group_by(Origin,Genebank_country) %>%
  summarize(Val=sum(Average.no.samples.per.year)) -> Source2GB

names(Source2GB)[1:2] <- c("From","To") 

## Step 2, get GB -> Sink
a %>%
  group_by(Genebank_country,Recipient) %>%
  summarize(Val=sum(Average.no.samples.per.year)) -> GB2Sink

names(GB2Sink)[1:2] <- c("From","To") 

######### OK, do it ##########
BofoDem <- list(Source2GB=Source2GB,GB2Sink=GB2Sink)

i=1

plotlyTest <- lapply(1:length(BofoDem), function(i){
  
  b <- BofoDem[[i]]
  
  ## Harvest nodes
  nodes <- data.frame(name=b[,1:2] %>% unlist %>% as.character() %>% unique())
  
  ## Ok, now add coordinates by geocoding. 
  ## Step 1: Run the following:
  # paste(unlist(a[,1:3]) %>% unique(),collapse="\r") %>% write.table("clipboard")
  ## Step 2: Paste results in input box for http://www.findlatitudeandlongitude.com/batch-geocode/, 
  ## get back results and save them in coords.csv
  coords <- read.csv("coords.csv")
  
  bof <- coords[coords$original.address %in% nodes$name,]
  names(bof)[1] <- "name"
  
  ## OK, now build the df to plot
  b$fromLat <- bof$latitude[match(b$From,bof$name)]
  b$fromLon <- bof$longitude[match(b$From,bof$name)]
  b$toLat <- bof$latitude[match(b$To,bof$name)]
  b$toLon <- bof$longitude[match(b$To,bof$name)]
  
  ##### OK, Start thinking about plotting! Use this awesome guide: http://personal.tcu.edu/kylewalker/interactive-flow-visualization-in-r.html
  ## But first, I have to remove flows to self, since these show up as a line across map:
  df <- b[b$From != b$To,]
  df <- df %>% filter(!is.na(toLon)&!is.na(fromLon))
  
  ## Map regions to FROM (or TO nodes)
  regions <- read.csv("regions.csv",stringsAsFactors = F)
  df$regions <- regions$Region[match(df$From,regions$Country)]
  ##################### Approach one, plot on 2-d plot. Meh... crossing time-line makes it ugly and messy ##################### 
  library(plotly)
  library(nycflights13)
  library(dplyr)
  
  viz <- ggplot(df) + borders("world", fill='black', colour = "black") + coord_equal()
  viz <- viz + geom_segment(data = df, alpha = .1, aes(x = fromLon, y = fromLat, xend = toLon, yend = toLat, size=Val, colour=To), arrow = arrow(length = unit(0.13, "npc"))) + theme_bw()
  viz <- viz + guides(colour = FALSE) + guides(size = FALSE)
  
  return(viz)
  
})
plotlyTest[[2]]

## Calculate centroids of each continent
# shapeContinents <- shapefile('./continents/continents.shp')
# centroids       <- list()
# tablas_centroids <- list()
# 
# centroids               <- getSpPPolygonsLabptSlots(shapeContinents)
# tablas_centroids        <- as.data.frame(centroids)
# names(tablas_centroids) <- c("Lon", "Lat")
# 
# tablas_centroids$Continet <- shapeContinents@data$CONTINENT
# write.csv(tablas_centroids, './continents/coordinates_continents.csv', row.names = F)
# 
# shapeCoordinates <- shapefile('./continents/coordinates_continent.shp')
# write.csv(shapeCoordinates@data, './continents/coordinates_continents_fixed.csv', row.names = F)

#############################################################################################################################
# GEO-JSON maker
#############################################################################################################################

flows <- lapply(1:length(BofoDem), function(i){
  
  b <- BofoDem[[i]]
  
  ## Harvest nodes
  nodes <- data.frame(name=b[,1:2] %>% unlist %>% as.character() %>% unique())
  
  ## Ok, now add coordinates by geocoding. 
  ## Step 1: Run the following:
  # paste(unlist(a[,1:3]) %>% unique(),collapse="\r") %>% write.table("clipboard")
  ## Step 2: Paste results in input box for http://www.findlatitudeandlongitude.com/batch-geocode/, 
  ## get back results and save them in coords.csv
  coords <- read.csv("coords.csv")
  
  bof <- coords[coords$original.address %in% nodes$name,]
  names(bof)[1] <- "name"
  
  ## OK, now build the df to plot
  b$fromLat <- bof$latitude[match(b$From,bof$name)]
  b$fromLon <- bof$longitude[match(b$From,bof$name)]
  b$toLat <- bof$latitude[match(b$To,bof$name)]
  b$toLon <- bof$longitude[match(b$To,bof$name)]
  
  ##### OK, Start thinking about plotting! Use this awesome guide: http://personal.tcu.edu/kylewalker/interactive-flow-visualization-in-r.html
  ## But first, I have to remove flows to self, since these show up as a line across map:
  df <- b[b$From != b$To,]
  df <- df %>% filter(!is.na(toLon)&!is.na(fromLon))
  
  ## Map regions to FROM (or TO nodes)
  regions <- read.csv("regions.csv",stringsAsFactors = F)
  df$regions <- regions$Region[match(df$From,regions$Country)]
  
  ## Continent coordinates
  regionsVal <- as.data.frame(df %>% group_by(regions) %>% summarise(sum(Val)))
  regionsVal <- regionsVal[complete.cases(regionsVal),]; rownames(regionsVal) <- 1:nrow(regionsVal); colnames(regionsVal)[2] <- 'sum'
  regionsVal$sum <- regionsVal$sum/1000000
  aux <- read.csv('./continents/coordinates_continents_fixed.csv')
  regionsVal <- inner_join(regionsVal, aux, by=c('regions'='Continet')); rm(aux)
  
  ## GeneBank coordinates
  if(i==1){
    genebankVal <- as.data.frame(df[complete.cases(df),] %>% group_by(To) %>% summarise(sum(Val)))
    colnames(genebankVal) <- c('genebank', 'sum')
    genebankVal$sum <- genebankVal$sum/1000000
    aux <- unique(df[,c("To", "toLat", "toLon")])
    genebankVal <- inner_join(genebankVal, aux, by=c('genebank'='To')); rm(aux)
  } else {
    if(i==2){
      genebankVal <- as.data.frame(df[complete.cases(df),] %>% group_by(From) %>% summarise(sum(Val)))
      colnames(genebankVal) <- c('genebank', 'sum')
      genebankVal$sum <- genebankVal$sum/1000000
      aux <- unique(df[,c("From", "toLat", "toLon")])
      genebankVal <- inner_join(genebankVal, aux, by=c('genebank'='From')); rm(aux)
    }
  }
  
  df_regions <- df %>% select(regions, To, fromLon, fromLat, toLon, toLat)
  colnames(df_regions)[1] <- 'From'
  df_regions <- df_regions[complete.cases(df_regions),]; df_regions[, c("fromLat", "fromLon")] <- NA
  df_regions <- unique(df_regions)
  
  df_regions$fromLon[grep(pattern = 'Asia', x = df_regions$From, fixed = TRUE)] <- regionsVal$Lon[3]
  df_regions$fromLat[grep(pattern = 'Asia', x = df_regions$From, fixed = TRUE)] <- regionsVal$Lat[3]
  
  df_regions$fromLon[grep(pattern = 'Europe', x = df_regions$From, fixed = TRUE)] <- regionsVal$Lon[4]
  df_regions$fromLat[grep(pattern = 'Europe', x = df_regions$From, fixed = TRUE)] <- regionsVal$Lat[4]
  
  df_regions$fromLon[grep(pattern = 'Africa', x = df_regions$From, fixed = TRUE)] <- regionsVal$Lon[1]
  df_regions$fromLat[grep(pattern = 'Africa', x = df_regions$From, fixed = TRUE)] <- regionsVal$Lat[1]
  
  df_regions$fromLon[grep(pattern = 'Americas', x = df_regions$From, fixed = TRUE)] <- regionsVal$Lon[2]
  df_regions$fromLat[grep(pattern = 'Americas', x = df_regions$From, fixed = TRUE)] <- regionsVal$Lat[2]
  
  df_regions$fromLon[grep(pattern = 'Oceania', x = df_regions$From, fixed = TRUE)] <- regionsVal$Lon[5]
  df_regions$fromLat[grep(pattern = 'Oceania', x = df_regions$From, fixed = TRUE)] <- regionsVal$Lat[5]
  
  ## Save GeoJSON file
  sink(paste("./map_genebank_test_lp_region_v", i, ".json",sep=""))
  
  cat('{')
  cat('"RegionsDensity": {')
  cat('"type": "FeatureCollection",')
  cat('"features": [')
  for(j in 1:nrow(regionsVal)){
    # [lon, lat]
    cat('{ "type": "Feature", "geometry": { "type": "Point", "coordinates": [ ', regionsVal$Lon[j], ', ', regionsVal$Lat[j], '] }, "properties": { "radio": ', regionsVal$sum[j], ' } },')
    if(j == nrow(regionsVal)){
      # [lon, lat]
      cat('{ "type": "Feature", "geometry": { "type": "Point", "coordinates": [ ', regionsVal$Lon[j], ', ', regionsVal$Lat[j], ' ] }, "properties": { "radio": ', regionsVal$sum[j], ' } }')
    }
  }; rm(j)
  cat(']')
  cat('},')
  cat('"GenebankDensity": {')
  cat('"type": "FeatureCollection",')
  cat('"features": [')
  for(j in 1:nrow(genebankVal)){
    # [lon, lat]
    cat('{ "type": "Feature", "geometry": { "type": "Point", "coordinates": [ ', genebankVal$toLon[j], ', ', genebankVal$toLat[j], '] }, "properties": { "radio": ', genebankVal$sum[j], ' } },')
    if(j == nrow(genebankVal)){
      # [lon, lat]
      cat('{ "type": "Feature", "geometry": { "type": "Point", "coordinates": [ ', genebankVal$toLon[j], ', ', genebankVal$toLat[j], ' ] }, "properties": { "radio": ', genebankVal$sum[j], ' } }')
    }
  }; rm(j)
  cat(']')
  cat('},')
  cat('"RegionsCoords":{')
  cat('"type": "FeatureCollection",')
  cat('"features": [')
  for(j in 1:nrow(df_regions)){
    # [lon, lat]
    cat('{ "type": "Feature", "geometry": { "type": "LineString", "coordinates": [ [ ', df_regions$fromLon[j], ', ', df_regions$fromLat[j], ' ], [ ', df_regions$toLon[j], ', ', df_regions$toLat[j], '] ] } },')
    if(j == nrow(df_regions)){
      # [lon, lat]
      cat('{ "type": "Feature", "geometry": { "type": "LineString", "coordinates": [ [ ', df_regions$fromLon[j], ', ', df_regions$fromLat[j], ' ], [ ', df_regions$toLon[j], ', ', df_regions$toLat[j], '] ] } }')
    }
  }; rm(j)
  cat(']')
  cat('}')
  cat('}')
  
  sink()
  
  return(cat('Done!\n'))
  
})

##################### Approach one, plot on 2-d plot. Meh... crossing time-line makes it ugly and messy ##################### 
library(plotly)
library(nycflights13)
library(dplyr)

# usa_map <- map_data("usa")
world_map <- map_data("world")


ggplot(df)  + geom_map(data=world_map, map=world_map,
                       aes(x=long, y=lat, map_id=region),
                       fill="#000000", color="#000000", size=0.15) +
  # geom_polygon(data = usa_map, aes(long, lat)) +
  geom_curve(data = df, alpha = .1,
             aes(x = fromLon, y = fromLat,
                 xend = toLon, yend = toLat,
                 size=Val, colour=To))

ggplot(df)  + borders("world") + coord_equal() +
  geom_map(data=world_map, map=world_map,
           aes(x=long, y=lat, map_id=region),
           fill="#000000", color="#000000", size=0.15) +
  geom_curve(data = df, alpha = .2,
             aes(x = fromLon, y = fromLat,
                 xend = toLon, yend = toLat,
                 size=Val, colour=To),arrow = arrow(angle = 10,length = unit(0.13, "npc")))
#############################################################################################################################

map1 <- ggplotly(plotlyTest[[1]])
map2 <- ggplotly(plotlyTest[[2]])

p %>% plotly::layout(add_data(map1),
                     add_data(map2),
                     title = "Drop down menus - Styling",
                     xaxis = list(title = "Longitude"),
                     yaxis = list(title = "Latitude"),
                     updatemenus = list(
                       list(
                         y = 40,
                         buttons = list(
                           
                           list(method = "restyle",
                                args = list("type", "map1"),
                                label = "Countries to GeneBanks"),
                           
                           list(method = "restyle",
                                args = list("type", "map2"),
                                label = "GeneBanks to countries")))
                     ))


############## Approach one and a half, plot on 2-d plot. Meh... crossing time-line makes it ugly and messy ###################
library(geosphere)

flows <- gcIntermediate(df[,5:4], df[,7:6],n=20,sp = TRUE, addStartEnd = T,breakAtDateLine=T)
flows$counts <- df$Val/max(df$Val)*10
flows$origins <- df$From
flows$destinations <- df$To

library(leaflet)
library(RColorBrewer)

hover <- paste0(flows$origins, " to ",
                flows$destinations, ': ',
                as.character(round(flows$counts*max(df$Val)/10),1))

pal <- colorFactor(brewer.pal(4, 'Set2'), flows$origins)

leaflet() %>%
  # addProviderTiles('CartoDB.Positron') %>%
  # addProviderTiles('Thunderforest.TransportDark') %>%
  addProviderTiles('Stamen.TonerBackground') %>%
  # addProviderTiles('CartoDB.DarkMatterNoLabels') %>%
  # addProviderTiles('NASAGIBS.ViirsEarthAtNight2012') %>%
  addPolylines(data = flows, weight = ~counts,
               group = ~origins, color = ~pal(origins),popup = ~hover) %>%
  addLayersControl(overlayGroups = unique(flows$origins),
                   options = layersControlOptions(collapsed = T))


library(threejs) # devtools::install_github("bwlewis/rthreejs")
library(RColorBrewer)

names(b) <- c("origins", "destinations", "counts", "latitude.x","longitude.x", "latitude.y",  "longitude.y")

colReference <- data.frame(GB =GeneBanks,
                           col=brewer.pal(length(GeneBanks), 'Dark2'))
if (i==1) b$colors <- colReference$col[match(x = b$destinations,table = colReference$GB)]
if (i==2) b$colors <- colReference$col[match(x = b$origins,table = colReference$GB)]
b$colors <- as.character(b$colors)

## Need to normalize the weights (not that it works anyway... but it works in RStudio :))
weights <- b$counts/10000
weights[weights>10] <- 10

## For Origin -> Gene Bank, show bars to show how MUCH each country is giving. 
##   And for Gene Bank -> Destination, show bars to show how much each country is GETTING
## (probably we can hide this eventually... but useful now to find bugs)
if (i==1) { ##Source2GB
  b$lat.pt <- b$latitude.x
  b$lon.pt <- b$longitude.x
} else{
  b$lat.pt <- b$latitude.y
  b$lon.pt <- b$longitude.y
}

m <- globejs(arcsLwd = weights, arcsHeight = .5,arcs = b[,4:7],
             arcsOpacity=.3,arcsColor = b$colors
             ,lat=b$lat.pt,lon=b$lon.pt,value=weights*10, color = "grey")
# )
visNetwork::visSave(m,paste("globe-",names(BofoDem)[i],".html",sep=""))
# }

