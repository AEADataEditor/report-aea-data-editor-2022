#!/bin/bash
PWD=$(pwd)
repo=${PWD##*/}
space=aeadataeditor
case $USER in
  vilhuber|larsvilhuber)
	  WORKSPACE=$(pwd)
  ;;
  codespace)
  WORKSPACE=/workspaces
  ;;
esac
  
# build the docker if necessary

BUILD=yes
arg1=$1

docker pull $space/$repo 
if [[ $? == 1 ]]
then
  ## maybe it's local only
  docker image inspect $space/$repo > /dev/null
  [[ $? == 0 ]] && BUILD=no
else
  BUILD=NO
fi
# override
[[ "$arg1" == "force" ]] && BUILD=yes

if [[ "$BUILD" == "yes" ]]; then
docker build . -t $space/$repo
nohup docker push $space/$repo &
fi

docker run -v $WORKSPACE:/home/rstudio --entrypoint="/bin/bash" -w /home/rstudio/programs -t --rm $space/$repo ./run_all.sh
