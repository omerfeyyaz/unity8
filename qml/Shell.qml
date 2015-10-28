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
import QtQuick.Window 2.0
import AccountsService 0.1
import Unity.Application 0.1
import Ubuntu.Components 0.1
import Ubuntu.Components.Popups 1.0
import Ubuntu.Gestures 0.1
import Ubuntu.Telephony 0.1 as Telephony
import Unity.Connectivity 0.1
import Unity.Launcher 0.1
import GlobalShortcut 1.0 // has to be before Utils, because of WindowKeysFilter
import Utils 0.1
import Powerd 0.1
import SessionBroadcast 0.1
import "Greeter"
import "Launcher"
import "Panel"
import "Components"
import "Notifications"
import "Stages"
import "Tutorial"
import "Wizard"
import Unity.Notifications 1.0 as NotificationBackend
import Unity.Session 0.1
import Unity.DashCommunicator 0.1
import Unity.Indicators 0.1 as Indicators
import Cursor 1.0


Item {
    id: shell

    // to be set from outside
    property int orientationAngle: 0
    property int orientation
    property int primaryOrientation
    property int nativeOrientation
    property real nativeWidth
    property real nativeHeight
    property alias indicatorAreaShowProgress: panel.indicatorAreaShowProgress
    property bool beingResized
    property string usageScenario: "phone" // supported values: "phone", "tablet" or "desktop"
    property string mode: "full-greeter"
    function updateFocusedAppOrientation() {
        applicationsDisplayLoader.item.updateFocusedAppOrientation();
    }
    function updateFocusedAppOrientationAnimated() {
        applicationsDisplayLoader.item.updateFocusedAppOrientationAnimated();
    }
    property bool hasMouse: false

    // to be read from outside
    readonly property int mainAppWindowOrientationAngle:
            applicationsDisplayLoader.item ? applicationsDisplayLoader.item.mainAppWindowOrientationAngle : 0

    readonly property bool orientationChangesEnabled: panel.indicators.fullyClosed
            && (applicationsDisplayLoader.item && applicationsDisplayLoader.item.orientationChangesEnabled)
            && (!greeter || !greeter.animating)

    readonly property bool showingGreeter: greeter && greeter.shown

    property bool startingUp: true
    Timer { id: finishStartUpTimer; interval: 500; onTriggered: startingUp = false }

    property int supportedOrientations: {
        if (startingUp) {
            // Ensure we don't rotate during start up
            return Qt.PrimaryOrientation;
        } else if (greeter && greeter.shown) {
            return Qt.PrimaryOrientation;
        } else if (mainApp) {
            return mainApp.supportedOrientations;
        } else {
            // we just don't care
            return Qt.PortraitOrientation
                 | Qt.LandscapeOrientation
                 | Qt.InvertedPortraitOrientation
                 | Qt.InvertedLandscapeOrientation;
        }
    }

    // For autopilot consumption
    readonly property string focusedApplicationId: ApplicationManager.focusedApplicationId

    // internal props from here onwards
    readonly property var mainApp:
            applicationsDisplayLoader.item ? applicationsDisplayLoader.item.mainApp : null

    // Disable everything while greeter is waiting, so that the user can't swipe
    // the greeter or launcher until we know whether the session is locked.
    enabled: greeter && !greeter.waiting

    property real edgeSize: units.gu(2)

    WallpaperResolver {
        id: wallpaperResolver
        width: shell.width
    }

    readonly property alias greeter: greeterLoader.item

    function activateApplication(appId) {
        if (ApplicationManager.findApplication(appId)) {
            ApplicationManager.requestFocusApplication(appId);
        } else {
            var execFlags = shell.usageScenario === "phone" ? ApplicationManager.ForceMainStage
                                                            : ApplicationManager.NoFlag;
            ApplicationManager.startApplication(appId, execFlags);
        }
    }

    function startLockedApp(app) {
        if (greeter.locked) {
            greeter.lockedApp = app;
        }
        shell.activateApplication(app);
    }

    Binding {
        target: LauncherModel
        property: "applicationManager"
        value: ApplicationManager
    }

    Component.onCompleted: {
        Theme.name = "Ubuntu.Components.Themes.SuruGradient"
        if (ApplicationManager.count > 0) {
            ApplicationManager.focusApplication(ApplicationManager.get(0).appId);
        }
        finishStartUpTimer.start();
    }

    LightDM{id: lightDM} // Provide backend access
    VolumeControl {
        id: volumeControl
        indicators: panel.indicators
    }

    DashCommunicator {
        id: dash
        objectName: "dashCommunicator"
    }

    PhysicalKeysMapper {
        id: physicalKeysMapper
        objectName: "physicalKeysMapper"

        onPowerKeyLongPressed: dialogs.showPowerDialog();
        onVolumeDownTriggered: volumeControl.volumeDown();
        onVolumeUpTriggered: volumeControl.volumeUp();
        onScreenshotTriggered: screenGrabber.capture();
    }

    GlobalShortcut {
        // dummy shortcut to force creation of GlobalShortcutRegistry before WindowKeyFilter
    }

    WindowKeysFilter {
        Keys.onPressed: physicalKeysMapper.onKeyPressed(event);
        Keys.onReleased: physicalKeysMapper.onKeyReleased(event);
    }

    HomeKeyWatcher {
        onActivated: { launcher.fadeOut(); shell.showHome(); }
    }

    Item {
        id: stages
        objectName: "stages"
        width: parent.width
        height: parent.height

        Connections {
            target: ApplicationManager

            // This signal is also fired when we try to focus the current app
            // again.  We rely on this!
            onFocusedApplicationIdChanged: {
                var appId = ApplicationManager.focusedApplicationId;

                if (tutorial.running && appId != "" && appId != "unity8-dash") {
                    // If this happens on first boot, we may be in edge
                    // tutorial or wizard while receiving a call.  But a call
                    // is more important than wizard so just bail out of those.
                    tutorial.finish();
                    wizard.hide();
                }

                if (appId === "dialer-app" && callManager.hasCalls && greeter.locked) {
                    // If we are in the middle of a call, make dialer lockedApp and show it.
                    // This can happen if user backs out of dialer back to greeter, then
                    // launches dialer again.
                    greeter.lockedApp = appId;
                }
                greeter.notifyAppFocused(appId);

                panel.indicators.hide();
            }

            onApplicationAdded: {
                launcher.hide();
            }
        }

        Loader {
            id: applicationsDisplayLoader
            objectName: "applicationsDisplayLoader"
            anchors.fill: parent

            // When we have a locked app, we only want to show that one app.
            // FIXME: do this in a less traumatic way.  We currently only allow
            // locked apps in phone mode (see FIXME in Lockscreen component in
            // this same file).  When that changes, we need to do something
            // nicer here.  But this code is currently just to prevent a
            // theoretical attack where user enters lockedApp mode, then makes
            // the screen larger (maybe connects to monitor) and tries to enter
            // tablet mode.

            property string usageScenario: shell.usageScenario === "phone" || greeter.hasLockedApp
                                           ? "phone"
                                           : shell.usageScenario
            source: {
                if(shell.mode === "greeter") {
                    return "Stages/ShimStage.qml"
                } else if (applicationsDisplayLoader.usageScenario === "phone") {
                    return "Stages/PhoneStage.qml";
                } else if (applicationsDisplayLoader.usageScenario === "tablet") {
                    return "Stages/TabletStage.qml";
                } else {
                    return "Stages/DesktopStage.qml";
                }
            }

            property bool interactive: tutorial.spreadEnabled
                    && (!greeter || !greeter.shown)
                    && panel.indicators.fullyClosed
                    && launcher.progress == 0
                    && !notifications.useModal

            onInteractiveChanged: { if (interactive) { focus = true; } }

            Binding {
                target: applicationsDisplayLoader.item
                property: "objectName"
                value: "stage"
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "dragAreaWidth"
                value: shell.edgeSize
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "maximizedAppTopMargin"
                // Not just using panel.panelHeight as that changes depending on the focused app.
                value: panel.indicators.minimizedPanelHeight + units.dp(2) // dp(2) for orange line
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "interactive"
                value: applicationsDisplayLoader.interactive
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "spreadEnabled"
                value: tutorial.spreadEnabled && (!greeter || (!greeter.hasLockedApp && !greeter.shown))
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "inverseProgress"
                value: greeter && greeter.locked ? 0 : launcher.progress
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "shellOrientationAngle"
                value: shell.orientationAngle
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "shellOrientation"
                value: shell.orientation
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "background"
                value: wallpaperResolver.background
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "shellPrimaryOrientation"
                value: shell.primaryOrientation
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "nativeOrientation"
                value: shell.nativeOrientation
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "nativeWidth"
                value: shell.nativeWidth
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "nativeHeight"
                value: shell.nativeHeight
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "beingResized"
                value: shell.beingResized
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "keepDashRunning"
                value: launcher.shown || launcher.dashSwipe
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "suspended"
                value: greeter.shown
            }
            Binding {
                target: applicationsDisplayLoader.item
                property: "altTabPressed"
                value: physicalKeysMapper.altTabPressed
            }
        }

        Tutorial {
            id: tutorial
            objectName: "tutorial"
            anchors.fill: parent

            // EdgeDragAreas don't work with mice.  So to avoid trapping the user,
            // we skip the tutorial on the Desktop to avoid using them.  The
            // Desktop doesn't use the same spread design anyway.  The tutorial is
            // all a bit of a placeholder on non-phone form factors right now.
            // When the design team gives us more guidance, we can do something
            // more clever here.
            active: usageScenario != "desktop" && AccountsService.demoEdges

            paused: lightDM.greeter.active
            launcher: launcher
            panel: panel
            edgeSize: shell.edgeSize

            onFinished: {
                AccountsService.demoEdges = false;
                active = false; // for immediate response / if AS is having problems
            }
        }
    }

    InputMethod {
        id: inputMethod
        objectName: "inputMethod"
        anchors { fill: parent; topMargin: panel.panelHeight }
        z: notifications.useModal || panel.indicators.shown || wizard.active ? overlay.z + 1 : overlay.z - 1
    }

    Connections {
        target: SessionManager
        onSessionStopping: {
            if (!session.parentSession && !session.application) {
                // nothing is using it. delete it right away
                session.release();
            }
        }
    }

    Loader {
        id: greeterLoader
        anchors.fill: parent
        anchors.topMargin: panel.panelHeight
        sourceComponent: shell.mode != "shell" ? integratedGreeter :
            Qt.createComponent(Qt.resolvedUrl("Greeter/ShimGreeter.qml"));
        onLoaded: {
            item.objectName = "greeter"
        }
    }

    Component {
        id: integratedGreeter
        Greeter {

            hides: [launcher, panel.indicators]
            tabletMode: shell.usageScenario != "phone"
            launcherOffset: launcher.progress
            forcedUnlock: tutorial.running
            background: wallpaperResolver.background

            // avoid overlapping with Launcher's edge drag area
            // FIXME: Fix TouchRegistry & friends and remove this workaround
            //        Issue involves launcher's DDA getting disabled on a long
            //        left-edge drag
            dragHandleLeftMargin: launcher.available ? launcher.dragAreaWidth + 1 : 0

            onSessionStarted: {
                launcher.hide();
            }

            onTease: {
                if (!tutorial.running) {
                    launcher.tease();
                }
            }

            onEmergencyCall: startLockedApp("dialer-app")
        }
    }

    Timer {
        // See powerConnection for why this is useful
        id: showGreeterDelayed
        interval: 1
        onTriggered: {
            greeter.forceShow();
        }
    }

    Connections {
        id: callConnection
        target: callManager

        onHasCallsChanged: {
            if (greeter.locked && callManager.hasCalls && greeter.lockedApp !== "dialer-app") {
                // We just received an incoming call while locked.  The
                // indicator will have already launched dialer-app for us, but
                // there is a race between "hasCalls" changing and the dialer
                // starting up.  So in case we lose that race, we'll start/
                // focus the dialer ourselves here too.  Even if the indicator
                // didn't launch the dialer for some reason (or maybe a call
                // started via some other means), if an active call is
                // happening, we want to be in the dialer.
                startLockedApp("dialer-app")
            }
        }
    }

    Connections {
        id: powerConnection
        target: Powerd

        onStatusChanged: {
            if (Powerd.status === Powerd.Off && reason !== Powerd.Proximity &&
                    !callManager.hasCalls && !tutorial.running) {
                // We don't want to simply call greeter.showNow() here, because
                // that will take too long.  Qt will delay button event
                // handling until the greeter is done loading and may think the
                // user held down the power button the whole time, leading to a
                // power dialog being shown.  Instead, delay showing the
                // greeter until we've finished handling the event.  We could
                // make the greeter load asynchronously instead, but that
                // introduces a whole host of timing issues, especially with
                // its animations.  So this is simpler.
                showGreeterDelayed.start();
            }
        }
    }

    function showHome() {
        if (tutorial.running) {
            return
        }

        greeter.notifyAboutToFocusApp("unity8-dash");

        var animate = !lightDM.greeter.active && !stages.shown
        dash.setCurrentScope(0, animate, false)
        ApplicationManager.requestFocusApplication("unity8-dash")
    }

    function showDash() {
        if (greeter.notifyShowingDashFromDrag()) {
            launcher.fadeOut();
        }

        if (!greeter.locked && ApplicationManager.focusedApplicationId != "unity8-dash") {
            ApplicationManager.requestFocusApplication("unity8-dash")
            launcher.fadeOut();
        }
    }

    Item {
        id: overlay
        z: 10

        anchors.fill: parent

        Panel {
            id: panel
            objectName: "panel"
            anchors.fill: parent //because this draws indicator menus
            indicators {
                hides: [launcher]
                available: tutorial.panelEnabled
                        && ((!greeter || !greeter.locked) || AccountsService.enableIndicatorsWhileLocked)
                        && (!greeter || !greeter.hasLockedApp)
                contentEnabled: tutorial.panelContentEnabled
                width: parent.width > units.gu(60) ? units.gu(40) : parent.width

                minimizedPanelHeight: units.gu(3)
                expandedPanelHeight: units.gu(7)

                indicatorsModel: Indicators.IndicatorsModel {
                    // tablet and phone both use the same profile
                    profile: shell.usageScenario === "desktop" ? "desktop" : "phone"
                    Component.onCompleted: load();
                }
            }

            callHint {
                greeterShown: greeter.shown
            }

            property bool topmostApplicationIsFullscreen:
                ApplicationManager.focusedApplicationId &&
                    ApplicationManager.findApplication(ApplicationManager.focusedApplicationId).fullscreen

            fullscreenMode: (topmostApplicationIsFullscreen && !lightDM.greeter.active && launcher.progress == 0)
                            || greeter.hasLockedApp
        }

        Launcher {
            id: launcher
            objectName: "launcher"

            readonly property bool dashSwipe: progress > 0

            anchors.top: parent.top
            anchors.topMargin: inverted ? 0 : panel.panelHeight
            anchors.bottom: parent.bottom
            width: parent.width
            dragAreaWidth: shell.edgeSize
            available: tutorial.launcherEnabled
                    && (!greeter.locked || AccountsService.enableLauncherWhileLocked)
                    && !greeter.hasLockedApp
            inverted: shell.usageScenario !== "desktop"
            shadeBackground: !tutorial.running

            onShowDashHome: showHome()
            onDash: showDash()
            onDashSwipeChanged: {
                if (dashSwipe) {
                    dash.setCurrentScope(0, false, true)
                }
            }
            onLauncherApplicationSelected: {
                if (!tutorial.running) {
                    greeter.notifyAboutToFocusApp(appId);
                    shell.activateApplication(appId)
                }
            }
            onShownChanged: {
                if (shown) {
                    panel.indicators.hide()
                }
            }
        }

        Wizard {
            id: wizard
            objectName: "wizard"
            anchors.fill: parent
            background: wallpaperResolver.background

            function unlockWhenDoneWithWizard() {
                if (!active) {
                    Connectivity.unlockAllModems();
                }
            }

            Component.onCompleted: unlockWhenDoneWithWizard()
            onActiveChanged: unlockWhenDoneWithWizard()
        }

        Rectangle {
            id: modalNotificationBackground

            visible: notifications.useModal
            color: "#000000"
            anchors.fill: parent
            opacity: 0.9

            MouseArea {
                anchors.fill: parent
            }
        }

        Notifications {
            id: notifications

            model: NotificationBackend.Model
            margin: units.gu(1)
            hasMouse: shell.hasMouse
            background: wallpaperResolver.background

            y: topmostIsFullscreen ? 0 : panel.panelHeight
            height: parent.height - (topmostIsFullscreen ? 0 : panel.panelHeight)

            states: [
                State {
                    name: "narrow"
                    when: overlay.width <= units.gu(60)
                    AnchorChanges {
                        target: notifications
                        anchors.left: parent.left
                        anchors.right: parent.right
                    }
                },
                State {
                    name: "wide"
                    when: overlay.width > units.gu(60)
                    AnchorChanges {
                        target: notifications
                        anchors.left: undefined
                        anchors.right: parent.right
                    }
                    PropertyChanges { target: notifications; width: units.gu(38) }
                }
            ]
        }
    }

    Dialogs {
        id: dialogs
        objectName: "dialogs"
        anchors.fill: parent
        z: overlay.z + 10
        usageScenario: shell.usageScenario
        onPowerOffClicked: {
            shutdownFadeOutRectangle.enabled = true;
            shutdownFadeOutRectangle.visible = true;
            shutdownFadeOut.start();
        }
    }

    Connections {
        target: SessionBroadcast
        onShowHome: showHome()
    }

    ScreenGrabber {
        id: screenGrabber
        rotationAngle: -shell.orientationAngle
        z: dialogs.z + 10
    }

    Cursor {
        id: cursor
        visible: shell.hasMouse
        z: screenGrabber.z + 1
    }

    Rectangle {
        id: shutdownFadeOutRectangle
        z: cursor.z + 1
        enabled: false
        visible: false
        color: "black"
        anchors.fill: parent
        opacity: 0.0
        NumberAnimation on opacity {
            id: shutdownFadeOut
            from: 0.0
            to: 1.0
            onStopped: {
                if (shutdownFadeOutRectangle.enabled && shutdownFadeOutRectangle.visible) {
                    DBusUnitySessionService.shutdown();
                }
            }
        }
    }
}
