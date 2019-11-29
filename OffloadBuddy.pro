TARGET  = OffloadBuddy

VERSION = 0.3
DEFINES += APP_VERSION=\\\"$$VERSION\\\"

CONFIG += c++14
QT     += core qml quickcontrols2 svg
QT     += multimedia location sql charts

# Validate Qt version
if (lessThan(QT_MAJOR_VERSION, 5) | lessThan(QT_MINOR_VERSION, 9)) {
    error("You need Qt 5.9 to build $${TARGET}...")
}

# Build artifacts ##############################################################

OBJECTS_DIR = build/
MOC_DIR     = build/
RCC_DIR     = build/
UI_DIR      = build/
QMLCACHE_DIR= build/

DESTDIR     = bin/

# Project files ################################################################

SOURCES  += src/main.cpp \
            src/SettingsManager.cpp \
            src/JobManager.cpp \
            src/JobWorkerAsync.cpp \
            src/JobWorkerSync.cpp \
            src/MediaDirectory.cpp \
            src/MediaLibrary.cpp \
            src/DeviceScanner.cpp \
            src/DeviceManager.cpp \
            src/Device.cpp \
            src/FileScanner.cpp \
            src/ItemImage.cpp \
            src/Shot.cpp \
            src/ShotTelemetry.cpp \
            src/ShotModel.cpp \
            src/ShotFilter.cpp \
            src/ShotProvider.cpp \
            src/GenericFileModel.cpp \
            src/GoProFileModel.cpp \
            src/GridThumbnailer.cpp \
            src/GpmfBuffer.cpp \
            src/GpmfKLV.cpp \
            src/GpmfTags.cpp \
            src/utils_app.cpp \
            src/utils_ffmpeg.cpp \
            src/utils_maths.cpp

HEADERS  += src/SettingsManager.h \
            src/JobManager.h \
            src/JobWorkerAsync.h \
            src/JobWorkerSync.h \
            src/MediaDirectory.h \
            src/MediaLibrary.h \
            src/DeviceScanner.h \
            src/DeviceManager.h \
            src/Device.h \
            src/FileScanner.h \
            src/ItemImage.h \
            src/Shot.h \
            src/ShotModel.h \
            src/ShotFilter.h \
            src/ShotProvider.h \
            src/GenericFileModel.h \
            src/GoProFileModel.h \
            src/GridThumbnailer.h \
            src/GpmfBuffer.h \
            src/GpmfKLV.h \
            src/GpmfTags.h \
            src/utils_app.h \
            src/utils_ffmpeg.h \
            src/utils_maths.h \
            src/utils_enums.h

RESOURCES += qml/qml.qrc \
             i18n/i18n.qrc \
             assets/assets.qrc

OTHER_FILES += .travis.yml \
               contribs/contribs.py \
               deploy_linux.sh \
               deploy_macos.sh \
               deploy_windows.sh

#TRANSLATIONS = i18n/offloadbuddy_fr.ts

lupdate_only { SOURCES += qml/*.qml qml/*.js }

# App features #################################################################

# Use Qt Quick compiler
# CONFIG += qtquickcompiler

DEFINES += ENABLE_FFMPEG
DEFINES += ENABLE_LIBEXIF
DEFINES += ENABLE_MINIVIDEO
unix { DEFINES += ENABLE_LIBMTP }

#DEFINES += USE_CONTRIBS

# SingleApplication for desktop OS
include(src/thirdparty/SingleApplication/singleapplication.pri)
DEFINES += QAPPLICATION_CLASS=QApplication

# macOS icon
ICON = assets/desktop/$$lower($${TARGET}).icns
# Windows icon
RC_ICONS = assets/desktop/$$lower($${TARGET}).ico

# Build settings ###############################################################

unix {
    # Enables AddressSanitizer
    #QMAKE_CXXFLAGS += -fsanitize=address,undefined
    #QMAKE_LFLAGS += -fsanitize=address,undefined

    #QMAKE_CXXFLAGS += -Wno-nullability-completeness
}

DEFINES += QT_DEPRECATED_WARNINGS

# Dependencies #################################################################

contains(DEFINES, USE_CONTRIBS) {

    ARCH = "x86_64"
    linux { PLATFORM = "linux" }
    macx { PLATFORM = "macOS" }
    win32 { PLATFORM = "windows" }
    CONTRIBS_DIR = $${PWD}/contribs/env/$${PLATFORM}_$${ARCH}/usr

    INCLUDEPATH     += $${CONTRIBS_DIR}/include/
    QMAKE_LIBDIR    += $${CONTRIBS_DIR}/lib/
    QMAKE_RPATHDIR  += $${CONTRIBS_DIR}/lib/
    LIBS            += -L$${CONTRIBS_DIR}/lib/

    contains(DEFINES, ENABLE_LIBMTP) { LIBS += -lusb-1.0 -lmtp }
    contains(DEFINES, ENABLE_LIBEXIF) { LIBS += -lexif }
    contains(DEFINES, ENABLE_EXIV2) { LIBS += -lexiv2 }
    contains(DEFINES, ENABLE_MINIVIDEO) { LIBS += -lminivideo }
    linux {
        CONFIG += link_pkgconfig
        contains(DEFINES, ENABLE_FFMPEG) { PKGCONFIG += libavformat libavcodec libswscale libswresample libavutil }
        INCLUDEPATH += /usr/include/
    } else {
        contains(DEFINES, ENABLE_FFMPEG) { LIBS += -lavformat -lavcodec -lswscale -lswresample -lavutil }
    }

} else {

    !unix { warning("Building $${TARGET} without contribs on windows is untested...") }

    CONFIG += link_pkgconfig
    macx { PKG_CONFIG = /usr/local/bin/pkg-config } # use pkg-config from brew
    macx { INCLUDEPATH += /usr/local/include/ }

    contains(DEFINES, ENABLE_LIBMTP) { PKGCONFIG += libusb-1.0 libmtp }
    contains(DEFINES, ENABLE_LIBEXIF) { PKGCONFIG += libexif }
    contains(DEFINES, ENABLE_EXIV2) { PKGCONFIG += exiv2 }
    contains(DEFINES, ENABLE_MINIVIDEO) { PKGCONFIG += libminivideo }
    contains(DEFINES, ENABLE_FFMPEG) { PKGCONFIG += libavformat libavcodec libswscale libswresample libavutil }
}

################################################################################
# Application deployment and installation steps

linux {
    TARGET = $$lower($${TARGET})

    # Automatic application packaging # Needs linuxdeployqt installed
    #deploy.commands = $${OUT_PWD}/$${DESTDIR}/ -qmldir=qml/
    #install.depends = deploy
    #QMAKE_EXTRA_TARGETS += install deploy

    # Installation
    isEmpty(PREFIX) { PREFIX = /usr/local }
    target_app.files      += $${OUT_PWD}/$${DESTDIR}/$$lower($${TARGET})
    target_app.path        = $${PREFIX}/bin/
    target_icon.files     += $${OUT_PWD}/assets/desktop/$$lower($${TARGET}).svg
    target_icon.path       = $${PREFIX}/share/pixmaps/
    target_appentry.files += $${OUT_PWD}/assets/desktop/$$lower($${TARGET}).desktop
    target_appentry.path   = $${PREFIX}/share/applications
    target_appdata.files  += $${OUT_PWD}/assets/desktop/$$lower($${TARGET}).appdata.xml
    target_appdata.path    = $${PREFIX}/share/appdata
    INSTALLS += target_app target_icon target_appentry target_appdata

    # Clean appdir/ and bin/ directories
    #QMAKE_CLEAN += $${OUT_PWD}/$${DESTDIR}/$$lower($${TARGET})
    #QMAKE_CLEAN += $${OUT_PWD}/appdir/
}

macx {
    # Automatic bundle packaging
    deploy.commands = macdeployqt $${OUT_PWD}/$${DESTDIR}/$${TARGET}.app -qmldir=qml/ -appstore-compliant
    install.depends = deploy
    QMAKE_EXTRA_TARGETS += install deploy

    # Installation
    isEmpty(PREFIX) { PREFIX = /usr/local }
    target.files += $${OUT_PWD}/${DESTDIR}/${TARGET}.app
    target.path = $$(HOME)/Applications
    INSTALLS += target

    # Clean ${TARGET}.app directory
    QMAKE_DISTCLEAN += -r $${OUT_PWD}/${DESTDIR}/${TARGET}.app
}

win32 {
    # Automatic application packaging
    deploy.commands = $$quote(windeployqt $${OUT_PWD}/$${DESTDIR}/ --qmldir qml/)
    install.depends = deploy
    QMAKE_EXTRA_TARGETS += install deploy
}
