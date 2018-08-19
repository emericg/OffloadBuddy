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

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>

int main(int argc, char *argv[])
{
#if defined(Q_OS_WIN)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QCoreApplication::setApplicationName("OffloadBuddy");

    //SingleApplication app(argc, argv);
    QGuiApplication app(argc, argv);

    QIcon appIcon(":/appicons/offloadbuddy.svg");
    app.setWindowIcon(appIcon);
    app.setApplicationDisplayName("OffloadBuddy");

    ////////////////////////////////////////////////////////////////////////////

    SettingsManager *s = SettingsManager::getInstance();

    JobManager *j = JobManager::getInstance();

    DeviceManager *d = new DeviceManager;
    d->searchDevices();

    ////////////////////////////////////////////////////////////////////////////

    qmlRegisterSingletonType(QUrl("qrc:/qml/themes.qml"),
                             "com.offloadbuddy.style", 1, 0, "ThemeEngine");

    qmlRegisterUncreatableMetaObject(
      Shared::staticMetaObject,
      "com.offloadbuddy.shared", 1, 0,
      "Shared",                 // name in QML (does not have to match C++ name)
      "Error: only enums"            // error in case someone tries to create a MyNamespace object
    );

    //qRegisterMetaType<Shot*>("Shot*");
    qmlRegisterType<Shot>("com.offloadbuddy.shared", 1, 0, "Shot");

    QQmlApplicationEngine engine;
    QQmlContext *engine_context = engine.rootContext();
    engine_context->setContextProperty("settingsManager", s);
    engine_context->setContextProperty("jobManager", j);
    engine_context->setContextProperty("deviceManager", d);

    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    //QObject::connect(&app, &SingleApplication::instanceStarted, view, &QQuickView::show);
    //QObject::connect(&app, &SingleApplication::instanceStarted, view, &QQuickView::raise);

    return app.exec();
}
