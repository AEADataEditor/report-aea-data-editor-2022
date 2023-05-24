# write out the numbers collected



# Make available the latexnums dataset

latexnums <- readRDS(latexnums.Rda) %>%
  mutate(pre="\\newcommand{\\",mid="}{",end="}") %>%
  unite(latexcode,c("pre","field","mid","value","end"),sep = "")
write(latexnums$latexcode,file=file.path(outputs,"latexnums.tex"))

