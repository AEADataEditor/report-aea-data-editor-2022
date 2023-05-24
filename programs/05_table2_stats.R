# Tabulate statistics and make graphs for the AEA data editor report
# Harry Son
# 12/11/2020

# Inputs
#   - file.path(jiraanon,"jira.anon.RDS") 
# Outputs


### Load libraries 
### Requirements: have library *here*
source(here::here("global-libraries.R"),echo=TRUE)
source(here::here("programs","config.R"),echo=TRUE)
library(stargazer)


# we will re-use these 
jira.pyear <- readRDS(file=file.path(temp,"jira.pyear.RDS"))
jira.filter.submitted <- readRDS(file=file.path(temp,"jira.submitted.RDS"))

## By journal
issues_total_journal <- jira.pyear %>%
  filter(!(Journal=="")) %>%
  group_by(Journal) %>%
  summarise(issue_numbers = n_distinct(ticket),
            mcs_numbers   = n_distinct(mc_number_anon))

# stargazer(issues_total_journal,style = "aer",
#           summary = FALSE,
#           out = file.path(tables,"issues_total_journal.tex"),
#           out.header = FALSE,
#           float = FALSE
# )

#### Number of reports processed (went past submitted to MC) since December 1

assess_cplt <- jira.filter.submitted %>%
  select(ticket) %>% 
  distinct() %>%
  nrow()
#update_latexnums("jiraissuescplt",assess_cplt)


manuscript_cplt <- jira.filter.submitted %>%
  select(mc_number_anon) %>% 
  distinct() %>% nrow()
#update_latexnums("jiramcscplt",manuscript_cplt)


## By journal
assess_cplt_journal <- jira.filter.submitted %>%
  group_by(Journal) %>%
  summarise(issues_cplt = n_distinct(ticket),
            mcs_cplt    = n_distinct(mc_number_anon)) 

# stargazer(assess_cplt_journal,style = "aer",
#           summary = FALSE,
#           out = file.path(tables,"assess_cplt_journal.tex"),
#           out.header = FALSE,
#           float = FALSE
#           )






#### Number of assessments/manuscript that are pending publication

jira.filter.pending <- jira.pyear %>%
  filter(Status %in% c("Pending publication","Pending Article DOI"))

manuscript_pending <- jira.filter.pending %>%
  select(mc_number_anon) %>% 
  distinct() %>% nrow()
#update_latexnums("jiramcspending",manuscript_pending)


## By journal
pendingpub_by_journal <- jira.filter.pending %>%
  group_by(Journal) %>%
  summarise(mcs_pendingpub   = n_distinct(mc_number_anon))

# stargazer(pendingpub_by_journal,style = "aer",
#           summary = FALSE,
#           out = file.path(tables,"pendingpub_by_journal.tex"),
#           out.header = FALSE,
#           float = FALSE
# )



#### Number of assessment processed by external replicator since December 1, 2019
## Total

external_total <- jira.filter.submitted %>%
  filter(external == "Yes") %>%
  select(ticket) %>% distinct() %>%
  nrow()
#update_latexnums("jiraexternal",external_total)
mcs_external <- jira.filter.submitted %>%
  filter(external == "Yes") %>%
  select(mc_number_anon) %>% distinct() %>%
  nrow()
#update_latexnums("jiramcsexternal",mcs_external)

## By journal
external_total_journal <- jira.filter.submitted %>%
  filter(external == "Yes") %>%
  group_by(Journal) %>%
  summarise(mcs_external = n_distinct(mc_number_anon),
            issues_external=n_distinct(ticket))

# # output table
# stargazer(external_total_journal,style = "aer",
#           summary = FALSE,
#           out = file.path(tables,"external_total_journal.tex"),
#           out.header = FALSE,
#           float = FALSE
# )
# # Histogram
# n_external_journal_plot <- ggplot(external_total_journal, aes(x = Journal, y = issues_external)) +
#   geom_bar(stat = "identity", colour="white", fill="grey") +
#   labs(x = "Journal", y = "Number of cases processed by external replicator", title = "Total usage of external replicators by journal") + 
#   theme_classic() +
#   geom_text(aes(label=issues_external), hjust=1.5, size=3.5) +
#   coord_flip()
# 
# 
# ggsave(file.path(images,"n_external_journal_plot.png"), 
#        n_external_journal_plot  +
#          labs(y=element_blank(),title=element_blank()))
# 
#n_external_journal_plot


### Combine five data columns

full_join(issues_total_journal,assess_cplt_journal,by=c("Journal")) %>%
                   full_join(external_total_journal,by=c("Journal")) %>%
                   full_join(pendingpub_by_journal,by=c("Journal")) %>%
                   mutate(Journal = if_else(Journal=="AEA P&P","AEA P+P",Journal)) ->
  tmp

# should probably have been done before

tmp %>% 
  summarize(      "Issues (rcvd)" = sum(issue_numbers,na.rm = TRUE),
                   "Issues (cplt)" = sum(issues_cplt,na.rm = TRUE),
                   "Issues (external)" = sum(issues_external,na.rm = TRUE),
                   "Manuscripts (rcvd)" = sum(mcs_numbers,na.rm = TRUE),
                   "Manuscripts (cplt)" = sum(mcs_cplt,na.rm = TRUE),
                   "Manuscripts (ext.)" = sum(mcs_external,na.rm = TRUE),
                   "Manuscripts (pend.)"= sum(mcs_pendingpub,na.rm = TRUE)) %>%
  mutate(Journal = "Totals") %>%
  select(Journal,everything()) -> tmp2

# update numbers

update_latexnums("jiraissues",tmp2$`Issues (rcvd)`)
update_latexnums("jiramcs",   tmp2$`Manuscripts (rcvd)`)

update_latexnums("jiraissuescplt", tmp2$`Issues (cplt)`)
update_latexnums("jiraexternal",   tmp2$`Issues (external)`)
update_latexnums("jiramcscplt",    tmp2$`Manuscripts (cplt)`)
update_latexnums("jiramcspending", tmp2$`Manuscripts (pend.)`)
update_latexnums("jiramcsexternal",tmp2$`Manuscripts (ext.)`)



bind_rows(tmp%>%
            select(Journal,"Issues (rcvd)" = issue_numbers,
                   "Issues (cplt)" = issues_cplt,
                   "Issues (external)" = issues_external,
                   "Manuscripts (rcvd)" = mcs_numbers,
                   "Manuscripts (cplt)" = mcs_cplt,
                   "Manuscripts (ext.)" = mcs_external,
                   "Manuscripts (pend.)"= mcs_pendingpub),
          tmp2) -> n_journal_table
# output table
stargazer(n_journal_table,style = "aer",
          summary = FALSE,
          out = file.path(tables,"n_journal_numbers.tex"),
          out.header = FALSE,
          float = FALSE,
          rownames = FALSE
)


#