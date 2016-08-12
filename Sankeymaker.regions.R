library(networkD3)
library(dplyr)

## Remove scientific notation
options(scipen=999)

# ############# FILE 1 ################
# ## Read data in
# a <- read.csv("regions_sourceofprod.csv")
# str(a)
# a[,1] <- as.character(a[,1])
# a[,2] <- as.character(a[,2])
# a[,3] <- as.numeric(a[,3])
# 
# ## Step 0, make 2 levels
# a[,2] <- paste(">",a[,2],sep="")
# 
# ## Step 1, rename nicely
# names(a) <- c("From","To","Value") 
# 
# # ## And now see what the biggest players are:
# # a %>% filter(Val>100000) -> a
# 
# ## get nodes and edges:
# source("https://gist.githubusercontent.com/mexindian/a77102065c75c69c22216f43cc3761be/raw/466e9702d4896121d76a007ad504afeef0a8f09e/easyModeNodeEdge.R")
# nodesEdges <- easyMode(a,0)
# nodes <- nodesEdges[[1]]
# edges <- nodesEdges[[2]]
# 
# edges$thingie <- sub(' ', '', nodes[edges$from + 1, 'name'])
# 
# ## this bug cost me about 4 hours to find.
# edges <-as.data.frame(edges)
# 
# # Create graph
# c <- sankeyNetwork(Links = edges, Nodes = nodes, 
#               Source = 'from',Target = 'to', Value = 'value', NodeID = 'name',
#               LinkGroup = 'thingie',NodeGroup = NULL, fontSize = 15)
# saveNetwork(c,"sankey.regions_sourceofprod.html",selfcontained = T)
# 
# ############## FILE 2 ##########
# 
# a <- read.csv("interchange_CGIARandCIAT.csv")
# 
# ## Reshape
# library(tidyr)
# b <- gather(data = a,key = X)
# 
# ## Clean a bit, and make second column a destination
# b[,1] <- gsub("\n",".",b[,1])
# b[,2] <- gsub("\n",".",b[,2])
# 
# b[,2] <- paste(">",b[,2],sep="")
# 
# names(b) <- c("From","To","Value") 
# 
# source("https://gist.githubusercontent.com/mexindian/a77102065c75c69c22216f43cc3761be/raw/466e9702d4896121d76a007ad504afeef0a8f09e/easyModeNodeEdge.R")
# nodesEdges <- easyMode(b,0)
# nodes <- nodesEdges[[1]]
# edges <- nodesEdges[[2]]
# 
# edges$thingie <- sub(' ', '', nodes[edges$from + 1, 'name'])
# 
# ## this bug cost me about 4 hours to find.
# edges <-as.data.frame(edges)
# 
# # Create graph
# d <- sankeyNetwork(Links = edges, Nodes = nodes, 
#                    Source = 'from',Target = 'to', Value = 'value', NodeID = 'name',
#                    LinkGroup = 'thingie',NodeGroup = NULL, fontSize = 15)
# saveNetwork(d,"sankey.interchange_CGIARandCIAT.html",selfcontained = T)
# 
# ## Seems to be same to file 1.

####################  Hrm... get my own regions and do the first file ####

library(networkD3)
library(dplyr)
library(xlsx)

## Remove scientific notation
options(scipen=999)

## Read data in
a <- read.xlsx2("ALL_Origincountry-Tocountry_circosfinal_2016_7_7_avannualwgenebank_share.xlsx",1)
str(a)
a[,1] <- as.character(a[,1])
a[,2] <- as.character(a[,2])
a[,3] <- as.character(a[,3])
a[,4] <- as.numeric(a[,4])

## Convert to regions, thanks to AQUASTAT db http://www.fao.org/nr/aquastat
regions <- read.csv("regions.csv",stringsAsFactors = F)
a$from.region <- regions$Region[match(x = a[,1],table = regions$Country)]
a$to.region <- regions$Region[match(x = a[,3],table = regions$Country)]

## Examine what countries did not get a region
bind_rows(
  a %>% filter(is.na(from.region)) %>% select(a=Origin) ,
  a %>% filter(is.na(to.region)) %>% select(a=Recipient)) %>% 
  unique() %>% View

## Hrm... regroup China, the rest of the data can be dropped
a$Origin[grep("[cC]hina",a$Origin)] <- "China"
a$Recipient[grep("[cC]hina",a$Recipient)] <- "China"
a$from.region <- regions$Region[match(x = a[,1],table = regions$Country)]
a$to.region <- regions$Region[match(x = a[,3],table = regions$Country)]

## Just check, what percent of the flow are we losing in NAs?
bind_rows(
  a %>% filter(is.na(from.region)) %>% select(a=Average.no.samples.per.year) ,
  a %>% filter(is.na(to.region)) %>% select(a=Average.no.samples.per.year)) %>% 
  summarize(sum(a))/sum(a$Average.no.samples.per.year)*100

## Rinse and repeat until satisfied, and then remove NAs
a %>% filter(!is.na(from.region)&!is.na(to.region)) -> a

GeneBanks <- unique(a[,2])

## And now create a frame w/ regions only:
a %>% select(Origin=from.region,
             Genebank_country,
             Recipient= to.region,
             Average.no.samples.per.year) -> b

# Step 0, make 3 levels
b[,1] <- paste(b[,1]," >",sep="")
b[,3] <- paste("> ",b[,3],sep="")
b[,2] <- paste(b[,2],"-GeneBank",sep="")


## Step 1, get SOURCE -> Genebank relationships
b %>%
  group_by(Origin,Genebank_country) %>%
  summarize(Val=sum(Average.no.samples.per.year)) -> Source2GB

names(Source2GB)[1:2] <- c("FROM","TO") 

## Step 2, get GB -> Sink
b %>%
  group_by(Genebank_country,Recipient) %>%
  summarize(Val=sum(Average.no.samples.per.year)) -> GB2Sink

names(GB2Sink)[1:2] <- c("FROM","TO") 


## Combine
Boff <- bind_rows(Source2GB,GB2Sink)

# ## And now see what the biggest players are:
# Boff %>% filter(Val>100000) -> Boff


## get nodes and edges:
source("https://gist.githubusercontent.com/mexindian/a77102065c75c69c22216f43cc3761be/raw/466e9702d4896121d76a007ad504afeef0a8f09e/easyModeNodeEdge.R")
nodesEdges <- easyMode(as.data.frame(Boff),0)
nodes <- nodesEdges[[1]]
edges <- nodesEdges[[2]]

edges$thingie <- sub(' ', '', nodes[edges$from + 1, 'name'])

## this bug cost me about 4 hours to find.
edges <-as.data.frame(edges)

# Create graph
e <- sankeyNetwork(Links = edges, Nodes = nodes, 
                   Source = 'from',Target = 'to', Value = 'value', NodeID = 'name',
                   LinkGroup = 'thingie', NodeGroup=NULL,fontSize = 15)
saveNetwork(e,paste("sankey.ALL_Origincountry-Tocountry_circosfinal_2016_7_7_avannualwgenebank_share.html",sep=""),selfcontained = T)


######### And using this same dataset, do a network chart #####
library(visNetwork)

b %>%
  group_by(Origin,Genebank_country) %>%
  summarize(Val=sum(Average.no.samples.per.year)) -> Source2GB

Source2GB$group <- "SourceToGeneBank"
Source2GB$color <- "blue"
names(Source2GB)[1:2] <- c("FROM","TO") 

## Step 2, get GB -> Sink
b %>%
  group_by(Genebank_country,Recipient) %>%
  summarize(Val=sum(Average.no.samples.per.year)) -> GB2Sink

GB2Sink$group <- "GeneBankToSink"
GB2Sink$color <- "red"
names(GB2Sink)[1:2] <- c("FROM","TO") 


## Combine
Boff <- bind_rows(Source2GB,GB2Sink)

## And clean up direction
Boff$FROM <- gsub(" >","",Boff$FROM)
Boff$TO <- gsub("> ","",Boff$TO)
## get nodes
nodes <- data.frame(label=Boff[,1:2] %>% unlist %>% as.character() %>% unique())
nodes$id <- rownames(nodes)
nodes$title <- nodes$label

## And add node largeness By how BIG a source it is:
## (note... we're using SOURCES, not endcountries)
Boff %>% group_by(FROM) %>% summarize(value=sum(Val)) -> nodeBigness
nodeBigness$value <- log(nodeBigness$value)+4
nodes$value <- round(nodeBigness[match(nodes$label,nodeBigness$FROM),2] %>% unlist,0)
nodes$value[is.na(nodes$value)] <- 1

## and match to IDs to make edges
Boff$From1 <- match(Boff$FROM,nodes$label)
Boff$To1 <- match(Boff$TO,nodes$label)

## Clean up into Edges df
Edges <- Boff %>% select(from=From1,to=To1,value=Val,color)

## Too many relationships, set some threshold on edges
Edges %>% filter(value>50000) -> EdgesPlot

# Create graph
# visNetwork(nodes, head(Edges,30)) %>% visEdges(arrows = 'to')
f <- visNetwork(nodes, EdgesPlot) %>% 
  visEdges(arrows = 'to',length = 100)
saveNetwork(f,paste("network.ALL_Origincountry-Tocountry_circosfinal_2016_7_7_avannualwgenebank_share.html",sep=""),selfcontained = T)

