/*
 * Copyright (C) 2014 Canonical, Ltd.
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
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem

ListItem.Empty {
    id: listItem

    property alias text: label.text
    property bool checked: false
    property real leftMargin
    property real rightMargin

    readonly property real labelOffset: label.x

    signal linkActivated(string link)

    implicitHeight: Math.max(label.height, checkBox.height)

    Item {
        anchors.fill: parent

        CheckBox {
            id: checkBox

            anchors {
                left: parent.left
                top: parent.top
                leftMargin: listItem.leftMargin
            }

            Component.onCompleted: {
                checked = listItem.checked;
            }

            onClicked: {
                listItem.checked = checked
                listItem.triggered(listItem.checked)
            }

            Connections {
                target: listItem
                onCheckedChanged: checkBox.checked = listItem.checked
            }

            Connections {
                target: listItem.__mouseArea
                onClicked: {
                    listItem.checked = !listItem.checked
                    listItem.triggered(listItem.checked)
                }
            }
        }

        Label {
            id: label
            anchors {
                left: checkBox.right
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: units.gu(2)
                rightMargin: listItem.rightMargin
            }
            wrapMode: Text.Wrap
            linkColor: Theme.palette.normal.foregroundText
            onLinkActivated: listItem.linkActivated(link)
        }
    }
}
