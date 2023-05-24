#!/bin/bash
PWD=$(pwd)
. ${PWD}/.myconfig.sh
  
# build the docker if necessary

BUILD=yes

if [[ "$BUILD" == "yes" ]]; then
docker build . -t $dockerrepo
nohup docker push $dockerrepo&
fi
