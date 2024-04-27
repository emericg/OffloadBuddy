TARGET  = OffloadBuddy

VERSION = 0.12
DEFINES+= APP_NAME=\\\"$$TARGET\\\"
DEFINES+= APP_VERSION=\\\"$$VERSION\\\"

CONFIG += c++17
QT     += core qml quickcontrols2 svg
QT     += multimedia charts
QT += location

# Validate Qt version
!versionAtLeast(QT_VERSION, 6.5) : error("You need at least Qt version 6.5 for $${TARGET}")

# Project features #############################################################

unix { DEFINES += ENABLE_LIBMTP }

#DEFINES += ENABLE_GSTREAMER
DEFINES += ENABLE_FFMPEG
#DEFINES += ENABLE_LIBCPUID
DEFINES += ENABLE_MINIVIDEO
DEFINES += ENABLE_LIBEXIF
#DEFINES += ENABLE_EXIV2
DEFINES += ENABLE_QTLOCATION

# Use contribs (otherwise use system libs)
win32 | ios | android { DEFINES += USE_CONTRIBS }

# Project modules ##############################################################

# App utils
CONFIG += UTILS_DOCK_ENABLED
include(src/thirdparty/AppUtils/AppUtils.pri)

# SingleApplication for desktop OS
DEFINES += QAPPLICATION_CLASS=QApplication
include(src/thirdparty/SingleApplication/SingleApplication.pri)

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
            src/GeoCoding.cpp

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
            src/GeoCoding.h

RESOURCES   += assets/cameras.qrc assets/gfx.qrc assets/icons.qrc
RESOURCES   += qml/ComponentLibrary/ComponentLibrary.qrc
RESOURCES   += qml/qml.qrc i18n/i18n.qrc \

OTHER_FILES += .gitignore \
               .github/workflows/builds_desktop.yml \
               .github/workflows/flatpak.yml \
               contribs/contribs_builder.py \
               deploy_linux.sh \
               deploy_macos.sh \
               deploy_windows.sh \
               README.md

#TRANSLATIONS = i18n/offloadbuddy_en.ts

lupdate_only { SOURCES += qml/*.qml qml/*.js qml/components/*.qml }

# Dependencies #################################################################

contains(DEFINES, USE_CONTRIBS) {

    ARCH = "x86_64"
    linux { PLATFORM = "linux" }
    win32 { PLATFORM = "windows" }
    macx {
        PLATFORM = "macOS"
        ARCH = "x86_64"
        QMAKE_APPLE_DEVICE_ARCHS = x86_64

        #ARCH = "unified"
        #QMAKE_APPLE_DEVICE_ARCHS = x86_64 arm64
    }

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

    #QMAKE_CXXFLAGS += -Wno-nullability-completeness -fno-omit-frame-pointer
}

win32 { DEFINES += _USE_MATH_DEFINES }

DEFINES += QT_DEPRECATED_WARNINGS

CONFIG(release, debug|release) : DEFINES += NDEBUG QT_NO_DEBUG QT_NO_DEBUG_OUTPUT

# Build artifacts ##############################################################

OBJECTS_DIR = build/
MOC_DIR     = build/
RCC_DIR     = build/
UI_DIR      = build/

DESTDIR     = bin/

################################################################################
# Application deployment and installation steps

linux:!android {
    TARGET = $$lower($${TARGET})

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
    # Bundle name
    QMAKE_TARGET_BUNDLE_PREFIX = com.emeric
    QMAKE_BUNDLE = offloadbuddy
    CONFIG += app_bundle

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

    # Target OS
    QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.15

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
