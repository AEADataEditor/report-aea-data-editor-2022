# Tabulate statistics and make graphs for the AEA data editor report
# Lars Vilhuber
# - This reformats tables created from the ScholarOne system 
# - Source data is confidential.
# 2/18/2021

# Inputs
#   - file.path(basepath,"data","scholarone","dataEditorReport_20191128-20201127.xlsx") 
# Outputs
#   - Tables


### Load libraries 
### Requirements: have library *here*
source(here::here("global-libraries.R"),echo=TRUE)
source(here::here("programs","config.R"),echo=TRUE)


## Non-standard - install of a page with same name
#pkgTest.github("stargazer-booktabs","markwestcott34")
library(stargazer)

# Get Median number of rounds

## Get list of journals


jira.journals <- readRDS(jira.anon.name)  %>%
            distinct(Journal) %>%
            filter(! Journal %in% c("JEP","JEL","","AEA P&P")) %>%
            mutate(Journal = str_replace(Journal,":"," "),
                   Journal = str_replace(Journal," Economics",""),
                   Journal = str_replace(Journal," Economic","")) 

# diagnostics

jira.journals

## cycle over journals

read_scholarone <- function(filename,skip,alt=FALSE) {
  rounds <- tibble()
  for ( j in as.list(jira.journals$Journal)) {
    print(paste0("Reading in ",j))
    so <- read_excel(filename,
                     sheet = j, skip = skip, n_max = 3) 
    if ( alt ) {
      so <- so %>% rename(`Total Rounds` = `...1`)
    }
    
    so <- so %>% 
      select(Rounds = `Total Rounds`,Count = `Manuscripts`) %>%
      mutate(Journal = j,
             jorder  = if_else(substr(j,1,3)=="AER",0,1))
    rounds <- bind_rows(rounds,so)
    print(so)
  }
  rounds <- rounds %>% 
    arrange(jorder,Journal) %>%
    select(Journal,Rounds,Count)
  return(rounds)
}

# read the files

rounds <- read_scholarone(scholarone.name,scholarone.skip) 

underreview <- read_scholarone(scholarone.name,scholarone.skip2,alt=TRUE) %>%
  mutate(Count = if_else(is.na(Rounds),0,Count),
         Rounds = if_else(is.na(Rounds),"With Author",Rounds))

reportyear.current <- substr(str_split(scholarone.file,"-")[[1]][2],1,4)

# we also want to read back in the previous year. This is custom code here.
# This file is not provided as part of the replication package, as it is 
# available in the previous year's repository

scholarone.pname <- file.path(scholarone,scholarone.prev)
reportyear.prev <- substr(str_split(scholarone.prev,"-")[[1]][2],1,4)

rounds.pyear <- read_scholarone(scholarone.pname,scholarone.pskip) %>% 
  mutate(reportyear={{ reportyear.prev}})

# summarize

rounds.all <- rounds %>%
  group_by(Rounds) %>%
  summarize(Count = sum(Count)) %>%
  ungroup() %>%
  arrange(Rounds) %>%
  mutate(CPercent = cumsum(100*Count/sum(Count)),
         Percent = round(100*Count/sum(Count),1))


rounds.pall <- rounds.pyear %>%
  group_by(Rounds) %>%
  summarize(Count = sum(Count)) %>%
  ungroup() %>%
  arrange(Rounds) %>%
  mutate(CPercent = cumsum(100*Count/sum(Count)),
         Percent = round(100*Count/sum(Count),1))

# pre-aggregated - which is the median?

median <- NA
pmedian <- NA

for ( row in 1:nrow(rounds.all) ) {
  print(paste0(row))
  if ( rounds.all$CPercent[row] > 50 & is.na(median) ) {
    median = rounds.all$Rounds[row]
  }
}

for ( row in 1:nrow(rounds.pall) ) {
  print(paste0(row))
  if ( rounds.all$CPercent[row] > 50 & is.na(pmedian) ) {
    pmedian = rounds.all$Rounds[row]
  }
}

update_latexnums("medianrounds",median)
update_latexnums("pmedianrounds",pmedian)
update_latexnums("roundone",rounds.all$Percent[1])
update_latexnums("proundone",rounds.pall$Percent[1])
update_latexnums("roundthree",rounds.all$Percent[3])
update_latexnums("proundthree",rounds.pall$Percent[3])


# create table

rounds.wide <- rounds %>%
  select(Journal,Rounds,Count) %>%
  pivot_wider(names_from = Journal,
              values_from = Count,
              values_fill = 0)

stargazer(rounds.wide,style = "aer",
          summary = FALSE,
          out = file.path(tables,"n_rounds.tex"),
          out.header = FALSE,
          float = FALSE,
          rownames = FALSE
)

# Merge with previous year to generate figure
# to convince ggplot to do the right stacked chart, we need the percentages pre-calculated
# We also go wide then narrow to get zeros

rounds.pwide <- rounds.pyear %>%
  select(Journal,Rounds,Count) %>%
  pivot_wider(names_from = Journal,
              values_from = Count,
              values_fill = 0) %>%
  pivot_longer(cols = starts_with("A"),
               names_to = "Journal",
               values_to = "Count") %>%
  mutate(reportyear={{ reportyear.prev }})


rounds.years <- bind_rows(rounds.wide %>%
                          pivot_longer(cols = starts_with("A"),
                                       names_to = "Journal",
                                       values_to = "Count") %>%
  mutate(reportyear={{ reportyear.current}}),rounds.pwide) %>%
  arrange(reportyear) %>%
  group_by(reportyear,Journal) %>%
  mutate(fraction = round(100*Count/sum(Count),0),
         Rounds=as.factor(Rounds)) 

rounds.plot <- ggplot(rounds.years,aes(y=fraction,x=Journal,fill=Rounds,group=reportyear)) + 
  geom_bar(stat='identity') + 
  scale_x_discrete(guide = guide_axis(n.dodge=2))+
  theme_tufte() +
  scale_fill_brewer(palette="Paired") +
  labs(y=element_blank()) +
  facet_grid(~ reportyear)


ggsave(file.path(images,"plot_rounds_compare.png"), 
       rounds.plot +
         labs(y=element_blank(),title=element_blank()),
       width=7,height=3,units="in")

