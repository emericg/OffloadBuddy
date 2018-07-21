import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Window 2.2

import com.offloadbuddy.style 1.0

ApplicationWindow {
    id: applicationWindow
    //flags: Qt.FramelessWindowHint | Qt.Window

    title: "OffloadBuddy"
    width: 1280
    height: 720
    minimumWidth: 1280
    minimumHeight: 720

    visible: true
/*
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
    Rectangle {
        id: sideBar
        width: 96
        color: ThemeEngine.colorSidebar
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0
        transformOrigin: Item.Center

        Rectangle {
            id: button_media
            width: 64
            height: 64
            color: "#00000000"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: content.state = "medias"
            }

            Image {
                id: image
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.top: parent.top
                source: "qrc:/resources/menus/media.svg"
            }
        }

        Rectangle {
            id: menuDevice
            color: "#00000000"

            anchors.bottom: button_settings.top
            anchors.bottomMargin: 16
            anchors.top: button_media.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            ListView {
                id: devicesview
                interactive: false
                spacing: 16
                anchors.fill: parent

                model: deviceManager.devicesList
                delegate: ItemDeviceMenu {
                    myDevice: modelData
                    Component.onCompleted: {
                        myDeviceClicked.connect(sideBar.myDeviceClicked)
                    }
                }
            }
        }

        Rectangle {
            id: button_settings
            width: 50
            height: 50
            color: "#00000000"
            anchors.bottom: button_about.top
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: content.state = "settings"
            }
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "qrc:/resources/menus/settings.svg"
            }
        }

        Rectangle {
            id: button_about
            width: 50
            height: 50
            color: "#00000000"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: button_exit.top
            anchors.bottomMargin: 8

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: content.state = "about"
            }
            Image {
                anchors.fill: parent
                source: "qrc:/resources/menus/about.svg"
            }
        }

        Rectangle {
            id: button_exit
            x: 8
            y: 664
            width: 50
            height: 50
            color: "#00000000"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16

            MouseArea {
                anchors.fill: parent
                onClicked: Qt.quit()
            }
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                source: "qrc:/resources/menus/exit.svg"
            }
        }

        Image {
            id: imageArrow
            width: 12
            height: 12
            anchors.right: parent.right
            anchors.rightMargin: 0
            source: "../resources/menus/arrow.svg"
        }

        signal myDeviceClicked(var devicePtr)
        onMyDeviceClicked: {
            if (typeof devicePtr !== "undefined") {
                //console.log(devicePtr + ' component was triggered')
                content.state = "device"
                screenDevice.myDevice = devicePtr
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Item {
        id: content

        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: sideBar.right
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        ScreenMedias {
            anchors.fill: parent
            id: screenMedias
        }
        ScreenDevice {
            anchors.fill: parent
            id: screenDevice
            mySettings: settingsManager
            myDevice: deviceManager.getFirstDevice()
        }
        ScreenSettings {
            anchors.fill: parent
            id: screenSettings
            mySettings: settingsManager
        }
        ScreenAbout {
            anchors.fill: parent
            id: screenAbout
        }

        state: "medias"
        states: [
            State {
                name: "medias"

                PropertyChanges {
                    target: imageArrow
                    anchors.verticalCenter: button_media.verticalCenter
                }
                PropertyChanges {
                    target: screenMedias
                    visible: true
                }
                PropertyChanges {
                    target: screenDevice
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
                    target: imageArrow
                    anchors.verticalCenter: undefined
                }
                PropertyChanges {
                    target: screenMedias
                    visible: false
                }
                PropertyChanges {
                    target: screenDevice
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
                    target: imageArrow
                    anchors.verticalCenter: button_settings.verticalCenter
                }
                PropertyChanges {
                    target: screenMedias
                    visible: false
                }
                PropertyChanges {
                    target: screenDevice
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
                    target: imageArrow
                    anchors.verticalCenter: button_about.verticalCenter
                }
                PropertyChanges {
                    target: screenMedias
                    visible: false
                }
                PropertyChanges {
                    target: screenDevice
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
