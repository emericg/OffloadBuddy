import QtQuick
import QtQuick.Effects
import QtQuick.Controls

import ThemeEngine
import StorageUtils

import "qrc:/utils/UtilsString.js" as UtilsString
import "qrc:/utils/UtilsPath.js" as UtilsPath

Popup {
    id: popupFirmware

    x: (appWindow.width / 2) - (width / 2) + (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 720
    padding: 0

    dim: true
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    parent: Overlay.overlay

    ////////////////////////////////////////////////////////////////////////////

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

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.333; to: 1.0; duration: 133; } }

    Overlay.modal: Rectangle {
        color: "#000"
        opacity: ThemeEngine.isLight ? 0.333 : 0.666
    }

    background: Rectangle {
        radius: Theme.componentRadius
        color: Theme.colorBackground

        Item {
            anchors.fill: parent

            Rectangle { // title area
                anchors.left: parent.left
                anchors.right: parent.right
                height: 64
                color: Theme.colorPrimary
            }

            Rectangle { // border
                anchors.fill: parent
                radius: Theme.componentRadius
                color: "transparent"
                border.color: Theme.colorSeparator
                border.width: Theme.componentBorderWidth
                opacity: 0.4
            }

            layer.enabled: true
            layer.effect: MultiEffect { // clip
                maskEnabled: true
                maskInverted: false
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                maskSpreadAtMax: 0.0
                maskSource: ShaderEffectSource {
                    sourceItem: Rectangle {
                        x: background.x
                        y: background.y
                        width: background.width
                        height: background.height
                        radius: background.radius
                    }
                }
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect { // shadow
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowColor: ThemeEngine.isLight ? "#aa000000" : "#aaffffff"
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    contentItem: Column {

        ////////////////

        Item { // titleArea
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentMarginXL
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Firmware update")
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: "white"
            }
        }

        ////////////////

        Column { // contentArea
            anchors.left: parent.left
            anchors.leftMargin: Theme.componentMarginXL
            anchors.right: parent.right
            anchors.rightMargin: Theme.componentMarginXL

            topPadding: Theme.componentMarginXL
            bottomPadding: Theme.componentMarginXL
            spacing: Theme.componentMarginXL

            ////////////

            Column {
                id: columnFirmware
                anchors.left: parent.left
                anchors.right: parent.right

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

                        text: currentDevice && currentDevice.firmware
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

            ////////////

            Row {
                anchors.right: parent.right
                spacing: Theme.componentMargin

                ButtonSolid {
                    text: qsTr("Cancel")
                    color: Theme.colorGrey

                    onClicked: popupFirmware.close()
                }

                ButtonSolid {
                    text: qsTr("Update")
                    source: "qrc:/assets/icons/material-symbols/archive.svg"
                    color: Theme.colorPrimary

                    onClicked: {
                        if (typeof currentDevice === "undefined" || !currentDevice) return

                        currentDevice.firmwareUpdate()
                        popupFirmware.close()
                    }
                }
            }

            ////////////
        }

        ////////////////
    }

    ////////////////////////////////////////////////////////////////////////////
}
