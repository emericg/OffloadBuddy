import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import DeviceUtils 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsDeviceCamera.js" as UtilsDevice

Rectangle {
    id: deviceInfos
    width: 1280
    height: 720

    color: Theme.colorHeader

    ////////////////////////////////////////////////////////////////////////////

    Connections {
        target: currentDevice
        onStorageUpdated: updateStorage()
        onBatteryUpdated: updateBattery()
    }

    function loadScreen() {
        if (typeof currentDevice === "undefined" || !currentDevice) return

        initDeviceHeader()
        deviceStorageStats.load(currentDevice.shotModel)
        screenDevice.state = "stateDeviceInfos"
    }

    function restoreState() {
        if (typeof currentDevice === "undefined" || !currentDevice) return
        //console.log("ScreenDeviceGrid.restoreState()")
    }

    function initDeviceHeader() {
        if (typeof currentDevice === "undefined" || !currentDevice) return
        //console.log("ScreenDeviceGrid.initDeviceHeader()")

        // Header picture
        deviceImage.source = UtilsDevice.getDevicePicture(currentDevice)

        // Storage and battery infos
        updateStorage()
        updateBattery()
    }

    function updateBattery() {
        if (typeof currentDevice === "undefined" || !currentDevice) return
        //console.log("ScreenDeviceGrid.updateBattery() batteryLevel: " + currentDevice.batteryLevel)
    }

    function updateStorage() {
        if (typeof currentDevice === "undefined" || !currentDevice) return
        //console.log("ScreenDeviceGrid.updateStorage() storageLevel: " + currentDevice.storageLevel)
    }

    // POPUPs //////////////////////////////////////////////////////////////////

    PopupFirmware { id: popupFirmware }

    // HEADER //////////////////////////////////////////////////////////////////

    Rectangle {
        id: rectangleHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        z: 1
        height: 64
        color: Theme.colorHeader

        DragHandler {
            // Drag on the sidebar to drag the whole window // Qt 5.15+
            // Also, prevent clicks below this area
            acceptedButtons: Qt.AllButtons
            onActiveChanged: if (active) appWindow.startSystemMove()
            target: null
        }

        ////////////////

        ItemImageButton {
            id: buttonBack
            width: 48
            height: 48
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            iconColor: Theme.colorHeaderContent
            backgroundColor: Theme.colorForeground

            source: "qrc:/assets/others/navigate_before_big.svg"
            onClicked: {
                if (appContent.state === "library") {
                    screenLibrary.state = "stateMediaGrid"
                } else if (appContent.state === "device") {
                    screenDevice.state = "stateMediaGrid"
                    deviceSavedState.mainState = "stateMediaGrid"
                }
            }
        }

        Text {
            id: textShotName
            height: 40
            anchors.left: buttonBack.right
            anchors.leftMargin: 8
            anchors.right: rowButtons.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Hardware Infos")
            color: Theme.colorHeaderContent
            fontSizeMode: Text.HorizontalFit
            font.bold: true
            font.pixelSize: Theme.fontSizeHeader
            minimumPixelSize: 22
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    // CONTENT /////////////////////////////////////////////////////////////////

    Flow {
        id: contentflow

        anchors.top: rectangleHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24

        spacing: 24
        property int boxSize: (width >= 1280) ? ((width - 24) / 2) : (width)

        ////////////////

        Rectangle {
            width: columnDevice.width
            height: columnDevice.height + 48
            radius: Theme.componentRadius

            color: Theme.colorBackground
            border.color: Theme.colorBackground

            Rectangle {
                id: columnDeviceHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                height: 48
                color: Theme.colorForeground
                radius: Theme.componentRadius

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    ImageSvg{
                        source: "qrc:/assets/icons_material/outline-camera_alt-24px.svg"
                        color: Theme.colorText
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Device")
                        font.pixelSize: 18
                        font.bold: true
                        color: Theme.colorText
                    }
                }
            }

            ImageSvg {
                id: deviceImage
                width: 256
                anchors.top: columnDeviceHeader.bottom
                anchors.topMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8

                fillMode: Image.PreserveAspectCrop
                color: Theme.colorHeaderContent
            }

            Column {
                id: columnDevice
                anchors.top: columnDeviceHeader.bottom
                width: contentflow.boxSize
                padding: 16
                spacing: 16

                Row {
                    spacing: 8
                    Text {
                        text: qsTr("Brand")
                        color: Theme.colorText
                        font.bold: true
                        font.pixelSize: Theme.fontSizeContent
                    }
                    Text {
                        text: currentDevice.brand
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContent
                    }
                }
                Row {
                    spacing: 8
                    Text {
                        text: qsTr("Model")
                        color: Theme.colorText
                        font.bold: true
                        font.pixelSize: Theme.fontSizeContent
                    }
                    Text {
                        text: currentDevice.model
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContent
                    }
                }
                Row {
                    spacing: 8
                    Text {
                        text: qsTr("Serial")
                        color: Theme.colorText
                        font.bold: true
                        font.pixelSize: Theme.fontSizeContent
                    }
                    Text {
                        text: currentDevice.serial
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContent
                    }
                }
                Row {
                    spacing: 8
                    Text {
                        text: qsTr("Firmware")
                        color: Theme.colorText
                        font.bold: true
                        font.pixelSize: Theme.fontSizeContent
                    }
                    Text {
                        text: currentDevice.firmware
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContent
                    }
                }
                ButtonWireframeImage {
                    fullColor: true
                    text: {
                        if (currentDevice.firmwareState === DeviceUtils.FirmwareUpToDate) return qsTr("Up to date")
                        if (currentDevice.firmwareState === DeviceUtils.FirmwareUpdateAvailable) return qsTr("Update available")
                        if (currentDevice.firmwareState === DeviceUtils.FirmwareUpdating) return qsTr("Updating...")
                        if (currentDevice.firmwareState === DeviceUtils.FirmwareUpdateInstalled) return qsTr("Update installed")
                        return ""
                    }
                    source: "qrc:/assets/icons_material/baseline-archive-24px.svg"

                    visible: (currentDevice.firmwareState > 0)
                    onClicked: popupFirmware.openDevice(currentDevice)
                }
            }
        }

        ////////////////

        Rectangle {
            width: columnStorage.width
            height: columnStorage.height + 48
            radius: Theme.componentRadius

            color: Theme.colorBackground
            border.color: Theme.colorBackground

            Rectangle {
                id: columnStorageHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                height: 48
                color: Theme.colorForeground
                radius: Theme.componentRadius

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    ImageSvg{
                        source: "qrc:/assets/icons_material/outline-sd_card-24px.svg"
                        color: Theme.colorText
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Storage")
                        font.pixelSize: 18
                        font.bold: true
                        color: Theme.colorText
                    }
                }
            }

            Column {
                id: columnStorage
                anchors.top: columnStorageHeader.bottom
                width: contentflow.boxSize
                padding: 16
                spacing: 16

                Repeater {
                    model: currentDevice.storageList
                    delegate: DataBarStorage {
                        width: columnStorage.width-32
                        value: modelData.spaceUsed
                        valueMin: 0
                        valueMax: modelData.spaceTotal
                        vsu: modelData.spaceUsed
                        vst: modelData.spaceTotal
                    }
                }

                DataBarPower {
                    id: deviceBatteryBar
                    width: columnStorage.width-32
                    height: 16

                    visible: currentDevice.batteryLevel > 0
                    value: currentDevice.batteryLevel
                    valueMin: 0
                    valueMax: 100
                }

                DataBarStorageStats {
                    id: deviceStorageStats
                    width: columnStorage.width-32
                    height: 32
                }
            }
        }

        ////////////////

        Rectangle {
            width: columnCapabilities.width
            height: columnCapabilities.height + 48
            radius: Theme.componentRadius

            color: Theme.colorBackground
            border.color: Theme.colorBackground

            Rectangle {
                id: columnCapabilitiesHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                height: 48
                color: Theme.colorForeground
                radius: Theme.componentRadius

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    ImageSvg{
                        source: "qrc:/assets/icons_material/baseline-aspect_ratio-24px.svg"
                        color: Theme.colorText
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Capabilities")
                        font.pixelSize: Theme.fontSizeContent
                        font.bold: true
                        color: Theme.colorText
                    }
                }
            }

            Column {
                id: columnCapabilities
                anchors.top: columnCapabilitiesHeader.bottom
                width: contentflow.boxSize
                padding: 16
                spacing: 16
            }
        }

        ////////////////
    }
}
