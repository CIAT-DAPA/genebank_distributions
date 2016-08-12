library(visNetwork)
library(dplyr)
library(xlsx)

## Read data in
a <- read.xlsx2("ALL_Origincountry-Tocountry_circosfinal_2016_7_7_avannualwgenebank_share.xlsx",1)
str(a)
a[,1] <- as.character(a[,1])
a[,2] <- as.character(a[,2])
a[,3] <- as.character(a[,3])
a[,4] <- as.numeric(a[,4])

## Step 0, make 3 levels of nodes from -> genebank -> to
a[,1] <- paste(a[,1]," >",sep="")
a[,3] <- paste("> ",a[,3],sep="")


a %>% filter(Genebank_country=="Canada"|Genebank_country=="United States of America") -> b
## Step 1, get SOURCE -> Genebank relationships
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
Edges <- Boff %>% select(from=From1,to=To1,value=Val,group,color)

## Too many relationships, set some threshold on edges
Edges %>% filter(value>50000) -> EdgesPlot

# Create graph
# visNetwork(nodes, head(Edges,30)) %>% visEdges(arrows = 'to')
visNetwork(nodes, EdgesPlot) %>% visEdges(arrows = 'to',length = 10)
