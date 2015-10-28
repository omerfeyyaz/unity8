/*
 * Copyright (C) 2012-2014 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 0.1

Item {
    width: parent.width
    height: body.height

    /* Relevant really only for ListViewWithPageHeader case: specify how many pixels we can overlap with the section header */
    readonly property int allowedOverlap: units.dp(1)

    property real __heightToClip: {
        // Check this is in position where clipping is needed
        if (typeof ListViewWithPageHeader !== 'undefined') {
            if (typeof heightToClip !== 'undefined') {
                if (heightToClip >= allowedOverlap) {
                    return heightToClip - allowedOverlap;
                }
            }
        }
        return 0;
    }

    /*!
      \internal
      Reparent so that the visuals of the children does not
      occlude the bottom divider line.
     */
    default property alias children: body.children

    Item {
        id: clippingContainer
        height: parent.height - __heightToClip
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        clip: __heightToClip > 0

        Item {
            id: body
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: childrenRect.height
        }
    }
}
