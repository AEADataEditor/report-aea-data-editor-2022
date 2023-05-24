#!/bin/bash

outfile=pandp-vilhuber-2022-$(date +%F).zip

zip -rp $outfile AEA*tex AEA*pdf *bib images/ tables/*tex *.cls *.sty data/replication*txt *.bst
