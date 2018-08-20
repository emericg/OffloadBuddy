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
    color: ThemeEngine.colorContentBackground

    property Shot shot

    onShotChanged: {
        if (shot) {
            textShotName.text = shot.name
            duration.text = shot.duration
            date.text = shot.date
            size.text = StringUtils.bytesToString_short(shot.size)
            datasize.text = StringUtils.bytesToString_short(shot.datasize)
            codecVideo.visible = false

            codecAudio.visible = false
            chapters.text = shot.chapters

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
            width: 582
            height: 40
            anchors.leftMargin: 16
            anchors.left: rectangleBack.right
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("SHOT")
            color: ThemeEngine.colorHeaderTitle
            font.bold: true
            font.pixelSize: ThemeEngine.fontSizeHeaderTitle
            verticalAlignment: Text.AlignVCenter
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
                anchors.fill: parent

                text: qsTr("<")
                color: "#1d1d1d"
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeHeaderTitle
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Image {
            id: codecVideo
            x: 733
            y: 20
            width: 64
            height: 24
            anchors.right: codecAudio.left
            anchors.rightMargin: 16
            anchors.verticalCenterOffset: 0
            anchors.verticalCenter: parent.verticalCenter
            source: "qrc:/badges/H264.svg"
        }

        Image {
            id: codecAudio
            x: 1
            y: 22
            width: 64
            height: 24
            anchors.right: buttonOverview.left
            anchors.rightMargin: 32
            anchors.verticalCenterOffset: 0
            anchors.verticalCenter: parent.verticalCenter
            source: "qrc:/badges/AAC.svg"
        }

        Button {
            id: buttonMap
            x: 1164
            y: 12
            text: qsTr("Map")
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: buttonOverview.verticalCenter
        }

        Button {
            id: buttonMetadata
            x: 1164
            y: 340
            text: qsTr("Metadata")
            anchors.right: buttonMap.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
        }

        Button {
            id: buttonOverview
            x: 935
            y: 12
            text: qsTr("Overview")
            anchors.right: buttonMetadata.left
            anchors.rightMargin: 16
        }

        anchors.leftMargin: 0
        anchors.left: parent.left
        anchors.topMargin: 0
        anchors.top: parent.top
    }

    Image {
        id: image
        width: 512
        height: 480
        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.leftMargin: 16
        fillMode: Image.PreserveAspectFit
        source: "qrc:/resources/other/placeholder.png"
    }

    Rectangle {
        id: rectangleMetadata
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
        color: ThemeEngine.colorContentBox
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
            x: 123
            y: 41
            width: 128
            height: 32
            text: qsTr("Duration:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText
        }

        Text {
            id: text3
            x: 123
            y: 79
            width: 128
            height: 32
            text: qsTr("Date:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText
        }

        Text {
            id: text4
            x: 128
            y: 341
            width: 128
            height: 32
            text: qsTr("Resolution:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText
        }

        Text {
            id: text5
            x: 472
            y: 41
            width: 128
            height: 32
            text: qsTr("size:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText

            Text {
                id: size
                x: 102
                y: 9
                text: qsTr("Text")
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }
        }

        Text {
            id: text6
            x: 128
            y: 379
            width: 128
            height: 32
            text: qsTr("Framerate:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText
        }

        Text {
            id: text7
            x: 472
            y: 117
            width: 128
            height: 32
            text: qsTr("Files:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText
        }

        Text {
            id: text8
            x: 128
            y: 417
            width: 128
            height: 32
            text: qsTr("Bitrate:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText
        }

        Text {
            id: text9
            x: 123
            y: 155
            width: 128
            height: 32
            text: qsTr("Aspect Ratio:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText
        }

        Text {
            id: text10
            x: 128
            y: 303
            width: 128
            height: 32
            text: qsTr("Codec:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText
        }

        Text {
            id: text11
            x: 123
            y: 193
            width: 128
            height: 32
            text: qsTr("Timecode:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText
        }

        Text {
            id: text12
            x: 123
            y: 117
            width: 128
            height: 32
            text: qsTr("Camera:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText
        }

        Text {
            id: text13
            x: 123
            y: 265
            width: 234
            height: 32
            text: qsTr("Chapters:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText

            Text {
                id: chapters
                x: 114
                y: 9
                text: qsTr("Text")
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }
        }

        Text {
            id: duration
            x: 257
            y: 50
            text: qsTr("Text")
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText
        }

        Text {
            id: date
            x: 258
            y: 88
            text: qsTr("Text")
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText
        }

        Text {
            id: text14
            x: 472
            y: 80
            width: 128
            height: 32
            text: qsTr("Data size:")
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText

            Text {
                id: datasize
                x: 102
                y: 9
                text: qsTr("Text")
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }
        }
    }
}
