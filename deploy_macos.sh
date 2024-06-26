#!/usr/bin/env bash

export APP_NAME="OffloadBuddy"
export APP_VERSION=0.12
export GIT_VERSION=$(git rev-parse --short HEAD)

echo "> $APP_NAME packager (macOS x86_64) [v$APP_VERSION]"

## CHECKS ######################################################################

if [ "$(id -u)" == "0" ]; then
  echo "This script MUST NOT be run as root" 1>&2
  exit 1
fi

if [ ${PWD##*/} != $APP_NAME ]; then
  echo "This script MUST be run from the $APP_NAME/ directory"
  exit 1
fi

## SETTINGS ####################################################################

use_contribs=false
make_install=false
create_package=false
upload_package=false

while [[ $# -gt 0 ]]
do
case $1 in
  -c|--contribs)
  use_contribs=true
  ;;
  -i|--install)
  make_install=true
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

if [[ $make_install = true ]] ; then
  echo '---- Running make install'
  make INSTALL_ROOT=bin/ install

  #echo '---- Installation directory content recap (after make install):'
  #find bin/
fi

## DEPLOY ######################################################################

if [[ $use_contribs = true ]] ; then
  export LD_LIBRARY_PATH=$(pwd)/contribs/src/env/macOS_x86_64/usr/lib/
else
  export LD_LIBRARY_PATH=/usr/local/lib/
fi

echo '---- Running macdeployqt'
macdeployqt bin/$APP_NAME.app -qmldir=qml/ -hardened-runtime -timestamp -appstore-compliant

# Copy ffmpeg libraries
cp -RP contribs/env/macos_x86_64/usr/lib/libav*.dylib bin/$APP_NAME.app/Contents/Frameworks/
cp -RP contribs/env/macos_x86_64/usr/lib/libsw*.dylib bin/$APP_NAME.app/Contents/Frameworks/
cp -RP contribs/env/macos_x86_64/usr/lib/libpostproc*.dylib bin/$APP_NAME.app/Contents/Frameworks/
# Copy ffmpeg binary
cp contribs/env/macos_x86_64/usr/bin/ffmpeg bin/$APP_NAME.app/Contents/MacOS/
chmod +x bin/$APP_NAME.app/Contents/MacOS/ffmpeg

# Patch ffmpeg binary and libraries rpaths
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

#echo '---- Installation directory content recap (after macdeployqt):'
#find bin/

## PACKAGE (zip) ###############################################################

if [[ $create_package = true ]] ; then
  echo '---- Compressing package'
  cd bin/
  zip -r -y -X ../$APP_NAME-$APP_VERSION-macos.zip $APP_NAME.app
  cd ..
fi

## UPLOAD ######################################################################

if [[ $upload_package = true ]] ; then
  printf "---- Uploading to transfer.sh"
  curl --upload-file $APP_NAME*.zip https://transfer.sh/$APP_NAME.$APP_VERSION-git$GIT_VERSION-macOS.zip
  printf "\n"
fi
