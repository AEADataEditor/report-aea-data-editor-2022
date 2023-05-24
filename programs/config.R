# ###########################
# CONFIG: parameters affecting processing
# ###########################

## These control whether the external data is downloaded and processed.
process_anon <- TRUE
download_anon <- TRUE

## These define the start (and end) dates for processing of data
firstday <- "2021-12-01"
lastday  <- "2022-11-30"

# ###########################
# CONFIG: define paths and filenames for later reference
# ###########################

# Change the basepath depending on your system

basepath <- here::here()
setwd(basepath)



# for Jira stuff
jira.anon.partial <- file.path("data","jira","anon")
jiraanon <- file.path(basepath,jira.anon.partial)
manual   <- file.path(basepath,"data","manual")
jira.raw <- file.path("data","jira","raw")


# for other stuff
icpsrbase       <- file.path(basepath,"data","icpsr")
icpsr.utilization.date <- "2022-12-07" 
icpsr.utilization.file <- paste0("utilizationReport-",icpsr.utilization.date,".csv")

zenodobase       <- file.path(basepath,"data","zenodo")

# file names
# These need to be updated to reflect latest
jira.anon.name <- file.path(jiraanon,"jira.anon.RDS")
jira.anon.commit   <- "01b56117b4eaa65671f2b60d804cf6b176e1a6ce" # this is the hash from the Git repo
jira.anon.sha256 <- "08b93c4a60d4bf02a4394f37da2ae16880ab89482278f98e74e0f9552c459a8e"
jira.anon.sha512 <- "c8d828bc34bb965a57aab0e4446e0b06b7e55329f0600a4bb8e6d2d75908f4c14340a9f7ea6fe4e6eae103ffdb1d019aab313956be52c6971bf3c89633ecc314"
jira.anon.urlbase <- paste0("https://raw.githubusercontent.com/AEADataEditor/processing-jira-process-data/",jira.anon.commit)

jira.anon.url     <- file.path(jira.anon.urlbase,"data","anon","jira.anon.RDS")
jira.members.url  <- file.path(jira.anon.urlbase,"data","replicationlab_members.txt")
jira.members.name <- file.path(jiraanon,"replicationlab_members.txt")

noncompliance.name <- file.path(jira.raw,"non-compliant-raw.xlsx")
jira.updates.name  <- file.path(jira.raw,"updates-raw.xlsx")

# This file is received from the AEA Editorial Office. It may need some minor formatting changes.
scholarone      <- file.path(basepath,"data","scholarone")
scholarone.file <- "dataEditorReport_20211118-20221117.xlsx"

scholarone.name <- file.path(scholarone,scholarone.file)

scholarone.prev <- "dataEditorReport_20201128-20211127Revised.xlsx"


# The file should have one tab per journal. 07_table4.R will rename journal names accordingly.
# Look for the part that says
# 27: Total Number of Rounds Manuscripts Underwent			
# 28: 
# 29: Total Rounds	Manuscripts	Percentage	
# 30:            1	58	0.79	
# 31:            2	15	0.21	
scholarone.skip  <- 31  # <---- This number should correspond to the lines above "Total Rounds"
scholarone.skip2 <- 44  # <---- This number should correspond to the lines with "Current Round"

scholarone.pskip <- 33 # <---- This is the number in the previous year's file

# local
images   <- file.path(basepath, "images" )
tables   <- file.path(basepath, "tables" )
programs <- file.path(basepath,"programs")
temp     <- file.path(basepath,"data","temp")


# parameters
latexnums.Rda <- file.path(tables,"latexnums.Rda")
latexnums.tex <- file.path(tables,"latexnums.tex")

for ( dir in list(images,tables,programs,temp)){
  if (file.exists(dir)){
  } else {
    dir.create(file.path(dir))
  }
}

set.seed(20201201)


####################################
# global libraries used everywhere #
####################################



## Initialize a file that will be used at the end to write out LaTeX parameters for in-text 
## reference

pkgTest("tibble")
if (file.exists(latexnums.Rda)) {
  print(paste0("File for export to LaTeX found: ",latexnums.Rda))
} else {
  latexnums <- tibble(field="version",value=as.character(date()),updated=date())
  saveRDS(latexnums,latexnums.Rda)
}

update_latexnums <- function(field,value) {
  # should test if latexnums is in memory
  latexnums <- readRDS(latexnums.Rda)
  
  # find out if a field exists
  if ( any(latexnums$field == field) ) {
    message(paste0("Updating existing field ",field))
    latexnums[which(latexnums$field == field), ]$value <- as.character(value)
    latexnums[which(latexnums$field == field), ]$updated <- date()
    #return(latexnums)
  } else {
    message(paste0("Adding new row for field ",field))
    latexnums <- latexnums %>% add_row(field=field,value=as.character(value),updated=date())
    #return(latexnums)
  }
  saveRDS(latexnums,latexnums.Rda)
}

.Last <- function() {
  sessionInfo()
}
