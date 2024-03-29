/*
 * Copyright (C) 2014, 2015 Canonical, Ltd.
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

import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtTest 1.0
import ".."
import "../../../qml/Notifications"
import "../../../qml/Components/UnityInputInfo"
import Ubuntu.Components 0.1
import Unity.Test 0.1
import Unity.Notifications 1.0

Item {
    width: notificationsRect.width + interactiveControls.width
    height: notificationsRect.height

    Row {
        id: rootRow

        Component {
            id: mockNotification

            QtObject {
                function invokeAction(actionId) {
                    mockModel.actionInvoked(actionId)
                }
            }
        }

        ListModel {
            id: mockModel
            dynamicRoles: true

            signal actionInvoked(string actionId)

            function getRaw(id) {
                return mockNotification.createObject(mockModel)
            }

            // add the default/PlaceHolder notification to the model
            Component.onCompleted: {
                var n = {
                    type: Notification.PlaceHolder,
                    hints: {},
                    summary: "",
                    body: "",
                    icon: "",
                    secondaryIcon: "",
                    actions: []
                }

                append(n)
            }
        }

        function addSwipeToActNotification() {
            var n = {
                type: Notification.SnapDecision,
                hints: {"x-canonical-snap-decisions-swipe": "true"},
                summary: "Incoming call",
                body: "Frank Zappa\n+44 (0)7736 027340",
                icon: "../graphics/avatars/amanda.png",
                secondaryIcon: "incoming-call",
                actions: [{ id: "ok_id", label: "Ok"},
                    { id: "cancel_id", label: "Cancel"},
                    { id: "foo_id", label: "Foo"},
                    { id: "bar_id", label: "Bar"}
                ]
            }

            mockModel.append(n)
        }

        function clearNotifications() {
            mockModel.clear()
        }

        function remove1stNotification() {
            if (mockModel.count > 0)
                mockModel.remove(0)
        }

        Rectangle {
            id: notificationsRect

            width: units.gu(40)
            height: units.gu(71)

            MouseArea{
                id: clickThroughCatcher
                anchors.fill: parent
            }

            Notifications {
                id: notifications

                margin: units.gu(1)

                anchors.fill: parent
                model: mockModel
                hasMouse: UnityInputInfo.mice > 0 // for testing, we add/remove only a mock mouse
            }
        }

        Rectangle {
            id: interactiveControls

            width: units.gu(30)
            height: units.gu(81)
            color: "grey"

            Column {
                spacing: units.gu(1)
                anchors.fill: parent
                anchors.margins: units.gu(1)

                Button {
                    width: parent.width
                    text: "add a SwipeToAct snap-decision"
                    onClicked: rootRow.addSwipeToActNotification()
                }

                Button {
                    width: parent.width
                    text: "remove 1st notification"
                    onClicked: rootRow.remove1stNotification()
                }

                Button {
                    width: parent.width
                    text: "clear model"
                    onClicked: rootRow.clearNotifications()
                }

                RowLayout {
                    Layout.fillWidth: true
                    CheckBox {
                        id: fakeMouseCB
                        onClicked: {
                            if (checked) {
                                UnityInputInfo.inputInfo.addMockMouse();
                            } else {
                                UnityInputInfo.inputInfo.removeMockMouse();
                            }
                        }
                    }
                    Label {
                        text: "With fake mouse"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        ActionModel {
            id: myActionModel
        }

        UnityTestCase {
            id: root
            name: "NotificationRendererTest"
            when: windowShown

            function test_NotificationRenderer_data() {
                return [
                {
                    tag: "Snap Decision with SwipeToAct-widget (accept)",
                    type: Notification.SnapDecision,
                    hints: {"x-canonical-snap-decisions-swipe": "true"},
                    summary: "Incoming call",
                    body: "Frank Zappa\n+44 (0)7736 027340",
                    icon: "../graphics/avatars/amanda.png",
                    secondaryIcon: "../graphics/applicationIcons/facebook.png",
                    actions: myActionModel,
                    summaryVisible: true,
                    bodyVisible: true,
                    iconVisible: true,
                    shaped: true,
                    secondaryIconVisible: true,
                    buttonRowVisible: true,
                    buttonTinted: false,
                    checkSwipeToActAccept: true,
                    checkSwipeToActReject: false
                },
                {
                    tag: "Snap Decision with SwipeToAct-widget (reject)",
                    type: Notification.SnapDecision,
                    hints: {"x-canonical-snap-decisions-swipe": "true"},
                    summary: "Incoming call",
                    body: "Bro Coly\n+49 (0)221 426973",
                    icon: "../graphics/avatars/funky.png",
                    secondaryIcon: "../graphics/applicationIcons/facebook.png",
                    actions: myActionModel,
                    summaryVisible: true,
                    bodyVisible: true,
                    iconVisible: true,
                    shaped: true,
                    secondaryIconVisible: true,
                    buttonRowVisible: true,
                    buttonTinted: false,
                    checkSwipeToActAccept: false,
                    checkSwipeToActReject: true
                }
                ]
            }

            SignalSpy {
                id: clickThroughSpy

                target: clickThroughCatcher
                signalName: "clicked"
            }

            SignalSpy {
                id: actionSpy

                target: mockModel
                signalName: "actionInvoked"
            }

            function cleanup() {
                clickThroughSpy.clear()
                actionSpy.clear()
            }

            function test_NotificationRenderer(data) {
                // populate model with some mock notifications
                mockModel.append(data)

                // add actions to action-model to test against
                myActionModel.append("ok_id", "Ok")
                myActionModel.append("cancel_id", "Cancel")

                // make sure the view is properly updated before going on
                notifications.forceLayout();
                waitForRendering(notifications);

                var notification = findChild(notifications, "notification" + (mockModel.count - 1))
                verify(notification !== undefined, "notification wasn't found");

                waitForRendering(notification);

                var icon = findChild(notification, "icon")
                var interactiveArea = findChild(notification, "interactiveArea")
                var secondaryIcon = findChild(notification, "secondaryIcon")
                var summaryLabel = findChild(notification, "summaryLabel")
                var bodyLabel = findChild(notification, "bodyLabel")
                var buttonRow = findChild(notification, "buttonRow")

                compare(icon.visible, data.iconVisible, "avatar-icon visibility is incorrect")
                if (icon.visible) {
                    compare(icon.shaped, data.shaped, "shaped-status is incorrect")
                }

                // test input does not fall through
                mouseClick(notification)
                if(data.type == Notification.Interactive) {
                    actionSpy.wait()
                    compare(actionSpy.signalArguments[0][0], data.actions[0]["id"], "got wrong id for interactive action")
                }
                compare(clickThroughSpy.count, 0, "click on notification fell through")

                compare(secondaryIcon.visible, data.secondaryIconVisible, "secondary-icon visibility is incorrect")
                compare(summaryLabel.visible, data.summaryVisible, "summary-text visibility is incorrect")
                compare(bodyLabel.visible, data.bodyVisible, "body-text visibility is incorrect")
                compare(buttonRow.visible, data.buttonRowVisible, "button visibility is incorrect")

                if(data.buttonRowVisible) {
                    var swipeButton = findChild(buttonRow, "notify_swipe_button")

                    if (!swipeButton.clickToAct) { // don't run if there's a real mouse
                        var slider = findChild(swipeButton, "slider")
                        var swipeMouseArea = findChild(swipeButton, "swipeMouseArea")
                        var x = swipeMouseArea.width / 2
                        var y = swipeMouseArea.height / 2

                        if(data.checkSwipeToActAccept) {
                            tryCompareFunction(function() { mouseDrag(slider, x, y, (swipeMouseArea.width / 2) - slider.width, 0); return actionSpy.signalArguments.length > 0; }, true);
                            compare(actionSpy.signalArguments[0][0], data.actions.data(0, ActionModel.RoleActionId), "got wrong id for positive action");
                            actionSpy.clear();
                        }
                        if(data.checkSwipeToActReject) {
                            tryCompareFunction(function() { mouseDrag(slider, x, y, -(swipeMouseArea.width / 2), 0); return actionSpy.signalArguments.length > 0; }, true);
                            compare(actionSpy.signalArguments[0][0], data.actions.data(1, ActionModel.RoleActionId), "got wrong id for negative action");
                            actionSpy.clear();
                        }
                    }

                    // add a mock mouse, test clicking the left/right buttons
                    UnityInputInfo.inputInfo.addMockMouse();
                    var leftButton = findChild(swipeButton, "leftButton");
                    var rightButton = findChild(swipeButton, "rightButton");

                    if(data.checkSwipeToActAccept) {
                        mouseClick(rightButton);
                        compare(actionSpy.signalArguments[0][0], data.actions.data(0, ActionModel.RoleActionId), "got wrong id for positive action");
                        actionSpy.clear();
                    }

                    if(data.checkSwipeToActReject) {
                        mouseClick(leftButton);
                        compare(actionSpy.signalArguments[0][0], data.actions.data(1, ActionModel.RoleActionId), "got wrong id for negative action");
                        actionSpy.clear();
                    }
                    UnityInputInfo.inputInfo.removeMockMouse();
                }
            }
        }
    }
}
