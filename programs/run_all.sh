#!/bin/bash

rm -f ../tables/latexnums.Rda

for arg in $(ls [0-9]*.R)
do
R CMD BATCH ${arg} 
done

tail *.Rout
