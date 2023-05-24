#!/bin/bash
PWD=$(pwd)

. ${PWD}/.myconfig.sh
  
# build the docker if necessary

BUILD=yes
arg1=$1
docker pull $dockerrepo

if [[ $? == 1 ]]
then
  ## maybe it's local only
  docker image inspect $dockerrepo> /dev/null
  [[ $? == 0 ]] && BUILD=no
fi
# override
BUILD=no
[[ "$arg1" == "force" ]] && BUILD=yes

if [[ "$BUILD" == "yes" ]]; then
bash -x ${PWD}/build.sh
fi

docker run -e DISABLE_AUTH=true \
   -v $WORKSPACE:/home/rstudio \
   --rm -p 8787:8787 \
   $dockerrepo
