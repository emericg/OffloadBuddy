TARGET  = OffloadBuddy
VERSION = 0.1.0

CONFIG += c++14
QT     += core gui svg
QT     += quick quickcontrols2
QT     += charts location

# Features
#DEFINES += ENABLE_LIBMTP
#DEFINES += ENABLE_FFMPEG

# Validate Qt version
if (lessThan(QT_MAJOR_VERSION, 5) | lessThan(QT_MINOR_VERSION, 10)) {
    error("You need Qt 5.10 to build $${TARGET}...")
}

# Build artifacts
OBJECTS_DIR = build/
MOC_DIR     = build/
RCC_DIR     = build/
UI_DIR      = build/
DESTDIR     = bin/

# Sources ######################################################################

SOURCES  += src/main.cpp \
            src/SettingsManager.cpp \
            src/DeviceManager.cpp \
            src/Device.cpp \
            src/Shot.cpp

HEADERS  += src/SettingsManager.h \
            src/DeviceManager.h \
            src/Device.h \
            src/Shot.h

RESOURCES += qml.qrc \
             resources.qrc

include(src/thirdparty/SingleApplication/singleapplication.pri)
DEFINES += QAPPLICATION_CLASS=QApplication

# OS icons (macOS and Windows)
#ICON        = resources/app/$$lower($${TARGET}).icns
#RC_ICONS    = resources/app/$$lower($${TARGET}).ico

# Build ########################################################################

unix {
    contains(DEFINES, ENABLE_LIBMTP) {
        CONFIG += link_pkgconfig
        PKGCONFIG += libusb-1.0 libmtp

        #LIBS += `pkg-config --libs libusb-1.0 libmtp`
        #INCLUDEPATH += `pkg-config --cflags libusb-1.0 libmtp`
    }

    contains(DEFINES, ENABLE_FFMPEG) {
        CONFIG += link_pkgconfig
        PKGCONFIG += libavutil libavparser libavcodec
    }
}

DEFINES += QT_DEPRECATED_WARNINGS

# Additional import path used to resolve QML modules
QML_IMPORT_PATH = qml/
QML_DESIGNER_IMPORT_PATH = qml/

# Deploy #######################################################################
