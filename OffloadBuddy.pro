TARGET  = OffloadBuddy
VERSION = 0.1.0

CONFIG += c++14
QT     += core gui svg quick quickcontrols2
QT     += multimedia location charts

# Enables or disable optional features
DEFINES += ENABLE_LIBEXIF
DEFINES += ENABLE_MINIVIDEO
unix {
    DEFINES += ENABLE_LIBMTP
    DEFINES += ENABLE_FFMPEG
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
            src/JobWorkerAsync.cpp \
            src/JobWorkerSync.cpp \
            src/MediaManager.cpp \
            src/DeviceScanner.cpp \
            src/DeviceManager.cpp \
            src/Device.cpp \
            src/FileScanner.cpp \
            src/Shot.cpp \
            src/ShotModel.cpp \
            src/ShotFilter.cpp \
            src/GenericFileModel.cpp \
            src/GoProFileModel.cpp

HEADERS  += src/SettingsManager.h \
            src/JobManager.h \
            src/JobWorkerAsync.h \
            src/JobWorkerSync.h \
            src/MediaManager.h \
            src/DeviceScanner.h \
            src/DeviceManager.h \
            src/Device.h \
            src/FileScanner.h \
            src/Shot.h \
            src/ShotModel.h \
            src/ShotFilter.h \
            src/GenericFileModel.h \
            src/GoProFileModel.h

RESOURCES += qml/qml.qrc \
             resources.qrc

include(src/thirdparty/SingleApplication/singleapplication.pri)
DEFINES += QAPPLICATION_CLASS=QApplication

# macOS icon
ICON = resources/app/$$lower($${TARGET}).icns
# Windows icon
RC_ICONS = resources/app/$$lower($${TARGET}).ico

# Build settings ###############################################################

unix {
    # Enables AddressSanitizer
    #QMAKE_CXXFLAGS += -fsanitize=address,undefined
    #QMAKE_LFLAGS += -fsanitize=address,undefined

    QMAKE_CXXFLAGS += -Wno-nullability-completeness
}

DEFINES += QT_DEPRECATED_WARNINGS

# Additional import path used to resolve QML modules
QML_IMPORT_PATH = qml/
QML_DESIGNER_IMPORT_PATH = qml/

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

    INCLUDEPATH     += /usr/include/
    QMAKE_LIBDIR    += /usr/lib/
    LIBS            += -L/usr/lib/

    contains(DEFINES, ENABLE_LIBMTP) { LIBS += -lusb-1.0 -lmtp }
    contains(DEFINES, ENABLE_LIBEXIF) { LIBS += -lexif }
    contains(DEFINES, ENABLE_MINIVIDEO) { LIBS += -lminivideo }
    contains(DEFINES, ENABLE_FFMPEG) { LIBS += -lavformat -lavcodec -lswscale -lswresample -lavutil }

} else {

    !unix { warning("Building ReShoot without contribs on windows is untested...") }

    CONFIG += link_pkgconfig

    # PKG_CONFIG_PATH = "contribs/env/usr/lib/pkgconfig:$(PKG_CONFIG_PATH)"
    # warning("PKG_CONFIG_PATH: " $(PKG_CONFIG_PATH))

    #system("pkg-config --exists libmtp")
    #    DEFINES -= ENABLE_LIBMTP

    contains(DEFINES, ENABLE_LIBMTP) {
        PKGCONFIG += libusb-1.0 libmtp
    }
    contains(DEFINES, ENABLE_LIBEXIF) {
        PKGCONFIG += libexif
    }
    contains(DEFINES, ENABLE_MINIVIDEO) {
        PKGCONFIG += libminivideo
    }
    contains(DEFINES, ENABLE_FFMPEG) {
        PKGCONFIG += libavformat libavcodec libswscale libswresample libavutil
    }
}

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
    #QMAKE_CLEAN += $${OUT_PWD}/appdir
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
