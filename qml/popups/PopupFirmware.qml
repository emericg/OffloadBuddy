import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import ThemeEngine
import StorageUtils

import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Popup {
    id: popupFirmware

    x: (appWindow.width / 2) - (width / 2) - (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 720
    padding: 0

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    signal confirmed()

    ////////

    property var currentDevice: null

    property int legendWidth: 128

    ////////

    function open() { return; }

    function openDevice(device) {
        if (typeof device === "undefined" || !device) return
        if (device.brand !== "GoPro") return
        if (!firmwareManager.hasUpdate(device.modelString, device.firmware)) return

        currentDevice = device
        visible = true
    }

    onClosed: {
        currentDevice = null
    }

    ////////////////////////////////////////////////////////////////////////////

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.5; to: 1.0; duration: 133; } }

    background: Item {
        Rectangle {
            id: bgrect
            anchors.fill: parent

            radius: Theme.componentRadius
            color: Theme.colorBackground
            border.color: Theme.colorSeparator
            border.width: Theme.componentBorderWidth
        }
        DropShadow {
            anchors.fill: parent
            source: bgrect
            color: "#60000000"
            radius: 24
            samples: radius*2+1
            cached: true
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    contentItem: Column {

        Rectangle { // titleArea
            anchors.left: parent.left
            anchors.right: parent.right

            height: 64
            color: Theme.colorPrimary
            radius: Theme.componentRadius

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 1
                anchors.right: parent.right
                anchors.rightMargin: 1
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Firmware update")
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: "white"
            }
        }

        ////////////////

        Item {
            id: contentArea
            height: columnFirmware.height
            anchors.left: parent.left
            anchors.right: parent.right

            ////////

            Column {
                id: columnFirmware
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 24
                topPadding: 16
                bottomPadding: 16

                Item {
                    anchors.right: parent.right
                    anchors.left: parent.left
                    height: 32

                    Text {
                        width: popupFirmware.legendWidth
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Model")
                        color: Theme.colorSubText
                        font.pixelSize: Theme.fontSizeContent
                    }
                    Text {
                        width: popupFirmware.legendWidth
                        anchors.left: parent.left
                        anchors.leftMargin: popupFirmware.legendWidth + 16
                        anchors.verticalCenter: parent.verticalCenter

                        text: currentDevice.brand + " " + currentDevice.model
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContent
                    }
                }

                Item {
                    anchors.right: parent.right
                    anchors.left: parent.left
                    height: 32

                    Text {
                        width: popupFirmware.legendWidth
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Firmware")
                        color: Theme.colorSubText
                        font.pixelSize: Theme.fontSizeContent
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: popupFirmware.legendWidth + 16
                        anchors.verticalCenter: parent.verticalCenter

                        text: currentDevice.firmware
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContent
                    }
                }

                Item {
                    anchors.right: parent.right
                    anchors.left: parent.left
                    height: 32

                    Text {
                        width: popupFirmware.legendWidth
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Update")
                        color: Theme.colorSubText
                        font.pixelSize: Theme.fontSizeContent
                    }
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: popupFirmware.legendWidth + 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16

                        Text {
                            text: "v" + firmwareManager.lastUpdate(currentDevice.modelString)
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContent
                        }

                        Text {
                            text: "(" + firmwareManager.lastDate(currentDevice.modelString).toLocaleDateString() + ")"
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContent
                        }
                    }
                }

                Item { width: 16; height: 16; } // spacer

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 200

                    border.width: 2
                    border.color: Theme.colorComponentBorder
                    radius: Theme.componentRadius
                    color: Theme.colorComponentBackground

                    ScrollView {
                        anchors.fill: parent
                        contentWidth: parent.width-32
                        clip: true
                        padding: 16

                        Text {
                            width: parent.width-32
                            text: firmwareManager.lastReleaseNotes(currentDevice.modelString)
                            wrapMode: Text.WordWrap
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContent
                        }
                    }
                }
            }
        }

        //////////////////

        Row {
            height: Theme.componentHeight*2 + parent.spacing
            anchors.right: parent.right
            anchors.rightMargin: 24
            spacing: 24

            ButtonWireframe {
                width: 96
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Cancel")
                fullColor: true
                primaryColor: Theme.colorGrey
                onClicked: popupFirmware.close()
            }
            ButtonWireframeIcon {
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Update")
                source: "qrc:/assets/icons_material/baseline-archive-24px.svg"
                fullColor: true
                primaryColor: Theme.colorPrimary

                onClicked: {
                    if (typeof currentDevice === "undefined" || !currentDevice) return

                    currentDevice.firmwareUpdate()
                    popupFirmware.close()
                }
            }
        }
    }
}
