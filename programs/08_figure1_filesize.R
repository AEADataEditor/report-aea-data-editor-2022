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

# Get the data
# Read in data extracted from openICPSR,
# This varies from year to year

readin <- read_excel(file.path(icpsrbase,"AEA-Projects-Query-Results.xlsx")) %>%
  unite(title, starts_with("..."),na.rm = TRUE) %>% 
  unite(Title,Title, title) %>%
  separate(Created,c("Created.Date","Created.Time"),sep="T") %>%
  mutate(date=parse_date(Created.Date)) %>%
  filter(date >= firstday & date <= lastday )

icpsr.actual_lastday <- readin %>% 
  summarize(lastday=max(date)) %>%
  pull(lastday) %>% as.character()

# QA
summary(readin)


update_latexnums("pkgcount",nrow(readin))
update_latexnums("pkglastday",icpsr.actual_lastday)



utilizationReport <- read_csv(file.path(icpsrbase,icpsr.utilization.file)) %>%
  select(Project.ID = "Study ID",
         Status,
         Views,
         Downloads  = "Download",
         Updated.Date = "Updated Date") %>%
  # blacklist - these are in an ambiguous state
  mutate(exclude = (Project.ID %in% c(109644,110581,110621,110902,111003))) %>%
  filter(exclude == FALSE) %>%
  filter(Status %in% c("PUBLISHED","NEW VERSION IN PROGRESS","SUBMITTED") ) %>%
  mutate(is_published = (Views >0))

summary(utilizationReport)

# we save this filtered file
saveRDS(utilizationReport,file=file.path(icpsrbase,"anonUtilizationReport.Rds"))
write_csv(utilizationReport,file=file.path(icpsrbase,"anonUtilizationReport.csv"))

                            

# cleanup
icpsr <- readin %>%
  select(Project.ID              = Identifier,
         openICPSR.title         = Title,
         fileCount,
         Total.File.Size         = "size bytes",
         Created.Date            ,
         date
  ) 

## Distribution of replication packages
icpsr.file_size <- icpsr %>% 
  distinct(Project.ID,.keep_all = TRUE) %>%
  mutate(date_created=as.Date(substr(Created.Date, 1,10), "%Y-%m-%d")) %>%
  filter(date_created >= as.Date(firstday)-30, date_created <= lastday) %>%
  transform(filesize=Total.File.Size/(1024^3)) %>% # in GB
  transform(filesizemb=Total.File.Size/(1024^2)) %>% # in MB
  transform(intfilesize=round(filesize))

# get some stats
icpsr.file_size %>% 
  summarize(n   = n(),
            files=sum(fileCount),
            mean=round(mean(filesize),2),
            median=round(median(filesize),2),
            q75=round(quantile(filesize,0.75),2),
            sum=round(sum(filesize),2)) -> icpsr.stats.gb

icpsr.file_size %>% 
    summarize(n   = n(),
              files=sum(fileCount),
              mean=round(mean(filesizemb),2),
            median=round(median(filesizemb),2),
            q75=round(quantile(filesizemb,0.75),2),
            sum=round(sum(filesizemb),2)) -> icpsr.stats.mb

saveRDS(icpsr.stats.mb,file=file.path(temp,"icpsr.stats.mb.Rds"))
saveRDS(icpsr.stats.gb,file=file.path(temp,"icpsr.stats.gb.Rds"))

icpsr.file_size %>% 
  group_by(intfilesize) %>% 
  summarise(n=n()) %>% 
  ungroup() %>% 
  mutate(percent=100*n/sum(n)) -> icpsr.stats1

update_latexnums("pkgsizetwog",icpsr.stats1 %>% 
                             filter(intfilesize > 2) %>% 
                             summarize(percent=sum(percent)) %>% round(0))
update_latexnums("pkgsizetwentyg",icpsr.stats1 %>% 
                              filter(intfilesize >19) %>% 
                              summarize(percent=sum(percent)) %>% round(0))


update_latexnums("pkgsizetotalgb",icpsr.stats.gb$sum)
update_latexnums("pkgsizetotaltb",round(icpsr.stats.gb$sum/1024,0))
update_latexnums("pkgsizemean",icpsr.stats.mb$mean)
update_latexnums("pkgsizemedian",icpsr.stats.mb$median)
update_latexnums("pkgsizeqsvntyfv",icpsr.stats.mb$q75)
update_latexnums("pkgfilesT",round(icpsr.stats.mb$files/1000,0))
update_latexnums("pkgfiles",icpsr.stats.mb$files)

# graph it all

dist_size <- icpsr.file_size %>%
  transform(intfilesize=pmin(round(filesize),10,na.rm = TRUE)) %>%
  group_by(intfilesize) %>%
  summarise(count=n())


plot_filesize_dist <- ggplot(dist_size, aes(x = intfilesize,y=count)) +
  geom_bar(stat="identity", colour="black", fill="grey")+
  theme_classic() +
  labs(x = "GB",
       y = "Number of Packages", 
       title = "Size distribution of replication packages")

ggsave(file.path(images,"plot_filesize_dist.png"), 
       plot_filesize_dist  +
         labs(y=element_blank(),title=element_blank()),
       width=7,height=3,units="in")
#plot_filesize_dist
