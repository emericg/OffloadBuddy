import QtQuick 2.0
import QtQuick.Controls 2.3

import com.offloadbuddy.style 1.0

Rectangle {
    width: 1280
    height: 720

    Rectangle {
        id: rectangleHeader
        height: 128
        color: ThemeEngine.colorHeaderBackground
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        Text {
            id: textHeader
            width: 200
            height: 40
            color: ThemeEngine.colorHeaderTitle
            text: qsTr("MEDIAS GALLERY")
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            font.bold: true
            font.pixelSize: 30
        }

        ComboBox {
            id: comboBox_directories
            y: 16
            width: 300
            height: 40
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            displayText: qsTr("Show ALL media directories")

            model: ListModel {
                id: cbMediaDirectories
                ListElement { text: qsTr("ALL media directories"); }
            }
        }

        ComboBox {
            id: comboBox_filterby
            width: 256
            anchors.top: parent.top
            anchors.topMargin: 16
            displayText: "Filter by:"
            textRole: "text"
            anchors.left: parent.left
            anchors.leftMargin: 16

            model: ListModel {
                id: cbMediaFilters
                ListElement { text: qsTr("Shot types"); }
                ListElement { text: qsTr("Camera models"); }
            }
            /*
            model: ListModel {
                id: cbMediaOrders
                ListElement { text: qsTr("Date"); }
                ListElement { text: qsTr("Duration"); }
                ListElement { text: qsTr("GPS location"); }
                ListElement { text: qsTr("Camera model"); }
            }
*/
        }

        Slider {
            id: sliderZoom
            y: 72
            width: 200
            anchors.verticalCenter: comboBox_filterby.verticalCenter
            anchors.left: textZoom.right
            anchors.leftMargin: 16
            stepSize: 1
            to: 3
            from: 1
            value: 2
        }

        Text {
            id: textZoom
            y: 72
            height: 40
            text: qsTr("Zoom:")
            anchors.verticalCenter: comboBox_filterby.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.left: comboBox_filterby.right
            anchors.leftMargin: 16
            font.pixelSize: 16
        }
    }

    Rectangle {
        id: rectangleContent
        color: ThemeEngine.colorContentBackground

        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        Rectangle {
            id: circleEmpty
            x: 474
            y: 130
            width: 366
            height: 366
            color: "#f9f9f9"
            radius: width*0.5
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                id: imageEmpty
                x: 38
                y: 38
                width: 256
                height: 256
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                source: "qrc:/icons/disk.svg"
            }
        }
    }
}
