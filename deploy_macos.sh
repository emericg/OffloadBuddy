#!/usr/bin/env bash

echo "> OffloadBuddy packager"

export VERSION=$(git rev-parse --short HEAD);

## APP INSTALL #################################################################

make install

## PACKAGE #####################################################################

# already run by the make install
#macdeployqt bin/OffloadBuddy.app

cd bin/;
zip -r -X OffloadBuddy.zip OffloadBuddy.app;

## UPLOAD ######################################################################

curl --upload-file OffloadBuddy*.zip https://transfer.sh/OffloadBuddy-git.$VERSION-macOS.zip;
