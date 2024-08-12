/*!
 * This file is part of OffloadBuddy.
 * COPYRIGHT (C) 2020 Emeric Grange - All Rights Reserved
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * \author    Emeric Grange <emeric.grange@gmail.com>
 * \date      2018
 */

#include "SettingsManager.h"
#include "StorageManager.h"
#include "DeviceManager.h"
#include "FirmwareManager.h"
#include "JobManager.h"
#include "MediaLibrary.h"

#include "ShotUtils.h"
#include "ItemImage.h"
#include "MediaThumbnailer.h"

#include "utils_app.h"
#include "utils_screen.h"
#include "utils_sysinfo.h"
#include "utils_language.h"
#include "utils_os_macos_dock.h"

#include <SingleApplication>

#ifdef ENABLE_MINIVIDEO
#include <minivideo.h>
#endif

#include <QtGlobal>
#include <QLibraryInfo>
#include <QTranslator>
#include <QIcon>
#include <QQuickWindow>
#include <QQmlApplicationEngine>
#include <QQmlContext>

/* ************************************************************************** */

void print_build_infos()
{
    qDebug() << "OffloadBuddy::print_build_infos()";
    qDebug() << "* Built on '" << __DATE__ << __TIME__ << "'";

#if !defined(QT_NO_DEBUG) && !defined(NDEBUG)
    qDebug() << "* This is a DEBUG build";
#endif

#if defined(__ICC) || defined(__INTEL_COMPILER)
    qDebug() << "* Built with ICC '" << __INTEL_COMPILER << "/" __INTEL_COMPILER_BUILD_DATE << "'";
#elif defined(_MSC_VER)
    qDebug() << "* Built with MSVC '" <<_MSC_VER<< "'";
#elif defined(__clang__)
    qDebug() << "* Built with CLANG '" << __clang_major__ << __clang_minor__<< "'";
#elif defined(__GNUC__) || defined(__GNUG__)
    qDebug() << "* Built with GCC '" << __GNUC__ << __GNUC_MINOR__ << __GNUC_PATCHLEVEL__ << "'";
#else
    qDebug() << "* Built with an unknown compiler";
#endif

    qDebug() << "- Qt version:" << QT_VERSION_STR;

#ifdef ENABLE_LIBMTP
    qDebug() << "- libmtp enabled, version:" << LIBMTP_VERSION_STRING;
#endif
#ifdef ENABLE_LIBEXIF
    qDebug() << "- libexif enabled";
#endif
#ifdef ENABLE_EXIV2
    qDebug() << "- exiv2 enabled";
#endif
#ifdef ENABLE_LIBCPUID
    qDebug() << "- libcpuid enabled";
#endif
#ifdef ENABLE_MINIVIDEO
    int mv_maj, mv_min, mv_patch;
    minivideo_get_infos(&mv_maj, &mv_min, &mv_patch, nullptr, nullptr, nullptr);
    qDebug() << "- minivideo enabled, version:" << mv_maj << mv_min << mv_patch;
#endif
#ifdef ENABLE_FFMPEG
    qDebug() << "- ffmpeg enabled";
#endif
#ifdef ENABLE_GSTREAMER
    qDebug() << "- GStreamer enabled";
#endif
}

/* ************************************************************************** */

static void exithandler()
{
    JobManager *jm = JobManager::getInstance();
    if (jm) jm->cleanup();
}

/* ************************************************************************** */

int main(int argc, char *argv[])
{
    print_build_infos();

#if defined(Q_OS_LINUX)
    // NVIDIA suspend&resume hack
    if (QLibraryInfo::version() >= QVersionNumber(5, 13, 0))
    {
        auto format = QSurfaceFormat::defaultFormat();
        format.setOption(QSurfaceFormat::ResetNotification);
        QSurfaceFormat::setDefaultFormat(format);
    }

    // Force "old" gstreamer multimedia backend
    //qputenv("QT_MEDIA_BACKEND", "gstreamer");
#endif

    // Mouse wheel hack
    qputenv("QT_QUICK_FLICKABLE_WHEEL_DECELERATION", "2500");

    SingleApplication app(argc, argv, false);

    app.setWindowIcon(QIcon(":/gfx/offloadbuddy.svg"));
    app.setApplicationName("OffloadBuddy");
    app.setApplicationDisplayName("OffloadBuddy");
    app.setOrganizationDomain("OffloadBuddy");
    app.setOrganizationName("OffloadBuddy");

    ////////////////////////////////////////////////////////////////////////////

    // Init OffloadBuddy components
    SettingsManager *sm = SettingsManager::getInstance();
    StorageManager *st = StorageManager::getInstance();
    FirmwareManager *fm = FirmwareManager::getInstance();
    DeviceManager *dm = DeviceManager::getInstance();
    JobManager *jm = JobManager::getInstance();
    MediaLibrary *ml = new MediaLibrary;
    if (!sm || !st || !fm || !dm || !jm || !ml)
    {
        qWarning() << "Cannot init OffloadBuddy components!";
        return EXIT_FAILURE;
    }
    fm->loadCatalogs();
    jm->attachLibrary(ml);
    atexit(exithandler); // will stop running job on exit

    // Init OffloadBuddy utils
    UtilsApp *utilsApp = UtilsApp::getInstance();
    UtilsScreen *utilsScreen = UtilsScreen::getInstance();
    UtilsLanguage *utilsLanguage = UtilsLanguage::getInstance();
    UtilsSysInfo *utilsSysinfo = UtilsSysInfo::getInstance();
    if (!utilsApp || !utilsScreen || !utilsLanguage || !utilsSysinfo)
    {
        qWarning() << "Cannot init OffloadBuddy utils!";
        return EXIT_FAILURE;
    }

    MediaUtils *mediaUtils = new MediaUtils();

    // Set application path
    utilsApp->setAppPath(QString::fromLocal8Bit(argv[0]));

    // Translate the application
    utilsLanguage->loadLanguage(sm->getAppLanguage());

    ////////////////////////////////////////////////////////////////////////////

    qmlRegisterSingletonType(QUrl("qrc:/qml/ThemeEngine.qml"), "ThemeEngine", 1, 0, "Theme");

    qmlRegisterUncreatableMetaObject(DeviceUtils::staticMetaObject, "DeviceUtils", 1, 0,
                                     "DeviceUtils", "Error: only enums");

    qmlRegisterUncreatableMetaObject(JobUtils::staticMetaObject, "JobUtils", 1, 0,
                                     "JobUtils", "Error: only enums");

    qmlRegisterUncreatableMetaObject(SettingsUtils::staticMetaObject, "SettingsUtils", 1, 0,
                                     "SettingsUtils",  "Error: only enums");

    qmlRegisterUncreatableMetaObject(StorageUtils::staticMetaObject, "StorageUtils", 1, 0,
                                     "StorageUtils", "Error: only enums");

    qmlRegisterUncreatableMetaObject(ShotUtils::staticMetaObject, "ShotUtils", 1, 0,
                                     "ShotUtils", "Error: only enums");

    ItemImage::registerQml();

    ////////////////////////////////////////////////////////////////////////////

    // Then we start the UI
    QQmlApplicationEngine engine;
    QQmlContext *engine_context = engine.rootContext();
    engine_context->setContextProperty("settingsManager", sm);
    engine_context->setContextProperty("storageManager", st);
    engine_context->setContextProperty("deviceManager", dm);
    engine_context->setContextProperty("firmwareManager", fm);
    engine_context->setContextProperty("jobManager", jm);
    engine_context->setContextProperty("mediaLibrary", ml);
    engine_context->setContextProperty("utilsApp", utilsApp);
    engine_context->setContextProperty("utilsScreen", utilsScreen);
    engine_context->setContextProperty("mediaUtils", mediaUtils);

    MediaThumbnailer_threadpool *tmb = new MediaThumbnailer_threadpool(utilsSysinfo->getCpuCoreCountPhysical() / 2);
    tmb->registerQml(&engine);

    // Load the main view
    engine.load(QUrl(QStringLiteral("qrc:/qml/Application.qml")));
    if (engine.rootObjects().isEmpty())
    {
        qWarning() << "Cannot init QmlApplicationEngine!";
        return EXIT_FAILURE;
    }

    // For i18n retranslate
    utilsLanguage->setQmlEngine(&engine);

#if defined(Q_OS_MACOS)
    QQuickWindow *window = qobject_cast<QQuickWindow *>(engine.rootObjects().value(0));
    engine_context->setContextProperty("quickWindow", window);

    MacOSDockHandler *dockIconHandler = MacOSDockHandler::getInstance();
    QObject::connect(dockIconHandler, &MacOSDockHandler::dockIconClicked, window, &QQuickWindow::show);
    QObject::connect(dockIconHandler, &MacOSDockHandler::dockIconClicked, window, &QQuickWindow::raise);
#endif

    return app.exec();
}

/* ************************************************************************** */
