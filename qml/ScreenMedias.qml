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
            text: qsTr("MEDIAS")
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            font.bold: true
            font.pixelSize: 30
        }

        ComboBox {
            id: comboBox_directories
            width: 300
            height: 40
            displayText: "Show ALL media directories"
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.left: textHeader.right
            anchors.leftMargin: 16

            model: ListModel {
                id: cbMediaDirectories
                ListElement { text: "ALL media directories"; }
            }
        }

        Text {
            id: text1
            x: 1117
            width: 143
            height: 40
            text: qsTr("x elements")
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
        }

        ComboBox {
            id: comboBox_filterby
            y: 72
            width: 256
            displayText: "Filter by:"
            textRole: "text"
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16

            model: ListModel {
                id: cbMediaFilters
                ListElement { text: "Shot types"; }
                ListElement { text: "Camera models"; }
            }
/*
            model: ListModel {
                id: cbMediaOrders
                ListElement { text: "Date"; }
                ListElement { text: "Duration"; }
                ListElement { text: "GPS location"; }
                ListElement { text: "Camera model"; }
            }
*/
        }

        Slider {
            id: sliderZoom
            y: 72
            width: 200
            anchors.left: textZoom.right
            anchors.leftMargin: 16
            stepSize: 1
            to: 3
            from: 1
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            value: 2
        }

        Text {
            id: textZoom
            y: 72
            height: 40
            text: qsTr("Zoom:")
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
    }
}

/*##^## Designer {
    D{i:3;anchors_height:40;anchors_y:16}D{i:5;anchors_x:16}D{i:6;anchors_x:260}D{i:8;anchors_x:278}
}
 ##^##*/
