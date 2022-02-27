import QtQuick 2.15
import QtQuick.Controls 2.15

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

        RoundButtonIcon {
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
            anchors.right: parent.right
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

    Flickable {
        anchors.top: rectangleHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24

        contentHeight: contentflow.height

        Flow {
            id: contentflow
            anchors.left: parent.left
            anchors.right: parent.right

            spacing: 24
            property int boxSize: (width >= 1280) ? ((width - 24) / 2) : (width)

            ////////////////////////////////

            Rectangle { // DEVICE
                width: contentflow.boxSize
                height: columnDevice.height + 80
                radius: Theme.componentRadius

                color: Theme.colorBackground
                border.color: Theme.colorForeground

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

                        IconSvg {
                            source: "qrc:/assets/icons_material/duotone-camera_alt-24px.svg"
                            color: Theme.colorText
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            text: qsTr("Device")
                            font.pixelSize: Theme.fontSizeContentBig
                            font.bold: true
                            color: Theme.colorText
                        }
                    }
                }

                IconSvg {
                    id: deviceImage
                    anchors.top: columnDeviceHeader.bottom
                    anchors.topMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    width: height

                    smooth: true
                    color: Theme.colorHeaderContent
                    fillMode: Image.PreserveAspectFit
                }

                Column {
                    id: columnDevice
                    anchors.top: columnDeviceHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 16
                    spacing: 16

                    Row {
                        spacing: 8
                        visible: currentDevice.brand

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
                        visible: currentDevice.model

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
                        visible: currentDevice.serial

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
                        visible: currentDevice.firmware

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
                    ButtonWireframeIcon {
                        visible: (currentDevice.brand === "GoPro" && currentDevice.firmwareState > 0)

                        fullColor: true
                        primaryColor: {
                            if (currentDevice.firmwareState === DeviceUtils.FirmwareUpToDate) return Theme.colorSuccess
                            if (currentDevice.firmwareState === DeviceUtils.FirmwareUpdateInstalled) return Theme.colorSuccess
                            return Theme.colorPrimary
                        }
                        text: {
                            if (currentDevice.firmwareState === DeviceUtils.FirmwareUpToDate) return qsTr("Up to date")
                            if (currentDevice.firmwareState === DeviceUtils.FirmwareUpdateAvailable) return qsTr("Update available")
                            if (currentDevice.firmwareState === DeviceUtils.FirmwareUpdating) return qsTr("Updating...")
                            if (currentDevice.firmwareState === DeviceUtils.FirmwareUpdateInstalled) return qsTr("Update installed")
                            return ""
                        }
                        source: {
                            if (currentDevice.firmwareState === DeviceUtils.FirmwareUpToDate)
                                return "qrc:/assets/icons_material/baseline-done-24px.svg"
                            return "qrc:/assets/icons_material/baseline-archive-24px.svg"
                        }

                        onClicked: {
                            if (currentDevice.firmwareState === DeviceUtils.FirmwareUpdateAvailable)
                                popupFirmware.openDevice(currentDevice)
                        }
                    }
                }
            }

            ////////////////////////////////

            Rectangle { // STORAGE
                width: contentflow.boxSize
                height: columnStorage.height + 80
                radius: Theme.componentRadius

                color: Theme.colorBackground
                border.color: Theme.colorForeground

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

                        IconSvg {
                            source: "qrc:/assets/icons_material/duotone-sd_card-24px.svg"
                            color: Theme.colorText
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            text: qsTr("Storage")
                            font.pixelSize: Theme.fontSizeContentBig
                            font.bold: true
                            color: Theme.colorText
                        }
                    }
                }

                Column {
                    id: columnStorage
                    anchors.top: columnStorageHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 16
                    spacing: 16

                    Repeater {
                        model: currentDevice.storageList
                        delegate: DataBarStorage {
                            width: columnStorage.width
                            value: modelData.spaceUsed
                            valueMin: 0
                            valueMax: modelData.spaceTotal
                            vsu: modelData.spaceUsed
                            vst: modelData.spaceTotal
                        }
                    }

                    DataBarPower {
                        id: deviceBatteryBar
                        width: columnStorage.width
                        height: 16

                        visible: currentDevice.batteryLevel > 0
                        value: currentDevice.batteryLevel
                        valueMin: 0
                        valueMax: 100
                    }

                    DataBarStorageStats {
                        id: deviceStorageStats
                        width: columnStorage.width
                        height: 32
                    }
                }
            }

            ////////////////////////////////

            Rectangle { // CAPABILITIES
                width: contentflow.boxSize
                height: columnCapabilities.height + 80
                radius: Theme.componentRadius

                color: Theme.colorBackground
                border.color: Theme.colorForeground

                visible: currentDevice.capabilities

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

                        IconSvg {
                            source: "qrc:/assets/icons_material/duotone-aspect_ratio-24px.svg"
                            color: Theme.colorText
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            text: qsTr("Capabilities")
                            font.pixelSize: Theme.fontSizeContentBig
                            font.bold: true
                            color: Theme.colorText
                        }
                    }
                }

                Column {
                    id: columnCapabilities
                    anchors.top: columnCapabilitiesHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 16
                    spacing: 16

                    Row {
                        spacing: 8
                        visible: currentDevice.capabilities.year

                        Text {
                            text: qsTr("Release")
                            color: Theme.colorText
                            font.bold: true
                            font.pixelSize: Theme.fontSizeContent
                        }
                        Text {
                            text: currentDevice.capabilities.year
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContent
                        }
                    }
                    Flow {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 8
                        visible: currentDevice.capabilities.features

                        Text {
                            text: qsTr("Features")
                            color: Theme.colorText
                            font.bold: true
                            font.pixelSize: Theme.fontSizeContent
                        }
                        Repeater {
                            model: currentDevice.capabilities.features
                            Text {
                                text: modelData + " / "
                                color: Theme.colorText
                                font.pixelSize: Theme.fontSizeContent
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                    Flow {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 8
                        visible: currentDevice.capabilities.modesVideo

                        Text {
                            text: qsTr("Video modes")
                            color: Theme.colorText
                            font.bold: true
                            font.pixelSize: Theme.fontSizeContent
                        }
                        Repeater {
                            model: currentDevice.capabilities.modesVideo
                            Text {
                                text: modelData + " / "
                                color: Theme.colorText
                                font.pixelSize: Theme.fontSizeContent
                            }
                        }
                    }
                    Flow {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 8
                        visible: currentDevice.capabilities.modesPhoto

                        Text {
                            text: qsTr("Photo modes")
                            color: Theme.colorText
                            font.bold: true
                            font.pixelSize: Theme.fontSizeContent
                        }
                        Repeater {
                            model: currentDevice.capabilities.modesPhoto
                            Text {
                                text: modelData + " / "
                                color: Theme.colorText
                                font.pixelSize: Theme.fontSizeContent
                            }
                        }
                    }
                    Flow {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 8
                        visible: currentDevice.capabilities.modesTimelapse

                        Text {
                            text: qsTr("Timelapse modes")
                            color: Theme.colorText
                            font.bold: true
                            font.pixelSize: Theme.fontSizeContent
                        }
                        Repeater {
                            model: currentDevice.capabilities.modesTimelapse
                            Text {
                                text: modelData + " / "
                                color: Theme.colorText
                                font.pixelSize: Theme.fontSizeContent
                            }
                        }
                    }

                    //

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: currentDevice.capabilities.modesVideoTable

                        Rectangle {
                            id: modeHeader
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 32
                            radius: Theme.componentRadius
                            color: Theme.colorForeground

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: 24

                                Text {
                                    width: modeHeader.width*0.12
                                    height: 24
                                    text: qsTr("MODE")
                                    color: Theme.colorText
                                    font.pixelSize: Theme.fontSizeContent
                                    verticalAlignment: Text.AlignVCenter
                                }
                                Text {
                                    width: modeHeader.width*0.24
                                    height: 24
                                    text: qsTr("FOV")
                                    color: Theme.colorText
                                    font.pixelSize: Theme.fontSizeContent
                                    verticalAlignment: Text.AlignVCenter
                                }
                                Text {
                                    width: modeHeader.width*0.12
                                    height: 24
                                    text: qsTr("RATIO")
                                    color: Theme.colorText
                                    font.pixelSize: Theme.fontSizeContent
                                    verticalAlignment: Text.AlignVCenter
                                }
                                Text {
                                    width: modeHeader.width*0.24
                                    height: 24
                                    text: qsTr("RESOLUTION")
                                    color: Theme.colorText
                                    font.pixelSize: Theme.fontSizeContent
                                    verticalAlignment: Text.AlignVCenter
                                }
                                Text {
                                    width: modeHeader.width*0.12
                                    height: 24
                                    text: qsTr("FPS")
                                    color: Theme.colorText
                                    font.pixelSize: Theme.fontSizeContent
                                    verticalAlignment: Text.AlignVCenter
                                }
                                Text {
                                    width: modeHeader.width*0.12
                                    height: 24
                                    text: qsTr("CODEC")
                                    color: Theme.colorText
                                    font.pixelSize: Theme.fontSizeContent
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        Repeater {
                            model: currentDevice.capabilities.modesVideoTable

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 32
                                color: (index % 2 === 0) ? Theme.colorBackground : Theme.colorForeground

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 1
                                    color: Theme.colorSeparator
                                }

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    height: 24

                                    Text {
                                        width: modeHeader.width*0.12
                                        height: 24
                                        text: modelData.name
                                        color: Theme.colorSubText
                                        font.pixelSize: Theme.fontSizeContent
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    Text {
                                        width: modeHeader.width*0.24
                                        height: 24
                                        text: modelData.fov
                                        color: Theme.colorSubText
                                        font.pixelSize: Theme.fontSizeContent
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    Text {
                                        width: modeHeader.width*0.12
                                        height: 24
                                        text: modelData.ratio
                                        color: Theme.colorSubText
                                        font.pixelSize: Theme.fontSizeContent
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    Text {
                                        width: modeHeader.width*0.24
                                        height: 24
                                        text: modelData.resolution
                                        color: Theme.colorSubText
                                        font.pixelSize: Theme.fontSizeContent
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    Text {
                                        width: modeHeader.width*0.12
                                        height: 24
                                        text: modelData.fps
                                        color: Theme.colorSubText
                                        font.pixelSize: Theme.fontSizeContent
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    Text {
                                        width: modeHeader.width*0.12
                                        height: 24
                                        text: modelData.codec
                                        color: Theme.colorSubText
                                        font.pixelSize: Theme.fontSizeContent
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ////////////////////////////////
        }
    }
}
