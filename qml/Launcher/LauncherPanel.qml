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

import QtQuick 2.3
import Ubuntu.Components 1.2
import Ubuntu.Components.ListItems 1.0 as ListItems
import Unity.Launcher 0.1
import Ubuntu.Components.Popups 0.1
import "../Components/ListItems"
import "../Components/"

Rectangle {
    id: root
    color: "#B2000000"

    rotation: inverted ? 180 : 0

    property var model
    property bool inverted: false
    property bool dragging: false
    property bool moving: launcherListView.moving || launcherListView.flicking
    property bool preventHiding: moving || dndArea.draggedIndex >= 0 || quickList.state === "open" || dndArea.pressed
    property int highlightIndex: -1

    signal applicationSelected(string appId)
    signal showDashHome()

    onXChanged: {
        if (quickList.state == "open") {
            quickList.state = ""
        }
    }

    Column {
        id: mainColumn
        anchors {
            fill: parent
        }

        Item {
            objectName: "buttonShowDashHome"
            width: parent.width
            height: units.gu(7)
            clip: true

            UbuntuShape {
                anchors {
                    fill: parent
                    topMargin: -units.gu(2)
                }
                borderSource: "none"
                color: UbuntuColors.orange
            }

            Image {
                objectName: "dashItem"
                width: units.gu(5)
                height: width
                anchors.centerIn: parent
                source: "graphics/home.png"
                rotation: root.rotation
            }
            AbstractButton {
                id: dashItem
                anchors.fill: parent
                onClicked: root.showDashHome()
            }
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height - dashItem.height - parent.spacing*2

            Item {
                id: launcherListViewItem
                anchors.fill: parent
                clip: true

                ListView {
                    id: launcherListView
                    objectName: "launcherListView"
                    anchors {
                        fill: parent
                        topMargin: -extensionSize + units.gu(0.5)
                        bottomMargin: -extensionSize + units.gu(1)
                        leftMargin: units.gu(0.5)
                        rightMargin: units.gu(0.5)
                    }
                    topMargin: extensionSize
                    bottomMargin: extensionSize
                    height: parent.height - dashItem.height - parent.spacing*2
                    model: root.model
                    cacheBuffer: itemHeight * 3
                    snapMode: interactive ? ListView.SnapToItem : ListView.NoSnap
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: (height - itemHeight) / 2
                    preferredHighlightEnd: (height + itemHeight) / 2

                    // for the single peeking icon, when alert-state is set on delegate
                    property int peekingIndex: -1

                    // The size of the area the ListView is extended to make sure items are not
                    // destroyed when dragging them outside the list. This needs to be at least
                    // itemHeight to prevent folded items from disappearing and DragArea limits
                    // need to be smaller than this size to avoid breakage.
                    property int extensionSize: 0

                    // Setting extensionSize after the list has been populated because it has
                    // the potential to mess up with the intial positioning in combination
                    // with snapping to the center of the list. This catches all the cases
                    // where the item would be outside the list for more than itemHeight / 2.
                    // For the rest, give it a flick to scroll to the beginning. Note that
                    // the flicking alone isn't enough because in some cases it's not strong
                    // enough to overcome the snapping.
                    // https://bugreports.qt-project.org/browse/QTBUG-32251
                    Component.onCompleted: {
                        extensionSize = itemHeight * 3
                        flick(0, clickFlickSpeed)
                    }

                    // The height of the area where icons start getting folded
                    property int foldingStartHeight: units.gu(6.5)
                    // The height of the area where the items reach the final folding angle
                    property int foldingStopHeight: foldingStartHeight - itemHeight - spacing
                    property int itemWidth: units.gu(7)
                    property int itemHeight: units.gu(6.5)
                    property int clickFlickSpeed: units.gu(60)
                    property int draggedIndex: dndArea.draggedIndex
                    property real realContentY: contentY - originY + topMargin
                    property int realItemHeight: itemHeight + spacing

                    // In case the start dragging transition is running, we need to delay the
                    // move because the displaced transition would clash with it and cause items
                    // to be moved to wrong places
                    property bool draggingTransitionRunning: false
                    property int scheduledMoveTo: -1

                    UbuntuNumberAnimation {
                        id: snapToBottomAnimation
                        target: launcherListView
                        property: "contentY"
                        to: launcherListView.originY + launcherListView.topMargin
                    }

                    UbuntuNumberAnimation {
                        id: snapToTopAnimation
                        target: launcherListView
                        property: "contentY"
                        to: launcherListView.contentHeight - launcherListView.height + launcherListView.originY - launcherListView.topMargin
                    }

                    UbuntuNumberAnimation {
                        id: moveAnimation
                        target: launcherListView
                        property: "contentY"
                        function moveTo(contentY) {
                            from = launcherListView.contentY;
                            to = contentY;
                            start();
                        }
                    }

                    displaced: Transition {
                        NumberAnimation { properties: "x,y"; duration: UbuntuAnimation.FastDuration; easing: UbuntuAnimation.StandardEasing }
                    }

                    delegate: FoldingLauncherDelegate {
                        id: launcherDelegate
                        objectName: "launcherDelegate" + index
                        // We need the appId in the delegate in order to find
                        // the right app when running autopilot tests for
                        // multiple apps.
                        readonly property string appId: model.appId
                        itemHeight: launcherListView.itemHeight
                        itemWidth: launcherListView.itemWidth
                        width: itemWidth
                        height: itemHeight
                        iconName: model.icon
                        count: model.count
                        countVisible: model.countVisible
                        progress: model.progress
                        itemRunning: model.running
                        itemFocused: model.focused
                        inverted: root.inverted
                        alerting: model.alerting
                        z: -Math.abs(offset)
                        maxAngle: 55
                        property bool dragging: false

                        SequentialAnimation {
                            id: peekingAnimation

                            // revealing
                            PropertyAction { target: root; property: "visible"; value: (launcher.visibleWidth === 0) ? 1 : 0 }
                            PropertyAction { target: launcherListViewItem; property: "clip"; value: 0 }

                            UbuntuNumberAnimation {
                                target: launcherDelegate
                                alwaysRunToEnd: true
                                loops: 1
                                properties: "x"
                                to: (units.gu(.5) + launcherListView.width * .5) * (root.inverted ? -1 : 1)
                                duration: UbuntuAnimation.BriskDuration
                            }

                            // hiding
                            UbuntuNumberAnimation {
                                target: launcherDelegate
                                alwaysRunToEnd: true
                                loops: 1
                                properties: "x"
                                to: 0
                                duration: UbuntuAnimation.BriskDuration
                            }

                            PropertyAction { target: launcherListViewItem; property: "clip"; value: 1 }
                            PropertyAction { target: root; property: "visible"; value: (launcher.visibleWidth === 0) ? 0 : 1 }
                        }

                        onAlertingChanged: {
                            if(alerting) {
                                if (!dragging && (launcherListView.peekingIndex === -1 || launcher.visibleWidth > 0)) {
                                      var itemPosition = index * launcherListView.itemHeight;
                                      var height = launcherListView.height - launcherListView.topMargin - launcherListView.bottomMargin
                                      var distanceToEnd = index == 0 || index == launcherListView.count - 1 ? 0 : launcherListView.itemHeight
                                      if (itemPosition + launcherListView.itemHeight + distanceToEnd > launcherListView.contentY + launcherListView.topMargin + height) {
                                          moveAnimation.moveTo(itemPosition + launcherListView.itemHeight - launcherListView.topMargin - height + distanceToEnd);
                                      } else if (itemPosition - distanceToEnd < launcherListView.contentY + launcherListView.topMargin) {
                                          moveAnimation.moveTo(itemPosition - distanceToEnd - launcherListView.topMargin);
                                      }
                                    if (!dragging && launcher.state !== "visible") {
                                        peekingAnimation.start()
                                    }
                                }

                                if (launcherListView.peekingIndex === -1) {
                                    launcherListView.peekingIndex = index
                                }
                            } else {
                                if (launcherListView.peekingIndex === index) {
                                    launcherListView.peekingIndex = -1
                                }
                            }
                        }

                        ThinDivider {
                            id: dropIndicator
                            objectName: "dropIndicator"
                            anchors.centerIn: parent
                            width: parent.width + mainColumn.anchors.leftMargin + mainColumn.anchors.rightMargin
                            opacity: 0
                            source: "graphics/divider-line.png"
                        }

                        states: [
                            State {
                                name: "selected"
                                when: dndArea.selectedItem === launcherDelegate && fakeDragItem.visible && !dragging
                                PropertyChanges {
                                    target: launcherDelegate
                                    itemOpacity: 0
                                }
                            },
                            State {
                                name: "dragging"
                                when: dragging
                                PropertyChanges {
                                    target: launcherDelegate
                                    height: units.gu(1)
                                    itemOpacity: 0
                                }
                                PropertyChanges {
                                    target: dropIndicator
                                    opacity: 1
                                }
                            },
                            State {
                                name: "expanded"
                                when: dndArea.draggedIndex >= 0 && (dndArea.preDragging || dndArea.dragging || dndArea.postDragging) && dndArea.draggedIndex != index
                                PropertyChanges {
                                    target: launcherDelegate
                                    angle: 0
                                    offset: 0
                                    itemOpacity: 0.6
                                }
                            }
                        ]

                        transitions: [
                            Transition {
                                from: ""
                                to: "selected"
                                NumberAnimation { properties: "itemOpacity"; duration: UbuntuAnimation.FastDuration }
                            },
                            Transition {
                                from: "*"
                                to: "expanded"
                                NumberAnimation { properties: "itemOpacity"; duration: UbuntuAnimation.FastDuration }
                                UbuntuNumberAnimation { properties: "angle,offset" }
                            },
                            Transition {
                                from: "expanded"
                                to: ""
                                NumberAnimation { properties: "itemOpacity"; duration: UbuntuAnimation.BriskDuration }
                                UbuntuNumberAnimation { properties: "angle,offset" }
                            },
                            Transition {
                                id: draggingTransition
                                from: "selected"
                                to: "dragging"
                                SequentialAnimation {
                                    PropertyAction { target: launcherListView; property: "draggingTransitionRunning"; value: true }
                                    ParallelAnimation {
                                        UbuntuNumberAnimation { properties: "height" }
                                        NumberAnimation { target: dropIndicator; properties: "opacity"; duration: UbuntuAnimation.FastDuration }
                                    }
                                    ScriptAction {
                                        script: {
                                            if (launcherListView.scheduledMoveTo > -1) {
                                                launcherListView.model.move(dndArea.draggedIndex, launcherListView.scheduledMoveTo)
                                                dndArea.draggedIndex = launcherListView.scheduledMoveTo
                                                launcherListView.scheduledMoveTo = -1
                                            }
                                        }
                                    }
                                    PropertyAction { target: launcherListView; property: "draggingTransitionRunning"; value: false }
                                }
                            },
                            Transition {
                                from: "dragging"
                                to: "*"
                                NumberAnimation { target: dropIndicator; properties: "opacity"; duration: UbuntuAnimation.SnapDuration }
                                NumberAnimation { properties: "itemOpacity"; duration: UbuntuAnimation.BriskDuration }
                                SequentialAnimation {
                                    ScriptAction { script: if (index == launcherListView.count-1) launcherListView.flick(0, -launcherListView.clickFlickSpeed); }
                                    UbuntuNumberAnimation { properties: "height" }
                                    ScriptAction { script: if (index == launcherListView.count-1) launcherListView.flick(0, -launcherListView.clickFlickSpeed); }
                                    PropertyAction { target: dndArea; property: "postDragging"; value: false }
                                    PropertyAction { target: dndArea; property: "draggedIndex"; value: -1 }
                                }
                            }
                        ]
                    }

                    MouseArea {
                        id: dndArea
                        objectName: "dndArea"
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        anchors {
                            fill: parent
                            topMargin: launcherListView.topMargin
                            bottomMargin: launcherListView.bottomMargin
                        }
                        drag.minimumY: -launcherListView.topMargin
                        drag.maximumY: height + launcherListView.bottomMargin

                        property int draggedIndex: -1
                        property var selectedItem
                        property bool preDragging: false
                        property bool dragging: !!selectedItem && selectedItem.dragging
                        property bool postDragging: false
                        property int startX
                        property int startY

                        onPressed: {
                            selectedItem = launcherListView.itemAt(mouseX, mouseY + launcherListView.realContentY)
                        }

                        onClicked: {
                            Haptics.play();
                            var index = Math.floor((mouseY + launcherListView.realContentY) / launcherListView.realItemHeight);
                            var clickedItem = launcherListView.itemAt(mouseX, mouseY + launcherListView.realContentY)

                            // Check if we actually clicked an item or only at the spacing in between
                            if (clickedItem === null) {
                                return;
                            }

                            if (mouse.button & Qt.RightButton) { // context menu
                                // Opening QuickList
                                quickList.item = clickedItem;
                                quickList.model = launcherListView.model.get(index).quickList;
                                quickList.appId = launcherListView.model.get(index).appId;
                                quickList.state = "open";
                                return
                            }

                            // First/last item do the scrolling at more than 12 degrees
                            if (index == 0 || index == launcherListView.count - 1) {
                                if (clickedItem.angle > 12) {
                                    launcherListView.flick(0, -launcherListView.clickFlickSpeed);
                                } else if (clickedItem.angle < -12) {
                                    launcherListView.flick(0, launcherListView.clickFlickSpeed);
                                } else {
                                    root.applicationSelected(LauncherModel.get(index).appId);
                                }
                                return;
                            }

                            // the rest launches apps up to an angle of 30 degrees
                            if (clickedItem.angle > 30) {
                                launcherListView.flick(0, -launcherListView.clickFlickSpeed);
                            } else if (clickedItem.angle < -30) {
                                launcherListView.flick(0, launcherListView.clickFlickSpeed);
                            } else {
                                root.applicationSelected(LauncherModel.get(index).appId);
                            }
                        }

                        onCanceled: {
                            endDrag();
                        }

                        onReleased: {
                            endDrag();
                        }

                        function endDrag() {
                            var droppedIndex = draggedIndex;
                            if (dragging) {
                                postDragging = true;
                            } else {
                                draggedIndex = -1;
                            }

                            if (!selectedItem) {
                                return;
                            }

                            selectedItem.dragging = false;
                            selectedItem = undefined;
                            preDragging = false;

                            drag.target = undefined

                            progressiveScrollingTimer.stop();
                            launcherListView.interactive = true;
                            if (droppedIndex >= launcherListView.count - 2 && postDragging) {
                                snapToBottomAnimation.start();
                            } else if (droppedIndex < 2 && postDragging) {
                                snapToTopAnimation.start();
                            }
                        }

                        onPressAndHold: {
                            if (Math.abs(selectedItem.angle) > 30) {
                                return;
                            }

                            Haptics.play();

                            draggedIndex = Math.floor((mouseY + launcherListView.realContentY) / launcherListView.realItemHeight);

                            // Opening QuickList
                            quickList.item = selectedItem;
                            quickList.model = launcherListView.model.get(draggedIndex).quickList;
                            quickList.appId = launcherListView.model.get(draggedIndex).appId;
                            quickList.state = "open";

                            launcherListView.interactive = false

                            var yOffset = draggedIndex > 0 ? (mouseY + launcherListView.realContentY) % (draggedIndex * launcherListView.realItemHeight) : mouseY + launcherListView.realContentY

                            fakeDragItem.iconName = launcherListView.model.get(draggedIndex).icon
                            fakeDragItem.x = units.gu(0.5)
                            fakeDragItem.y = mouseY - yOffset + launcherListView.anchors.topMargin + launcherListView.topMargin
                            fakeDragItem.angle = selectedItem.angle * (root.inverted ? -1 : 1)
                            fakeDragItem.offset = selectedItem.offset * (root.inverted ? -1 : 1)
                            fakeDragItem.count = LauncherModel.get(draggedIndex).count
                            fakeDragItem.progress = LauncherModel.get(draggedIndex).progress
                            fakeDragItem.flatten()
                            drag.target = fakeDragItem

                            startX = mouseX
                            startY = mouseY
                        }

                        onPositionChanged: {
                            if (draggedIndex >= 0) {
                                if (!selectedItem.dragging) {
                                    var distance = Math.max(Math.abs(mouseX - startX), Math.abs(mouseY - startY))
                                    if (!preDragging && distance > units.gu(1.5)) {
                                        preDragging = true;
                                        quickList.state = "";
                                    }
                                    if (distance > launcherListView.itemHeight) {
                                        selectedItem.dragging = true
                                        preDragging = false;
                                    }
                                }
                                if (!selectedItem.dragging) {
                                    return
                                }

                                var itemCenterY = fakeDragItem.y + fakeDragItem.height / 2

                                // Move it down by the the missing size to compensate index calculation with only expanded items
                                itemCenterY += (launcherListView.itemHeight - selectedItem.height) / 2

                                if (mouseY > launcherListView.height - launcherListView.topMargin - launcherListView.bottomMargin - launcherListView.realItemHeight) {
                                    progressiveScrollingTimer.downwards = false
                                    progressiveScrollingTimer.start()
                                } else if (mouseY < launcherListView.realItemHeight) {
                                    progressiveScrollingTimer.downwards = true
                                    progressiveScrollingTimer.start()
                                } else {
                                    progressiveScrollingTimer.stop()
                                }

                                var newIndex = (itemCenterY + launcherListView.realContentY) / launcherListView.realItemHeight

                                if (newIndex > draggedIndex + 1) {
                                    newIndex = draggedIndex + 1
                                } else if (newIndex < draggedIndex) {
                                    newIndex = draggedIndex -1
                                } else {
                                    return
                                }

                                if (newIndex >= 0 && newIndex < launcherListView.count) {
                                    if (launcherListView.draggingTransitionRunning) {
                                        launcherListView.scheduledMoveTo = newIndex
                                    } else {
                                        launcherListView.model.move(draggedIndex, newIndex)
                                        draggedIndex = newIndex
                                    }
                                }
                            }
                        }
                    }
                    Timer {
                        id: progressiveScrollingTimer
                        interval: 2
                        repeat: true
                        running: false
                        property bool downwards: true
                        onTriggered: {
                            if (downwards) {
                                var minY =  -launcherListView.topMargin
                                if (launcherListView.contentY > minY) {
                                    launcherListView.contentY = Math.max(launcherListView.contentY - units.dp(2), minY)
                                }
                            } else {
                                var maxY = launcherListView.contentHeight - launcherListView.height + launcherListView.topMargin + launcherListView.originY
                                if (launcherListView.contentY < maxY) {
                                    launcherListView.contentY = Math.min(launcherListView.contentY + units.dp(2), maxY)
                                }
                            }
                        }
                    }
                }
            }

            LauncherDelegate {
                id: fakeDragItem
                objectName: "fakeDragItem"
                visible: dndArea.draggedIndex >= 0 && !dndArea.postDragging
                itemWidth: launcherListView.itemWidth
                itemHeight: launcherListView.itemHeight
                height: itemHeight
                width: itemWidth
                rotation: root.rotation
                itemOpacity: 0.9

                function flatten() {
                    fakeDragItemAnimation.start();
                }

                UbuntuNumberAnimation {
                    id: fakeDragItemAnimation
                    target: fakeDragItem;
                    properties: "angle,offset";
                    to: 0
                }
            }
        }
    }

    UbuntuShapeForItem {
        id: quickListShape
        objectName: "quickListShape"
        anchors.fill: quickList
        opacity: quickList.state === "open" ? 0.8 : 0
        visible: opacity > 0
        rotation: root.rotation

        Behavior on opacity {
            UbuntuNumberAnimation {}
        }

        image: quickList

        Image {
            anchors {
                right: parent.left
                rightMargin: -units.dp(4)
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: -quickList.offset * (root.inverted ? -1 : 1)
            }
            height: units.gu(1)
            width: units.gu(2)
            source: "graphics/quicklist_tooltip.png"
            rotation: 90
        }

        InverseMouseArea {
            anchors.fill: parent
            enabled: quickList.state == "open"
            onClicked: {
                quickList.state = ""
            }
        }

    }

    Rectangle {
        id: quickList
        objectName: "quickList"
        color: "#f5f5f5"
        // Because we're setting left/right anchors depending on orientation, it will break the
        // width setting after rotating twice. This makes sure we also re-apply width on rotation
        width: root.inverted ? units.gu(30) : units.gu(30)
        height: quickListColumn.height
        visible: quickListShape.visible
        anchors {
            left: root.inverted ? undefined : parent.right
            right: root.inverted ? parent.left : undefined
            margins: units.gu(1)
        }
        y: itemCenter - (height / 2) + offset
        rotation: root.rotation

        property var model
        property string appId
        property var item

        // internal
        property int itemCenter: item ? root.mapFromItem(quickList.item).y + (item.height / 2) : units.gu(1)
        property int offset: itemCenter + (height/2) + units.gu(1) > parent.height ? -itemCenter - (height/2) - units.gu(1) + parent.height :
                             itemCenter - (height/2) < units.gu(1) ? (height/2) - itemCenter + units.gu(1) : 0

        Column {
            id: quickListColumn
            width: parent.width
            height: childrenRect.height

            Repeater {
                id: popoverRepeater
                model: quickList.model

                ListItems.Standard {
                    objectName: "quickListEntry" + index
                    text: (model.clickable ? "" : "<b>") + model.label + (model.clickable ? "" : "</b>")
                    highlightWhenPressed: model.clickable

                    // FIXME: This is a workaround for the theme not being context sensitive. I.e. the
                    // ListItems don't know that they are sitting in a themed Popover where the color
                    // needs to be inverted.
                    __foregroundColor: "black"

                    onClicked: {
                        if (!model.clickable) {
                            return;
                        }
                        Haptics.play();
                        quickList.state = "";
                        // Unsetting model to prevent showing changing entries during fading out
                        // that may happen because of triggering an action.
                        LauncherModel.quickListActionInvoked(quickList.appId, index);
                        quickList.model = undefined;
                    }
                }
            }
        }
    }
}
