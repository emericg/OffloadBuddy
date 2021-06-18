#!/usr/bin/env bash

echo "> OffloadBuddy packager (Linux x86_64)"

export APP_NAME="OffloadBuddy";
export APP_VERSION=0.6;
export GIT_VERSION=$(git rev-parse --short HEAD);

## CHECKS ######################################################################

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
  make INSTALL_ROOT=appdir install;

  #echo '---- Installation directory content recap:'
  #find appdir/;
fi

## DEPLOY ######################################################################

unset LD_LIBRARY_PATH; unset QT_PLUGIN_PATH; #unset QTDIR;

if [[ $use_contribs = true ]] ; then
  export LD_LIBRARY_PATH=$(pwd)/contribs/src/env/linux_x86_64/usr/lib/:/usr/lib;
else
  export LD_LIBRARY_PATH=/usr/lib/;
fi
USRDIR=/usr;
if [ -d appdir/usr/local ]; then
  USRDIR=/usr/local;
fi
if [ -z "$QTDIR" ]; then
  QTDIR=/usr/lib/qt;
fi

echo '---- Downloading linuxdeployqt'
if [ ! -x contribs/src/linuxdeployqt-6-x86_64.AppImage ]; then
  wget -c -nv "https://github.com/probonopd/linuxdeployqt/releases/download/6/linuxdeployqt-6-x86_64.AppImage" -P contribs/src/;
fi
chmod a+x contribs/src/linuxdeployqt-6-x86_64.AppImage;

echo '---- Running linuxdeployqt'
mkdir -p appdir/$USRDIR/plugins/imageformats/ appdir/$USRDIR/plugins/iconengines/ appdir/$USRDIR/plugins/geoservices/ appdir/$USRDIR/plugins/mediaservice/;
cp $QTDIR/plugins/imageformats/libqsvg.so appdir/$USRDIR/plugins/imageformats/;
cp $QTDIR/plugins/iconengines/libqsvgicon.so appdir/$USRDIR/plugins/iconengines/;
cp $QTDIR/plugins/geoservices/*.so appdir/$USRDIR/plugins/geoservices/;
cp $QTDIR/plugins/mediaservice/*.so appdir/$USRDIR/plugins/mediaservice/;
./contribs/src/linuxdeployqt-6-x86_64.AppImage appdir/$USRDIR/share/applications/*.desktop -qmldir=qml/ -unsupported-allow-new-glibc -bundle-non-qt-libs -extra-plugins=geoservices,mediaservice,imageformats/libqsvg.so,iconengines/libqsvgicon.so;

#echo '---- Installation directory content recap:'
#find appdir/;

## PACKAGE (ZIP) ###############################################################

# TODO

## PACKAGE (AppImage) ##########################################################

if [[ $create_package = true ]] ; then
  echo '---- Running AppImage packager'
  ./contribs/src/linuxdeployqt-6-x86_64.AppImage appdir/$USRDIR/share/applications/*.desktop -qmldir=qml/ -unsupported-allow-new-glibc -appimage;
fi

## UPLOAD ######################################################################

if [[ $upload_package = true ]] ; then
  echo '---- Uploading to transfer.sh'
  find appdir -executable -type f -exec ldd {} \; | grep " => $USRDIR" | cut -d " " -f 2-3 | sort | uniq;
  curl --upload-file $APP_NAME*.AppImage https://transfer.sh/$APP_NAME-$APP_VERSION-linux64.AppImage;
fi
