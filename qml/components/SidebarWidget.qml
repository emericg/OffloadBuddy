import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import "qrc:/js/UtilsDevice.js" as UtilsDevice

Item {
    id: sidebarWidget
    width: parent.width
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
            source = UtilsDevice.getDevicePicture(myDevice)
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
            color: (Theme.sidebarSelector === "bar") ? "black" : Theme.colorSidebarContent
            opacity: (Theme.sidebarSelector === "bar") ? 1 : 0.2
        }
        ImageSvg {
            id: selectorArrow
            width: 12
            height: 12
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            source: "qrc:/menus/selector_arrow.svg"
            color: Theme.colorBackground
            visible: (Theme.sidebarSelector === "arrow")
        }
        Rectangle {
            id: selectorBar
            width: 4
            height: parent.height
            color: Theme.colorPrimary
            visible: (Theme.sidebarSelector === "bar")
        }
    }

    // MOUSE

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            if (myDevice) {
                sidebarWidget.myDeviceClicked(myDevice)
            } else {
                sidebarWidget.clicked()
            }
        }
        onEntered: {
            bgFocus.opacity = 0.1
            sidebarWidget.highlighted = true
        }
        onExited: {
            bgFocus.opacity = 0
            sidebarWidget.highlighted = false
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
        anchors.verticalCenter: sidebarWidget.verticalCenter
        anchors.verticalCenterOffset: (title) ? -8 : 0
        anchors.horizontalCenter: parent.horizontalCenter

        opacity: sidebarWidget.enabled ? 1.0 : 0.3
        source: sidebarWidget.source
        color: Theme.colorSidebarContent

        NumberAnimation on opacity {
            id: image_fadein
            from: 0
            to: 1
            duration: (myDevice) ? 333 : 0
        }

        SequentialAnimation on opacity {
            id: image_fadeinout
            running: sidebarWidget.animated
            loops: Animation.Infinite
            onStopped: { contentImage.opacity = 1 }
            OpacityAnimator { from: 0; to: 1; duration: 1000 }
            OpacityAnimator { from: 1; to: 0; duration: 1000 }
        }

        Item {
            width: 24; height: 24;
            anchors.right: parent.right
            anchors.rightMargin: -4
            anchors.bottom: parent.bottom

            //visible: animated
            opacity: animated ? 1 : 0
            Behavior on opacity { OpacityAnimator { duration: 250 } }

            Rectangle {
                width: 24; height: 24; radius: 12;
                opacity: 0.66
                color: Theme.colorHighContrast
            }

            ImageSvg {
                width: 20; height: 20;
                anchors.centerIn: parent
                source: "qrc:/assets/icons_material/baseline-autorenew-24px.svg"
                color: Theme.colorLowContrast

                NumberAnimation on rotation {
                    running: sidebarWidget.animated
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    duration: 1000
                    from: 0
                    to: 360
                }
            }
        }
    }

    Text {
        id: contentText
        anchors.top: contentImage.bottom
        anchors.topMargin: -4
        anchors.horizontalCenter: parent.horizontalCenter

        text: title
        font.pixelSize: 11
        font.bold: true
        color: Theme.colorSidebarContent
        verticalAlignment: Text.AlignVCenter
    }
}
