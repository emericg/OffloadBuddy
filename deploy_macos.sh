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

if [[ $use_contribs = true ]] ; then
  export LD_LIBRARY_PATH=$(pwd)/contribs/src/env/macOS_x86_64/usr/lib/;
else
  export LD_LIBRARY_PATH=/usr/local/lib/;
fi

echo '---- Running macdeployqt'
macdeployqt bin/OffloadBuddy.app -qmldir=qml/ -appstore-compliant;

# Copy ffmpeg binary and libs
cp contribs/env/macos_x86_64/usr/bin/ffmpeg bin/OffloadBuddy.app/Contents/MacOS/
chmod +x bin/OffloadBuddy.app/Contents/MacOS/ffmpeg
cp -RP contribs/env/macos_x86_64/usr/lib/libav*.dylib bin/OffloadBuddy.app/Contents/Frameworks/
cp -RP contribs/env/macos_x86_64/usr/lib/libsw*.dylib bin/OffloadBuddy.app/Contents/Frameworks/
cp -RP contribs/env/macos_x86_64/usr/lib/libpostproc*.dylib bin/OffloadBuddy.app/Contents/Frameworks/

# Patch ffmpeg related rpaths
if [[ $use_contribs = true ]] ; then
  install_name_tool -change @loader_path/libavcodec.58.dylib @executable_path/../Frameworks/libavcodec.58.dylib bin/OffloadBuddy.app/Contents/MacOS/ffmpeg
  install_name_tool -change @loader_path/libavdevice.58.dylib @executable_path/../Frameworks/libavdevice.58.dylib bin/OffloadBuddy.app/Contents/MacOS/ffmpeg
  install_name_tool -change @loader_path/libavfilter.7.dylib @executable_path/../Frameworks/libavfilter.7.dylib bin/OffloadBuddy.app/Contents/MacOS/ffmpeg
  install_name_tool -change @loader_path/libavformat.58.dylib @executable_path/../Frameworks/libavformat.58.dylib bin/OffloadBuddy.app/Contents/MacOS/ffmpeg
  install_name_tool -change @loader_path/libavutil.56.dylib @executable_path/../Frameworks/libavutil.56.dylib bin/OffloadBuddy.app/Contents/MacOS/ffmpeg
  install_name_tool -change @loader_path/libpostproc.55.dylib @executable_path/../Frameworks/libpostproc.55.dylib bin/OffloadBuddy.app/Contents/MacOS/ffmpeg
  install_name_tool -change @loader_path/libswresample.3.dylib @executable_path/../Frameworks/libswresample.3.dylib bin/OffloadBuddy.app/Contents/MacOS/ffmpeg
  install_name_tool -change @loader_path/libswscale.5.dylib @executable_path/../Frameworks/libswscale.5.dylib bin/OffloadBuddy.app/Contents/MacOS/ffmpeg

  install_name_tool -change @loader_path/libavcodec.58.dylib @executable_path/../Frameworks/libavcodec.58.dylib bin/OffloadBuddy.app/Contents/MacOS/OffloadBuddy
  install_name_tool -change @loader_path/libavdevice.58.dylib @executable_path/../Frameworks/libavdevice.58.dylib bin/OffloadBuddy.app/Contents/MacOS/OffloadBuddy
  install_name_tool -change @loader_path/libavfilter.7.dylib @executable_path/../Frameworks/libavfilter.7.dylib bin/OffloadBuddy.app/Contents/MacOS/OffloadBuddy
  install_name_tool -change @loader_path/libavformat.58.dylib @executable_path/../Frameworks/libavformat.58.dylib bin/OffloadBuddy.app/Contents/MacOS/OffloadBuddy
  install_name_tool -change @loader_path/libavutil.56.dylib @executable_path/../Frameworks/libavutil.56.dylib bin/OffloadBuddy.app/Contents/MacOS/OffloadBuddy
  install_name_tool -change @loader_path/libpostproc.55.dylib @executable_path/../Frameworks/libpostproc.55.dylib bin/OffloadBuddy.app/Contents/MacOS/OffloadBuddy
  install_name_tool -change @loader_path/libswresample.3.dylib @executable_path/../Frameworks/libswresample.3.dylib bin/OffloadBuddy.app/Contents/MacOS/OffloadBuddy
  install_name_tool -change @loader_path/libswscale.5.dylib @executable_path/../Frameworks/libswscale.5.dylib bin/OffloadBuddy.app/Contents/MacOS/OffloadBuddy
fi

echo '---- Installation directory content recap:'
find bin/;

## PACKAGE #####################################################################

if [[ $create_package = true ]] ; then
  echo '---- Compressing package'
  cd bin/;
  zip -r -X OffloadBuddy-$GIT_VERSION-macos.zip OffloadBuddy.app;
fi

## UPLOAD ######################################################################

if [[ $upload_package = true ]] ; then
  echo '---- Uploading to transfer.sh'
  curl --upload-file OffloadBuddy*.zip https://transfer.sh/OffloadBuddy-git.$GIT_VERSION-macOS.zip;
  echo '---- Uploaded...'
fi
