#!/usr/bin/env bash

echo "> OffloadBuddy packager (macOS x86_64)"

if [ "$(id -u)" == "0" ]; then
  echo "This script MUST NOT be run as root" 1>&2
  exit 1
fi

current_dir=$(pwd)
if [ ! ${current_dir##*/} == "OffloadBuddy" ]; then
  echo "This script MUST be run from the OffloadBuddy/ directory"
  exit 1
fi

## APP INSTALL #################################################################

echo '---- Running make install'
make install

echo '---- Installation directory content recap:'
find bin/;

## PACKAGE #####################################################################

export GIT_VERSION=$(git rev-parse --short HEAD);

# (already run by the make install)
#echo '---- Running macdeployqt'
#macdeployqt bin/OffloadBuddy.app

echo '---- Compressing package'
cd bin/;
zip -r -X OffloadBuddy.zip OffloadBuddy.app;

## UPLOAD ######################################################################

echo '---- Uploading to transfer.sh'
curl --upload-file OffloadBuddy*.zip https://transfer.sh/OffloadBuddy-git.$GIT_VERSION-macOS.zip;
