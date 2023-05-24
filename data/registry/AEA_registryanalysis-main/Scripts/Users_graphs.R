###### Set-up ###########
rm(list = ls()) ##Clean up workspace
library(plyr) ##data cleaning
library(dplyr) ##data cleaning
library(purrr) ##data cleaning
library(tidyr) ##data cleaning
library(stringr) ## String cleaning
library(dataverse)
library(ggplot2)
library(qdapRegex)

setwd("~/Documents/AEA_registryanalysis")

#### Functions:
sep_help <- function(col, sep){
  max <- 0
  for (i in 1:length(col)){
    if (is.na(col[i])){
      next
    }
    iter <- str_count(col[i], sep)
    if (iter > max){
      max = iter
    }
    else{
      next
    }
  }
  return(max)
}

sep_ls <- function(col,sep,name){
  num <- sep_help(col,sep)
  num <- num + 1
  nums <- 1:num
  listy <-  paste(name, nums,sep = "")
  return(listy)
}
better_sep <- function(df,col,sep,name){
  names <- sep_ls(col,sep,name)
  str <-deparse(substitute(col))
  co <- sub(".*\\$", "",str)
  new_df <- df %>%
    separate(co, names, sep =sep)
  return(new_df)
}

reshape_long <- function(df, var_name){
  nms <- colnames(df)
  end1 <- str_detect(nms,var_name)
  end <- sum(end1 == TRUE)
  vn <- paste(var_name,"1",sep = "")
  pos <-match(vn, nms)
  pos_min <- pos-1
  nms <- nms[1:pos_min]
  nms <- c(nms, var_name)
  new_df <- data.frame(matrix(ncol= length(nms), nrow = 0))
  colnames(new_df) <- nms
  for (q in 1:nrow(df)){
    iter <- df[q,]
    bool <- sapply(df, is.na)[q,]
    x<-1
    e <- var_name
    for (i in x:end){
      y <- paste(e,i, sep = "")
      if (bool[y] == TRUE){
        break
      }
      else{
        x = x+1
      }
    }
    x = x-1
    df_dup <- iter[rep(seq_len(nrow(iter)), each = x), ]
    df_new <- data.frame(matrix(ncol= length(new_df), nrow = x))
    df_new[,1:pos_min] <- df_dup[,1:pos_min]
    colnames(df_new) <- nms
    j = pos
    for (k in 1:nrow(df_new)){
      res <- as.character(df_dup[k,j])
      df_new[k,pos] = res
      j = j+1
    }
    new_df <- rbind(new_df, df_new)
  }
  return(new_df)
}

## Getting list of dataverse data
## Suggest using file #, as it is the most stable with the dataverse API
aea <- get_dataframe_by_id(file = 6690545, 
                             server = "dataverse.harvard.edu",.f = read.csv, original = T, )
aea <- get_dataset("https://doi.org/10.7910/DVN/TGMJFD")
## This can also be used to pull the dataset, but harvard dataverse's API works more
#frequently with fewer bugs with file ids
#aea <- get_dataframe_by_name(filename ="trials.tab", dataset = https://doi.org/10.7910/DVN/TGMJFD
#                           server = "dataverse.harvard.edu",.f = read.csv, original = T)

#### Making graph of regitered users

## Getting data from 2019 report:
years <- c(2014,2016,2018,2022)
cum_reg_users <- c(744,1778,3472,8355)
df <- data.frame(Year = years, Registered.users = cum_reg_users)

b <- ggplot(data=df, aes(x=Year,y=Registered.users))+
  geom_line(data = subset(df, Year <=2018), aes(y = Registered.users, group = 1), color = "olivedrab4", linetype = 1) +
  geom_line(data = subset(df, Year >=2018), aes(y = Registered.users, group = 1), color = "olivedrab4", linetype = 2) +
  ggtitle("Cumulative registered users") +
  geom_text(y= df$Registered.users,label= df$Registered.users, vjust = -1) +
  labs(y= "", x= "Year") + 
  theme_minimal()
b
ggsave("Output/registered_users.png", b, width = 3, height = 3)

### Getting number of active users:
# Defined by # of PIs with active projects or on registrations that have been updated in the last year

## First getting the right subset
aea_sm <- select(aea, c(Title, Last.update.date,End.date,Primary.Investigator,Other.Primary.Investigators))

aea_sm$Last.update.date <- as.Date(aea_sm$Last.update.date, format = "%B %d, %Y")
aea_sm$End.date <- as.Date(aea_sm$End.date)

today <- Sys.Date()

aea_sm <- filter(aea_sm, End.date >= today | Last.update.date >= "2022-01-01")


### Then we separate out the PIs:
Oth <- select(aea_sm, -c(Primary.Investigator))

Oth <- better_sep(Oth,Oth$Other.Primary.Investigators,"; ","PIs")
Oth_long <- reshape_long(Oth,"PIs")

Prim <- aea_sm %>%
  dplyr::rename(PI = Primary.Investigator) %>%
  select(PI)

Oth <- Oth_long %>%
  dplyr::rename(PI = PIs) %>%
  select(PI)

fin <- rbind(Prim,Oth)

fin$PI <- str_trim(fin$PI)
fin <- filter(fin, PI != "")

fin$PI <- gsub("\\s*\\([^\\)]+\\)","",as.character(fin$PI))

fin$PI <- rm_email(fin$PI)
fin$PI <- str_trim(fin$PI)

fin$PI <- sub("^(\\S*\\s+\\S+).*", "\\1", fin$PI)

fin$PI <- tolower(fin$PI)
fin <- distinct(fin,PI)
fin <- fin[order(fin$PI),]

cat("----------------------")
cat("\n")
cat("The current number of active registered users is:")
cat(nrow(fin))
cat("\n")
cat("----------------------")

