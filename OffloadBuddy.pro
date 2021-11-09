TARGET  = OffloadBuddy

VERSION = 0.9
DEFINES+= APP_VERSION=\\\"$$VERSION\\\"

CONFIG += c++14
QT     += core qml quickcontrols2 svg
QT     += multimedia location charts

# Validate Qt version
!versionAtLeast(QT_VERSION, 5.12) : error("You need at least Qt version 5.12 for $${TARGET}")
!versionAtMost(QT_VERSION, 6.0) : error("You can't use Qt 6.0+ for $${TARGET}")

# Project features #############################################################

# Use Qt Quick compiler
ios | android { CONFIG += qtquickcompiler }

# Use contribs (otherwise use system libs)
win32 | ios | android { DEFINES += USE_CONTRIBS }

win32 { DEFINES += _USE_MATH_DEFINES }

# SingleApplication for desktop OS
include(src/thirdparty/SingleApplication/singleapplication.pri)
DEFINES += QAPPLICATION_CLASS=QApplication

unix { DEFINES += ENABLE_LIBMTP }

#DEFINES += ENABLE_GSTREAMER

DEFINES += ENABLE_FFMPEG

#DEFINES += ENABLE_LIBCPUID

# Metadata backends
DEFINES += ENABLE_MINIVIDEO
DEFINES += ENABLE_LIBEXIF
#DEFINES += ENABLE_EXIV2

# Zip extraction
include(src/thirdparty/miniz/miniz.pri)

# EGM96 altitude correction
include(src/thirdparty/EGM96/EGM96.pri)

# Fast thumbnailer for photo and video
include(src/thirdparty/MediaThumbnailer/MediaThumbnailer.pri)

# Project files ################################################################

SOURCES  += src/main.cpp \
            src/SettingsManager.cpp \
            src/FirmwareManager.cpp \
            src/JobManager.cpp \
            src/JobWorkerFFmpeg.cpp \
            src/JobWorkerThread.cpp \
            src/JobWorkerASync.cpp \
            src/StorageManager.cpp \
            src/MediaDirectory.cpp \
            src/MediaLibrary.cpp \
            src/DeviceScanner.cpp \
            src/DeviceManager.cpp \
            src/Device.cpp \
            src/DeviceStorage.cpp \
            src/DeviceCapabilities.cpp \
            src/FileScanner.cpp \
            src/ItemImage.cpp \
            src/Job.cpp \
            src/Shot.cpp \
            src/ShotTelemetry.cpp \
            src/ShotModel.cpp \
            src/ShotFilter.cpp \
            src/ShotProvider.cpp \
            src/GenericFileModel.cpp \
            src/GoProFileModel.cpp \
            src/Insta360FileModel.cpp \
            src/GpmfBuffer.cpp \
            src/GpmfKLV.cpp \
            src/GpmfTags.cpp \
            src/GeoCoding.cpp \
            src/utils/utils_app.cpp \
            src/utils/utils_screen.cpp \
            src/utils/utils_language.cpp \
            src/utils/utils_ffmpeg.cpp \
            src/utils/utils_maths.cpp \
            src/utils/utils_sysinfo.cpp

HEADERS  += src/SettingsManager.h \
            src/FirmwareManager.h \
            src/JobManager.h \
            src/Job.h \
            src/JobUtils.h \
            src/JobWorkerFFmpeg.h \
            src/JobWorkerThread.h \
            src/JobWorkerASync.h \
            src/StorageManager.h \
            src/StorageUtils.h \
            src/MediaDirectory.h \
            src/MediaLibrary.h \
            src/MediaUtils.h \
            src/DeviceScanner.h \
            src/DeviceManager.h \
            src/Device.h \
            src/DeviceStorage.h \
            src/DeviceCapabilities.h \
            src/DeviceUtils.h \
            src/FileScanner.h \
            src/ItemImage.h \
            src/Shot.h \
            src/ShotUtils.h \
            src/ShotModel.h \
            src/ShotFilter.h \
            src/ShotProvider.h \
            src/GenericFileModel.h \
            src/GoProFileModel.h \
            src/Insta360FileModel.h \
            src/GpmfBuffer.h \
            src/GpmfKLV.h \
            src/GpmfTags.h \
            src/GeoCoding.h \
            src/utils/utils_app.h \
            src/utils/utils_screen.h \
            src/utils/utils_language.h \
            src/utils/utils_ffmpeg.h \
            src/utils/utils_maths.h \
            src/utils/utils_sysinfo.h \
            src/utils/utils_versionchecker.h

RESOURCES   += qml/qml.qrc \
               i18n/i18n.qrc \
               assets/assets.qrc

OTHER_FILES += .travis.yml \
               .gitignore \
               .github/workflows/builds.yml \
               contribs/contribs.py \
               deploy_linux.sh \
               deploy_macos.sh \
               deploy_windows.sh

#TRANSLATIONS = i18n/offloadbuddy_en.ts

lupdate_only { SOURCES += qml/*.qml qml/*.js qml/components/*.qml }

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

    contains(DEFINES, ENABLE_LIBCPUID) { LIBS += -lcpuid }
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

    contains(DEFINES, ENABLE_LIBCPUID) { PKGCONFIG += libcpuid }
    contains(DEFINES, ENABLE_LIBMTP) { PKGCONFIG += libusb-1.0 libmtp }
    contains(DEFINES, ENABLE_LIBEXIF) { PKGCONFIG += libexif }
    contains(DEFINES, ENABLE_EXIV2) { PKGCONFIG += exiv2 }
    contains(DEFINES, ENABLE_MINIVIDEO) { PKGCONFIG += libminivideo }
    contains(DEFINES, ENABLE_FFMPEG) { PKGCONFIG += libavformat libavcodec libswscale libswresample libavutil }
}

# Build settings ###############################################################

unix {
    # Enables AddressSanitizer
    #QMAKE_CXXFLAGS += -fsanitize=address,undefined
    #QMAKE_LFLAGS += -fsanitize=address,undefined

    #QMAKE_CXXFLAGS += -Wno-nullability-completeness
}

DEFINES += QT_DEPRECATED_WARNINGS

CONFIG(release, debug|release) : DEFINES += QT_NO_DEBUG_OUTPUT

# Build artifacts ##############################################################

OBJECTS_DIR = build/
MOC_DIR     = build/
RCC_DIR     = build/
UI_DIR      = build/
QMLCACHE_DIR= build/

DESTDIR     = bin/

################################################################################
# Application deployment and installation steps

linux:!android {
    TARGET = $$lower($${TARGET})

    # Linux utils
    SOURCES += src/utils/utils_os_linux.cpp
    HEADERS += src/utils/utils_os_linux.h
    QT += dbus

    # Application packaging # Needs linuxdeployqt installed
    #deploy.commands = $${OUT_PWD}/$${DESTDIR}/ -qmldir=qml/
    #install.depends = deploy
    #QMAKE_EXTRA_TARGETS += install deploy

    # Installation
    isEmpty(PREFIX) { PREFIX = /usr/local }
    target_app.files       += $${OUT_PWD}/$${DESTDIR}/$$lower($${TARGET})
    target_app.path         = $${PREFIX}/bin/
    target_icon.files      += $${OUT_PWD}/assets/linux/$$lower($${TARGET}).svg
    target_icon.path        = $${PREFIX}/share/pixmaps/
    target_appentry.files  += $${OUT_PWD}/assets/linux/$$lower($${TARGET}).desktop
    target_appentry.path    = $${PREFIX}/share/applications
    target_appdata.files   += $${OUT_PWD}/assets/linux/$$lower($${TARGET}).appdata.xml
    target_appdata.path     = $${PREFIX}/share/appdata
    INSTALLS += target_app target_icon target_appentry target_appdata

    # Clean appdir/ and bin/ directories
    #QMAKE_CLEAN += $${OUT_PWD}/$${DESTDIR}/$$lower($${TARGET})
    #QMAKE_CLEAN += $${OUT_PWD}/appdir/
}

macx {
    #QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.12
    #message("QMAKE_MACOSX_DEPLOYMENT_TARGET: $$QMAKE_MACOSX_DEPLOYMENT_TARGET")

    # Bundle name
    QMAKE_TARGET_BUNDLE_PREFIX = com.emeric
    QMAKE_BUNDLE = offloadbuddy
    CONFIG += app_bundle

    # macOS utils
    SOURCES += src/utils/utils_os_macos.mm
    HEADERS += src/utils/utils_os_macos.h
    LIBS    += -framework IOKit
    # macOS dock click handler
    SOURCES += src/utils/utils_os_macosdock.mm
    HEADERS += src/utils/utils_os_macosdock.h
    LIBS    += -framework AppKit

    # OS icon
    ICON = $${PWD}/assets/macos/$$lower($${TARGET}).icns
    #QMAKE_ASSET_CATALOGS = $${PWD}/assets/macos/Images.xcassets
    #QMAKE_ASSET_CATALOGS_APP_ICON = "AppIcon"

    # OS infos
    #QMAKE_INFO_PLIST = $${PWD}/assets/macos/Info.plist

    # OS entitlement (sandbox and stuff)
    ENTITLEMENTS.name = CODE_SIGN_ENTITLEMENTS
    ENTITLEMENTS.value = $${PWD}/assets/macos/$$lower($${TARGET}).entitlements
    QMAKE_MAC_XCODE_SETTINGS += ENTITLEMENTS

    #======== Automatic bundle packaging

    # Deploy step (app bundle packaging)
    deploy.commands = macdeployqt $${OUT_PWD}/$${DESTDIR}/$${TARGET}.app -qmldir=qml/ -appstore-compliant
    install.depends = deploy
    QMAKE_EXTRA_TARGETS += install deploy

    # Installation step (note: app bundle packaging)
    isEmpty(PREFIX) { PREFIX = /usr/local }
    target.files += $${OUT_PWD}/${DESTDIR}/${TARGET}.app
    target.path = $$(HOME)/Applications
    INSTALLS += target

    # Clean step
    QMAKE_DISTCLEAN += -r $${OUT_PWD}/${DESTDIR}/${TARGET}.app
}

win32 {
    # OS icon
    RC_ICONS = $${PWD}/assets/windows/$$lower($${TARGET}).ico

    # Deploy step
    deploy.commands = $$quote(windeployqt $${OUT_PWD}/$${DESTDIR}/ --qmldir qml/)
    install.depends = deploy
    QMAKE_EXTRA_TARGETS += install deploy

    # Installation step
    # TODO?

    # Clean step
    # TODO
}
