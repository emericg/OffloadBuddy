
#include "GeoCoding.h"
#include "Shot.h"

#include <QCoreApplication>
#include <QQmlEngine>
#include <QJSEngine>

#include <QGeoCodingManager>
#include <QGeoServiceProvider>
#include <QGeoCoordinate>
#include <QGeoCodeReply>
#include <QGeoRectangle>

#include <QDebug>

/* ************************************************************************** */
/* ************************************************************************** */

GeoCoding *GeoCoding::getInstance()
{
    static GeoCoding *instance = new GeoCoding(QCoreApplication::instance());
    return instance;
}

GeoCoding *GeoCoding::create(QQmlEngine *, QJSEngine *)
{
    GeoCoding *instance = getInstance();
    QJSEngine::setObjectOwnership(instance, QJSEngine::CppOwnership);
    return instance;
}

GeoCoding::GeoCoding(QObject *parent) : QObject(parent)
{
    geo_pro = new QGeoServiceProvider("osm");
    if (geo_pro) geo_mgr = geo_pro->geocodingManager();
}

/* ************************************************************************** */
/* ************************************************************************** */

void GeoCoding::getLocation(Shot *shot)
{
    //qDebug() << "GeoCoding::getLocation(coord)";

    if (geo_mgr && shot)
    {
        QGeoCoordinate gc(shot->getLatitude(), shot->getLongitude());
        QGeoRectangle gr(gc, 0.1, 0.1);

        QGeoCodeReply *geo_rep = geo_mgr->reverseGeocode(gc, gr);

        if (geo_rep && !geo_rep->isFinished())
        {
            shot->setLocationResponse(geo_rep);
        }
        else
        {
            delete geo_rep;
        }
    }
}

/* ************************************************************************** */
