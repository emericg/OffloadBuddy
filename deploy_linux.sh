#!/usr/bin/env bash

echo "> OffloadBuddy packager"

export VERSION=$(git rev-parse --short HEAD);

## APP INSTALL #################################################################

make INSTALL_ROOT=appdir -j$(nproc) install;

# recap installation directory content
find appdir/;

## PACKAGE #####################################################################

# get linuxdeployqt
if [ ! -x contribs/src/linuxdeployqt-continuous-x86_64.AppImage ]; then
  wget -c -nv "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage" -P contribs/src/;
fi
chmod a+x contribs/src/linuxdeployqt-continuous-x86_64.AppImage;

unset LD_LIBRARY_PATH; unset QT_PLUGIN_PATH; #unset QTDIR;
if [ -z "$QTDIR" ]; then
  QTDIR=/usr/lib/qt
fi
USRDIR=/usr
if [ -d appdir/usr/local ]; then
  USRDIR=/usr/local
fi

# run linuxdeployqt
mkdir -p appdir/$USRDIR/plugins/imageformats/ appdir/$USRDIR/plugins/iconengines/;
cp $QTDIR/plugins/imageformats/libqsvg.so appdir/$USRDIR/plugins/imageformats/;
cp $QTDIR/plugins/iconengines/libqsvgicon.so appdir/$USRDIR/plugins/iconengines/;
./contribs/src/linuxdeployqt-continuous-x86_64.AppImage appdir/$USRDIR/share/applications/*.desktop -qmldir=qml/ -bundle-non-qt-libs -extra-plugins=imageformats/libqsvg.so,iconengines/libqsvgicon.so;

# run appimage packager
./contribs/src/linuxdeployqt-continuous-x86_64.AppImage appdir/$USRDIR/share/applications/*.desktop -qmldir=qml/ -appimage;

## UPLOAD ######################################################################

# upload to transfer.sh
find appdir -executable -type f -exec ldd {} \; | grep " => $USRDIR" | cut -d " " -f 2-3 | sort | uniq;
curl --upload-file OffloadBuddy*.AppImage https://transfer.sh/OffloadBuddy-git.$VERSION-linux64.AppImage;
