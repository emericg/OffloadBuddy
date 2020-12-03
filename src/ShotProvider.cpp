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

#include "ShotProvider.h"

/* ************************************************************************** */

ShotProvider::ShotProvider()
{
    m_shotModel = new ShotModel;
    m_shotFilter = new ShotFilter;

    if (m_shotFilter)
    {
        m_shotFilter->setSourceModel(m_shotModel);
        m_shotFilter->setSortRole(ShotModel::DateRole);
        m_shotFilter->sort(0, Qt::AscendingOrder);
    }
}

ShotProvider::~ShotProvider()
{
    delete m_shotModel;
    delete m_shotFilter;
}

/* ************************************************************************** */

void ShotProvider::addShot(Shot *shot)
{
    if (m_shotModel)
    {
        m_shotModel->addShot(shot);
    }
}

void ShotProvider::deleteShot(Shot *shot)
{
    if (m_shotModel)
    {
        m_shotModel->removeShot(shot);
    }
}

/* ************************************************************************** */

void ShotProvider::orderByAsc()
{
    if (m_shotFilter)
    {
        m_shotFilter->sort(0, Qt::AscendingOrder);
        m_shotFilter->invalidate();
    }
}

void ShotProvider::orderByDesc()
{
    if (m_shotFilter)
    {
        m_shotFilter->sort(0, Qt::DescendingOrder);
        m_shotFilter->invalidate();
    }
}

/* ************************************************************************** */

void ShotProvider::orderByDate()
{
    if (m_shotFilter)
    {
        m_shotFilter->setSortRole(ShotModel::DateRole);
        //m_shotFilter->sort(0, Qt::AscendingOrder);
        m_shotFilter->invalidate();
    }
}

void ShotProvider::orderByDuration()
{
    if (m_shotFilter)
    {
        m_shotFilter->setSortRole(ShotModel::DurationRole);
        //m_shotFilter->sort(0, Qt::DescendingOrder);
        m_shotFilter->invalidate();
    }
}

void ShotProvider::orderByShotType()
{
    if (m_shotFilter)
    {
        m_shotFilter->setSortRole(ShotModel::ShotTypeRole);
        //m_shotFilter->sort(0, Qt::AscendingOrder);
        m_shotFilter->invalidate();
    }
}

void ShotProvider::orderByName()
{
    if (m_shotFilter)
    {
        m_shotFilter->setSortRole(ShotModel::NameRole);
        //m_shotFilter->sort(0, Qt::AscendingOrder);
        m_shotFilter->invalidate();
    }
}

void ShotProvider::orderByPath()
{
    if (m_shotFilter)
    {
        m_shotFilter->setSortRole(ShotModel::PathRole);
        //m_shotFilter->sort(0, Qt::AscendingOrder);
        m_shotFilter->invalidate();
    }
}

/* ************************************************************************** */

void ShotProvider::filterByType(const QString &type)
{
    if (m_shotFilter)
    {
        QList <int> types;

        if (type == "Videos")
            types << Shared::SHOT_VIDEO << Shared::SHOT_VIDEO_LOOPING << Shared::SHOT_VIDEO_3D;
        else if (type == "Photos")
            types << Shared::SHOT_PICTURE << Shared::SHOT_PICTURE_BURST;
        else if (type == "Timelapses")
            types << Shared::SHOT_VIDEO_TIMELAPSE << Shared::SHOT_VIDEO_NIGHTLAPSE
                  << Shared::SHOT_PICTURE_MULTI
                  << Shared::SHOT_PICTURE_TIMELAPSE << Shared::SHOT_PICTURE_NIGHTLAPSE;

        m_shotFilter->setAcceptedTypes(types);
        m_shotFilter->invalidate();
    }
}

/* ************************************************************************** */

void ShotProvider::filterByFolder(const QString &path)
{
    if (m_shotFilter)
    {
        m_shotFilter->setAcceptedFolder(path);
        m_shotFilter->invalidate();
    }
}

/* ************************************************************************** */
