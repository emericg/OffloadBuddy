#!/usr/bin/env bash

echo "> OffloadBuddy packager (Windows x86_64)"

if [ ${PWD##*/} != "OffloadBuddy" ]; then
  echo "This script MUST be run from the OffloadBuddy/ directory"
  exit 1
fi

## SETTINGS ####################################################################

use_contribs=false
create_package=false
upload_package=false

while [[ $# -gt 0 ]]
do
case $1 in
  -c|--contribs)
  use_contribs=true
  ;;
  -p|--package)
  create_package=true
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

#echo '---- Running make install'
#make INSTALL_ROOT=bin/ install;

#echo '---- Installation directory content recap:'
#find bin/;

## DEPLOY ######################################################################

export GIT_VERSION=$(git rev-parse --short HEAD);

#echo '---- Running windeployqt'
windeployqt bin/ --qmldir qml/

cp contribs/env/windows_x86_64/usr/lib/exif.dll bin/
cp contribs/env/windows_x86_64/usr/lib/minivideo.dll bin/

cp contribs/env/windows_x86_64/usr/lib/avcodec-*.dll bin/
cp contribs/env/windows_x86_64/usr/lib/avdevice-*.dll bin/
cp contribs/env/windows_x86_64/usr/lib/avfilter-*.dll bin/
cp contribs/env/windows_x86_64/usr/lib/avformat-*.dll bin/
cp contribs/env/windows_x86_64/usr/lib/avutil-*.dll bin/
cp contribs/env/windows_x86_64/usr/lib/postproc-*.dll bin/
cp contribs/env/windows_x86_64/usr/lib/swresample-*.dll bin/
cp contribs/env/windows_x86_64/usr/lib/swscale-*.dll bin/

cp contribs/env/windows_x86_64/usr/bin/ffmpeg.exe bin/

echo '---- Installation directory content recap:'
find bin/;

## PACKAGE #####################################################################

if [[ $create_package = true ]] ; then
  echo '---- Compressing package'
  mv bin OffloadBuddy-$GIT_VERSION-win64
  7z a OffloadBuddy-$GIT_VERSION-win64.zip OffloadBuddy-$GIT_VERSION-win64
fi

## UPLOAD ######################################################################

if [[ $upload_package = true ]] ; then
  echo '---- Uploading to transfer.sh'
  curl --upload-file OffloadBuddy*.zip https://transfer.sh/OffloadBuddy-git.$GIT_VERSION-win64.zip;
  echo '---- Uploaded...'
fi
