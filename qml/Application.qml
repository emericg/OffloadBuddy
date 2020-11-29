/*!
 * This file is part of OffloadBuddy.
 * COPYRIGHT (C) 2020 Emeric Grange - All Rights Reserved
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * \date      2018
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

import ThemeEngine 1.0

ApplicationWindow {
    id: appWindow
    flags: Qt.Window //| Qt.FramelessWindowHint
    color: Theme.colorBackground

    // Desktop stuff ///////////////////////////////////////////////////////////

    minimumWidth: isHdpi ? 800 : 1280
    minimumHeight: isHdpi ? 540 : 720

    width: {
        if (settingsManager.initialSize.width > 0)
            return settingsManager.initialSize.width
        else
            return isHdpi ? 800 : 1280
    }
    height: {
        if (settingsManager.initialSize.height > 0)
            return settingsManager.initialSize.height
        else
            return isHdpi ? 480 : 720
    }
    x: settingsManager.initialPosition.width
    y: settingsManager.initialPosition.height

    WindowGeometrySaver {
        windowInstance: appWindow
    }

    // Mobile stuff ////////////////////////////////////////////////////////////

    property bool isHdpi: (utilsScreen.screenDpi > 128)
    property bool isDesktop: true
    property bool isMobile: false
    property bool isPhone: false
    property bool isTablet: false

    // Events handling /////////////////////////////////////////////////////////

    Component.onCompleted: {
        mediaLibrary.searchMediaDirectories()
        deviceManager.searchDevices()
    }
    Shortcut {
        sequence: StandardKey.Preferences
        onActivated: appContent.state = "settings"
    }
    Shortcut {
        sequence: StandardKey.Close
        onActivated: appWindow.close()
    }
    Shortcut {
        sequence: StandardKey.Quit
        onActivated: utilsApp.appExit()
    }

    // Menubar /////////////////////////////////////////////////////////////////
/*
    menuBar: MenuBar {
        id: appMenubar
        Menu {
            title: qsTr("File")
            MenuItem {
                text: qsTr("Do nothing")
                onTriggered: console.log("Do nothing action triggered");
            }
            MenuItem {
                text: qsTr("&Exit")
                onTriggered: Qt.quit();
            }
        }
    }
*/
    // Sidebar /////////////////////////////////////////////////////////////////

    Sidebar {
        id: appSidebar
        DragHandler { // Drag on the sidebar to drag the whole window // Qt 5.15+
            id: windowHandler1
            target: null
            onActiveChanged: if (active) appWindow.startSystemMove();
    }
        }

    // Content /////////////////////////////////////////////////////////////////

    property var currentDevicePtr: null

    Item {
        id: appContent

        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: appSidebar.right
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        ScreenLibrary {
            anchors.fill: parent
            id: screenLibrary
        }
        ScreenDevice {
            anchors.fill: parent
            id: screenDevice
        }
        ScreenJobs {
            anchors.fill: parent
            id: screenJobs
            myJobs: jobManager
        }
        ScreenSettings {
            anchors.fill: parent
            id: screenSettings
        }
        ScreenAbout {
            anchors.fill: parent
            id: screenAbout
        }

        ScreenComponents {
            anchors.fill: parent
            id: screenComponents
        }

        onStateChanged: {
            screenLibrary.updateFocus()
            screenDevice.updateFocus()
        }

        state: "library"
        states: [
            State {
                name: "library"
                PropertyChanges { target: screenLibrary; visible: true; }
                PropertyChanges { target: screenDevice; visible: false; }
                PropertyChanges { target: screenJobs; visible: false; }
                PropertyChanges { target: screenSettings; visible: false; }
                PropertyChanges { target: screenAbout; visible: false; }
                PropertyChanges { target: screenComponents; visible: false; }
            },
            State {
                name: "device"
                PropertyChanges { target: screenLibrary; visible: false; }
                PropertyChanges { target: screenDevice; visible: true; }
                PropertyChanges { target: screenJobs; visible: false; }
                PropertyChanges { target: screenSettings; visible: false; }
                PropertyChanges { target: screenAbout; visible: false; }
                PropertyChanges { target: screenComponents; visible: false; }
            },
            State {
                name: "jobs"
                PropertyChanges { target: screenLibrary; visible: false; }
                PropertyChanges { target: screenDevice; visible: false; }
                PropertyChanges { target: screenJobs; visible: true; }
                PropertyChanges { target: screenSettings; visible: false; }
                PropertyChanges { target: screenAbout; visible: false; }
                PropertyChanges { target: screenComponents; visible: false; }
            },
            State {
                name: "settings"
                PropertyChanges { target: screenLibrary; visible: false; }
                PropertyChanges { target: screenDevice; visible: false; }
                PropertyChanges { target: screenJobs; visible: false; }
                PropertyChanges { target: screenSettings; visible: true; }
                PropertyChanges { target: screenAbout; visible: false; }
                PropertyChanges { target: screenComponents; visible: false; }
            },
            State {
                name: "about"
                PropertyChanges { target: screenLibrary; visible: false; }
                PropertyChanges { target: screenDevice; visible: false; }
                PropertyChanges { target: screenJobs; visible: false; }
                PropertyChanges { target: screenSettings; visible: false; }
                PropertyChanges { target: screenAbout; visible: true; }
                PropertyChanges { target: screenComponents; visible: false; }
            },
            State {
                name: "components"
                PropertyChanges { target: screenLibrary; visible: false; }
                PropertyChanges { target: screenDevice; visible: false; }
                PropertyChanges { target: screenJobs; visible: false; }
                PropertyChanges { target: screenSettings; visible: false; }
                PropertyChanges { target: screenAbout; visible: false; }
                PropertyChanges { target: screenComponents; visible: true; }
            }
        ]
    }

    // Exit ////////////////////////////////////////////////////////////////////

    PopupExit {
        id: popupExit
        onConfirmed: Qt.quit()
    }
    onClosing: {
        // If a job is running, ask user to confirm exit
        if (jobManager.workingJobCount > 0) {
            close.accepted = false;
            popupExit.open()
        }
    }
}
