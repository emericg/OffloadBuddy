
#include "GeoCoding.h"
#include "Shot.h"

#include <QGeoCodingManager>
#include <QGeoServiceProvider>
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
    geo_pro = new QGeoServiceProvider("osm");
    if (geo_pro) geo_mgr = geo_pro->geocodingManager();
}

GeoCoding::~GeoCoding()
{
    delete geo_pro;
    delete geo_mgr;
}

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
