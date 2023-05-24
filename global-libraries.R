
####################################
# global libraries used everywhere #
####################################

#mran.date <- "2021-12-01"
#options(repos=paste0("https://cran.microsoft.com/snapshot/",mran.date,"/"))
# 
# Switching from MRAN (source code) to RSPM (binary) reduced build time from 170s to 74s
#
options(repos = c(REPO_NAME = "https://packagemanager.rstudio.com/all/__linux__/focal/2021-12-01+MTo2NjQ1NDU1LDI6NDUyNjIxNTtCRjhCNTA0Mw"))

pkgTest <- function(x)
{
  if (!require(x,character.only = TRUE))
  {
    install.packages(x,dep=TRUE)
    if(!require(x,character.only = TRUE)) stop("Package not found")
  }
  return("OK")
}

pkgTest.github <- function(libname,source,pkgname=libname)
{
  if (!require(libname,character.only = TRUE))
  {
    if ( pkgname == "" ) { pkgname = libname }
    message(paste0("installing from ",source,"/",pkgname))
    remotes::install_github(paste(source,pkgname,sep="/"))
    if(!require(libname,character.only = TRUE)) stop(paste("Package ",x,"not found"))
  }
  return("OK")
}

global.libraries <- c("dplyr","here","tidyr","tibble","stringr","readr",
                      "splitstackshape","digest","remotes","readxl","writexl",
                      "ggplot2","ggthemes","janitor","dataverse")
results <- sapply(as.list(global.libraries), pkgTest)

pkgTest.github("data.table","Rdatatable")

## Non-standard - install of a page with same name
pkgTest.github("stargazer","markwestcott34","stargazer-booktabs")
#install_github("markwestcott34/stargazer-booktabs")

