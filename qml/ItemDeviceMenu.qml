import QtQuick 2.10
import QtQuick.Controls 2.3
import QtGraphicalEffects 1.0

import com.offloadbuddy.style 1.0

Rectangle {
    id: itemDeviceMenu
    width: 80
    height: 80
    color: "#00000000"
    anchors.horizontalCenter: parent.horizontalCenter

    property var myDevice
    signal myDeviceClicked(var devicePtr)

    Image {
        id: deviceImage
        width: 64
        height: 64
        anchors.horizontalCenterOffset: 0
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        fillMode: Image.PreserveAspectCrop
        source: "qrc:/menus/device.svg"
        sourceSize.width: 64
        sourceSize.height: 64

        ColorOverlay {
            anchors.fill: parent
            source: parent
            color: ThemeEngine.colorSidebarIcons
            visible: ThemeEngine.colorSidebarIcons === "#ffffff" ? true : false
        }
    }

    Text {
        id: deviceText
        height: 16
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        color: ThemeEngine.colorSidebarText
        text: (myDevice.model === "device")? myDevice.brand : myDevice.model
        font.bold: true
        font.pixelSize: 11
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        id: deviceClick
        anchors.fill: parent
        onClicked: {
            //console.log("SIDEBAR deviceClick: " + myDevice.serial);
            itemDeviceMenu.myDeviceClicked(myDevice)

            selectorArrow.anchors.verticalCenter = undefined
            selectorArrow.y = menuDevice.y + itemDeviceMenu.y + 34
            selectorBar.anchors.verticalCenter = undefined
            selectorBar.y = menuDevice.y + itemDeviceMenu.y + 10
        }
    }
}
