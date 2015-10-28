/*
 * Copyright (C) 2014-2015 Canonical, Ltd.
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

import QtQuick 2.3
import Unity.Application 0.1 // For Mir singleton
import Ubuntu.Components 1.1
import "../Components"

MouseArea {
    id: root
    clip: true

    property Item target
    property alias title: titleLabel.text
    property bool active: false
    hoverEnabled: true

    signal close()
    signal minimize()
    signal maximize()

    QtObject {
        id: priv
        property real distanceX
        property real distanceY
        property bool dragging
    }

    onPressedChanged: {
        if (pressed) {
            var pos = mapToItem(root.target, mouseX, mouseY);
            priv.distanceX = pos.x;
            priv.distanceY = pos.y;
            priv.dragging = true;
            Mir.cursorName = "grabbing";
        } else {
            priv.dragging = false;
            Mir.cursorName = "";
        }
    }
    onPositionChanged: {
        if (priv.dragging) {
            var pos = mapToItem(root.target.parent, mouseX, mouseY);
            root.target.x = pos.x - priv.distanceX;
            root.target.y = pos.y - priv.distanceY;
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.bottomMargin: -radius
        radius: units.gu(.5)
        gradient: Gradient {
            GradientStop { color: "#626055"; position: 0 }
            GradientStop { color: "#3C3B37"; position: 1 }
        }
    }

    Row {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: units.gu(0.7) }
        spacing: units.gu(1)
        opacity: root.active ? 1 : 0.5

        WindowControlButtons {
            height: parent.height
            onClose: root.close();
            onMinimize: root.minimize();
            onMaximize: root.maximize();
        }

        Label {
            id: titleLabel
            objectName: "windowDecorationTitle"
            color: "#DFDBD2"
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            fontSize: "small"
            font.bold: true
        }
    }
}
