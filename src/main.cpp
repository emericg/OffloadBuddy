/*!
 * This file is part of OffloadBuddy.
 * COPYRIGHT (C) 2018 Emeric Grange - All Rights Reserved
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
 * \date      2018
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#include "SettingsManager.h"
#include "MediaLibrary.h"
#include "DeviceManager.h"
#include "JobManager.h"
#include "macosdockmanager.h"

#include "GridThumbnailer.h"
#include "ItemImage.h"
#include "utils_app.h"

#include <singleapplication.h>

#ifdef ENABLE_MINIVIDEO
#include <minivideo.h>
#endif

#include <QTranslator>
#include <QLibraryInfo>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QIcon>

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

#ifndef QT_NO_DEBUG
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
    print_build_infos();

    QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

#ifdef QT_NO_DEBUG
    SingleApplication app(argc, argv);
#else
    QApplication app(argc, argv);
#endif

    app.setApplicationName("OffloadBuddy");
    app.setApplicationDisplayName("OffloadBuddy");
    app.setOrganizationDomain("OffloadBuddy");
    app.setOrganizationName("OffloadBuddy");

    // icon
    QIcon appIcon(":/appicons/offloadbuddy.svg");
    app.setWindowIcon(appIcon);

    // i18n
    QTranslator qtTranslator;
    qtTranslator.load("qt_" + QLocale::system().name(), QLibraryInfo::location(QLibraryInfo::TranslationsPath));
    app.installTranslator(&qtTranslator);

    QTranslator appTranslator;
    appTranslator.load(":/i18n/offloadbuddy.qm");
    app.installTranslator(&appTranslator);

    ////////////////////////////////////////////////////////////////////////////

    UtilsApp *utilsApp = new UtilsApp();
    if (!utilsApp) return EXIT_FAILURE;

    SettingsManager *sm = SettingsManager::getInstance();
    if (sm)
    {
        if (argc > 0 && argv[0])
        {
            QString path = QString::fromLocal8Bit(argv[0]);
            sm->setAppPath(path);
        }
    }

    MediaLibrary *ml = new MediaLibrary;
    //ml->searchMediaDirectories();

    DeviceManager *dm = new DeviceManager;
    //dm->searchDevices();

    JobManager *jm = JobManager::getInstance();
    jm->attachLibrary(ml);
    atexit(exithandler); // will stop running job on exit

    ////////////////////////////////////////////////////////////////////////////

    qmlRegisterSingletonType(
        QUrl("qrc:/qml/ThemeEngine.qml"),
        "ThemeEngine", 1, 0,
        "Theme");

    qmlRegisterUncreatableMetaObject(
        Shared::staticMetaObject,
        "com.offloadbuddy.shared", 1, 0,
        "Shared",             // name in QML (does not have to match C++ name)
        "Error: only enums"); // error in case someone tries to create a MyNamespace object

    qmlRegisterType<Shot>("com.offloadbuddy.shared", 1, 0, "Shot");
    qmlRegisterType<ItemImage>("com.offloadbuddy.shared", 1, 0, "ItemImage");

    QQmlApplicationEngine engine;
    QQmlContext *engine_context = engine.rootContext();
    engine_context->setContextProperty("settingsManager", sm);
    engine_context->setContextProperty("app", utilsApp);
    engine_context->setContextProperty("mediaLibrary", ml);
    engine_context->setContextProperty("deviceManager", dm);
    engine_context->setContextProperty("jobManager", jm);

    engine.addImageProvider("GridThumbnailer", new GridThumbnailer);

    engine.load(QUrl(QStringLiteral("qrc:/qml/Application.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    QQuickWindow *window = qobject_cast<QQuickWindow *>(engine.rootObjects().value(0));

#if defined(Q_OS_MACOS)
    MacOSDockManager *dockIconHandler = MacOSDockManager::getInstance();
    QObject::connect(dockIconHandler, &MacOSDockManager::dockIconClicked, window, &QQuickWindow::show);
    QObject::connect(dockIconHandler, &MacOSDockManager::dockIconClicked, window, &QQuickWindow::raise);
#endif


    return app.exec();
}

/* ************************************************************************** */
