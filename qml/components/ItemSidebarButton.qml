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

        anchors.verticalCenterOffset: (title) ? -12 : 0
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
        anchors.topMargin: 0
        anchors.horizontalCenter: parent.horizontalCenter

        text: title
        font.pixelSize: 12
        font.bold: true
        color: Theme.colorSidebarContent
        verticalAlignment: Text.AlignVCenter
    }
}
