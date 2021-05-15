library(gtrendsR)
library(tidyverse)
library(stringr)

states <- paste0("US-",state.abb) 

##set the keyword of interest you want here
word <- "covid"
 
for (i in 1:50) {
download <- gtrends(keyword = word, geo = states[i], time = "2021-01-01 2021-05-11", onlyInterest = TRUE)

if (i == 1) {
  df <- download[[1]]
}
else {
  df <- rbind(df, download[[1]])
}
}

df$geo <- str_sub(df$geo,4) 
df$geo <- state.name[match(df$geo, state.abb)]
df <- select(df, keyword, date, geo, hits )

write.csv(df,paste(word,"data.csv"))
