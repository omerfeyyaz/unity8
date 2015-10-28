/*
 * Copyright (C) 2013-2015 Canonical, Ltd.
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
import QtTest 1.0
import AccountsService 0.1
import GSettings 1.0
import IntegratedLightDM 0.1 as LightDM
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem
import Ubuntu.Telephony 0.1 as Telephony
import Unity.Application 0.1
import Unity.Connectivity 0.1
import Unity.Indicators 0.1
import Unity.Notifications 1.0
import Unity.Test 0.1
import Powerd 0.1
import Wizard 0.1 as Wizard

import "../../qml"
import "Stages"

Rectangle {
    id: root
    color: "grey"
    width: units.gu(100) + controls.width
    height: units.gu(71)

    Component.onCompleted: {
        // must set the mock mode before loading the Shell
        LightDM.Greeter.mockMode = "single";
        LightDM.Users.mockMode = "single";
        shellLoader.active = true;
    }

    Item {
        id: shellContainer
        anchors.left: root.left
        anchors.right: controls.left
        anchors.top: root.top
        anchors.bottom: root.bottom
        Loader {
            id: shellLoader
            focus: true

            anchors.centerIn: parent

            state: "phone"
            states: [
                State {
                    name: "phone"
                    PropertyChanges {
                        target: shellLoader
                        width: units.gu(40)
                        height: units.gu(71)
                    }
                },
                State {
                    name: "tablet"
                    PropertyChanges {
                        target: shellLoader
                        width: units.gu(100)
                        height: units.gu(71)
                    }
                },
                State {
                    name: "desktop"
                    PropertyChanges {
                        target: shellLoader
                        width: shellContainer.width
                        height: shellContainer.height
                    }
                    PropertyChanges {
                        target: mouseEmulation
                        checked: false
                    }
                }
            ]

            active: false
            property bool itemDestroyed: false
            sourceComponent: Component {
                Shell {
                    id: __shell
                    usageScenario: usageScenarioSelector.model[usageScenarioSelector.selectedIndex]
                    orientation: Qt.PortraitOrientation
                    primaryOrientation: Qt.PortraitOrientation
                    nativeOrientation: Qt.PortraitOrientation
                    Component.onDestruction: {
                        shellLoader.itemDestroyed = true;
                    }
                    Component.onCompleted: {
                        var keyMapper = testCase.findChild(__shell, "physicalKeysMapper");
                        keyMapper.controlInsteadOfAlt = true;
                    }
                }
            }
        }
    }

    Flickable {
        id: controls
        contentHeight: controlRect.height

        anchors.top: root.top
        anchors.bottom: root.bottom
        anchors.right: root.right
        width: units.gu(30)

        Rectangle {
            id: controlRect
            anchors { left: parent.left; right: parent.right }
            color: "darkgrey"
            height: childrenRect.height + units.gu(2)

            Column {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: units.gu(1) }
                spacing: units.gu(1)

                Row {
                    spacing: units.gu(1)
                    Button {
                        text: "Show Greeter"
                        activeFocusOnPress: false
                        onClicked: {
                            if (shellLoader.status !== Loader.Ready)
                                return;

                            var greeter = testCase.findChild(shellLoader.item, "greeter");
                            if (!greeter.shown) {
                                LightDM.Greeter.showGreeter();
                            }
                        }
                    }
                    Button {
                        text: "Hide Greeter"
                        activeFocusOnPress: false
                        onClicked: {
                            if (shellLoader.status !== Loader.Ready)
                                return;

                            var greeter = testCase.findChild(shellLoader.item, "greeter");
                            if (greeter.shown) {
                                greeter.hide()
                            }
                        }
                    }
                }
                ListItem.ItemSelector {
                    anchors { left: parent.left; right: parent.right }
                    activeFocusOnPress: false
                    text: "LightDM mock mode"
                    model: ["single", "single-passphrase", "single-pin", "full"]
                    onSelectedIndexChanged: {
                        shellLoader.active = false;
                        LightDM.Greeter.mockMode = model[selectedIndex];
                        LightDM.Users.mockMode = model[selectedIndex];
                        shellLoader.active = true;
                    }
                }
                ListItem.ItemSelector {
                    anchors { left: parent.left; right: parent.right }
                    activeFocusOnPress: false
                    text: "Size"
                    model: ["phone", "tablet", "desktop"]
                    onSelectedIndexChanged: {
                        shellLoader.active = false;
                        shellLoader.state = model[selectedIndex];
                        shellLoader.active = true;
                    }
                }
                ListItem.ItemSelector {
                    id: usageScenarioSelector
                    anchors { left: parent.left; right: parent.right }
                    activeFocusOnPress: false
                    text: "Usage scenario"
                    model: ["phone", "tablet", "desktop"]
                }
                MouseTouchEmulationCheckbox {
                    id: mouseEmulation
                    checked: true
                    color: "white"
                }

                Label { text: "Applications"; font.bold: true }

                Button {
                    text: "Start all apps"
                    width: parent.width
                    onClicked: {
                        for (var i = 0; i < ApplicationManager.availableApplications.length; i++) {
                            var appId = ApplicationManager.availableApplications[i];
                            ApplicationManager.startApplication(appId)
                        }
                    }
                }

                Repeater {
                    id: appRepeater
                    model: ApplicationManager.availableApplications
                    ApplicationCheckBox {
                        appId: modelData
                    }
                }
            }
        }
    }

    Component {
        id: mockNotification

        QtObject {
            function invokeAction(actionId) {
                mockNotificationsModel.actionInvoked(actionId)
            }
        }
    }
    ListModel {
        id: mockNotificationsModel

        signal actionInvoked(string actionId)

        function getRaw(id) {
            return mockNotification.createObject(mockNotificationsModel)
        }

        onActionInvoked: {
            if(actionId == "ok_id") {
                mockNotificationsModel.clear()
            }
        }
    }

    SignalSpy {
        id: launcherShowDashHomeSpy
        signalName: "showDashHome"
    }

    SignalSpy {
        id: sessionSpy
        signalName: "sessionStarted"
    }

    SignalSpy {
        id: dashCommunicatorSpy
        signalName: "setCurrentScopeCalled"
    }

    SignalSpy {
        id: unlockAllModemsSpy
        target: Connectivity
        signalName: "unlockingAllModems"
    }

    SignalSpy {
        id: notificationActionSpy
        target: mockNotificationsModel
        signalName: "actionInvoked"
    }

    SignalSpy {
        id: appRemovedSpy
        target: ApplicationManager
        signalName: "applicationRemoved"
    }

    Telephony.CallEntry {
        id: phoneCall
        phoneNumber: "+447812221111"
    }

    UnityTestCase {
        id: testCase
        name: "Shell"
        when: windowShown

        property Item shell: shellLoader.status === Loader.Ready ? shellLoader.item : null

        function init() {
            if (shellLoader.active) {
                // happens for the very first test function as shell
                // is loaded by default
                tearDown();
            }

        }

        function cleanup() {
            mouseEmulation.checked = true;
            tryCompare(shell, "enabled", true); // make sure greeter didn't leave us in disabled state
            tearDown();
        }

        function loadShell(formFactor) {
            shellLoader.state = formFactor;
            shellLoader.active = true;
            tryCompare(shellLoader, "status", Loader.Ready);
            removeTimeConstraintsFromDirectionalDragAreas(shellLoader.item);
            tryCompare(shell, "enabled", true); // enabled by greeter when ready

            sessionSpy.target = findChild(shell, "greeter")
            dashCommunicatorSpy.target = findInvisibleChild(shell, "dashCommunicator");

            var launcher = findChild(shell, "launcher");
            launcherShowDashHomeSpy.target = launcher;

            waitForGreeterToStabilize();
        }

        function loadDesktopShellWithApps() {
            loadShell("desktop");
            waitForRendering(shell)
            shell.usageScenario = "desktop"
            waitForRendering(shell)
            var app1 = ApplicationManager.startApplication("dialer-app")
            var app2 = ApplicationManager.startApplication("webbrowser-app")
            var app3 = ApplicationManager.startApplication("camera-app")
            var app4 = ApplicationManager.startApplication("facebook-webapp")
            var app5 = ApplicationManager.startApplication("calendar-app")
            var app6 = ApplicationManager.startApplication("gallery-app")
            var app7 = ApplicationManager.startApplication("camera-app")
            waitUntilAppWindowIsFullyLoaded(app7);
        }

        function waitForGreeterToStabilize() {
            var greeter = findChild(shell, "greeter");
            verify(greeter);

            var loginList = findChild(greeter, "loginList");
            // Only present in WideView
            if (loginList) {
                var userList = findChild(loginList, "userList");
                verify(userList);
                tryCompare(userList, "movingInternally", false);
            }
        }

        function tearDown() {
            launcherShowDashHomeSpy.target = null;

            shellLoader.itemDestroyed = false;

            shellLoader.active = false;

            tryCompare(shellLoader, "status", Loader.Null);
            tryCompare(shellLoader, "item", null);
            // Loader.status might be Loader.Null and Loader.item might be null but the Loader
            // item might still be alive. So if we set Loader.active back to true
            // again right now we will get the very same Shell instance back. So no reload
            // actually took place. Likely because Loader waits until the next event loop
            // iteration to do its work. So to ensure the reload, we will wait until the
            // Shell instance gets destroyed.
            tryCompare(shellLoader, "itemDestroyed", true);

            setLightDMMockMode("single"); // back to the default value

            AccountsService.demoEdges = false;
            Wizard.System.wizardEnabled = false;

            // kill all (fake) running apps
            killApps(ApplicationManager);

            unlockAllModemsSpy.clear()
            LightDM.Greeter.authenticate(""); // reset greeter

            sessionSpy.clear();
        }

        function killApps() {
            while (ApplicationManager.count > 1) {
                var appIndex = ApplicationManager.get(0).appId == "unity8-dash" ? 1 : 0
                ApplicationManager.stopApplication(ApplicationManager.get(appIndex).appId);
            }
            compare(ApplicationManager.count, 1)
        }

        function test_snapDecisionDismissalReturnsFocus() {
            loadShell("phone");
            swipeAwayGreeter();
            var notifications = findChild(shell, "notificationList");
            var app = ApplicationManager.startApplication("camera-app");
            var stage = findChild(shell, "stage")
            // Open an application and focus
            waitUntilApplicationWindowIsFullyVisible(app);
            ApplicationManager.focusApplication(app);
            tryCompare(app.session.surface, "activeFocus", true);

            notifications.model = mockNotificationsModel;

            // FIXME: Hack: UnitySortFilterProxyModelQML doesn't work with QML ListModels which we use
            // for mocking here (RoleType can't be found in the QML model). As we only need to show
            // one SnapDecision lets just disable the filtering and make appear any notification as a
            // SnapDecision.
            var snapDecisionProxyModel = findInvisibleChild(shell, "snapDecisionProxyModel");
            snapDecisionProxyModel.filterRegExp = RegExp("");

            // Pop-up a notification
            addSnapDecisionNotification();
            waitForRendering(shell);

            // Make sure the notification really opened
            var notification = findChild(notifications, "notification" + (mockNotificationsModel.count - 1));
            verify(notification !== undefined && notification != null, "notification wasn't found");
            tryCompare(notification, "height", notification.implicitHeight)
            waitForRendering(notification);

            // Make sure activeFocus went away from the app window
            tryCompare(app.session.surface, "activeFocus", false);
            tryCompare(stage, "interactive", false);

            // Clicking the button should dismiss the notification and return focus
            var buttonAccept = findChild(notification, "notify_button0");
            mouseClick(buttonAccept);

            // Make sure we're back to normal
            tryCompare(app.session.surface, "activeFocus", true);
            compare(stage.interactive, true, "Stages not interactive again after modal notification has closed");
        }

        function addSnapDecisionNotification() {
            var n = {
                type: Notification.SnapDecision,
                hints: {"x-canonical-private-affirmative-tint": "true"},
                summary: "Tom Ato",
                body: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.",
                icon: "../graphics/avatars/funky.png",
                secondaryIcon: "../graphics/applicationIcons/facebook.png",
                actions: [{ id: "ok_id", label: "Ok"},
                    { id: "cancel_id", label: "Cancel"},
                    { id: "notreally_id", label: "Not really"},
                    { id: "noway_id", label: "messages:No way"},
                    { id: "nada_id", label: "messages:Nada"}]
            }

            mockNotificationsModel.append(n)
        }

        function test_phoneLeftEdgeDrag_data() {
            return [
                {tag: "without launcher",
                 revealLauncher: false, swipeLength: units.gu(30), appHides: true, focusedApp: "dialer-app",
                 launcherHides: true, greeterShown: false},

                {tag: "with launcher",
                 revealLauncher: true, swipeLength: units.gu(30), appHides: true, focusedApp: "dialer-app",
                 launcherHides: true, greeterShown: false},

                {tag: "small swipe",
                 revealLauncher: false, swipeLength: units.gu(25), appHides: false, focusedApp: "dialer-app",
                 launcherHides: false, greeterShown: false},

                {tag: "long swipe",
                 revealLauncher: false, swipeLength: units.gu(30), appHides: true, focusedApp: "dialer-app",
                 launcherHides: true, greeterShown: false},

                {tag: "small swipe with greeter",
                 revealLauncher: false, swipeLength: units.gu(25), appHides: false, focusedApp: "dialer-app",
                 launcherHides: false, greeterShown: true},

                {tag: "long swipe with greeter",
                 revealLauncher: false, swipeLength: units.gu(30), appHides: true, focusedApp: "dialer-app",
                 launcherHides: true, greeterShown: true},

                {tag: "swipe over dash",
                 revealLauncher: false, swipeLength: units.gu(30), appHides: true, focusedApp: "unity8-dash",
                 launcherHides: false, greeterShown: false},
            ];
        }

        function test_phoneLeftEdgeDrag(data) {
            loadShell("phone");
            swipeAwayGreeter();
            dragLauncherIntoView();
            tapOnAppIconInLauncher();
            waitUntilApplicationWindowIsFullyVisible();
            ApplicationManager.focusApplication(data.focusedApp)
            waitUntilApplicationWindowIsFullyVisible();

            var greeter = findChild(shell, "greeter");
            if (data.greeterShown) {
                showGreeter();
            }

            if (data.revealLauncher) {
                dragLauncherIntoView();
            }

            swipeFromLeftEdge(data.swipeLength);
            if (data.appHides) {
                waitUntilDashIsFocused();
                tryCompare(greeter, "shown", false);
            } else {
                waitUntilApplicationWindowIsFullyVisible();
                compare(greeter.fullyShown, data.greeterShown);
            }

            var launcher = findChild(shell, "launcherPanel");
            tryCompare(launcher, "x", data.launcherHides ? -launcher.width : 0)

            // Make sure the helper for sliding out the launcher wasn't touched. We want to fade it out here.
            var animateTimer = findInvisibleChild(shell, "animateTimer");
            compare(animateTimer.nextState, "visible");
        }

        function test_tabletLeftEdgeDrag_data() {
            return [
                {tag: "without password", user: "no-password", loggedIn: true, demo: false},
                {tag: "with password", user: "has-password", loggedIn: false, demo: false},
                {tag: "with demo", user: "has-password", loggedIn: true, demo: true},
            ]
        }

        function test_tabletLeftEdgeDrag(data) {
            setLightDMMockMode("full");
            loadShell("tablet");

            selectUser(data.user)

            AccountsService.demoEdges = data.demo
            var tutorial = findChild(shell, "tutorial");
            tryCompare(tutorial, "running", data.demo);

            swipeFromLeftEdge(shell.width * 0.75)
            wait(500) // to give time to handle dash() signal from Launcher
            confirmLoggedIn(data.loggedIn)
        }

        function test_longLeftEdgeSwipeTakesToAppsAndResetSearchString() {
            loadShell("phone");
            swipeAwayGreeter();
            dragLauncherIntoView();
            dashCommunicatorSpy.clear();

            tapOnAppIconInLauncher();
            waitUntilApplicationWindowIsFullyVisible();

            verify(ApplicationManager.focusedApplicationId !== "unity8-dash")

            //Long left swipe
            swipeFromLeftEdge(units.gu(30));

            tryCompare(ApplicationManager, "focusedApplicationId", "unity8-dash");

            compare(dashCommunicatorSpy.count, 1);
        }

        function test_ClickUbuntuIconInLauncherTakesToAppsAndResetSearchString() {
            loadShell("phone");
            swipeAwayGreeter();
            dragLauncherIntoView();
            dashCommunicatorSpy.clear();

            var launcher = findChild(shell, "launcher");
            var dashIcon = findChild(launcher, "dashItem");
            verify(dashIcon != undefined);
            mouseClick(dashIcon);

            tryCompare(ApplicationManager, "focusedApplicationId", "unity8-dash");

            compare(dashCommunicatorSpy.count, 1);
        }

        function test_suspend() {
            loadShell("phone");
            swipeAwayGreeter();
            var greeter = findChild(shell, "greeter");

            // Launch an app from the launcher
            dragLauncherIntoView();
            tapOnAppIconInLauncher();
            waitUntilApplicationWindowIsFullyVisible();

            var mainAppId = ApplicationManager.focusedApplicationId;
            verify(mainAppId != "");
            var mainApp = ApplicationManager.findApplication(mainAppId);
            verify(mainApp);
            tryCompare(mainApp, "requestedState", ApplicationInfoInterface.RequestedRunning);

            // Display off while call is active...
            callManager.foregroundCall = phoneCall;
            Powerd.setStatus(Powerd.Off, Powerd.Unknown);
            tryCompare(greeter, "shown", false);

            // Now try again after ending call
            callManager.foregroundCall = null;
            Powerd.setStatus(Powerd.On, Powerd.Unknown);
            Powerd.setStatus(Powerd.Off, Powerd.Unknown);
            tryCompare(greeter, "fullyShown", true);

            compare(mainApp.requestedState, ApplicationInfoInterface.RequestedSuspended);

            // And wake up
            Powerd.setStatus(Powerd.On, Powerd.Unknown);
            tryCompare(greeter, "fullyShown", true);

            // Swipe away greeter to focus app

            // greeter unloads its internal components when hidden
            // and reloads them when shown. Thus we have to do this
            // again before interacting with it otherwise any
            // DirectionalDragAreas in there won't be easily fooled by
            // fake swipes.
            removeTimeConstraintsFromDirectionalDragAreas(greeter);
            swipeAwayGreeter();

            compare(mainApp.requestedState, ApplicationInfoInterface.RequestedRunning);
            tryCompare(ApplicationManager, "focusedApplicationId", mainAppId);
        }

        function swipeAwayGreeter() {
            var greeter = findChild(shell, "greeter");
            tryCompare(greeter, "fullyShown", true);

            var touchX = shell.width - (shell.edgeSize / 2);
            var touchY = shell.height / 2;
            touchFlick(shell, touchX, touchY, shell.width * 0.1, touchY);

            // wait until the animation has finished
            tryCompare(greeter, "shown", false);
            waitForRendering(greeter);
        }

        function selectUserAtIndex(i) {
            // We could be anywhere in list; find target index to know which direction
            var greeter = findChild(shell, "greeter")
            var userlist = findChild(greeter, "userList")
            if (userlist.currentIndex == i)
                keyClick(Qt.Key_Escape) // Reset state if we're not moving
            while (userlist.currentIndex != i) {
                var next = userlist.currentIndex + 1
                if (userlist.currentIndex > i) {
                    next = userlist.currentIndex - 1
                }
                tap(findChild(greeter, "username"+next));
                tryCompare(userlist, "currentIndex", next)
                tryCompare(userlist, "movingInternally", false)
            }
            tryCompare(shell, "enabled", true); // wait for PAM to settle
        }

        function selectUser(name) {
            // Find index of user with the right name
            for (var i = 0; i < LightDM.Users.count; i++) {
                if (LightDM.Users.data(i, LightDM.UserRoles.NameRole) == name) {
                    break
                }
            }
            if (i == LightDM.Users.count) {
                fail("Didn't find name")
                return -1
            }
            selectUserAtIndex(i)
            return i
        }

        function clickPasswordInput(isButton) {
            var greeter = findChild(shell, "greeter")
            tryCompare(greeter, "fullyShown", true);

            var passwordMouseArea = findChild(shell, "passwordMouseArea")
            tryCompare(passwordMouseArea, "enabled", isButton)

            var passwordInput = findChild(shell, "passwordInput")
            mouseClick(passwordInput)
        }

        function confirmLoggedIn(loggedIn) {
            var greeter = findChild(shell, "greeter");
            tryCompare(greeter, "shown", loggedIn ? false : true);
            verify(loggedIn ? sessionSpy.count > 0 : sessionSpy.count === 0);
        }

        function setLightDMMockMode(mode) {
            LightDM.Greeter.mockMode = mode;
            LightDM.Users.mockMode = mode;
        }

        /*
          Regression test for bug https://bugs.launchpad.net/touch-preview-images/+bug/1193419

          When the user minimizes an application (left-edge swipe) he should always end up in the
          "Applications" scope view.

          Steps:
          - reveal launcher and launch an app that covers the dash
          - perform long left edge swipe to go minimize the app and go back to the dash.
          - verify the setCurrentScope() D-Bus call to the dash has been called for the correct scope id.
         */
        function test_minimizingAppTakesToDashApps() {
            loadShell("phone");
            swipeAwayGreeter();
            dragLauncherIntoView();

            // Launch an app from the launcher
            tapOnAppIconInLauncher();

            waitUntilApplicationWindowIsFullyVisible();

            verify(ApplicationManager.focusedApplicationId !== "unity8-dash")

            dashCommunicatorSpy.clear();
            // Minimize the application we just launched
            swipeFromLeftEdge(shell.width * 0.75);

            tryCompare(ApplicationManager, "focusedApplicationId", "unity8-dash");

            compare(dashCommunicatorSpy.count, 1);
            compare(dashCommunicatorSpy.signalArguments[0][0], 0);
        }

        function test_showInputMethod() {
            loadShell("phone");
            swipeAwayGreeter();
            var item = findChild(shell, "inputMethod");
            var surface = SurfaceManager.inputMethodSurface();

            surface.setState(Mir.MinimizedState);
            tryCompare(item, "visible", false);

            surface.setState(Mir.RestoredState);
            tryCompare(item, "visible", true);

            surface.setState(Mir.MinimizedState);
            tryCompare(item, "visible", false);

            surface.setState(Mir.MaximizedState);
            tryCompare(item, "visible", true);

            surface.setState(Mir.MinimizedState);
            tryCompare(item, "visible", false);
        }

        // Wait until the ApplicationWindow for the given Application object is fully loaded
        // (ie, the real surface has replaced the splash screen)
        function waitUntilAppWindowIsFullyLoaded(app) {
            var appWindow = findChild(shell, "appWindow_" + app.appId);
            var appWindowStateGroup = findInvisibleChild(appWindow, "applicationWindowStateGroup");
            tryCompareFunction(function() { return appWindowStateGroup.state === "surface" }, true);
            waitUntilTransitionsEnd(appWindowStateGroup);
        }

        function test_surfaceLosesActiveFocusWhilePanelIsOpen() {
            loadShell("phone");
            swipeAwayGreeter();
            var app = ApplicationManager.startApplication("dialer-app");
            waitUntilAppWindowIsFullyLoaded(app);

            tryCompare(app.session.surface, "activeFocus", true);

            // Drag the indicators panel half-open
            var touchX = shell.width / 2;
            var indicators = findChild(shell, "indicators");
            touchFlick(indicators,
                    touchX /* fromX */, indicators.minimizedPanelHeight * 0.5 /* fromY */,
                    touchX /* toX */, shell.height * 0.5 /* toY */,
                    true /* beginTouch */, false /* endTouch */);
            verify(indicators.partiallyOpened);

            tryCompare(app.session.surface, "activeFocus", false);

            // And finish getting it open
            touchFlick(indicators,
                    touchX /* fromX */, shell.height * 0.5 /* fromY */,
                    touchX /* toX */, shell.height * 0.9 /* toY */,
                    false /* beginTouch */, true /* endTouch */);
            tryCompare(indicators, "fullyOpened", true);

            tryCompare(app.session.surface, "activeFocus", false);

            dragToCloseIndicatorsPanel();

            tryCompare(app.session.surface, "activeFocus", true);
        }

        function test_launchedAppHasActiveFocus_data() {
            return [
                {tag: "phone", formFactor: "phone", usageScenario: "phone"},
                {tag: "tablet", formFactor: "tablet", usageScenario: "tablet"},
                {tag: "desktop", formFactor: "tablet", usageScenario: "desktop"}
            ]
        }

        function test_launchedAppHasActiveFocus(data) {
            loadShell(data.formFactor);
            shell.usageScenario = data.usageScenario;
            waitForGreeterToStabilize();
            swipeAwayGreeter();

            var webApp = ApplicationManager.startApplication("webbrowser-app");
            verify(webApp);
            waitUntilAppSurfaceShowsUp("webbrowser-app")

            verify(webApp.session.surface);

            tryCompare(webApp.session.surface, "activeFocus", true);
        }

        function test_launchedAppKeepsActiveFocusOnUsageModeChange() {
            loadShell("tablet");
            swipeAwayGreeter();

            var webApp = ApplicationManager.startApplication("webbrowser-app");
            verify(webApp);
            waitUntilAppSurfaceShowsUp("webbrowser-app")

            verify(webApp.session.surface);

            tryCompare(webApp.session.surface, "activeFocus", true);

            shell.usageScenario = "desktop";

            // check that the desktop stage and window have been loaded
            {
                var desktopWindow = findChild(shell, "appWindow_webbrowser-app");
                verify(desktopWindow);
            }

            tryCompare(webApp.session.surface, "activeFocus", true);

            shell.usageScenario = "tablet";

            // check that the tablet stage and app surface delegate have been loaded
            {
                var desktopWindow = findChild(shell, "tabletSpreadDelegate_webbrowser-app");
                verify(desktopWindow);
            }

            tryCompare(webApp.session.surface, "activeFocus", true);
        }

        function waitUntilAppSurfaceShowsUp(appId) {
            var appWindow = findChild(shell, "appWindow_" + appId);
            verify(appWindow);
            var appWindowStates = findInvisibleChild(appWindow, "applicationWindowStateGroup");
            verify(appWindowStates);
            tryCompare(appWindowStates, "state", "surface");
        }

        function dragToCloseIndicatorsPanel() {
            var indicators = findChild(shell, "indicators");

            var touchStartX = shell.width / 2;
            var touchStartY = shell.height - (indicators.minimizedPanelHeight * 0.5);
            touchFlick(shell,
                    touchStartX, touchStartY,
                    touchStartX, shell.height * 0.1);

            tryCompare(indicators, "fullyClosed", true);
        }

        function dragLauncherIntoView() {
            var launcher = findChild(shell, "launcher");
            var launcherPanel = findChild(launcher, "launcherPanel");
            verify(launcherPanel.x = - launcherPanel.width);

            var touchStartX = 2;
            var touchStartY = shell.height / 2;
            touchFlick(shell, touchStartX, touchStartY, launcherPanel.width + units.gu(1), touchStartY);

            tryCompare(launcherPanel, "x", 0);
            tryCompare(launcher, "state", "visible");
        }

        function tapOnAppIconInLauncher() {
            var launcherPanel = findChild(shell, "launcherPanel");

            // pick the first icon, the one at the top.
            var appIcon = findChild(launcherPanel, "launcherDelegate0")
            tap(appIcon, appIcon.width / 2, appIcon.height / 2);
        }

        function showIndicators() {
            var indicators = findChild(shell, "indicators");
            indicators.show();
            tryCompare(indicators, "fullyOpened", true);
        }

        function hideIndicators() {
            var indicators = findChild(shell, "indicators");
            if (indicators.fullyOpened) {
                indicators.hide();
            }
        }

        function waitUntilApplicationWindowIsFullyVisible() {
            var appDelegate = findChild(shell, "appDelegate0")
            var surfaceContainer = findChild(appDelegate, "surfaceContainer");
            tryCompareFunction(function() { return surfaceContainer.surface !== null; }, true);
        }

        function waitUntilDashIsFocused() {
            tryCompare(ApplicationManager, "focusedApplicationId", "unity8-dash");
        }

        function swipeFromLeftEdge(swipeLength) {
            var touchStartX = 2;
            var touchStartY = shell.height / 2;
            touchFlick(shell,
                    touchStartX              , touchStartY,
                    touchStartX + swipeLength, touchStartY);
        }

        function itemIsOnScreen(item) {
            var itemRectInShell = item.mapToItem(shell, 0, 0, item.width, item.height);

            return itemRectInShell.x >= 0
                && itemRectInShell.y >= 0
                && itemRectInShell.x + itemRectInShell.width <= shell.width
                && itemRectInShell.y + itemRectInShell.height <= shell.height;
        }

        function showGreeter() {
            var greeter = findChild(shell, "greeter");
            LightDM.Greeter.showGreeter();
            waitForRendering(greeter);
            tryCompare(greeter, "fullyShown", true);

            // greeter unloads its internal components when hidden
            // and reloads them when shown. Thus we have to do this
            // again before interacting with it otherwise any
            // DirectionalDragAreas in there won't be easily fooled by
            // fake swipes.
            removeTimeConstraintsFromDirectionalDragAreas(greeter);
        }

        function test_focusRequestedHidesGreeter() {
            loadShell("phone");
            swipeAwayGreeter();
            var greeter = findChild(shell, "greeter");

            var app = ApplicationManager.startApplication("dialer-app");
            // wait until the app is fully loaded (ie, real surface replaces splash screen)
            tryCompareFunction(function() { return app.session !== null && app.session.surface !== null }, true);

            // Minimize the application we just launched
            swipeFromLeftEdge(shell.width * 0.75);

            waitUntilDashIsFocused();

            showGreeter();

            // The main point of this test
            ApplicationManager.requestFocusApplication("dialer-app");
            tryCompare(greeter, "shown", false);
            waitForRendering(greeter);
        }

        function test_focusRequestedHidesIndicators() {
            loadShell("phone");
            swipeAwayGreeter();
            var indicators = findChild(shell, "indicators");

            showIndicators();

            var oldCount = ApplicationManager.count;
            ApplicationManager.startApplication("camera-app");
            tryCompare(ApplicationManager, "count", oldCount + 1);

            tryCompare(indicators, "fullyClosed", true);
        }

        function test_showAndHideGreeterDBusCalls() {
            loadShell("phone");
            swipeAwayGreeter();
            var greeter = findChild(shell, "greeter")
            tryCompare(greeter, "shown", false)
            waitForRendering(greeter);
            LightDM.Greeter.showGreeter()
            waitForRendering(greeter)
            tryCompare(greeter, "fullyShown", true)
            LightDM.Greeter.hideGreeter()
            tryCompare(greeter, "shown", false)
        }

        function test_greeterLoginsAutomaticallyWhenNoPasswordSet() {
            loadShell("phone");
            swipeAwayGreeter();

            sessionSpy.clear();
            verify(sessionSpy.valid);

            showGreeter();

            tryCompare(sessionSpy, "count", 1);
        }

        function test_fullscreen() {
            loadShell("phone");
            swipeAwayGreeter();
            var panel = findChild(shell, "panel");
            compare(panel.fullscreenMode, false);
            ApplicationManager.startApplication("camera-app");
            tryCompare(panel, "fullscreenMode", true);
            ApplicationManager.startApplication("dialer-app");
            tryCompare(panel, "fullscreenMode", false);
            ApplicationManager.requestFocusApplication("camera-app");
            tryCompare(panel, "fullscreenMode", true);
            ApplicationManager.requestFocusApplication("dialer-app");
            tryCompare(panel, "fullscreenMode", false);
        }

        function test_leftEdgeDragFullscreen() {
            loadShell("phone");
            swipeAwayGreeter();
            var panel = findChild(shell, "panel");
            tryCompare(panel, "fullscreenMode", false)

            ApplicationManager.startApplication("camera-app");
            tryCompare(panel, "fullscreenMode", true)

            var touchStartX = 2;
            var touchStartY = shell.height / 2;

            touchFlick(shell, touchStartX, touchStartY, units.gu(2), touchStartY, true, false);

            compare(panel.fullscreenMode, true);

            touchFlick(shell, units.gu(2), touchStartY, shell.width * 0.5, touchStartY, false, false);

            tryCompare(panel, "fullscreenMode", false);

            touchRelease(shell);
        }

        function test_unlockedProperties() {
            loadShell("phone");
            swipeAwayGreeter();
            // Confirm that various properties have the correct values when unlocked
            var greeter = findChild(shell, "greeter");
            tryCompare(greeter, "locked", false);

            var launcher = findChild(shell, "launcher")
            tryCompare(launcher, "available", true)

            var indicators = findChild(shell, "indicators")
            tryCompare(indicators, "available", true)
        }

        function test_unlockAllModemsOnBoot() {
            loadShell("phone");
            swipeAwayGreeter();
            tryCompare(unlockAllModemsSpy, "count", 1)
        }

        function test_unlockAllModemsAfterWizard() {
            Wizard.System.wizardEnabled = true;
            loadShell("phone");

            var wizard = findChild(shell, "wizard");
            compare(wizard.active, true);
            compare(Wizard.System.wizardEnabled, true);
            compare(unlockAllModemsSpy.count, 0);

            wizard.hide();
            tryCompare(wizard, "active", false);
            compare(Wizard.System.wizardEnabled, false);
            compare(unlockAllModemsSpy.count, 1);
        }

        function test_wizardEarlyExit() {
            Wizard.System.wizardEnabled = true;
            AccountsService.demoEdges = true;
            loadShell("phone");

            var wizard = findChild(shell, "wizard");
            var tutorial = findChild(shell, "tutorial");
            tryCompare(wizard, "active", true);
            tryCompare(tutorial, "running", true);
            tryCompare(ApplicationManager, "focusedApplicationId", "unity8-dash");

            // Make sure we stay running when nothing focused (can happen for
            // a moment when we restart the dash after switching language)
            ApplicationManager.stopApplication("unity8-dash");
            tryCompare(ApplicationManager, "focusedApplicationId", "");
            compare(wizard.shown, true);
            compare(tutorial.running, true);

            // And make sure we stay running when dash focused again
            ApplicationManager.startApplication("unity8-dash");
            tryCompare(ApplicationManager, "focusedApplicationId", "unity8-dash");
            compare(wizard.shown, true);
            compare(tutorial.running, true);

            // And make sure we stop when something else is focused
            ApplicationManager.startApplication("gallery-app");
            tryCompare(ApplicationManager, "focusedApplicationId", "gallery-app");
            compare(wizard.shown, false);
            compare(tutorial.running, false);
            tryCompare(AccountsService, "demoEdges", false);
            tryCompare(Wizard.System, "wizardEnabled", false);

            var tutorialLeft = findChild(tutorial, "tutorialLeft");
            compare(tutorialLeft, null); // should be destroyed with tutorial
        }

        function test_tutorialPausedDuringGreeter() {
            loadShell("phone");

            var tutorial = findChild(shell, "tutorial");

            AccountsService.demoEdges = true;
            tryCompare(tutorial, "running", true);
            tryCompare(tutorial, "paused", true);

            swipeAwayGreeter();
            tryCompare(tutorial, "paused", false);
        }

        function test_tapOnRightEdgeReachesApplicationSurface() {
            loadShell("phone");
            swipeAwayGreeter();
            var topmostSpreadDelegate = findChild(shell, "appDelegate0");
            verify(topmostSpreadDelegate);

            waitUntilFocusedApplicationIsShowingItsSurface();

            var topmostSurfaceItem = findChild(topmostSpreadDelegate, "surfaceItem");
            verify(topmostSurfaceItem);

            var rightEdgeDragArea = findChild(shell, "spreadDragArea");
            topmostSurfaceItem.touchPressCount = 0;
            topmostSurfaceItem.touchReleaseCount = 0;

            var tapPoint = rightEdgeDragArea.mapToItem(shell, rightEdgeDragArea.width / 2,
                    rightEdgeDragArea.height / 2);

            tap(shell, tapPoint.x, tapPoint.y);

            tryCompare(topmostSurfaceItem, "touchPressCount", 1);
            tryCompare(topmostSurfaceItem, "touchReleaseCount", 1);
        }

        /*
            Perform a right edge drag over an application surface and check
            that no touch event was sent to it (ie, they were all consumed
            by the right-edge drag area)
         */
        function test_rightEdgeDragDoesNotReachApplicationSurface() {
            loadShell("phone");
            swipeAwayGreeter();
            var topmostSpreadDelegate = findChild(shell, "appDelegate0");
            var topmostSurfaceItem = findChild(topmostSpreadDelegate, "surfaceItem");
            var rightEdgeDragArea = findChild(shell, "spreadDragArea");

            topmostSurfaceItem.touchPressCount = 0;
            topmostSurfaceItem.touchReleaseCount = 0;

            var gestureStartPoint = rightEdgeDragArea.mapToItem(shell, rightEdgeDragArea.width / 2,
                    rightEdgeDragArea.height / 2);

            touchFlick(shell,
                    gestureStartPoint.x /* fromX */, gestureStartPoint.y /* fromY */,
                    units.gu(1) /* toX */, gestureStartPoint.y /* toY */);

            tryCompare(topmostSurfaceItem, "touchPressCount", 0);
            tryCompare(topmostSurfaceItem, "touchReleaseCount", 0);
        }

        function waitUntilFocusedApplicationIsShowingItsSurface()
        {
            var spreadDelegate = findChild(shell, "appDelegate0");
            var appState = findInvisibleChild(spreadDelegate, "applicationWindowStateGroup");
            tryCompare(appState, "state", "surface");
            var transitions = appState.transitions;
            for (var i = 0; i < transitions.length; ++i) {
                var transition = transitions[i];
                tryCompare(transition, "running", false, 2000);
            }
        }

        function swipeFromRightEdgeToShowAppSpread()
        {
            // perform a right-edge drag to show the spread
            var touchStartX = shell.width - (shell.edgeSize / 2)
            var touchStartY = shell.height / 2;
            touchFlick(shell, touchStartX, touchStartY, units.gu(1) /* endX */, touchStartY /* endY */);

            // check if it's indeed showing the spread
            var stage = findChild(shell, "stage");
            var spreadView = findChild(stage, "spreadView");
            tryCompare(spreadView, "phase", 2);
        }

        function test_tapUbuntuIconInLauncherOverAppSpread() {
            launcherShowDashHomeSpy.clear();

            loadShell("phone");
            swipeAwayGreeter();

            waitUntilFocusedApplicationIsShowingItsSurface();

            swipeFromRightEdgeToShowAppSpread();

            var launcher = findChild(shell, "launcher");

            // ensure the launcher dimissal timer never gets triggered during the test run
            var dismissTimer = findInvisibleChild(launcher, "dismissTimer");
            dismissTimer.interval = 60 * 60 * 1000;

            dragLauncherIntoView();

            // Emulate a tap with a finger, where the touch position drifts during the tap.
            // This is to test the touch ownership changes. The tap is happening on the button
            // area but then drifting into the left edge drag area. This test makes sure
            // the touch ownership stays with the button and doesn't move over to the
            // left edge drag area.
            {
                var buttonShowDashHome = findChild(launcher, "buttonShowDashHome");
                touchFlick(buttonShowDashHome,
                    buttonShowDashHome.width * 0.2,  /* startPos.x */
                    buttonShowDashHome.height * 0.8, /* startPos.y */
                    buttonShowDashHome.width * 0.8,  /* endPos.x */
                    buttonShowDashHome.height * 0.2  /* endPos.y */);
            }

            compare(launcherShowDashHomeSpy.count, 1);

            // check that the stage has left spread mode.
            {
                var stage = findChild(shell, "stage");
                var spreadView = findChild(stage, "spreadView");
                tryCompare(spreadView, "phase", 0);
            }

            // check that the launcher got dismissed
            var launcherPanel = findChild(shell, "launcherPanel");
            tryCompare(launcherPanel, "x", -launcherPanel.width);
        }

        function test_tabletLogin_data() {
            return [
                {tag: "auth error", user: "auth-error", loggedIn: false, password: ""},
                {tag: "with password", user: "has-password", loggedIn: true, password: "password"},
                {tag: "without password", user: "no-password", loggedIn: true, password: ""},
            ]
        }

        function test_tabletLogin(data) {
            setLightDMMockMode("full");
            loadShell("tablet");

            selectUser(data.user);

            clickPasswordInput(data.password === "" /* isButton */);

            if (data.password !== "") {
                typeString(data.password);
                keyClick(Qt.Key_Enter);
            }

            confirmLoggedIn(data.loggedIn);
        }

        function test_appLaunchDuringGreeter_data() {
            return [
                {tag: "auth error", user: "auth-error", loggedIn: false, passwordFocus: false},
                {tag: "without password", user: "no-password", loggedIn: true, passwordFocus: false},
                {tag: "with password", user: "has-password", loggedIn: false, passwordFocus: true},
            ]
        }

        function test_appLaunchDuringGreeter(data) {
            setLightDMMockMode("full");
            loadShell("tablet");

            selectUser(data.user)

            var greeter = findChild(shell, "greeter")
            var app = ApplicationManager.startApplication("dialer-app")

            confirmLoggedIn(data.loggedIn)

            if (data.passwordFocus) {
                var passwordInput = findChild(greeter, "passwordInput")
                tryCompare(passwordInput, "focus", true)
            }
        }

        function test_stageLoader_data() {
            return [
                {tag: "phone", source: "Stages/PhoneStage.qml", formFactor: "phone", usageScenario: "phone"},
                {tag: "tablet", source: "Stages/TabletStage.qml", formFactor: "tablet", usageScenario: "tablet"},
                {tag: "desktop", source: "Stages/DesktopStage.qml", formFactor: "tablet", usageScenario: "desktop"}
            ]
        }

        function test_stageLoader(data) {
            loadShell(data.formFactor);
            shell.usageScenario = data.usageScenario;
            var stageLoader = findChild(shell, "applicationsDisplayLoader");
            verify(String(stageLoader.source).indexOf(data.source) >= 0);
        }

        function test_launcherInverted_data() {
            return [
                {tag: "phone", formFactor: "phone", usageScenario: "phone", launcherInverted: true},
                {tag: "tablet", formFactor: "tablet", usageScenario: "tablet", launcherInverted: true},
                {tag: "desktop", formFactor: "tablet", usageScenario: "desktop", launcherInverted: false}
            ]
        }

        function test_launcherInverted(data) {
            loadShell(data.formFactor);
            shell.usageScenario = data.usageScenario;

            var launcher = findChild(shell, "launcher");
            compare(launcher.inverted, data.launcherInverted);
        }

        function test_unfocusedAppsGetSuspendedAfterEnteringStagedMode() {
            loadShell("tablet");
            shell.usageScenario = "desktop";

            var webBrowserApp = ApplicationManager.startApplication("webbrowser-app");
            waitUntilAppWindowIsFullyLoaded(webBrowserApp);

            var galleryApp = ApplicationManager.startApplication("gallery-app");
            waitUntilAppWindowIsFullyLoaded(galleryApp);

            ApplicationManager.requestFocusApplication("unity8-dash");
            tryCompare(ApplicationManager, "focusedApplicationId", "unity8-dash");

            compare(webBrowserApp.requestedState, ApplicationInfoInterface.RequestedRunning);
            compare(galleryApp.requestedState, ApplicationInfoInterface.RequestedRunning);

            shell.usageScenario = "tablet";

            tryCompare(webBrowserApp, "requestedState", ApplicationInfoInterface.RequestedSuspended);
            tryCompare(galleryApp, "requestedState", ApplicationInfoInterface.RequestedSuspended);
        }

        function test_unfocusedAppsAreResumedWhenEnteringWindowedMode() {
            loadShell("tablet");
            shell.usageScenario = "tablet";

            var webBrowserApp = ApplicationManager.startApplication("webbrowser-app");
            waitUntilAppWindowIsFullyLoaded(webBrowserApp);

            var galleryApp = ApplicationManager.startApplication("gallery-app");
            waitUntilAppWindowIsFullyLoaded(galleryApp);

            ApplicationManager.requestFocusApplication("unity8-dash");
            tryCompare(ApplicationManager, "focusedApplicationId", "unity8-dash");

            compare(webBrowserApp.requestedState, ApplicationInfoInterface.RequestedSuspended);
            compare(galleryApp.requestedState, ApplicationInfoInterface.RequestedSuspended);

            shell.usageScenario = "desktop";

            tryCompare(webBrowserApp, "requestedState", ApplicationInfoInterface.RequestedRunning);
            tryCompare(galleryApp, "requestedState", ApplicationInfoInterface.RequestedRunning);
        }

        function test_altTabSwitchesFocus() {
            loadShell("desktop");
            shell.usageScenario = "desktop"
            waitForRendering(root)

            var desktopStage = findChild(shell, "stage");
            verify(desktopStage != null)

            var app1 = ApplicationManager.startApplication("dialer-app")
            waitUntilAppWindowIsFullyLoaded(app1);
            var app2 = ApplicationManager.startApplication("webbrowser-app")
            waitUntilAppWindowIsFullyLoaded(app2);
            var app3 = ApplicationManager.startApplication("camera-app")
            waitUntilAppWindowIsFullyLoaded(app3);

            // Do a quick alt-tab and see if focus changes
            tryCompare(app3.session.surface, "activeFocus", true)
            keyClick(Qt.Key_Tab, Qt.ControlModifier)
            tryCompare(app2.session.surface, "activeFocus", true)

            var desktopSpread = findChild(shell, "spread")

            tryCompare(desktopSpread, "state", "")

            // Just press Alt, make sure the spread comes up
            keyPress(Qt.Key_Control);
            keyClick(Qt.Key_Tab);
            tryCompare(desktopSpread, "state", "altTab")

            // Release control, check if spread disappears
            keyRelease(Qt.Key_Control)
            tryCompare(desktopSpread, "state", "")

            // Focus should have switched back now
            tryCompare(app3.session.surface, "activeFocus", true)
        }

        function test_altTabWrapAround() {
            loadDesktopShellWithApps();

            var desktopStage = findChild(shell, "stage");
            verify(desktopStage !== null)

            var desktopSpread = findChild(shell, "spread");
            verify(desktopSpread !== null)

            var spreadContainer = findInvisibleChild(shell, "spreadContainer")
            verify(spreadContainer !== null)

            var spreadRepeater = findInvisibleChild(shell, "spreadRepeater")
            verify(spreadRepeater !== null)

            // remember the focused appId
            var focused = ApplicationManager.get(ApplicationManager.findApplication(ApplicationManager.focusedApplicationId));

            tryCompare(desktopSpread, "state", "")

            // Just press Alt, make sure the spread comes up
            keyPress(Qt.Key_Control);
            keyClick(Qt.Key_Tab);
            tryCompare(desktopSpread, "state", "altTab")
            tryCompare(spreadRepeater, "highlightedIndex", 1)
            waitForRendering(shell)

            // Now press and hold Tab, make sure the highlight moves all the way but stops at the last one
            // We can't simulate a pressed key with keyPress() currently, so let's inject the events
            // at API level. Jump for 10 times, verify that it's still at the last one and didn't wrap around.
            for (var i = 0; i < 10; i++) {
                desktopSpread.selectNext(true); // true == isAutoRepeat
                wait(0); // Trigger the event loop to make sure all the things happen
            }
            tryCompare(spreadRepeater, "highlightedIndex", 6)

            // Now release it once, and verify that it does wrap around with an additional Tab press
            keyRelease(Qt.Key_Tab);
            keyClick(Qt.Key_Tab);
            tryCompare(spreadRepeater, "highlightedIndex", 0)

            // Release control, check if spread disappears
            keyRelease(Qt.Key_Control)
            tryCompare(desktopSpread, "state", "")

            // Make sure that after wrapping around once, we have the same one focused as at the beginning
            tryCompare(focused.session.surface, "activeFocus", true)
        }

        function test_altBackTabNavigation() {
            loadDesktopShellWithApps();

            var spreadRepeater = findInvisibleChild(shell, "spreadRepeater");
            verify(spreadRepeater !== null);

            keyPress(Qt.Key_Control)
            keyClick(Qt.Key_Tab);
            tryCompare(spreadRepeater, "highlightedIndex", 1);

            keyClick(Qt.Key_Tab);
            tryCompare(spreadRepeater, "highlightedIndex", 2);

            keyClick(Qt.Key_Tab);
            tryCompare(spreadRepeater, "highlightedIndex", 3);

            keyClick(Qt.Key_Tab);
            tryCompare(spreadRepeater, "highlightedIndex", 4);

            keyClick(Qt.Key_Backtab);
            tryCompare(spreadRepeater, "highlightedIndex", 3);

            keyClick(Qt.Key_Backtab);
            tryCompare(spreadRepeater, "highlightedIndex", 2);

            keyClick(Qt.Key_Backtab);
            tryCompare(spreadRepeater, "highlightedIndex", 1);

            keyRelease(Qt.Key_Control);
        }

        function test_highlightFollowsMouse() {
            loadDesktopShellWithApps()

            var spreadRepeater = findInvisibleChild(shell, "spreadRepeater");
            verify(spreadRepeater !== null);

            keyPress(Qt.Key_Control)
            keyClick(Qt.Key_Tab);

            tryCompare(spreadRepeater, "highlightedIndex", 1);

            var x = 0;
            var y = shell.height * .75;
            mouseMove(shell, x, y)

            for (var i = 0; i < 7; i++) {
                while (spreadRepeater.highlightedIndex != i && x <= 4000) {
                    x+=10;
                    mouseMove(shell, x, y)
                    wait(0); // spin the loop so bindings get evaluated
                }
            }

            verify(y < 4000);

            keyRelease(Qt.Key_Control);
        }

        function test_closeFromSpread() {
            loadDesktopShellWithApps()

            var spreadRepeater = findInvisibleChild(shell, "spreadRepeater");
            verify(spreadRepeater !== null);

            keyPress(Qt.Key_Control)
            keyClick(Qt.Key_Tab);

            appRemovedSpy.clear();

            var closedAppId = ApplicationManager.get(2).appId;
            var spreadDelegate2 = spreadRepeater.itemAt(2);
            var closeMouseArea = findChild(spreadDelegate2, "closeMouseArea");

            // Move the mosue over tile 2 and verify the close button becomes visible
            var x = 0;
            var y = shell.height * .5;
            mouseMove(shell, x, y)
            while (spreadRepeater.highlightedIndex !== 2 && x <= 4000) {
                x+=10;
                mouseMove(shell, x, y)
                wait(0); // spin the loop so bindings get evaluated
            }
            tryCompare(closeMouseArea, "enabled", true)

            // Close the app using the close button
            mouseClick(closeMouseArea, closeMouseArea.width / 2, closeMouseArea.height / 2)

            // Verify applicationRemoved has been emitted correctly
            tryCompare(appRemovedSpy, "count", 1)
            compare(appRemovedSpy.signalArguments[0][0], closedAppId);

            keyRelease(Qt.Key_Control);
        }

        function test_selectFromSpreadWithMouse_data() {
            return [
                {tag: "click on tileInfo", tileInfo: true },
                {tag: "click on surface", tileInfo: false },
            ]
        }

        function test_selectFromSpreadWithMouse(data) {
            loadDesktopShellWithApps()

            var stage = findChild(shell, "stage");
            var spread = findChild(stage, "spread");
            waitForRendering(spread)

            var spreadRepeater = findInvisibleChild(shell, "spreadRepeater");
            verify(spreadRepeater !== null);

            keyPress(Qt.Key_Control)
            keyClick(Qt.Key_Tab);

            var focusAppId = ApplicationManager.get(2).appId;
            var spreadDelegate2 = spreadRepeater.itemAt(2);
            var clippedSpreadDelegate = findChild(spreadDelegate2, "clippedSpreadDelegate");

            tryCompare(spread, "state", "altTab");

            // Move the mouse over tile 2 and verify the highlight becomes visible
            var x = 0;
            var y = shell.height * (data.tileInfo ? .95 : 0.5)
            mouseMove(shell, x, y)
            while (spreadRepeater.highlightedIndex !== 2 && x <= 4000) {
                x+=10;
                mouseMove(shell, x, y)
                wait(0); // spin the loop so bindings get evaluated
            }
            tryCompare(clippedSpreadDelegate, "highlightShown", true);

            // Click the tile
            mouseClick(clippedSpreadDelegate, clippedSpreadDelegate.width / 2, clippedSpreadDelegate.height / 2)

            // Verify that we left the spread and app2 is the focused one now
            tryCompare(stage, "state", "");
            tryCompare(ApplicationManager, "focusedApplicationId", focusAppId);

            keyRelease(Qt.Key_Control);
        }

        function test_progressiveAutoScrolling() {
            loadDesktopShellWithApps()

            var appRepeater = findInvisibleChild(shell, "appRepeater");
            verify(appRepeater !== null);

            keyPress(Qt.Key_Control)
            keyClick(Qt.Key_Tab);

            var spreadFlickable = findChild(shell, "spreadFlickable")

            compare(spreadFlickable.contentX, 0);

            // Move the mouse to the right and make sure it scrolls the Flickable
            var x = 0;
            var y = shell.height * .5
            mouseMove(shell, x, y)
            while (x <= spreadFlickable.width) {
                x+=10;
                mouseMove(shell, x, y)
                wait(0); // spin the loop so bindings get evaluated
            }
            tryCompare(spreadFlickable, "contentX", spreadFlickable.contentWidth - spreadFlickable.width);

            // And turn around
            while (x > 0) {
                x-=10;
                mouseMove(shell, x, y)
                wait(0); // spin the loop so bindings get evaluated
            }
            tryCompare(spreadFlickable, "contentX", 0);

            keyRelease(Qt.Key_Control);
        }

        // This makes sure the hoverMouseArea is set to invisible AND disabled
        // when not needed. Otherwise it'll eat mouse hover events for the rest of the shell/apps
        function test_hoverMouseAreaDisabledAndInvisible() {
            loadDesktopShellWithApps()

            var hoverMouseArea = findChild(shell, "hoverMouseArea");
            tryCompare(hoverMouseArea, "enabled", false)
            tryCompare(hoverMouseArea, "visible", false)

            keyPress(Qt.Key_Control)
            keyClick(Qt.Key_Tab);

            tryCompare(hoverMouseArea, "enabled", true)
            tryCompare(hoverMouseArea, "visible", true)

            keyRelease(Qt.Key_Control)

            tryCompare(hoverMouseArea, "enabled", false)
            tryCompare(hoverMouseArea, "visible", false)
        }

        function test_workspacePreviewsHighlightedApp() {
            loadDesktopShellWithApps()

            var targetZ = ApplicationManager.count + 1;

            var spreadRepeater = findInvisibleChild(shell, "spreadRepeater");
            verify(spreadRepeater !== null);

            var appRepeater = findInvisibleChild(shell, "appRepeater");
            verify(appRepeater !== null);

            keyPress(Qt.Key_Control)
            keyClick(Qt.Key_Tab);

            tryCompare(spreadRepeater, "highlightedIndex", 1);
            tryCompare(appRepeater.itemAt(1), "z", targetZ)

            var x = 0;
            var y = shell.height * .75;
            mouseMove(shell, x, y)

            for (var i = 0; i < 7; i++) {
                while (spreadRepeater.highlightedIndex != i && x <= 4000) {
                    tryCompare(appRepeater.itemAt(spreadRepeater.highlightedIndex), "z", targetZ)
                    x+=10;
                    mouseMove(shell, x, y)
                    wait(0); // spin the loop so bindings get evaluated
                }
            }

            verify(y < 4000);

            keyRelease(Qt.Key_Control);
        }

        function test_focusAppFromLauncherExitsSpread() {
            loadDesktopShellWithApps()

            var desktopSpread = findChild(shell, "spread");
            var launcher = findChild(shell, "launcher");
            var bfb = findChild(launcher, "buttonShowDashHome");

            keyPress(Qt.Key_Control)
            keyClick(Qt.Key_Tab);


            tryCompare(desktopSpread, "state", "altTab")

            mouseMove(shell, 0, 0);
            tryCompare(launcher, "state", "visibleTemporary")

            mouseClick(bfb, bfb.width / 2, bfb.height / 2)
            tryCompare(launcher, "state", "")
            tryCompare(desktopSpread, "state", "")

            tryCompare(ApplicationManager, "focusedApplicationId", "unity8-dash")

            keyRelease(Qt.Key_Control);
        }
    }
}
