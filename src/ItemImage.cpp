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
 * \date      2018
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#include "ItemImage.h"

#include <QQuickItem>
#include <QPainter>

/* ************************************************************************** */

ItemImage::ItemImage(QQuickItem *parent) : QQuickPaintedItem(parent)
{
    m_image = QImage();
}

/* ************************************************************************** */

QImage ItemImage::image() const
{
    return m_image;
}

void ItemImage::setImage(const QImage &image)
{
    m_image = image;
    update();
}

/* ************************************************************************** */

void ItemImage::paint(QPainter *painter)
{
    if (isEnabled() && isVisible())
    {
        QRectF bounding_rect = boundingRect();
        QImage scaled = m_image.scaledToHeight(bounding_rect.height(), Qt::SmoothTransformation);
        QPointF center = bounding_rect.center() - scaled.rect().center();

        if (center.x() < 0) center.setX(0);
        if (center.y() < 0) center.setY(0);

        painter->drawImage(center, scaled);
    }
}

/* ************************************************************************** */
