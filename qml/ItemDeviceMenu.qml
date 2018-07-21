import QtQuick 2.0
import QtQuick.Controls 2.3

import com.offloadbuddy.style 1.0

Rectangle {
    id: itemDeviceMenu
    width: 80
    height: 80
    color: "#00000000"
    //color: "#ff6464"
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
        source: "qrc:/resources/menus/device.svg"
    }

    Text {
        id: deviceText
        height: 16
        color: "#ffffff"
        text: myDevice.model
        font.bold: true
        font.pixelSize: 10
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
    }

    MouseArea {
        id: deviceClick
        anchors.fill: parent
        onClicked: {
            //console.log("SIDEBAR deviceClick: " + myDevice.serial);
            itemDeviceMenu.myDeviceClicked(myDevice)

            imageArrow.anchors.verticalCenter= undefined
            imageArrow.y = menuDevice.y + itemDeviceMenu.y + 32
        }
    }
}
