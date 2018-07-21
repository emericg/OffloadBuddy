import QtQuick 2.0
import QtQuick.Controls 2.3

import com.offloadbuddy.style 1.0

Rectangle {
    width: 1280
    height: 720

    Rectangle {
        id: rectangleHeader
        height: 64
        color: ThemeEngine.colorHeaderBackground
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        Text {
            id: textHeader
            y: 20
            width: 223
            height: 40
            color: ThemeEngine.colorHeaderTitle
            text: qsTr("ABOUT")
            verticalAlignment: Text.AlignVCenter
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            font.bold: true
            font.pixelSize: 30
        }
    }

    Rectangle {
        id: rectangleContent
        color: ThemeEngine.colorContentBackground

        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        Rectangle {
            id: rectangleProject
            height: 256
            color: ThemeEngine.colorContentBox
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16

            Text {
                id: text_title
                y: 10
                width: 300
                height: 40
                text: qsTr("Project")
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                anchors.left: parent.left
                anchors.leftMargin: 16
                font.pixelSize: 24
            }
            /*
            ListView {
                id: mediadirectoriesview
                width: parent.width
                clip: true
                model: settingManager.devicesList

                spacing: 16
                anchors.top: header.bottom
                anchors.topMargin: 16
                anchors.bottom: rectangleMenu.top
                anchors.bottomMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 16

                delegate: DeviceBox { myDevice: modelData }
            }
*/
        }

        Rectangle {
            id: rectangleAuthors
            x: -8
            y: -7
            height: 256
            color: ThemeEngine.colorContentBox
            Text {
                id: text_title1
                y: 10
                width: 300
                height: 40
                text: qsTr("Authors")
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                anchors.leftMargin: 16
                font.pixelSize: 24
                anchors.left: parent.left
            }
            anchors.topMargin: 16
            anchors.leftMargin: 16
            anchors.top: rectangleProject.bottom
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.left: parent.left
        }
    }
}
