/*
 * Copyright (C) 2013 Canonical, Ltd.
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
import "../../../../qml/Components"
import Ubuntu.Components 0.1
import Ubuntu.Gestures 0.1

Showable {
    id: showable
    y: stretch ? 0 : -height
    width: parent.width
    height: stretch ? 0 : parent.height

    property bool stretch
    property real hintDisplacement

    onStretchChanged: {
        if (stretch) {
            y = 0;
            height = 0;
        } else {
            y = -parent.height;
            height = parent.height;
        }
    }

    shown: false

    signal dragHandleRecognizedGesture(var dragHandle)

    property string animatedProp: stretch ? "height" : "y"
    property real propValueWhenShown: stretch ? parent.height : 0
    property real propValueWhenHidden: stretch ? 0 : -height

    showAnimation: StandardAnimation { property: animatedProp; to: propValueWhenShown }
    hideAnimation: StandardAnimation { property: animatedProp; to: propValueWhenHidden }

    Image { source: "../../UnityLogo.png"; anchors.fill: parent }

    DragHandle {
        objectName: "upwardsDragHandle"
        id: upwardsDragHandle
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        height: units.gu(2)

        direction: Direction.Upwards
        stretch: showable.stretch
        maxTotalDragDistance: showable.parent.height
        hintDisplacement: showable.hintDisplacement

        onDraggingChanged: {
            if (dragging) {
                dragHandleRecognizedGesture(upwardsDragHandle);
            }
        }

        Rectangle { color: "red"; anchors.fill: parent }
    }

    DragHandle {
        objectName: "downwardsDragHandle"
        id: downwardsDragHandle
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.bottom

        height: units.gu(2)

        direction: Direction.Downwards
        stretch: showable.stretch
        maxTotalDragDistance: showable.parent.height
        hintDisplacement: showable.hintDisplacement

        onDraggingChanged: {
            if (dragging) {
                dragHandleRecognizedGesture(downwardsDragHandle);
            }
        }

        Rectangle { color: "green"; anchors.fill: parent }
    }

}
