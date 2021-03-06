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
import QtGraphicalEffects 1.12 // Qt5
//import Qt5Compat.GraphicalEffects // Qt6

import ThemeEngine 1.0

ApplicationWindow {
    id: appWindow
    flags: settingsManager.appThemeCSD ? Qt.Window | Qt.FramelessWindowHint : Qt.Window
    color: settingsManager.appThemeCSD ? "transparent" : Theme.colorBackground

    property bool isDesktop: true
    property bool isMobile: false
    property bool isPhone: false
    property bool isTablet: false
    property bool isHdpi: (utilsScreen.screenDpi > 128)

    // Desktop stuff ///////////////////////////////////////////////////////////

    minimumWidth: isHdpi ? 800 : 1280
    minimumHeight: isHdpi ? 480 : 720

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
    visibility: settingsManager.initialVisibility
    visible: true

    WindowGeometrySaver {
        windowInstance: appWindow
    }

    // Events handling /////////////////////////////////////////////////////////

    Component.onCompleted: {
        mediaLibrary.searchMediaDirectories()
        deviceManager.searchDevices()
    }
/*
    Shortcut {
        sequences: [StandardKey.Back, StandardKey.Backspace]
        onActivated: backAction()
    }
    Shortcut {
        sequence: StandardKey.Forward
        onActivated: forwardAction()
    }
    Shortcut {
        sequence: StandardKey.Refresh
        onActivated: //
    }
    Shortcut {
        sequence: "Ctrl+F5"
        onActivated: //
    }
    Shortcut {
        sequences: [StandardKey.Deselect, StandardKey.Cancel]
        onActivated: deselectAction()
    }
*/
    Shortcut {
        sequence: StandardKey.FullScreen
        onActivated: {
            if (appWindow.visibility === Window.Windowed)
                appWindow.visibility = Window.FullScreen
            else
                appWindow.visibility = Window.Windowed
        }
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
    // Content /////////////////////////////////////////////////////////////////

    property var currentDevicePtr: null

    Rectangle {
        id: appBg
        anchors.fill: parent

        color: Theme.colorBackground
        border.color: Theme.colorSeparator
        border.width: settingsManager.appThemeCSD ? 1 : 0

        Sidebar {
            id: appSidebar
            z: 2

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
        }

        Item {
            id: appContent

            anchors.top: parent.top
            anchors.left: appSidebar.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom

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
            }
            ScreenSettings {
                anchors.fill: parent
                id: screenSettings
            }
            ScreenAbout {
                anchors.fill: parent
                id: screenAbout
            }

            //ScreenComponents {
            //    anchors.fill: parent
            //    id: screenComponents
            //}

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
                    //PropertyChanges { target: screenComponents; visible: false; }
                },
                State {
                    name: "device"
                    PropertyChanges { target: screenLibrary; visible: false; }
                    PropertyChanges { target: screenDevice; visible: true; }
                    PropertyChanges { target: screenJobs; visible: false; }
                    PropertyChanges { target: screenSettings; visible: false; }
                    PropertyChanges { target: screenAbout; visible: false; }
                    //PropertyChanges { target: screenComponents; visible: false; }
                },
                State {
                    name: "jobs"
                    PropertyChanges { target: screenLibrary; visible: false; }
                    PropertyChanges { target: screenDevice; visible: false; }
                    PropertyChanges { target: screenJobs; visible: true; }
                    PropertyChanges { target: screenSettings; visible: false; }
                    PropertyChanges { target: screenAbout; visible: false; }
                    //PropertyChanges { target: screenComponents; visible: false; }
                },
                State {
                    name: "settings"
                    PropertyChanges { target: screenLibrary; visible: false; }
                    PropertyChanges { target: screenDevice; visible: false; }
                    PropertyChanges { target: screenJobs; visible: false; }
                    PropertyChanges { target: screenSettings; visible: true; }
                    PropertyChanges { target: screenAbout; visible: false; }
                    //PropertyChanges { target: screenComponents; visible: false; }
                },
                State {
                    name: "about"
                    PropertyChanges { target: screenLibrary; visible: false; }
                    PropertyChanges { target: screenDevice; visible: false; }
                    PropertyChanges { target: screenJobs; visible: false; }
                    PropertyChanges { target: screenSettings; visible: false; }
                    PropertyChanges { target: screenAbout; visible: true; }
                    //PropertyChanges { target: screenComponents; visible: false; }
                },
                State {
                    name: "components"
                    PropertyChanges { target: screenLibrary; visible: false; }
                    PropertyChanges { target: screenDevice; visible: false; }
                    PropertyChanges { target: screenJobs; visible: false; }
                    PropertyChanges { target: screenSettings; visible: false; }
                    PropertyChanges { target: screenAbout; visible: false; }
                    //PropertyChanges { target: screenComponents; visible: true; }
                }
            ]
        }

        layer.enabled: (settingsManager.appThemeCSD && Qt.platform.os !== "windows")
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                x: appBg.x
                y: appBg.y
                width: appBg.width
                height: appBg.height
                radius: 10

                DragHandler { // Resize the window without a compositor bar // Qt 5.15+
                    id: windowHandler2
                    grabPermissions: TapHandler.TakeOverForbidden
                    target: null
                    onActiveChanged: if (active) {
                        var grabSize = 32

                        const p = windowHandler2.centroid.position;
                        let e = 0;
                        if (p.x < grabSize) e |= Qt.LeftEdge;
                        if (p.x >= width - grabSize) e |= Qt.RightEdge;
                        if (p.y < grabSize) e |= Qt.TopEdge;
                        if (p.y >= height - grabSize) e |= Qt.BottomEdge;

                        if (e) {
                            if (!appWindow.startSystemResize(e)) {
                                // your fallback code for setting window.width/height manually
                            }
                        } else {
                            appWindow.startSystemMove();
                        }
                    }
                }
            }
        }
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
