/*
 * Copyright 2013-2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.2
import Ubuntu.Components 1.1
import Ubuntu.Settings.Components 0.1
import "Indicators"

IndicatorDelegate {
    id: root

    property string identifier
    property string title: indicatorName.text
    property alias leftLabel: leftLabelItem.text
    property alias rightLabel: rightLabelItem.text
    property var icons: undefined
    property bool expanded: false
    property bool selected: false
    property real iconHeight: units.gu(2)
    readonly property color color: {
        if (!expanded) return "#ffffff";
        if (!selected) return "#888888";
        return "#ffffff";
    }

    signal clicked()

    implicitWidth: mainItems.width

    MouseArea {
        anchors.fill: parent
        onClicked: parent.clicked()
    }

    Item {
        id: mainItems
        anchors.centerIn: parent

        width: leftLabelItem.width + iconsItem.width + rightLabelItem.width
        implicitHeight: units.gu(2)

        Label {
            id: leftLabelItem
            objectName: "leftLabel"

            anchors {
                left: mainItems.left
                verticalCenter: parent.verticalCenter
            }
            width: contentWidth > 0 ? contentWidth + units.gu(1) : 0
            horizontalAlignment: Text.AlignHCenter

            opacity: 1.0
            font.family: "Ubuntu"
            fontSize: "medium"
            color: root.color
            Behavior on color { ColorAnimation { duration: UbuntuAnimation.FastDuration; easing: UbuntuAnimation.StandardEasing } }
        }

        Item {
            id: iconsItem
            objectName: "icons"

            width: iconRow.width > 0 ? iconRow.width + units.gu(1) : 0
            anchors {
                left: leftLabelItem.right
                verticalCenter: parent.verticalCenter
            }

            Row {
                id: iconRow
                anchors.centerIn: iconsItem
                spacing: units.gu(1)

                Repeater {
                    id: iconRepeater
                    objectName: "iconRepeater"

                    model: d.useFallbackIcon ? [ "image://theme/settings" ] : root.icons

                    Icon {
                        id: itemImage
                        objectName: "icon"+index
                        height: iconHeight
                        // FIXME Workaround for bug https://bugs.launchpad.net/ubuntu/+source/ubuntu-ui-toolkit/+bug/1421293
                        width: implicitWidth > 0 && implicitHeight > 0 ? (implicitWidth / implicitHeight * height) : implicitWidth;
                        source: modelData
                        color: root.color
                        Behavior on color { ColorAnimation { duration: UbuntuAnimation.FastDuration; easing: UbuntuAnimation.StandardEasing } }

                        opacity: {
                            if (!expanded) return 1.0;
                            if (!selected) return 0.6;
                            return 1.0;
                        }
                        Behavior on opacity { NumberAnimation { duration: UbuntuAnimation.FastDuration; easing: UbuntuAnimation.StandardEasing } }
                    }
                }
            }
        }

        Label {
            id: rightLabelItem
            objectName: "rightLabel"

            anchors {
                left: iconsItem.right
                verticalCenter: parent.verticalCenter
            }
            width: contentWidth > 0 ? contentWidth + units.gu(1) : 0
            horizontalAlignment: Text.AlignHCenter

            opacity: 1.0
            font.family: "Ubuntu"
            fontSize: "medium"
            color: root.color
            Behavior on color { ColorAnimation { duration: UbuntuAnimation.FastDuration; easing: UbuntuAnimation.StandardEasing } }
        }
    }

    Label {
        id: indicatorName
        objectName: "indicatorName"

        anchors.top: mainItems.bottom
        anchors.topMargin: units.gu(0.5)
        anchors.horizontalCenter: parent.horizontalCenter
        width: contentWidth > 0 ? contentWidth + units.gu(1) : 0

        text: title !== "" ? title : identifier
        fontSize: "x-small"
        horizontalAlignment: Text.AlignHCenter
        opacity: 0
        color: root.color
        Behavior on color { ColorAnimation { duration: UbuntuAnimation.FastDuration; easing: UbuntuAnimation.StandardEasing } }
    }

    StateGroup {
        id: d
        property bool useFallbackIcon: false

        states: [
            State {
                name: "minimised"
                when: !expanded && ((icons && icons.length > 0) || leftLabel !== "" || rightLabel !== "")
                PropertyChanges { target: indicatorName; opacity: 0}
            },

            State {
                name: "minimised_fallback"
                when: !expanded && (!icons || icons.length === 0) && leftLabel == "" && rightLabel == ""
                PropertyChanges { target: indicatorName; opacity: 0}
                PropertyChanges { target: d; useFallbackIcon: true }
            },

            State {
                name: "expanded"
                PropertyChanges { target: indicatorName; visible: true; opacity: 1}
                PropertyChanges { target: mainItems; anchors.verticalCenterOffset: -units.gu(1) }
            },

            State {
                name: "expanded_icon"
                extend: "expanded"
                when: expanded && (icons && icons.length > 0)
                AnchorChanges { target: iconsItem; anchors.left: undefined; anchors.horizontalCenter: parent.horizontalCenter }
                AnchorChanges { target: leftLabelItem; anchors.left: undefined; anchors.right: iconsItem.left }
                PropertyChanges { target: leftLabelItem; opacity: 0 }
                PropertyChanges { target: leftLabelItem; opacity: 0 }
                PropertyChanges { target: rightLabelItem; opacity: 0 }
                PropertyChanges { target: root; width: Math.max(units.gu(10), Math.max(iconsItem.width, indicatorName.width)) }
            },

            State {
                name: "expanded_fallback"
                extend: "expanded"
                when: expanded && (!icons || icons.length === 0) && leftLabel == "" && rightLabel == ""
                PropertyChanges { target: d; useFallbackIcon: true }
                AnchorChanges { target: iconsItem; anchors.left: undefined; anchors.horizontalCenter: parent.horizontalCenter }
                AnchorChanges { target: leftLabelItem; anchors.left: undefined; anchors.right: iconsItem.left }
                PropertyChanges { target: leftLabelItem; opacity: 0 }
                PropertyChanges { target: leftLabelItem; opacity: 0 }
                PropertyChanges { target: rightLabelItem; opacity: 0 }
                PropertyChanges { target: root; width: Math.max(units.gu(10), Math.max(iconsItem.width, indicatorName.width)) }
            },

            State {
                name: "expanded_rightLabel"
                extend: "expanded"
                when: expanded && (!icons || icons.length === 0) && rightLabel !== ""
                AnchorChanges { target: rightLabelItem; anchors.left: undefined; anchors.horizontalCenter: parent.horizontalCenter }
                PropertyChanges { target: iconsItem; opacity: 0 }
                PropertyChanges { target: leftLabelItem; opacity: 0 }
                PropertyChanges { target: root; width: Math.max(units.gu(10), Math.max(rightLabelItem.width, indicatorName.width)) }
            },

            State {
                name: "expanded_leftLabel"
                extend: "expanded"
                when: expanded && (!icons || icons.length === 0) && leftLabel !== ""
                AnchorChanges { target: leftLabelItem; anchors.left: undefined; anchors.horizontalCenter: parent.horizontalCenter }
                PropertyChanges { target: iconsItem; opacity: 0 }
                PropertyChanges { target: rightLabelItem; opacity: 0 }
                PropertyChanges { target: root; width: Math.max(units.gu(10), Math.max(leftLabelItem.width, indicatorName.width)) }
            }
        ]

        transitions: [
            Transition {
                PropertyAction { target: d; property: "useFallbackIcon" }
                AnchorAnimation {
                    targets: [ mainItems, iconsItem, leftLabelItem, rightLabelItem ]
                    duration: UbuntuAnimation.SnapDuration; easing: UbuntuAnimation.StandardEasing
                }
                PropertyAnimation {
                    targets: [ root, mainItems, iconsItem, leftLabelItem, rightLabelItem, indicatorName ]
                    properties: "width, opacity, anchors.verticalCenterOffset";
                    duration: UbuntuAnimation.SnapDuration; easing: UbuntuAnimation.StandardEasing
                }
            }
        ]
    }

    rootActionState.onUpdated: {
        if (rootActionState == undefined) {
            title = "";
            leftLabel = "";
            rightLabel = "";
            icons = undefined;
            return;
        }

        title = rootActionState.title ? rootActionState.title : rootActionState.accessibleName;
        leftLabel = rootActionState.leftLabel ? rootActionState.leftLabel : "";
        rightLabel = rootActionState.rightLabel ? rootActionState.rightLabel : "";
        icons = rootActionState.icons;
    }
}
