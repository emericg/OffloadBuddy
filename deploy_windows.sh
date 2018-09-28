#!/usr/bin/env bash

echo "> OffloadBuddy packager"

export VERSION=$(git rev-parse --short HEAD);

## PACKAGE #####################################################################

windeployqt bin/ --qmldir qml/
mv contribs/windows_x86_64/usr/lib/libexif.dll bin/
mv contribs/windows_x86_64/usr/lib/minivideo.dll bin/

mv bin OffloadBuddy-$VERSION-win64
7z a OffloadBuddy-$VERSION-win64.zip OffloadBuddy-$VERSION-win64

## UPLOAD ######################################################################

curl --upload-file OffloadBuddy*.zip https://transfer.sh/OffloadBuddy-git.$VERSION-win64.zip;
