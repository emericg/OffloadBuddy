import QtQuick 2.10
import QtQuick.Controls 2.4

import QtLocation 5.10
import QtPositioning 5.10

import com.offloadbuddy.style 1.0
import com.offloadbuddy.shared 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: screenDeviceShotDetails
    width: 1280
    height: 720
    anchors.fill: parent

    property Shot shot

    onShotChanged: {
        if (shot){
            //console.log("onShotChanged()" + shot);
            textShotName.text = shot.name
            duration.text = shot.duration
            date.text = shot.date
            datasize.text = StringUtils.bytesToString_short(shot.size)

            if (shot.preview) {
                image.source = "file:///" + shot.preview
            }
        }
    }

    Rectangle {
        id: rectangleHeader
        height: 64
        color: ThemeEngine.colorHeaderBackground
        anchors.rightMargin: 0
        anchors.right: parent.right

        Text {
            id: textShotName
            y: 20
            width: 223
            height: 40
            color: ThemeEngine.colorHeaderTitle
            text: qsTr("SHOT")
            verticalAlignment: Text.AlignVCenter
            font.bold: true
            anchors.leftMargin: 16
            anchors.left: rectangleBack.right
            font.pixelSize: 30
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            id: rectangleBack
            x: 16
            y: 16
            width: 40
            height: 40
            color: "#e0e0e0"
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 16

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                onClicked: screenDevice.state = "shotsview"
            }

            Text {
                id: textBack
                color: "#1d1d1d"
                text: qsTr("<")
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                anchors.fill: parent
                font.pixelSize: 30
            }
        }
        anchors.leftMargin: 0
        anchors.left: parent.left
        anchors.topMargin: 0
        anchors.top: parent.top
    }

    Image {
        id: image
        width: 400
        height: 400
        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 64
        anchors.left: parent.left
        anchors.leftMargin: 16
        fillMode: Image.PreserveAspectCrop
        source: "qrc:/resources/other/placeholder.png"
    }

    Button {
        id: buttonOverview
        text: qsTr("Overview")
        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.leftMargin: 16
    }

    Button {
        id: buttonMetadata
        y: 66
        text: qsTr("Metadata")
        anchors.verticalCenter: buttonOverview.verticalCenter
        anchors.left: buttonOverview.right
        anchors.leftMargin: 16
    }

    Button {
        id: buttonMap
        y: 64
        text: qsTr("Map")
        anchors.left: buttonMetadata.right
        anchors.leftMargin: 16
        anchors.verticalCenter: buttonOverview.verticalCenter
    }


    Rectangle {
        id: rectangleMetadata
        x: 7
        y: 4
        color: "#ffffff"
        anchors.rightMargin: 0
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.left: image.right
        anchors.topMargin: 0
        anchors.top: rectangleHeader.bottom
    }

    Rectangle {
        id: rectangleMap
        color: "#ffffff"
        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.left: image.right
        anchors.leftMargin: 16
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
/*
        Map {
            id: mapBase
            anchors.rightMargin: 32
            anchors.bottomMargin: 32
            anchors.leftMargin: 32
            anchors.topMargin: 32
            anchors.fill: parent

            gesture.enabled: false
            plugin: Plugin { name: "osm" }
            center: QtPositioning.coordinate(45,10)
            zoomLevel: 4
            z: parent.z + 1
        }
*/
    }
    Rectangle {
        id: rectangleOverview
        color: "#f4f4f4"
        anchors.bottomMargin: 0
        anchors.rightMargin: 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.left: image.right
        anchors.topMargin: 0
        anchors.top: rectangleHeader.bottom

        Text {
            id: text2
            x: 33
            y: 41
            width: 128
            height: 32
            text: qsTr("Duration:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
        }

        Text {
            id: text3
            x: 33
            y: 79
            width: 128
            height: 32
            text: qsTr("Date:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
        }

        Text {
            id: text4
            x: 33
            y: 363
            width: 128
            height: 32
            text: qsTr("Resolution:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
        }

        Text {
            id: text5
            x: 382
            y: 41
            width: 128
            height: 32
            text: qsTr("Data size:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16

            Text {
                id: datasize
                x: 102
                y: 9
                text: qsTr("Text")
                font.pixelSize: 12
            }
        }

        Text {
            id: text6
            x: 33
            y: 401
            width: 128
            height: 32
            text: qsTr("Framerate:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
        }

        Text {
            id: text7
            x: 382
            y: 117
            width: 128
            height: 32
            text: qsTr("Files:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
        }

        Text {
            id: text8
            x: 33
            y: 439
            width: 128
            height: 32
            text: qsTr("Bitrate:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
        }

        Text {
            id: text9
            x: 33
            y: 155
            width: 128
            height: 32
            text: qsTr("Aspect Ratio:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
        }

        Text {
            id: text10
            x: 33
            y: 325
            width: 128
            height: 32
            text: qsTr("Codec:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
        }

        Text {
            id: text11
            x: 33
            y: 193
            width: 128
            height: 32
            text: qsTr("Timecode:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
        }

        Text {
            id: text12
            x: 33
            y: 117
            width: 128
            height: 32
            text: qsTr("Camera:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
        }

        Text {
            id: text13
            x: 382
            y: 79
            width: 128
            height: 32
            text: qsTr("Chapters:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
        }

        Text {
            id: duration
            x: 167
            y: 50
            text: qsTr("Text")
            font.pixelSize: 12
        }

        Text {
            id: date
            x: 168
            y: 88
            text: qsTr("Text")
            font.pixelSize: 12
        }
    }
}
