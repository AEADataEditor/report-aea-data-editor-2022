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

## Non-standard - install of a page with same name
library(stargazer)

# Get an intermediate file
jira.filter.submitted <- readRDS(file.path(temp,"jira.submitted.RDS"))


## response options
jira.response.options <- jira.filter.submitted  %>%  
  distinct(mc_number_anon, .keep_all=TRUE) %>%
  unite(response,c(MCRecommendationV2,MCRecommendation),remove=FALSE,sep="") %>%
  group_by(response) %>%
  summarise(freq=n_distinct(mc_number_anon)) %>%
  select(`Response option`=response,`Frequency`=freq)

stargazer(jira.response.options,style = "aer",
          summary = FALSE,
          out = file.path(tables,"jira_response_options.tex"),
          out.header = FALSE,
          float = FALSE,
          rownames = FALSE
)
