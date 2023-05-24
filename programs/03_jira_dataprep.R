# Tabulate statistics and make graphs for the AEA data editor report
# Originally written by Harry Son
# 2021-12-30

# Inputs
#   - file.path(jiraanon,"jira.anon.RDS") 
# Outputs


### Load libraries 
### Requirements: have library *here*
source(here::here("global-libraries.R"),echo=TRUE)
source(here::here("programs","config.R"),echo=TRUE)


# Read in data extracted from Jira, anonymized

if ( file.exists(jira.anon.name) ) {
  message("File exists, proceeding.")
} else {
  message("Attempting to download file")
  try(download.file(jira.anon.url,jira.anon.name,mode="wb"))
  if ( file.exists(jira.anon.name) ) {
    message("Download successful, proceeding.")
  } else {
    stop("Download failed. Please investigate")
  }
}

jira.anon <- readRDS(jira.anon.name) 
#
# This should be compared to the published version.
#
jira.test.chksum <- digest(jira.anon,algo="sha256")

if ( jira.test.chksum == jira.anon.sha256) {
  message("SHA256 checksum verified.")
} else {
  stop("SHA256 fails, please verify that you are using the same file. Update config.R if necessary.")
}

# A list of non-issues, typically for information-only
# This code is not robust, and should be changed at some point.
jira.pyear.raw <- jira.anon %>%
  mutate(orig_order = row_number()) %>%
  filter(date_created >= firstday, date_created < lastday) 

jira.pyear <- jira.pyear.raw %>%
  arrange(ticket,date_updated,orig_order) %>%
  # identify only the status changes
  mutate(status_change = if_else(str_detect(Changed.Fields,"Status"),"yes","no")) %>%
  filter(status_change=="yes"|received=="Yes") %>%
  # remove the subtasks
  mutate(subtask_y=ifelse(is.na(subtask),"No",ifelse(subtask!="","Yes",""))) %>%
  filter(subtask_y=="No") %>%
  #filter(Journal != "AEA P&P") %>% ## Removing all P&P  
  # process software and reasons
    cSplit("Software.used",",")  %>%
    mutate(reason1=grepl("Discrepancy",reason.failure, ## 8 reasons for failutre to reproduce
                       fixed = "TRUE"),
         reason2=grepl("Bugs",reason.failure,
                       fixed = "TRUE"),
         reason3=grepl("Insufficient",reason.failure,
                       fixed = "TRUE"),
         reason4=grepl("Software",reason.failure,
                       fixed = "TRUE"),
         reason5=grepl("functional",reason.failure,
                       fixed = "TRUE"),
         reason6=grepl("Data not available",reason.failure,
                       fixed = "TRUE"),
         reason6.1=grepl("Data,not,available",reason.failure,
                         fixed = "TRUE"),
         reason7=grepl("Data missing",reason.failure,
                       fixed = "TRUE"),
         reason7.1=grepl("Data,missing",reason.failure,
                         fixed = "TRUE"),
         reason8=grepl("Code missing",reason.failure,
                       fixed = "TRUE"),
         reason8.1=grepl("Code,missing",reason.failure,
                         fixed = "TRUE")) %>% 
  mutate(reason1=case_when(reason1==TRUE ~ "Discrepancy in Output",
                           TRUE ~ ""),
         reason2=case_when(reason2==TRUE ~ "Bugs in code",
                           TRUE ~ ""),
         reason3=case_when(reason3==TRUE ~ "Insufficient time available to replicator",
                           TRUE ~ ""),
         reason4=case_when(reason4==TRUE ~ "Software not available to replicator",
                           TRUE ~ ""),
         reason5=case_when(reason5==TRUE ~ "Code not functional",
                           TRUE ~ ""),
         reason6=case_when(reason6==T ~ "Data not available",
                           reason6.1==T ~ "Data not available",
                           TRUE ~ ""),
         reason7=case_when(reason7==T ~ "Data missing",
                           reason7.1==T ~ "Data missing",
                           TRUE ~ ""),
         reason8=case_when(reason8==T ~ "Code missing",
                           reason8.1==T ~ "Code missing",
                           TRUE ~ "")) %>%
  select(-reason6.1,-reason7.1,-reason8.1) 

#### Break out of the issues
# not sure we need this
jira.issues.breakout <- jira.pyear %>%
  arrange(desc(row_number())) %>%
  group_by(ticket) %>%
  mutate(status_order =  row_number(), st = "Status") %>%
  mutate(new1 = paste(st, status_order, sep="")) %>%
  select(ticket,Status,new1) %>%
  pivot_wider(names_from = new1, values_from = "Status")

# identifying the list of received tickets
ji <- jira.pyear %>%
  select(ticket,Journal) %>%
  distinct(ticket, .keep_all = TRUE) 

# identifying the list of issues went through alternate workflow
ji_alt <- jira.pyear %>%
  filter(Status == "Alternate"|Status=="Alternate workflow") %>%
  select(ticket) %>%
  distinct() %>%
  mutate(alternate="Yes")

# identifying the list of submitted issues 
jis <- jira.pyear %>%
  filter(Status == "Submitted to MC" & Journal != "AEA P&P") %>%
  select(ticket) %>%
  distinct() %>%
  mutate(submitted="Yes")

# figure out the final status of the issue as of 12/01/

jifstatus <- jira.pyear %>%
  arrange(ticket,date_updated,desc(orig_order)) %>%
  group_by(ticket) %>%
  mutate(within_order=row_number(),
         max_status  = n()) %>%
  filter(max_status == within_order) %>%
  select(ticket,final_status = Status)



# categorize issues: P&P, Submitted, Not yet submitted, Alternate workflow, Others.
jira.issues.breakout.early <- ji %>%  
  left_join(jis,by="ticket") %>%
  left_join(ji_alt,by="ticket") %>%
  transform(submitted=ifelse(is.na(submitted),"No",as.character(submitted)),
            alternate=ifelse(is.na(alternate),"No",as.character(alternate))) %>%
  select(ticket,Journal,submitted,alternate) %>%
  left_join(jifstatus, by="ticket") 

# we now use the override file, if there is one, to correct some values
# before classifiying further



if (!file.exists(file.path(temp,"jira.others.xlsx")) ) {
  message("File not found. Run through this code once, then read instructions.")
  jira.issues.breakout.late <- jira.issues.breakout.early
} else {
  message("File exists, proceeding.")
  jira.override <- read_excel(file.path(temp,"jira.others.xlsx"),
                              sheet="override")
  jira.issues.breakout.late <- jira.issues.breakout.early %>%
    left_join(jira.override,by="ticket",suffix = c("",".override")) %>%
    mutate(submitted = if_else(!is.na(submitted != submitted.override),
                               submitted.override,submitted),
           alternate = if_else(!is.na(alternate != alternate.override),
                               alternate.override,alternate),
           final_status = if_else(!is.na(final_status != final_status.override),
                               final_status.override,final_status))
}

jira.issues.breakout <- jira.issues.breakout.late %>%
  # collapse outcomes
  transform(outcome=case_when(
                    submitted == "Yes" ~ "Submitted",
                    final_status %in% c("Open","Assigned","In Progress",
                                        "Code","Data",
                                           "Report Under Review","Write Preliminary Report",
                                           "Verification","Pre-Approved","Approved","Data",
                                           "Waiting for info","Waiting for external report",
                                           "Writing Report") ~ "Not yet submitted",
                    final_status %in% c("Incomplete","Blocked") ~ "Incomplete",
                    alternate=="Yes" ~ "Alternate",
                    TRUE ~ "Others"))  

# summarize the breakdown of the cases
summary.breakout <- jira.issues.breakout %>%  
  group_by(outcome) %>%
  summarise(n_outcome = n_distinct(ticket)) 

## separate the "Others" case
jira.others <- jira.issues.breakout %>%
  filter(outcome=="Others"|outcome=="Alternate") 

# we will need it again

## filter out the "others" case
## Actually let's not - what we would need is to see if we obtained the case 
## from the editorial office - don't have a good way to flag source right now
## Parsing of title might work.

#jira.pyear <- jira.pyear %>%
#  left_join(jira.others,by="ticket") %>%
#  transform(others=ifelse(is.na(others),"No",as.character(others))) %>%
#  filter(others=="No") 

# This filters for the cases **submitted** in the past 12 months
issues_all <- jira.pyear %>%
  filter(!(Journal=="")) %>%
  select(ticket) %>%
  distinct() %>% nrow()

manuscript_all <- jira.pyear %>%
  filter(!(Journal=="")) %>%
  select(mc_number_anon) %>% 
  distinct() %>% nrow()

## Total submitted records


jira.filter.submitted <- jira.pyear %>%  
  filter(Status == "Submitted to MC" & Journal != "AEA P&P") 

# we will re-use these 
saveRDS(jira.pyear,file=file.path(temp,"jira.pyear.RDS"))
saveRDS(jira.filter.submitted,file=file.path(temp,"jira.submitted.RDS"))
saveRDS(jira.issues.breakout ,file=file.path(temp,"jira.breakout.RDS"))
saveRDS(jira.others,file=file.path(temp,"jira.others.RDS"))

# this file will be used to revise the flow above. 
# Copy the sheet "output" to a sheet"override", edit, and then run this code again.

if (file.exists(file.path(temp,"jira.others.xlsx")) ) {
  message("File found. Preserving overrides, then read instructions.")
  override <- read_excel(path=file.path(temp,"jira.others.xlsx"),
                         sheet="override")
} else {
  # file doesn't exist, we instantiate the override sheet with the 
  # current list
  override <- jira.others
}
# now write the file.
  write_xlsx(list(output=jira.others,override=override),
           path=file.path(temp,"jira.others.xlsx"))


# we used the start and end date here, so write them out
update_latexnums("firstday",firstday)
update_latexnums("lastday",lastday)
#update_latexnums("jiraissues",issues_all)
#update_latexnums("jiramcs",manuscript_all)

