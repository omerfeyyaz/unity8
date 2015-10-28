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

import QtQuick 2.0

import Unity.Application 0.1
import Unity.Session 0.1
import Ubuntu.Components 1.1
import GlobalShortcut 1.0
import Unity.Platform 1.0
import "../Greeter"

Item {
    id: root

    // to be set from outside, useful mostly for testing purposes
    property var unitySessionService: DBusUnitySessionService
    property var closeAllApps: function() {
        while (true) {
            var app = ApplicationManager.get(0);
            if (app === null) {
                break;
            }
            ApplicationManager.stopApplication(app.appId);
        }
    }
    property string usageScenario

    signal powerOffClicked();

    function showPowerDialog() {
        d.showPowerDialog();
    }

    GlobalShortcut { // reboot/shutdown dialog
        shortcut: Qt.Key_PowerDown
        active: Platform.isPC
        onTriggered: root.unitySessionService.RequestShutdown()
    }

    GlobalShortcut { // reboot/shutdown dialog
        shortcut: Qt.Key_PowerOff
        active: Platform.isPC
        onTriggered: root.unitySessionService.RequestShutdown()
    }

    GlobalShortcut { // sleep
        shortcut: Qt.Key_Sleep
        onTriggered: root.unitySessionService.Suspend()
    }

    GlobalShortcut { // hibernate
        shortcut: Qt.Key_Hibernate
        onTriggered: root.unitySessionService.Hibernate()
    }

    GlobalShortcut { // logout/lock dialog
        shortcut: Qt.Key_LogOff
        onTriggered: root.unitySessionService.RequestLogout()
    }

    GlobalShortcut { // logout/lock dialog
        shortcut: Qt.ControlModifier|Qt.AltModifier|Qt.Key_Delete
        onTriggered: root.unitySessionService.RequestLogout()
    }

    GlobalShortcut { // lock screen
        shortcut: Qt.Key_ScreenSaver
        onTriggered: lightDM.greeter.showGreeter()
    }

    GlobalShortcut { // lock screen
        shortcut: Qt.ControlModifier|Qt.AltModifier|Qt.Key_L
        onTriggered: lightDM.greeter.showGreeter()
    }

    QtObject {
        id: d // private stuff
        objectName: "dialogsPrivate"

        function showPowerDialog() {
            if (!dialogLoader.active) {
                dialogLoader.sourceComponent = powerDialogComponent;
                dialogLoader.focus = true;
                dialogLoader.active = true;
            }
        }
    }

    Loader {
        id: dialogLoader
        objectName: "dialogLoader"
        anchors.fill: parent
        active: false
    }

    LightDM {id: lightDM} // Provide backend access

    Component {
        id: logoutDialogComponent
        ShellDialog {
            id: logoutDialog
            title: i18n.ctr("Title: Lock/Log out dialog", "Log out")
            text: i18n.tr("Are you sure you want to log out?")
            Button {
                text: i18n.ctr("Button: Lock the system", "Lock")
                onClicked: {
                    lightDM.greeter.showGreeter()
                    logoutDialog.hide();
                }
            }
            Button {
                text: i18n.ctr("Button: Log out from the system", "Log Out")
                onClicked: {
                    unitySessionService.logout();
                    logoutDialog.hide();
                }
            }
            Button {
                text: i18n.tr("Cancel")
                onClicked: {
                    logoutDialog.hide();
                }
            }
        }
    }

    Component {
        id: shutdownDialogComponent
        ShellDialog {
            id: shutdownDialog
            title: i18n.ctr("Title: Reboot/Shut down dialog", "Shut down")
            text: i18n.tr("Are you sure you want to shut down?")
            Button {
                text: i18n.ctr("Button: Reboot the system", "Reboot")
                onClicked: {
                    root.closeAllApps();
                    unitySessionService.reboot();
                    shutdownDialog.hide();
                }
                color: UbuntuColors.lightGrey
            }
            Button {
                text: i18n.ctr("Button: Shut down the system", "Shut down")
                onClicked: {
                    root.closeAllApps();
                    unitySessionService.shutdown();
                    shutdownDialog.hide();
                }
                color: UbuntuColors.red
            }
            Button {
                text: i18n.tr("Cancel")
                onClicked: {
                    shutdownDialog.hide();
                }
                color: UbuntuColors.lightGrey
            }
        }
    }

    Component {
        id: rebootDialogComponent
        ShellDialog {
            id: rebootDialog
            title: i18n.ctr("Title: Reboot dialog", "Reboot")
            text: i18n.tr("Are you sure you want to reboot?")
            Button {
                text: i18n.tr("No")
                onClicked: {
                    rebootDialog.hide();
                }
                color: UbuntuColors.lightGrey
            }
            Button {
                text: i18n.tr("Yes")
                onClicked: {
                    root.closeAllApps();
                    unitySessionService.reboot();
                    rebootDialog.hide();
                }
                color: UbuntuColors.red
            }
        }
    }

    Component {
        id: powerDialogComponent
        ShellDialog {
            id: powerDialog
            title: i18n.ctr("Title: Power off/Restart dialog", "Power")
            text: i18n.tr("Are you sure you would like\nto power off?")
            Button {
                text: i18n.ctr("Button: Power off the system", "Power off")
                onClicked: {
                    root.closeAllApps();
                    powerDialog.hide();
                    root.powerOffClicked();
                }
                color: UbuntuColors.red
            }
            Button {
                text: i18n.ctr("Button: Restart the system", "Restart")
                onClicked: {
                    root.closeAllApps();
                    unitySessionService.reboot();
                    powerDialog.hide();
                }
                color: UbuntuColors.lightGrey
            }
            Button {
                text: i18n.tr("Cancel")
                onClicked: {
                    powerDialog.hide();
                }
                color: UbuntuColors.lightGrey
            }
        }
    }

    Connections {
        target: root.unitySessionService

        onLogoutRequested: {
            // Display a dialog to ask the user to confirm.
            if (!dialogLoader.active) {
                dialogLoader.sourceComponent = logoutDialogComponent;
                dialogLoader.focus = true;
                dialogLoader.active = true;
            }
        }

        onShutdownRequested: {
            // Display a dialog to ask the user to confirm.
            if (!dialogLoader.active) {
                dialogLoader.sourceComponent = shutdownDialogComponent;
                dialogLoader.focus = true;
                dialogLoader.active = true;
            }
        }

        onRebootRequested: {
            // Display a dialog to ask the user to confirm.
            if (!dialogLoader.active) {
                // display a combined reboot/shutdown dialog, sadly the session indicator calls rather the "Reboot()" method
                // than shutdown when clicking on the "Shutdown..." menu item
                // FIXME: when/if session indicator is fixed, put the rebootDialogComponent here
                dialogLoader.sourceComponent = shutdownDialogComponent;
                dialogLoader.focus = true;
                dialogLoader.active = true;
            }
        }

        onLogoutReady: {
            root.closeAllApps();
            Qt.quit();
            unitySessionService.endSession();
        }
    }

}
