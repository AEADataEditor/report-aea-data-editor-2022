#!/bin/bash

outfile=deposit-repository-$(date +%F).zip

zip -rp $outfile README.* 
zip -rp $outfile tables/ 
zip -rp $outfile programs/ 
zip -rp $outfile images/*
zip -rp $outfile data/jira/anon  
zip -rp $outfile data/icpsr 
zip -rp $outfile data/manual/ 
zip -rp $outfile data/scholarone/*
zip -rp $outfile data/zenodo/*
zip -rp $outfile $(find data -name README.\*)
zip -rp $outfile *.sh 
zip -rp $outfile *.R
zip -rp $outfile *.Rproj
zip -rp $outfile LICENSE.txt
zip -rp $outfile Dockerfile
