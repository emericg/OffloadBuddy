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

#ifndef ITEM_IMAGE_H
#define ITEM_IMAGE_H
/* ************************************************************************** */

#include <QQuickPaintedItem>
#include <QImage>

class QQuickItem;
class QPainter;

/* ************************************************************************** */

/*!
 * \brief The ItemImage is used to draw QImage from C++ objects into QML components.
 */
class ItemImage : public QQuickPaintedItem
{
    Q_OBJECT

    Q_PROPERTY(QImage image READ image WRITE setImage NOTIFY imageChanged)

    QImage m_image;

signals:
    void imageChanged();

public:
    ItemImage(QQuickItem *parent = nullptr);

    QImage image() const;
    Q_INVOKABLE void setImage(const QImage &image);

    void paint(QPainter *painter);
};

/* ************************************************************************** */
#endif // ITEM_IMAGE_H
