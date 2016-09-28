library(networkD3)
library(dplyr)
library(tidyr)
library(xlsx)

# remove scientific notation and omit warning advertisements

options(scipen=999)
options(warn=-1)

# read data in

a <- read.xlsx2("ALL_Origincountry-Tocountry_circosfinal_2016_7_7_avannualwgenebank_share.xlsx", sheetIndex = 1)
str(a)
a[,1] <- as.character(a[,1])
a[,2] <- as.character(a[,2])
a[,3] <- as.character(a[,3])
a[,4] <- as.numeric(as.character(a[,4]))
a[,'Genebank_country'] <- paste(a[,'Genebank_country'], '-GB', sep = '')
GeneBanks <- unique(a[,2])

# loading regional data

countryRegions <- read.xlsx2('Countries_gb_data_regions_2016_6_13_sankey_share.xlsx', 1)

origin <- a %>% inner_join(countryRegions, c('Origin' = 'Country')) %>% select(Country_final, Region_macro_final)
names(origin) <- c('Origin', 'Origin_region')
recipient <- a %>% inner_join(countryRegions, c('Recipient' = 'Country')) %>% select(Country_final, Region_macro_final)
names(recipient) <- c('Recipient', 'Recipient_region')

a <- cbind(origin, recipient, a[,c(2,4)]); rm(origin, recipient)

countryRegions <- a %>% group_by(Origin_region) %>% select(Origin, Origin_region) %>% arrange(Origin_region) %>% unique

# regional calculations

a %>% select(Origin_region, Recipient_region, Genebank_country, Average.no.samples.per.year) -> region
region %>% group_by(Origin_region, Recipient_region, Genebank_country) %>% summarise(sum(Average.no.samples.per.year, na.rm=TRUE)) -> region2; rm(region)
names(region2)[4] <- 'Samples'
region2$Origin_region <- as.character(region2$Origin_region)
region2$Recipient_region <- as.character(region2$Recipient_region)
region2$Genebank_country <- as.character(region2$Genebank_country)
region2$Samples <- as.numeric(region2$Samples)

a$Origin <- as.character(a$Origin)
a$Recipient <- as.character(a$Recipient)
a$Origin[grep(pattern = "Côte d'Ivoire", x = a$Origin, fixed = TRUE)] <- 'Ivory Coast'
a$Recipient[grep(pattern = "Côte d'Ivoire", x = a$Recipient, fixed = TRUE)] <- 'Ivory Coast'

#### =============================================================== ###
#### create sankey to regional level
#### =============================================================== ####

flows <- lapply(1:length(GeneBanks), function(i){
  
  region2 %>% filter(Genebank_country == GeneBanks[i]) -> b
  
  ## Step 1, get SOURCE -> Genebank relationships
  b %>%
    group_by(Origin_region, Genebank_country) %>%
    summarize(Val=sum(Samples)) -> Source2GB
  
  names(Source2GB) <- c('source', 'target', 'value')
  
  ## Step 2, get Genebank -> Sink
  b %>%
    group_by(Genebank_country, Recipient_region) %>%
    summarize(Val=sum(Samples)) -> GB2Sink
  
  names(GB2Sink) <- c('source', 'target', 'value')
  
  ## Combine datasets
  Boff <- bind_rows(as.data.frame(Source2GB), as.data.frame(GB2Sink))
  return(Boff)
  
}); rm(region2)
flows <- do.call(rbind, flows)
write.csv(flows, 'regional_flows.csv', row.names = F)

flows$source[!(flows$source %in% GeneBanks)] <- paste(flows$source[!(flows$source %in% GeneBanks)], ' >', sep = '')
flows$target[!(flows$target %in% GeneBanks)] <- paste('> ', flows$target[!(flows$target %in% GeneBanks)], sep = '')

nodes <- c(flows$source, flows$target) %>% unique %>% sort
lnodes <- length(nodes)
nodes <- data.frame(node=0:(lnodes-1), name=nodes); rm(lnodes)
GeneBanks
nodes$id <- ifelse(test = nodes$name %in% GeneBanks, yes = 1, no = NA)
nodes$id[which(nodes$id==1)] <- gsub(pattern = ' ', replacement = '', x = nodes$name[which(nodes$id==1)])

nodes$id[is.na(nodes$id)] <- gsub(pattern = ' ', replacement = '', x = nodes$name[is.na(nodes$id)])
nodes$id[grep(pattern = '^>[a-zA-Z]', x = nodes$id, fixed = F)] <- paste(gsub(pattern = '>', replacement = '', x = nodes$id[grep(pattern = '^>[a-zA-Z]', x = nodes$id, fixed = F)]), '_in', sep = '')
nodes$id[grep(pattern = '*>$', x = nodes$id, fixed = F)] <- paste(gsub(pattern = '>', replacement = '', x = nodes$id[grep(pattern = '*>$', x = nodes$id, fixed = F)]), '_out', sep = '')

flows_coded <- flows; rm(flows)

for(i in 1:nrow(nodes)) {
  
  flows_coded$source <- gsub(pattern = as.character(nodes$name[i]), replacement = nodes$node[i], x = flows_coded$source, fixed = T)
  flows_coded$target <- gsub(pattern = as.character(nodes$name[i]), replacement = nodes$node[i], x = flows_coded$target, fixed = T)
  
}

flows_coded$source <- as.numeric(flows_coded$source)
flows_coded$target <- as.numeric(flows_coded$target)

write.csv(flows_coded, 'Links_Values.csv', row.names = F)
write.csv(nodes, 'Nodes_Names.csv', row.names = F)

sankeyList <- list(nodes = nodes,
                   links = flows_coded)

# save JSON file
library(jsonlite)
json <- list(nodes=data.frame(name=nodes$name, id=tolower(nodes$id)),
             links=flows_coded)

sink('sankey_draft.json') # redirect console output to a file
toJSON(json, pretty=FALSE)
sink()

s <- sankeyNetwork(Links = sankeyList$links, Nodes = sankeyList$nodes, Source = "source",
                   Target = "target", Value = "value", NodeID = "name",
                   units = "Samples", fontSize = 12, nodeWidth = 30)
s

# identify countries per region and adding to final JSON file

# regions <- countryRegions$Origin_region %>% as.character %>% unique %>% sort
# countryRegions <- lapply(regions, function(z){
#   
#   nodes_id <- nodes$id[grep(pattern = z, x = nodes$name, fixed = F)]
#   countryList <- countryRegions$Origin[countryRegions$Origin_region==z] %>% as.character %>% sort
#   
#   if(length(nodes_id) == 2){
#     return(list(id = nodes_id[1],
#                 countries = countryList,
#                 id = nodes_id[2],
#                 countries = countryList))
#   }
#   
# })
# 
# countryRegions <- do.call(list, unlist(countryRegions, recursive = F))
# length(countryRegions)
# 
# countryRegions2 <- list()
# index <- seq(1, 24, by = 2)
# for(i in 1:length(index)){
#   countryRegions2[[i]] <- list(id = tolower(countryRegions[[index[i]]]),
#                                countries = countryRegions[[index[i]+1]])
# }; rm(i, index)
# 
# # Save JSON file with countries per region
# library(jsonlite)
# json_subgroup <- list(nodes = data.frame(name=nodes$name, id=tolower(nodes$id)),
#                       links = flows_coded,
#                       nodes_subgroup = countryRegions2)
# 
# sink('sankey_draft_subgroup.json') # redirect console output to a file
# toJSON(json_subgroup, pretty=FALSE)
# sink()

#### =============================================================== ###
#### create sub-sankey to country level per region
#### =============================================================== ####

regions <- as.character(nodes$name[grep(pattern = '_out$', x = nodes$id, fixed = F)]) %>% sort

# calcs by region
countryRegions <- lapply(regions, function(z){
  
  nodes_id <- nodes$id[grep(pattern = z, x = nodes$name, fixed = F)]
  
  a %>% filter(Origin_region==gsub(pattern = ' >', replacement = '', x = z, fixed = TRUE)) %>% select(Origin, Recipient_region, Genebank_country, Average.no.samples.per.year) -> country
  country %>% group_by(Origin, Recipient_region, Genebank_country) %>% summarise(sum(Average.no.samples.per.year, na.rm=TRUE)) -> country2; rm(country)
  names(country2)[4] <- 'Samples'
  country2$Origin <- as.character(country2$Origin)
  country2$Recipient_region <- as.character(country2$Recipient_region)
  country2$Genebank_country <- as.character(country2$Genebank_country)
  country2$Samples <- as.numeric(country2$Samples)
  
  # calculate flows from country per genebank
  
  cFlows <- lapply(1:length(GeneBanks), function(i){
    
    country2 %>% filter(Genebank_country == GeneBanks[i]) -> b
    
    ## Step 1, get SOURCE -> Genebank relationships
    b %>%
      group_by(Origin, Genebank_country) %>%
      summarize(Val=sum(Samples)) -> Source2GB
    
    names(Source2GB) <- c('source', 'target', 'value')
    
    ## Step 2, get Genebank -> Sink
    b %>%
      group_by(Genebank_country, Recipient_region) %>%
      summarize(Val=sum(Samples)) -> GB2Sink
    
    names(GB2Sink) <- c('source', 'target', 'value')
    
    ## Combine datasets
    Boff <- bind_rows(as.data.frame(Source2GB), as.data.frame(GB2Sink))
    return(Boff)
    
  }); rm(country2)
  cFlows <- do.call(rbind, cFlows)
  
  cFlows$source[!(cFlows$source %in% GeneBanks)] <- paste(cFlows$source[!(cFlows$source %in% GeneBanks)], ' >', sep = '')
  cFlows$target[!(cFlows$target %in% GeneBanks)] <- paste('> ', cFlows$target[!(cFlows$target %in% GeneBanks)], sep = '')
  
  cNodes <- c(cFlows$source, cFlows$target) %>% unique %>% sort
  lcNodes <- length(cNodes)
  cNodes <- data.frame(node=0:(lcNodes-1), name=cNodes); rm(lcNodes)
  cNodes$id <- ifelse(test = cNodes$name %in% GeneBanks, yes = 1, no = NA)
  cNodes$id[which(cNodes$id==1)] <- gsub(pattern = ' ', replacement = '', x = cNodes$name[which(cNodes$id==1)])
  
  cNodes$id[is.na(cNodes$id)] <- gsub(pattern = ' ', replacement = '', x = cNodes$name[is.na(cNodes$id)])
  cNodes$id[grep(pattern = '^>[a-zA-Z]', x = cNodes$id, fixed = F)] <- paste(gsub(pattern = '>', replacement = '', x = cNodes$id[grep(pattern = '^>[a-zA-Z]', x = cNodes$id, fixed = F)]), '_in', sep = '')
  cNodes$id[grep(pattern = '*>$', x = cNodes$id, fixed = F)] <- paste(gsub(pattern = '>', replacement = '', x = cNodes$id[grep(pattern = '*>$', x = cNodes$id, fixed = F)]), '_out', sep = '')
  
  cFlows_coded <- cFlows#; rm(cFlows)
  
  for(i in 1:nrow(cNodes)) {
    
    cFlows_coded$source <- gsub(pattern = paste('^', as.character(cNodes$name[i]), sep = ''), replacement = cNodes$node[i], x = cFlows_coded$source, fixed = FALSE)
    cFlows_coded$target <- gsub(pattern = paste('^', as.character(cNodes$name[i]), sep = ''), replacement = cNodes$node[i], x = cFlows_coded$target, fixed = FALSE)
    
  }
  
  cFlows_coded$source <- as.numeric(cFlows_coded$source)
  cFlows_coded$target <- as.numeric(cFlows_coded$target)
  
  # Falkland Islands (Malvinas) case
  cFlows_coded[!complete.cases(cFlows_coded),'source'] <- cNodes$node[grep(pattern = 'Falkland Islands (Malvinas)', x = cNodes$name, fixed = TRUE)]
  
  subsankey <- list(id = tolower(nodes_id),
                    sankey = list(nodes = data.frame(name=cNodes$name, id=tolower(cNodes$id)),
                                  links = cFlows_coded)
                    )
  
  return(subsankey)
  
})

# save JSON file
library(jsonlite)
cJson <- list(nodes = data.frame(name = nodes$name, id = tolower(nodes$id)),
              links = flows_coded,
              subSankey = countryRegions)

sink('sankey_draft_subSankey_corrected.json') # redirect console output to a file
toJSON(cJson, pretty=FALSE)
sink()

#### =============================================================== ###
#### create sub-sankey to country level per region in-out schema
#### =============================================================== ####

regions2 <- as.character(nodes$name[grep(pattern = '_in$', x = nodes$id, fixed = F)]) %>% sort

# calcs by region
countryRegions2 <- lapply(regions2, function(z){
  
  nodes_id <- nodes$id[grep(pattern = z, x = nodes$name, fixed = F)]
  
  a %>% filter(Recipient_region==gsub(pattern = '> ', replacement = '', x = z, fixed = TRUE)) %>% select(Origin_region, Recipient, Genebank_country, Average.no.samples.per.year) -> country
  country %>% group_by(Origin_region, Recipient, Genebank_country) %>% summarise(sum(Average.no.samples.per.year, na.rm=TRUE)) -> country2; rm(country)
  names(country2)[4] <- 'Samples'
  country2$Origin_region <- as.character(country2$Origin_region)
  country2$Recipient <- as.character(country2$Recipient)
  country2$Genebank_country <- as.character(country2$Genebank_country)
  country2$Samples <- as.numeric(country2$Samples)
  
  # calculate flows from country per genebank
  
  cFlows <- lapply(1:length(GeneBanks), function(i){
    
    country2 %>% filter(Genebank_country == GeneBanks[i]) -> b
    
    ## Step 1, get SOURCE -> Genebank relationships
    b %>%
      group_by(Origin_region, Genebank_country) %>%
      summarize(Val=sum(Samples)) -> Source2GB
    
    names(Source2GB) <- c('source', 'target', 'value')
    
    ## Step 2, get Genebank -> Sink
    b %>%
      group_by(Genebank_country, Recipient) %>%
      summarize(Val=sum(Samples)) -> GB2Sink
    
    names(GB2Sink) <- c('source', 'target', 'value')
    
    ## Combine datasets
    Boff <- bind_rows(as.data.frame(Source2GB), as.data.frame(GB2Sink))
    return(Boff)
    
  }); rm(country2)
  cFlows <- do.call(rbind, cFlows)
  
  cFlows$source[!(cFlows$source %in% GeneBanks)] <- paste(cFlows$source[!(cFlows$source %in% GeneBanks)], ' >', sep = '')
  cFlows$target[!(cFlows$target %in% GeneBanks)] <- paste('> ', cFlows$target[!(cFlows$target %in% GeneBanks)], sep = '')
  
  cNodes <- c(cFlows$source, cFlows$target) %>% unique %>% sort
  lcNodes <- length(cNodes)
  cNodes <- data.frame(node=0:(lcNodes-1), name=cNodes); rm(lcNodes)
  cNodes$id <- ifelse(test = cNodes$name %in% GeneBanks, yes = 1, no = NA)
  cNodes$id[which(cNodes$id==1)] <- gsub(pattern = ' ', replacement = '', x = cNodes$name[which(cNodes$id==1)])
  
  cNodes$id[is.na(cNodes$id)] <- gsub(pattern = ' ', replacement = '', x = cNodes$name[is.na(cNodes$id)])
  cNodes$id[grep(pattern = '^>[a-zA-Z]', x = cNodes$id, fixed = F)] <- paste(gsub(pattern = '>', replacement = '', x = cNodes$id[grep(pattern = '^>[a-zA-Z]', x = cNodes$id, fixed = F)]), '_in', sep = '')
  cNodes$id[grep(pattern = '*>$', x = cNodes$id, fixed = F)] <- paste(gsub(pattern = '>', replacement = '', x = cNodes$id[grep(pattern = '*>$', x = cNodes$id, fixed = F)]), '_out', sep = '')
  
  cFlows_coded <- cFlows#; rm(cFlows)
  
  for(i in 1:nrow(cNodes)) {
    
    cFlows_coded$source <- gsub(pattern = paste('^', as.character(cNodes$name[i]), '$', sep = ''), replacement = cNodes$node[i], x = cFlows_coded$source, fixed = FALSE)
    cFlows_coded$target <- gsub(pattern = paste('^', as.character(cNodes$name[i]), '$', sep = ''), replacement = cNodes$node[i], x = cFlows_coded$target, fixed = FALSE)
    
  }
  
  cFlows_coded$source <- as.numeric(cFlows_coded$source)
  cFlows_coded$target <- as.numeric(cFlows_coded$target)
  
  # Falkland Islands (Malvinas) case
  # cFlows_coded[!complete.cases(cFlows_coded),'source'] <- cNodes$node[grep(pattern = 'Falkland Islands (Malvinas)', x = cNodes$name, fixed = TRUE)]
  
  subsankey <- list(id = tolower(nodes_id),
                    sankey = list(nodes = data.frame(name=cNodes$name, id=tolower(cNodes$id)),
                                  links = cFlows_coded)
  )
  
  return(subsankey)
  
})

all <- c(countryRegions, countryRegions2)

# save JSON file
library(jsonlite)
cJson <- list(nodes = data.frame(name = nodes$name, id = tolower(nodes$id)),
              links = flows_coded,
              subSankey = all)

sink('sankey_draft_subSankey_corrected2.json') # redirect console output to a file
toJSON(cJson, pretty=FALSE)
sink()
