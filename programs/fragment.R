# fragments


# Get an intermediate file
jira.others <- readRDS(file.path(temp,"jira.others.RDS"))

# Read in data extracted from Jira, anonymized
# 

if ( file.exists(jira.anon.name) ) {
  message("File exists, proceeding.")
} else {
  stop("Go to previous step to download file")
}

jira.anon <- readRDS(jira.anon.name) 

#  We capture those where the transition is from "pending publication"  to "done" at some point

# diagnostics
table(jira.anon$Status)

# 
jira.publish <-  jira.anon %>%
  filter(date_created >= firstday, date_created < lastday) %>%
  cSplit("Changed.Fields",",")  %>%
  mutate(status_change = ifelse(Changed.Fields_1=="Status","Yes",ifelse(Changed.Fields_2=="Status","Yes",ifelse(Changed.Fields_3=="Status","Yes",ifelse(Changed.Fields_4=="Status","Yes","No"))))) %>%
  filter(status_change=="Yes"|received=="Yes") %>%
  mutate(subtask_y=ifelse(is.na(subtask),"No",ifelse(subtask!="","Yes",""))) %>%
  filter(subtask_y=="No") %>%
  filter(Journal != "") %>%
  left_join(jira.others,by="ticket") %>%
  transform(others=ifelse(is.na(others),"No",as.character(others))) %>%
  filter(others=="No") %>%
  transform(pending_pub = ifelse(Status %in% c("Assess openICPSR changes","Pending publication","Pending Article DOI"),1,0),
            pending_author = ifelse(Status %in% c("Pending openICPSR changes"),1,0),
            done = ifelse(Status %in% c("Done","Processing publication"),1,0)) %>%
  group_by(mc_number_anon) %>%
  mutate(pending_pub = max(pending_pub), 
         pending_author = max(pending_author),
         done = max(done)) %>%
  select(ticket, mc_number_anon,Journal,pending_pub, pending_author,done) %>%
  # This filter will capture all those that were *ever* pending_pub and are also "done"
  filter(pending_pub==1&done==1) %>%
  distinct(mc_number_anon, .keep_all=TRUE)  %>%
  ungroup %>%
  #mutate(journal_group = ifelse(Journal=="AEA P&P","Papers and Proceedings","AER and journals")) %>%
  #group_by(journal_group) %>%
  group_by(Journal) %>%
  summarise(Published = n_distinct(mc_number_anon)) 

# diagnostic

head(jira.publish)

# not sure this is useful
