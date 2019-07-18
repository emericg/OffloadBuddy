import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

import com.offloadbuddy.theme 1.0

Item {
    id: itemSidebarButton
    width: 96
    height: (title) ? 80 : 60

    property var myDevice: null
    signal myDeviceClicked(var devicePtr)
    signal clicked()

    property bool animated: false
    property bool selected: false
    property bool highlighted: false

    property url source: ""
    property string title: ""
    property int imgSize: 64

    Component.onCompleted: {
        if (myDevice) {
            title = modelData.model
            source = "qrc:/menus/device.svg"
            myDeviceClicked.connect(sideBar.myDeviceClicked)
        }
    }

    function getDevicePicture(deviceName) {
        if (deviceName.includes("HERO7 White") ||
            deviceName.includes("HERO7 Silver")) {
            return "qrc:/cameras/H7w.svg"
        } else if (deviceName.includes("HERO7") ||
                   deviceName.includes("HERO6") ||
                   deviceName.includes("HERO5")) {
            return "qrc:/cameras/H5.svg"
        } else if (deviceName.includes("Session")) {
            return "qrc:/cameras/session.svg"
        } else if (deviceName.includes("HERO4")) {
            return "qrc:/cameras/H4.svg"
        } else if (deviceName.includes("HERO3") ||
                   deviceName.includes("Hero3")) {
            return "qrc:/cameras/H3.svg"
        } else if (deviceName.includes("FUSION") ||
                   deviceName.includes("Fusion")) {
            return "qrc:/cameras/fusion.svg"
        } else if (deviceName.includes("HD2")) {
            return "qrc:/cameras/H2.svg"
        }

        // fallback
        if (myDevice.deviceType === 2)
            return "qrc:/cameras/generic_smartphone.svg"
        else if (myDevice.deviceType === 3)
            return "qrc:/cameras/generic_camera.svg"

        // fallback
        return "qrc:/cameras/generic_actioncam.svg"
    }

    // SELECTOR

    Item {
        id: bgRect
        anchors.fill: parent
        visible: selected

        Rectangle {
            anchors.fill: parent
            height: parent.height
            color: (Theme.selector === "bar") ? "black" : Theme.colorSidebarContent
            opacity: (Theme.selector === "bar") ? 1 : 0.2
        }
        ImageSvg {
            id: selectorArrow
            width: 12
            height: 12
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            source: "qrc:/menus/selector_arrow.svg"
            color: Theme.colorSidebarContent
            visible: false // (Theme.selector === "arrow")
        }
        Rectangle {
            id: selectorBar
            width: 4
            height: parent.height
            color: Theme.colorPrimary
            visible: (Theme.selector === "bar")
        }
    }

    // MOUSE

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            if (myDevice) {
                itemSidebarButton.myDeviceClicked(myDevice)
            } else {
                itemSidebarButton.clicked()
            }
        }
        onEntered: {
            bgFocus.opacity = 0.1
            itemSidebarButton.highlighted = true
        }
        onExited: {
            bgFocus.opacity = 0
            itemSidebarButton.highlighted = false
        }

        Rectangle {
            id: bgFocus
            anchors.fill: parent
            color: Theme.colorSidebarContent
            opacity: 0

            Behavior on opacity { OpacityAnimator { duration: 250 } }
        }
    }

    // CONTENT

    ImageSvg {
        id: contentImage
        width: imgSize
        height: imgSize
        anchors.verticalCenter: itemSidebarButton.verticalCenter

        opacity: itemSidebarButton.enabled ? 1.0 : 0.3
        source: itemSidebarButton.source
        color: Theme.colorSidebarContent

        anchors.verticalCenterOffset: (title) ? -8 : 0
        anchors.horizontalCenter: parent.horizontalCenter

        NumberAnimation on opacity {
            id: image_fadein
            from: 0
            to: 1
            duration: (myDevice) ? 333 : 0
        }

        SequentialAnimation on opacity {
            id: image_fadeinout
            running: itemSidebarButton.animated
            loops: Animation.Infinite
            onStopped: { contentImage.opacity = 1 }
            OpacityAnimator { from: 0; to: 1; duration: 1000 }
            OpacityAnimator { from: 1; to: 0; duration: 1000 }
        }
    }

    Text {
        id: contentText
        anchors.top: contentImage.bottom
        anchors.topMargin: -4
        anchors.horizontalCenter: parent.horizontalCenter

        text: title
        font.pixelSize: 12
        font.bold: true
        color: Theme.colorSidebarContent
        verticalAlignment: Text.AlignVCenter
    }
}
