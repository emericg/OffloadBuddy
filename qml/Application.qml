/*!
 * This file is part of OffloadBuddy.
 * COPYRIGHT (C) 2018 Emeric Grange - All Rights Reserved
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

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Window 2.2

import com.offloadbuddy.theme 1.0

ApplicationWindow {
    id: applicationWindow
    flags: Qt.Window // | Qt.FramelessWindowHint
    minimumWidth: 1280
    minimumHeight: 720

    title: "OffloadBuddy"
    color: Theme.colorBackground
    visible: true

    WindowGeometrySaver {
        window: applicationWindow
    }
/*
    // Menubar /////////////////////////////////////////////////////////////////

    menuBar: MenuBar {
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
        id: applicationSidebar
    }

    // Content /////////////////////////////////////////////////////////////////

    property var currentDevicePtr: null

    Item {
        id: applicationContent

        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: applicationSidebar.right
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

        state: "library"
        states: [
            State {
                name: "library"

                PropertyChanges {
                    target: screenLibrary
                    visible: true
                }
                PropertyChanges {
                    target: screenDevice
                    visible: false
                }
                PropertyChanges {
                    target: screenJobs
                    visible: false
                }
                PropertyChanges {
                    target: screenSettings
                    visible: false
                }
                PropertyChanges {
                    target: screenAbout
                    visible: false
                }
            },
            State {
                name: "device"

                PropertyChanges {
                    target: screenLibrary
                    visible: false
                }
                PropertyChanges {
                    target: screenDevice
                    visible: true
                }
                PropertyChanges {
                    target: screenJobs
                    visible: false
                }
                PropertyChanges {
                    target: screenSettings
                    visible: false
                }
                PropertyChanges {
                    target: screenAbout
                    visible: false
                }
            },
            State {
                name: "jobs"

                PropertyChanges {
                    target: screenLibrary
                    visible: false
                }
                PropertyChanges {
                    target: screenDevice
                    visible: false
                }
                PropertyChanges {
                    target: screenJobs
                    visible: true
                }
                PropertyChanges {
                    target: screenSettings
                    visible: false
                }
                PropertyChanges {
                    target: screenAbout
                    visible: false
                }
            },
            State {
                name: "settings"

                PropertyChanges {
                    target: screenLibrary
                    visible: false
                }
                PropertyChanges {
                    target: screenDevice
                    visible: false
                }
                PropertyChanges {
                    target: screenJobs
                    visible: false
                }
                PropertyChanges {
                    target: screenSettings
                    visible: true
                }
                PropertyChanges {
                    target: screenAbout
                    visible: false
                }
            },
            State {
                name: "about"

                PropertyChanges {
                    target: screenLibrary
                    visible: false
                }
                PropertyChanges {
                    target: screenDevice
                    visible: false
                }
                PropertyChanges {
                    target: screenJobs
                    visible: false
                }
                PropertyChanges {
                    target: screenSettings
                    visible: false
                }
                PropertyChanges {
                    target: screenAbout
                    visible: true
                }
            }
        ]
    }
}
