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
#include "JobManager.h"
#include "DeviceManager.h"

#include <singleapplication.h>

#ifdef ENABLE_MINIVIDEO
#include <minivideo.h>
#endif

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>

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

#ifndef NDEBUG
    qDebug() << "* This is a DEBUG build";
#endif

    qDebug() << "- Qt version:" << QT_VERSION_MAJOR << QT_VERSION_MINOR << QT_VERSION_PATCH;
#ifdef ENABLE_LIBMTP
    qDebug() << "- libmtp enabled, version:" << LIBMTP_VERSION_STRING;
#endif
#ifdef ENABLE_LIBEXIF
    qDebug() << "- libexif enabled";
#endif
#ifdef ENABLE_MINIVIDEO
    int mv_maj, mv_min, mv_patch;
    minivideo_get_infos(&mv_maj, &mv_min, &mv_patch, nullptr, nullptr, nullptr);
    qDebug() << "- minivideo enabled, version:" << mv_maj << mv_min << mv_patch;
#endif
}

static void exithandler()
{
    JobManager *j = JobManager::getInstance();
    j->cleanup();
}

int main(int argc, char *argv[])
{
    print_build_infos();

    QCoreApplication::setApplicationName("OffloadBuddy");
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    //SingleApplication app(argc, argv);
    QGuiApplication app(argc, argv);
    app.setApplicationDisplayName("OffloadBuddy");

    QIcon appIcon(":/appicons/offloadbuddy.svg");
    app.setWindowIcon(appIcon);

    ////////////////////////////////////////////////////////////////////////////

    SettingsManager *s = SettingsManager::getInstance();

    JobManager *j = JobManager::getInstance();
    atexit(exithandler); // will stop running job on exit

    DeviceManager *d = new DeviceManager;
    d->searchDevices();

    ////////////////////////////////////////////////////////////////////////////

    qmlRegisterSingletonType(
        QUrl("qrc:/qml/ThemeEngine.qml"),
        "com.offloadbuddy.style", 1, 0,
        "ThemeEngine");

    qmlRegisterUncreatableMetaObject(
        Shared::staticMetaObject,
        "com.offloadbuddy.shared", 1, 0,
        "Shared",             // name in QML (does not have to match C++ name)
        "Error: only enums"); // error in case someone tries to create a MyNamespace object

    qmlRegisterType<Shot>("com.offloadbuddy.shared", 1, 0, "Shot");

    QQmlApplicationEngine engine;
    QQmlContext *engine_context = engine.rootContext();
    engine_context->setContextProperty("settingsManager", s);
    engine_context->setContextProperty("jobManager", j);
    engine_context->setContextProperty("deviceManager", d);

    engine.load(QUrl(QStringLiteral("qrc:/qml/MainWindow.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    //QObject::connect(&app, &SingleApplication::instanceStarted, view, &QQuickView::show);
    //QObject::connect(&app, &SingleApplication::instanceStarted, view, &QQuickView::raise);

    return app.exec();
}
