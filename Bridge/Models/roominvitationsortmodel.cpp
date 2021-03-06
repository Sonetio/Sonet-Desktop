/****************************************************************
 *  This file is part of Emoty.
 *  Emoty is distributed under the following license:
 *
 *  Copyright (C) 2017, Konrad Dębiec
 *
 *  Emoty is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 3
 *  of the License, or (at your option) any later version.
 *
 *  Emoty is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA  02110-1301, USA.
 ****************************************************************/
#include "roominvitationsortmodel.h"

RoomInvitationSortModel::RoomInvitationSortModel(QObject *parent)
 : QSortFilterProxyModel(parent)
{
	roomInvitationModel = new RoomInvitationModel();
	setSourceModel(roomInvitationModel);
	setDynamicSortFilter(true);
	sort(0);
}

RoomInvitationSortModel::~RoomInvitationSortModel()
{
	if(roomInvitationModel != NULL)
		delete roomInvitationModel;
	roomInvitationModel = NULL;
}

void RoomInvitationSortModel::setSearchText(QString search)
{
	searchText = search;
	invalidateFilter();
}

bool RoomInvitationSortModel::filterAcceptsRow(int sourceRow,
        const QModelIndex &sourceParent) const
{
	QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);

	if(searchText != "")
		return sourceModel()->data(index, 0).toString().contains(searchText, Qt::CaseInsensitive);

	return true;
}

bool RoomInvitationSortModel::lessThan(const QModelIndex &left,
                                      const QModelIndex &right) const
{
	QString leftName = sourceModel()->data(left, 0).toString();
	QString rightName = sourceModel()->data(right, 0).toString();

	return QString::localeAwareCompare(leftName, rightName) < 0;
}
