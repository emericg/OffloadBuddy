#!/usr/bin/env bash

echo "> OffloadBuddy packager (Windows x86_64)"

current_dir=$(pwd)
if [ ! ${current_dir##*/} == "OffloadBuddy" ]; then
  echo "This script MUST be run from the OffloadBuddy/ directory"
  exit 1
fi

## APP INSTALL #################################################################

echo '---- Installation directory content recap:'
find bin/;

## PACKAGE #####################################################################

export GIT_VERSION=$(git rev-parse --short HEAD);

#echo '---- Running windeployqt'
windeployqt bin/ --qmldir qml/

mv contribs/env/windows_x86_64/usr/lib/exif.dll bin/
mv contribs/env/windows_x86_64/usr/lib/minivideo.dll bin/

mv contribs/env/windows_x86_64/usr/lib/ffmpeg.exe bin/
mv contribs/env/windows_x86_64/usr/lib/avcodec-*.dll bin/
mv contribs/env/windows_x86_64/usr/lib/avdevice-*.dll bin/
mv contribs/env/windows_x86_64/usr/lib/avfilter-*.dll bin/
mv contribs/env/windows_x86_64/usr/lib/avformat-*.dll bin/
mv contribs/env/windows_x86_64/usr/lib/avutil-*.dll bin/
mv contribs/env/windows_x86_64/usr/lib/swresample-*.dll bin/
mv contribs/env/windows_x86_64/usr/lib/swscale-*.dll bin/

echo '---- Compressing package'
mv bin OffloadBuddy-$GIT_VERSION-win64
7z a OffloadBuddy-$GIT_VERSION-win64.zip OffloadBuddy-$GIT_VERSION-win64

## UPLOAD ######################################################################

echo '---- Uploading to transfer.sh'
curl --upload-file OffloadBuddy*.zip https://transfer.sh/OffloadBuddy-git.$GIT_VERSION-win64.zip;
