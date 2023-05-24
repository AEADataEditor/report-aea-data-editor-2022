# Tabulate statistics and make graphs for the AEA data editor report
# Harry Son
# 2/18/2021

# Inputs
#   - file.path(jiraanon,"jira.anon.RDS") 
#   - file.path(temp,"jira.others.RDS)
# Outputs


### Load libraries 
### Requirements: have library *here*
source(here::here("global-libraries.R"),echo=TRUE)
source(here::here("programs","config.R"),echo=TRUE)


library(stargazer)

# let's get the noncompliant 
# JIRA extract: select Task, Noncompliant = Yes. Verify and cleanup any pending. Download Excel file.
# Columns will depend on view. At a minimu, AEAREP number, Manuscript Number, Journal, openICPSR ID
# .... Key	Summary	Manuscript Central identifier	Status	Journal	openICPSRDOI	openICPSR Project Number	Assignee
# Summary and Assignee should be blanked
# other columns should be removed.

if ( file.exists(noncompliance.name) ) {
  noncompliance <- read_excel(noncompliance.name,
                              sheet = 2) 
  message(paste0("File ",noncompliance.name," read"))
} else {
  stop(paste0("Missing noncompliance file ",noncompliance.name))
}

# get the updates. Similar to above, but filter on MCStatus = Update.

if ( file.exists(jira.updates.name) ) {
  jira.updates <- read_excel(jira.updates.name,
                             sheet = 2) 
  message(paste0("File ",jira.updates.name," read"))
} else {
  stop(paste0("Missing updates file ",jira.updates.name))
}

# Summarize non-compliance

noncompliance %>% 
  group_by(Journal,`Manuscript Central identifier`) %>%
  summarize(n=n()) %>%
  ungroup() %>%
  # we ignore the n because it is just a trick to get distinct char vars
  group_by(Journal) %>%
  summarize(`Non-compliant`=n()) %>%
  ungroup() -> journal_compliance

journal_compliance %>%
  summarize(`Non-compliant`=sum(`Non-compliant`)) -> summary_compliance


update_latexnums("mcpubnoncompl",summary_compliance$`Non-compliant`)


# Summarize updates

jira.updates %>% 
  group_by(Journal,`Manuscript Central identifier`) %>%
  summarize(n=n()) %>%
  ungroup() %>%
  group_by(Journal) %>%
  summarize(`Updates`=n()) %>%
  ungroup() -> journal_updates

journal_updates %>%
  summarize(`Updates`=sum(`Updates`)) -> summary_updates


update_latexnums("mcpubupdates",summary_updates$`Updates`)


# create table by journal
full_join(journal_compliance,journal_updates,by="Journal") %>%
  mutate(Updates =replace_na(as.character(Updates),""),
         "Non-compliant" = replace_na(as.character(`Non-compliant`),"")) %>%
stargazer(style = "aer",
          summary = FALSE,
          out = file.path(tables,"n_compliance_manuscript.tex"),
          out.header = FALSE,
          float = FALSE,
          rownames = FALSE
)

# create table by update type

jira.updates %>% 
  group_by(`Update type`,`Manuscript Central identifier`) %>%
  summarize(n=n()) %>%
  ungroup() %>%
  group_by(`Update type`) %>%
  # here we actually allow for multiple updates per MC
  summarize(`Manuscripts`=sum(n)) %>%
  rename(Source = `Update type`) %>%
  ungroup() -> update_types



# create table by journal
update_types %>%
  mutate(Manuscripts =replace_na(as.character(Manuscripts),"")) %>%
  stargazer(style = "aer",
            summary = FALSE,
            out = file.path(tables,"n_updates_manuscript.tex"),
            out.header = FALSE,
            float = FALSE,
            rownames = FALSE

  )
