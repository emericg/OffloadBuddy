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
#include "JobManager.h"
#include "MediaLibrary.h"
#include "GridThumbnailer.h"
#include "ItemImage.h"

#include "utils/utils_app.h"
#include "utils/utils_screen.h"
#include "utils/utils_language.h"
#include "utils/utils_macosdock.h"

#include <singleapplication.h>

#ifdef ENABLE_MINIVIDEO
#include <minivideo.h>
#endif

#include <QtGlobal>
#include <QTranslator>
#include <QLibraryInfo>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>

/* ************************************************************************** */

void print_build_infos()
{
    qDebug() << "OffloadBuddy::print_build_infos()";
    qDebug() << "* Built on '" << __DATE__ << __TIME__ << "'";

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

#if !defined(QT_NO_DEBUG) && !defined(NDEBUG)
    qDebug() << "* This is a DEBUG build";
#endif

    qDebug() << "- Qt version:" << QT_VERSION_MAJOR << QT_VERSION_MINOR << QT_VERSION_PATCH;
#ifdef ENABLE_LIBMTP
    qDebug() << "- libmtp enabled, version:" << LIBMTP_VERSION_STRING;
#endif
#ifdef ENABLE_LIBEXIF
    qDebug() << "- libexif enabled";
#endif
#ifdef ENABLE_EXIV2
    qDebug() << "- exiv2 enabled";
#endif
#ifdef ENABLE_MINIVIDEO
    int mv_maj, mv_min, mv_patch;
    minivideo_get_infos(&mv_maj, &mv_min, &mv_patch, nullptr, nullptr, nullptr);
    qDebug() << "- minivideo enabled, version:" << mv_maj << mv_min << mv_patch;
#endif
#ifdef ENABLE_FFMPEG
    qDebug() << "- ffmpeg enabled";
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
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);

#if defined(Q_OS_LINUX)
    // NVIDIA suspend&resume hack
    if (QLibraryInfo::version() >= QVersionNumber(5, 13, 0))
    {
        auto format = QSurfaceFormat::defaultFormat();
        format.setOption(QSurfaceFormat::ResetNotification);
        QSurfaceFormat::setDefaultFormat(format);
    }
#endif

    print_build_infos();
    SingleApplication app(argc, argv, false);

    app.setWindowIcon(QIcon(":/appicons/offloadbuddy.svg"));
    app.setApplicationName("OffloadBuddy");
    app.setApplicationDisplayName("OffloadBuddy");
    app.setOrganizationDomain("OffloadBuddy");
    app.setOrganizationName("OffloadBuddy");

    ////////////////////////////////////////////////////////////////////////////

    // Init OffloadBuddy components
    SettingsManager *sm = SettingsManager::getInstance();
    StorageManager *mdm = StorageManager::getInstance();
    MediaLibrary *ml = new MediaLibrary;
    DeviceManager *dm = new DeviceManager;
    JobManager *jm = JobManager::getInstance();
    if (!sm || !ml || !dm || !jm)
    {
        qWarning() << "Cannot init OffloadBuddy components!";
        return EXIT_FAILURE;
    }
    jm->attachLibrary(ml);
    atexit(exithandler); // will stop running job on exit

    // Init OffloadBuddy utils
    UtilsScreen *utilsScreen = UtilsScreen::getInstance();
    UtilsApp *utilsApp = UtilsApp::getInstance();
    UtilsLanguage *utilsLanguage = UtilsLanguage::getInstance();
    if (!utilsScreen || !utilsApp || !utilsLanguage)
    {
        qWarning() << "Cannot init OffloadBuddy utils!";
        return EXIT_FAILURE;
    }

    if (argc > 0 && argv[0])
    {
        QString path = QString::fromLocal8Bit(argv[0]);
        utilsApp->setAppPath(path);
    }

    // Translate the application (demo mode always use english)
    utilsLanguage->loadLanguage(sm->getAppLanguage());

    ////////////////////////////////////////////////////////////////////////////

    qmlRegisterSingletonType(QUrl("qrc:/qml/ThemeEngine.qml"), "ThemeEngine", 1, 0, "Theme");

    qmlRegisterUncreatableMetaObject(
        Shared::staticMetaObject,
        "com.offloadbuddy.shared", 1, 0,
        "Shared",             // name in QML (does not have to match C++ name)
        "Error: only enums"); // error in case someone tries to create a MyNamespace object

    qmlRegisterType<ItemImage>("com.offloadbuddy.shared", 1, 0, "ItemImage");

    // Then we start the UI
    QQmlApplicationEngine engine;
    QQmlContext *engine_context = engine.rootContext();
    engine_context->setContextProperty("settingsManager", sm);
    engine_context->setContextProperty("storageManager", mdm);
    engine_context->setContextProperty("deviceManager", dm);
    engine_context->setContextProperty("jobManager", jm);
    engine_context->setContextProperty("mediaLibrary", ml);
    engine_context->setContextProperty("utilsApp", utilsApp);
    engine.addImageProvider("GridThumbnailer", new GridThumbnailer);

    // Load the main view
    engine.load(QUrl(QStringLiteral("qrc:/qml/Application.qml")));
    if (engine.rootObjects().isEmpty())
    {
        qWarning() << "Cannot init QmlApplicationEngine!";
        return EXIT_FAILURE;
    }

    // For i18n retranslate
    utilsLanguage->setQmlEngine(&engine);

    // QQuickWindow must be valid at this point
    QQuickWindow *window = qobject_cast<QQuickWindow *>(engine.rootObjects().value(0));
    engine_context->setContextProperty("quickWindow", window);

#if defined(Q_OS_MACOS)
    MacOSDockHandler *dockIconHandler = MacOSDockHandler::getInstance();
    QObject::connect(dockIconHandler, &MacOSDockHandler::dockIconClicked, window, &QQuickWindow::show);
    QObject::connect(dockIconHandler, &MacOSDockHandler::dockIconClicked, window, &QQuickWindow::raise);
#endif

    return app.exec();
}

/* ************************************************************************** */
