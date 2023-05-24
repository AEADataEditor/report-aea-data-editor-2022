repo=${PWD##*/}
space=aeadataeditor
dockerrepo=$(echo $space/$repo | tr [A-Z] [a-z])
case $USER in
  vilhuber)
  #WORKSPACE=$HOME/Workspace/git/
  WORKSPACE=$PWD
  ;;
  codespace)
  WORKSPACE=/workspaces
  ;;
esac
