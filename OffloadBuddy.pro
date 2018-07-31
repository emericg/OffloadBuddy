TARGET  = OffloadBuddy
VERSION = 0.1.0

CONFIG += c++14
QT     += core gui svg
QT     += quick quickcontrols2
QT     += charts location

# Enables or disable optional features
unix {
    DEFINES += ENABLE_LIBMTP
    #DEFINES += ENABLE_FFMPEG
}

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
            src/JobManager.cpp \
            src/MediaManager.cpp \
            src/DeviceManager.cpp \
            src/Device.cpp \
            src/Shot.cpp \
            src/ShotModel.cpp \
            src/GoProFileModel.cpp

HEADERS  += src/SettingsManager.h \
            src/JobManager.h \
            src/MediaManager.h \
            src/DeviceManager.h \
            src/Device.h \
            src/Shot.h \
            src/ShotModel.h \
            src/GoProFileModel.h

RESOURCES += qml.qrc \
             resources.qrc

include(src/thirdparty/SingleApplication/singleapplication.pri)
DEFINES += QAPPLICATION_CLASS=QApplication

# macOS icon
ICON = resources/app/$$lower($${TARGET}).icns
# Windows icon
RC_ICONS = resources/app/$$lower($${TARGET}).ico

# Build ########################################################################

unix {
    # Enables AddressSanitizer
    #QMAKE_CXXFLAGS += -fsanitize=address,undefined
    #QMAKE_LFLAGS += -fsanitize=address,undefined

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

# Application deployment and installation steps
linux {
    TARGET = $$lower($${TARGET})

    # Application packaging # Needs linuxdeployqt installed
    #deploy.commands = $${OUT_PWD}/$${DESTDIR}/ -qmldir=qml/
    #install.depends = deploy
    #QMAKE_EXTRA_TARGETS += install deploy

    # Installation
    isEmpty(PREFIX) { PREFIX = /usr/local }
    target_app.files   += $${OUT_PWD}/$${DESTDIR}/$$lower($${TARGET})
    target_app.path     = $${PREFIX}/bin/
    target_icon.files  += $${OUT_PWD}/resources/app/$$lower($${TARGET}).svg
    target_icon.path    = $${PREFIX}/share/pixmaps/
    target_appentry.files  += $${OUT_PWD}/resources/app/$$lower($${TARGET}).desktop
    target_appentry.path    = $${PREFIX}/share/applications
    target_appdata.files   += $${OUT_PWD}/resources/app/$$lower($${TARGET}).appdata.xml
    target_appdata.path     = $${PREFIX}/share/appdata
    INSTALLS += target_app target_icon target_appentry target_appdata

    # Clean bin/ directory
    #QMAKE_CLEAN += $${OUT_PWD}/$${DESTDIR}/$$lower($${TARGET})
}

macx {
    # Automatic bundle packaging
    deploy.commands = macdeployqt $${OUT_PWD}/$${DESTDIR}/$${TARGET}.app
    install.depends = deploy
    QMAKE_EXTRA_TARGETS += install deploy

    # Installation
    target.files += $${OUT_PWD}/${DESTDIR}/${TARGET}.app
    target.path = $$(HOME)/Applications
    INSTALLS += target

    # Clean bin/ directory
    QMAKE_DISTCLEAN += -r $${OUT_PWD}/${DESTDIR}/${TARGET}.app
}

win32 {
    # Automatic application packaging
    deploy.commands = $$quote(windeployqt $${OUT_PWD}/$${DESTDIR}/ --qmldir qml/)
    install.depends = deploy
    QMAKE_EXTRA_TARGETS += install deploy
}
