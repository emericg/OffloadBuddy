
#include "GeoCoding.h"
#include "Shot.h"

#ifdef ENABLE_QTLOCATION
#include <QGeoCodingManager>
#include <QGeoServiceProvider>
#include <QGeoCoordinate>
#include <QGeoCodeReply>
#include <QGeoRectangle>
#endif
#include <QDebug>

/* ************************************************************************** */

GeoCoding *GeoCoding::instance = nullptr;

GeoCoding *GeoCoding::getInstance()
{
    if (instance == nullptr)
    {
        instance = new GeoCoding();
    }

    return instance;
}

GeoCoding::GeoCoding()
{
#ifdef ENABLE_QTLOCATION
    geo_pro = new QGeoServiceProvider("osm");
    if (geo_pro) geo_mgr = geo_pro->geocodingManager();
#endif
}

GeoCoding::~GeoCoding()
{
#ifdef ENABLE_QTLOCATION
    delete geo_pro;
    delete geo_mgr;
#endif
}

/* ************************************************************************** */

void GeoCoding::getLocation(Shot *shot)
{
    //qDebug() << "GeoCoding::getLocation(coord)";

#ifdef ENABLE_QTLOCATION
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
#endif
}

/* ************************************************************************** */
