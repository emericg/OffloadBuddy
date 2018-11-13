#!/usr/bin/env bash

echo "> OffloadBuddy packager (macOS x86_64)"

if [ "$(id -u)" == "0" ]; then
  echo "This script MUST NOT be run as root" 1>&2
  exit 1
fi

if [ ${PWD##*/} != "OffloadBuddy" ]; then
  echo "This script MUST be run from the OffloadBuddy/ directory"
  exit 1
fi

## SETTINGS ####################################################################

use_contribs=false
upload_package=false

while [[ $# -gt 0 ]]
do
case $1 in
    -c|--contribs)
    use_contribs=true
    ;;
    -u|--upload)
    upload_package=true
    ;;
    *)
    echo "> Unknown argument '$1'"
    ;;
esac
shift # skip argument or value
done

## APP INSTALL #################################################################

echo '---- Running make install'
make install;

echo '---- Installation directory content recap:'
find bin/;

## PACKAGE #####################################################################

export GIT_VERSION=$(git rev-parse --short HEAD);

if [[ $use_contribs = true ]] ; then
  export LD_LIBRARY_PATH=$(pwd)/contribs/src/env/macOS_x86_64/usr/lib/;
else
  export LD_LIBRARY_PATH=/usr/local/lib/;
fi

# (already run by the make install)
#echo '---- Running macdeployqt'
#macdeployqt bin/OffloadBuddy.app -qmldir=qml/;

echo '---- Compressing package'
cd bin/;
zip -r -X OffloadBuddy-$GIT_VERSION-macos.zip OffloadBuddy.app;

## UPLOAD ######################################################################

if [[ $upload_package = true ]] ; then
  echo '---- Uploading to transfer.sh'
  curl --upload-file OffloadBuddy*.zip https://transfer.sh/OffloadBuddy-git.$GIT_VERSION-macOS.zip;
fi
