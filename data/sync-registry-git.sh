#!/bin/bash

dest=registry
src=https://github.com/J-PAL/AEA_registryanalysis/archive/refs/heads/main.zip

if [[ -d $dest ]]
then
  \rm -rf $dest
fi

# get zip file

wget -O registry.zip "$src"

# unzip

unzip registry.zip -d registry

# add it all back

git add registry
