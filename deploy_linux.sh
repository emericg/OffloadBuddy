#!/usr/bin/env bash

echo "> OffloadBuddy packager (Linux x86_64)"

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
make INSTALL_ROOT=appdir -j$(nproc) install;

echo '---- Installation directory content recap:'
find appdir/;

## PACKAGE #####################################################################

unset LD_LIBRARY_PATH; unset QT_PLUGIN_PATH; #unset QTDIR;
if [ -z "$QTDIR" ]; then
  QTDIR=/usr/lib/qt
fi
USRDIR=/usr
if [ -d appdir/usr/local ]; then
  USRDIR=/usr/local
fi

export GIT_VERSION=$(git rev-parse --short HEAD);
export LD_LIBRARY_PATH=contribs/src/env/linux_x86_64/usr/lib/

echo '---- Downloading linuxdeployqt'
if [ ! -x contribs/src/linuxdeployqt-continuous-x86_64.AppImage ]; then
  wget -c -nv "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage" -P contribs/src/;
fi
chmod a+x contribs/src/linuxdeployqt-continuous-x86_64.AppImage;

echo '---- Running linuxdeployqt'
mkdir -p appdir/$USRDIR/plugins/imageformats/ appdir/$USRDIR/plugins/iconengines/;
cp $QTDIR/plugins/imageformats/libqsvg.so appdir/$USRDIR/plugins/imageformats/;
cp $QTDIR/plugins/iconengines/libqsvgicon.so appdir/$USRDIR/plugins/iconengines/;
./contribs/src/linuxdeployqt-continuous-x86_64.AppImage appdir/$USRDIR/share/applications/*.desktop -qmldir=qml/ -bundle-non-qt-libs -extra-plugins=imageformats/libqsvg.so,iconengines/libqsvgicon.so;

echo '---- Running appimage packager'
./contribs/src/linuxdeployqt-continuous-x86_64.AppImage appdir/$USRDIR/share/applications/*.desktop -qmldir=qml/ -appimage;

## UPLOAD ######################################################################

echo '---- Uploading to transfer.sh'
find appdir -executable -type f -exec ldd {} \; | grep " => $USRDIR" | cut -d " " -f 2-3 | sort | uniq;
curl --upload-file OffloadBuddy*.AppImage https://transfer.sh/OffloadBuddy-git.$GIT_VERSION-linux64.AppImage;
