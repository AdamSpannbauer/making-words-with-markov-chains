library(readxl)
library(dplyr)
library(magrittr)

readxl::excel_sheets("tweets.xlsx")
python = readxl::read_excel("tweets.xlsx",sheet="#python",skip=1) %>%
  filter(!is.na(`Tweet Text`))
rstats = readxl::read_excel("tweets.xlsx",sheet="#rstats",skip=1) %>%
  filter(!is.na(`Tweet Text`))

python$`Tweet Text`
rstats$`Tweet Text`
tweets = c(python$`Tweet Text`,rstats$`Tweet Text`)
utf8tweets = iconv(tweets,to="UTF-8")

letterSets = function(x,n){
  buffer = paste(rep(" ",n),collapse="")
  x = paste0(buffer,x,"^^^")
  o = rep(NA,nchar(x)-n+1)
  for(i in 1:(nchar(x)-n+1)){
    o[i] = substr(x,i,i+n-1)
  }
  o
}

n = 6

set5 = lapply(utf8tweets,letterSets,n=n)
usets = sort(unique(unlist(set5)))
sets = lapply(utf8tweets,letterSets,n=n+1)
characters = strsplit(utf8tweets,"")
ucharacters = sort(unique(c("^",unlist(characters))))
P = matrix(0,nrow=length(usets),ncol=length(ucharacters))
rownames(P) = usets
colnames(P) = ucharacters

splitLastCharacter = function(x){
  return(c(substr(x,1,nchar(x)-1),substr(x,nchar(x),nchar(x))))
}

fullSets = unlist(sets)
fullSets = fullSets[fullSets != paste(rep(" ",n+1),collapse="")]
starting = vapply(fullSets,splitLastCharacter,c(Antecedant = " ",NextLetter = " ")) %>%
  t() %>%
  as.data.frame(stringsAsFactors = F)

counts = starting %>%
  dplyr::group_by(Antecedant,NextLetter) %>%
  dplyr::summarise(n = n()) %>%
  dplyr::ungroup()

locs = as.matrix(counts[,c(1:2)])
P[locs] = counts$n
Pr = P * 1/rowSums(P)

makeTweet = function(n){
  word = paste(rep(" ",n),collapse="")
  state = "j"
  while(state != "^^^"){
    lastSet = substr(word,nchar(word)-n+1,nchar(word))
    nextLetter = sample(ucharacters,1,prob=Pr[lastSet,])
    word = paste0(word,nextLetter)
    state = substr(word,(nchar(word)-2),(nchar(word)))
  }
  substr(word,n+1,(nchar(word)-3))
}

makeTweet = function(n){
  word = paste(rep(" ",n),collapse="")
  state = "j"
  while(state != "^^^"){
    lastSet = substr(word,nchar(word)-n+1,nchar(word))
    nextLetter = sample(ucharacters,1,prob=Pr[lastSet,])
    word = paste0(word,nextLetter)
    state = substr(word,(nchar(word)-2),(nchar(word)))
  }
  result = substr(word,n+1,(nchar(word)-3))
  scores = stringdist::stringdist(result,tweets,method="cosine")
  print(paste0("Most Similar: ",tweets[which.min(scores)]))
  return(result)
}


makeTweet(n)
