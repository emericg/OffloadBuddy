import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

Item {
    id: itemDeviceMenu
    width: 80
    height: 80
    anchors.horizontalCenter: parent.horizontalCenter

    property var myDevice
    signal myDeviceClicked(var devicePtr)

    ImageSvg {
        id: deviceImage
        width: 64
        height: 64
        anchors.horizontalCenterOffset: 0
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        color: Theme.colorSidebarContent
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

        color: Theme.colorSidebarContent
        text: (myDevice.model === "device") ? myDevice.brand : myDevice.model
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
