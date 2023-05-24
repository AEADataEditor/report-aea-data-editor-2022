# Download lab members from public repo
# Author: Lars Vilhuber

## Inputs: export_MM-DD-YYYY.csv
## Outputs: file.path(basepath,"data","replicationlab_members.txt")

### Cleans working environment.
source(here::here("global-libraries.R"),echo=TRUE)
source(here::here("programs","config.R"),echo=TRUE)


# Read in data extracted from Jira, anonymized

if ( file.exists(jira.members.name) ) {
  message("File exists, proceeding.")
  message(jira.members.name)
} else {
  message("Attempting to download file")
  try(download.file(jira.members.url,jira.members.name,mode="wb"))
  if ( file.exists(jira.members.name) ) {
    message("Download successful, proceeding.")
  } else {
    stop("Download failed. Please investigate")
  }
}

# read it in, and filter out some members who are not undergraduates

lab.members <- read_csv(jira.members.name) %>%
  filter(! name %in% c("Leonel Borja Plaza","Jenna Kutz Farabaugh","Hyuk Son")) %>%
  arrange(name) %>%
  # Tricky way to get this to be text when output!
  mutate(extra=",")
lab.members$extra[nrow(lab.members)]="."

update_latexnums("teamsize",nrow(lab.members))

write.table(lab.members, 
            file = file.path(tables,"replicationlab_members.tex"), sep = "",
            row.names = FALSE,col.names = FALSE,quote = FALSE)
