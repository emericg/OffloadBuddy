import QtQuick 2.10
import QtQuick.Controls 2.3

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
        if (shot) {
            textShotName.text = shot.name

            if (shot.preview) {
                image.source = "file:///" + shot.preview
                imageFull.source = "file:///" + shot.preview
            }
/*
            duration.text = shot.duration
            date.text = shot.date.toUTCString()
            size.text = StringUtils.bytesToString_short(shot.datasize)
            sizefull.text = StringUtils.bytesToString_short(shot.size)
            chapters.text = shot.chapters
            camera.text = shot.camera
*/
            if (shot.type >= Shared.SHOT_PICTURE) {
                rectanglePicture.visible = true
                rectangleVideo.visible = false

                codecAudio.visible = false
                codecVideo.visible = true
                codecVideo.source = "qrc:/badges/JPEG.svg"

                if (shot.duration > 1) {
                    labelDuration.visible = true
                    labelDuration.height = 40
                    duration.text = shot.duration + qsTr(" pictures")
                } else {
                    labelDuration.visible = false
                    labelDuration.height = 0
                }
            } else {
                rectanglePicture.visible = false
                rectangleVideo.visible = false
                codecVideo.visible = false
                codecAudio.visible = false

                labelDuration.visible = true
                labelDuration.height = 40
            }

            if (shot.size !== shot.datasize) {
                labelSizeFull.visible = true
            } else {
                labelSizeFull.visible = false
            }

            mapGPS.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
            mapGpsCenter.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
        }
    }

    Rectangle {
        id: rectangleHeader
        height: 64
        anchors.rightMargin: 0
        anchors.right: parent.right
        anchors.leftMargin: 0
        anchors.left: parent.left
        anchors.topMargin: 0
        anchors.top: parent.top
        color: ThemeEngine.colorHeaderBackground

        Button {
            id: rectangleBack
            width: 40
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 16
            text: "<"
            font.bold: true
            font.pixelSize: ThemeEngine.fontSizeHeaderTitle
            onClicked: screenDevice.state = "shotsview"
        }
        Text {
            id: textShotName
            y: 20
            width: 582
            height: 40
            anchors.leftMargin: 16
            anchors.left: rectangleBack.right
            anchors.verticalCenter: parent.verticalCenter

            text: "SHOT NAME"
            color: ThemeEngine.colorHeaderTitle
            font.bold: true
            font.pixelSize: ThemeEngine.fontSizeHeaderTitle
            verticalAlignment: Text.AlignVCenter
        }

        Image {
            id: codecAudio
            width: 64
            height: 24
            anchors.right: codecAudio.left
            anchors.rightMargin: 32
            anchors.verticalCenterOffset: 0
            anchors.verticalCenter: parent.verticalCenter
            source: "qrc:/badges/AAC.svg"
        }
        Image {
            id: codecVideo
            width: 64
            height: 24
            anchors.right: buttonOverview.left
            anchors.rightMargin: 16
            anchors.verticalCenterOffset: 0
            anchors.verticalCenter: parent.verticalCenter
            source: "qrc:/badges/H264.svg"
        }

        Button {
            id: buttonOverview
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: buttonPreview.left
            anchors.rightMargin: 16

            text: qsTr("Overview")
            onClicked: screenDeviceShotDetails.state = "overview"
        }
        Button {
            id: buttonPreview
            anchors.right: buttonMetadata.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Preview")
            onClicked: screenDeviceShotDetails.state = "preview"
        }
        Button {
            id: buttonMetadata
            anchors.right: buttonMap.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Metadatas")
            //onClicked: screenDeviceShotDetails.state = "metadatas"
        }
        Button {
            id: buttonMap
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: buttonOverview.verticalCenter

            text: qsTr("Map")
            onClicked: screenDeviceShotDetails.state = "map"
        }
    }

    state: "overview"
    states: [
        State {
            name: "overview"

            PropertyChanges {
                target: contentOverview
                visible: true
            }
            PropertyChanges {
                target: contentPreview
                visible: false
            }
            PropertyChanges {
                target: contentMetadatas
                visible: false
            }
            PropertyChanges {
                target: contentMap
                visible: false
            }
        },
        State {
            name: "preview"

            PropertyChanges {
                target: contentOverview
                visible: false
            }
            PropertyChanges {
                target: contentPreview
                visible: true
            }
            PropertyChanges {
                target: contentMetadatas
                visible: false
            }
            PropertyChanges {
                target: contentMap
                visible: false
            }
        },
        State {
            name: "map"

            PropertyChanges {
                target: contentOverview
                visible: false
            }
            PropertyChanges {
                target: contentPreview
                visible: false
            }
            PropertyChanges {
                target: contentMetadatas
                visible: false
            }
            PropertyChanges {
                target: contentMap
                visible: true
            }
        }
    ]

    Rectangle {
        id: rectangleContent
        color: ThemeEngine.colorContentBackground

        anchors.top: rectangleHeader.bottom
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.topMargin: 0

        Rectangle {
            id: contentOverview
            anchors.fill: parent
            color: "#00000000"

            Image {
                id: image
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 13
                anchors.right: rectangleMetadatas.left
                anchors.rightMargin: 13
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 16
                fillMode: Image.PreserveAspectFit
                source: "qrc:/resources/other/placeholder.png"
            }

            Rectangle {
                id: rectangleMetadatas
                width: 560
                color: ThemeEngine.colorContentBox
                anchors.bottomMargin: 0
                anchors.rightMargin: 0
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.topMargin: 0
                anchors.top: parent.top

                Text {
                    id: labelDuration
                    y: 104
                    width: 240
                    height: 40
                    color: ThemeEngine.colorContentText
                    text: qsTr("Duration:")
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    font.pixelSize: ThemeEngine.fontSizeContentText

                    Text {
                        id: duration
                        x: 142
                        y: 8
                        width: 128
                        height: 32
                        color: ThemeEngine.colorContentText
                        text: shot.duration
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: ThemeEngine.fontSizeContentText
                    }
                }

                Text {
                    id: labelDate
                    width: 512
                    height: 40
                    color: ThemeEngine.colorContentText
                    text: qsTr("Date:")
                    anchors.top: parent.top
                    anchors.topMargin: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    font.pixelSize: ThemeEngine.fontSizeContentText

                    Text {
                        id: date
                        x: 146
                        y: 263
                        width: 240
                        height: 32
                        color: ThemeEngine.colorContentText
                        text: shot.date.toUTCString()
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: ThemeEngine.fontSizeContentText
                    }
                }

                Text {
                    id: labelDefinition
                    width: 240
                    height: 40
                    anchors.top: labelDuration.bottom
                    anchors.topMargin: 0
                    anchors.left: parent.left
                    anchors.leftMargin: 24

                    color: ThemeEngine.colorContentText
                    text: qsTr("Definition:")
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    font.pixelSize: ThemeEngine.fontSizeContentText

                    Text {
                        id: definition
                        width: 128
                        height: 32
                        text: qsTr("Text")
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        font.pixelSize: ThemeEngine.fontSizeContentText
                        color: ThemeEngine.colorContentText
                    }
                }

                Text {
                    id: labelSize
                    y: 184
                    width: 240
                    height: 40
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    anchors.top: labelDefinition.bottom
                    anchors.topMargin: 0

                    color: ThemeEngine.colorContentText
                    text: qsTr("Size:")
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    font.pixelSize: ThemeEngine.fontSizeContentText

                    Text {
                        id: size
                        x: 102
                        y: 9
                        width: 128
                        height: 32
                        color: ThemeEngine.colorContentText
                        text: StringUtils.bytesToString_short(shot.datasize)
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        font.pixelSize: ThemeEngine.fontSizeContentText
                    }
                }
                Text {
                    id: labelSizeFull
                    x: 320
                    y: 184
                    width: 240
                    height: 40
                    anchors.right: parent.right
                    anchors.rightMargin: 24
                    anchors.verticalCenter: labelSize.verticalCenter

                    color: ThemeEngine.colorContentText
                    text: qsTr("Full size:")
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    font.pixelSize: ThemeEngine.fontSizeContentText

                    Text {
                        id: sizefull
                        x: 102
                        y: 9
                        width: 128
                        height: 32
                        color: ThemeEngine.colorContentText
                        text: StringUtils.bytesToString_short(shot.size)
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: ThemeEngine.fontSizeContentText
                    }
                }

                Text {
                    id: labelAR
                    x: 320
                    y: 144
                    width: 240
                    height: 40
                    color: ThemeEngine.colorContentText
                    text: qsTr("Aspect Ratio:")
                    anchors.right: parent.right
                    anchors.rightMargin: 24
                    anchors.verticalCenter: labelDefinition.verticalCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    font.pixelSize: ThemeEngine.fontSizeContentText

                    Text {
                        id: ar
                        width: 128
                        height: 32
                        text: qsTr("Text")
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: ThemeEngine.fontSizeContentText
                        color: ThemeEngine.colorContentText
                    }
                }

                Text {
                    id: labelCamera
                    x: 24
                    y: 64
                    width: 512
                    height: 40
                    color: ThemeEngine.colorContentText
                    text: qsTr("Camera:")
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    font.pixelSize: ThemeEngine.fontSizeContentText

                    Text {
                        id: camera
                        width: 240
                        height: 32
                        text: shot.camera
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: ThemeEngine.fontSizeContentText
                        color: ThemeEngine.colorContentText
                    }
                }

                Rectangle {
                    id: rectanglePicture
                    height: 120
                    color: "#00000000"
                    anchors.bottom: rectangleFiles.top
                    anchors.bottomMargin: 0
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    anchors.right: parent.right
                    anchors.rightMargin: 0

                    Text {
                        id: labelISO
                        width: 240
                        height: 40
                        color: ThemeEngine.colorContentText
                        text: qsTr("ISO:")
                        anchors.top: parent.top
                        anchors.topMargin: 0
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: ThemeEngine.fontSizeContentText

                        Text {
                            id: iso
                            x: 114
                            y: 9
                            width: 128
                            height: 32
                            anchors.right: parent.right
                            anchors.rightMargin: 0
                            anchors.verticalCenter: parent.verticalCenter

                            text: shot.iso
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: ThemeEngine.fontSizeContentText
                            color: ThemeEngine.colorContentText
                        }
                    }

                    Text {
                        id: labelFocal
                        width: 240
                        height: 40
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.top: labelISO.bottom
                        anchors.topMargin: 0

                        color: ThemeEngine.colorContentText
                        text: qsTr("Focal:")
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: ThemeEngine.fontSizeContentText

                        Text {
                            id: focal
                            x: 114
                            y: 9
                            width: 128
                            height: 32
                            anchors.right: parent.right
                            anchors.rightMargin: 0
                            anchors.verticalCenter: parent.verticalCenter

                            text: shot.focal
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: ThemeEngine.fontSizeContentText
                            color: ThemeEngine.colorContentText
                        }
                    }
                    Text {
                        id: labelExposure
                        width: 240
                        height: 40
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.top: labelFocal.bottom
                        anchors.topMargin: 0

                        color: ThemeEngine.colorContentText
                        text: qsTr("Exposure time:")
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: ThemeEngine.fontSizeContentText

                        Text {
                            id: exposure
                            x: 114
                            y: 9
                            width: 128
                            height: 32
                            anchors.right: parent.right
                            anchors.rightMargin: 0
                            anchors.verticalCenter: parent.verticalCenter

                            text: shot.exposure
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: ThemeEngine.fontSizeContentText
                            color: ThemeEngine.colorContentText
                        }
                    }
                }

                Rectangle {
                    id: rectangleVideo
                    height: 120
                    color: "#00000000"
                    anchors.bottom: rectangleFiles.top
                    anchors.bottomMargin: 0
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.left: parent.left
                    anchors.leftMargin: 0

                    Text {
                        id: labelChapter
                        x: 303
                        y: 113
                        width: 240
                        height: 40
                        color: ThemeEngine.colorContentText
                        text: qsTr("Chapters:")
                        anchors.right: parent.right
                        anchors.rightMargin: 24
                        anchors.verticalCenter: labelTimecode.verticalCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: ThemeEngine.fontSizeContentText

                        Text {
                            id: chapters
                            x: 114
                            y: 9
                            width: 128
                            height: 32
                            color: ThemeEngine.colorContentText
                            text: shot.chapters
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            anchors.right: parent.right
                            anchors.rightMargin: 0
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: ThemeEngine.fontSizeContentText
                        }
                    }

                    Text {
                        id: labelTimecode
                        width: 240
                        height: 40
                        color: ThemeEngine.colorContentText
                        text: qsTr("Timecode:")
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.top: labelFramerate.bottom
                        anchors.topMargin: 0
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: ThemeEngine.fontSizeContentText
                    }

                    Text {
                        id: labelCodec
                        width: 240
                        height: 40
                        color: ThemeEngine.colorContentText
                        text: qsTr("Codec:")
                        anchors.top: parent.top
                        anchors.topMargin: 0
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: ThemeEngine.fontSizeContentText
                    }

                    Text {
                        id: labelBitrate
                        x: 314
                        y: 51
                        width: 240
                        height: 40
                        color: ThemeEngine.colorContentText
                        text: qsTr("Bitrate:")
                        anchors.right: parent.right
                        anchors.rightMargin: 24
                        anchors.verticalCenter: labelFramerate.verticalCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: ThemeEngine.fontSizeContentText
                    }

                    Text {
                        id: labelFramerate
                        width: 240
                        height: 40
                        color: ThemeEngine.colorContentText
                        text: qsTr("Framerate:")
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.top: labelCodec.bottom
                        anchors.topMargin: 0
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: ThemeEngine.fontSizeContentText
                    }
                }

                Rectangle {
                    id: rectangleFiles
                    height: 256
                    color: ThemeEngine.colorContentSubBox
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 0
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.left: parent.left
                    anchors.leftMargin: 0

                    Text {
                        id: labelFileCount
                        height: 32
                        color: ThemeEngine.colorContentText
                        text: qsTr("Files:")
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        font.bold: true
                        horizontalAlignment: Text.AlignLeft
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: ThemeEngine.fontSizeContentText
                    }
                }
            }
        }

        Rectangle {
            id: contentPreview
            anchors.fill: parent
            color: "#00000000"

            Image {
                id: imageFull
                anchors.fill: parent
                anchors.margins: 16
                fillMode: Image.PreserveAspectFit
            }
        }

        Rectangle {
            id: contentMetadatas
            anchors.fill: parent
            color: "#00000000"
        }

        Rectangle {
            id: contentMap
            anchors.fill: parent
            color: "#00000000"

            Map {
                id: mapGPS
                anchors.fill: parent
                anchors.margins: 16

                gesture.enabled: false
                zoomLevel: 12
                z: parent.z + 1
                plugin: Plugin { name: "osm" } // "osm", "mapboxgl", "esri"
                //center: QtPositioning.coordinate(45, 5)

                MapCircle {
                    id: mapGpsCenter
                    radius: 200.00
                    color: ThemeEngine.colorApproved
                    opacity: 0.5
                    border.width: 4
                    //center: QtPositioning.coordinate(45, 5)
                }
/*
                MapPolyline {
                    line.width: 3
                    line.color: 'green'
                    path: [
                        { latitude: -27, longitude: 153.0 },
                        { latitude: -27, longitude: 154.1 },
                        { latitude: -28, longitude: 153.5 },
                        { latitude: -29, longitude: 153.5 }
                    ]
*/
            }
        }
    }
}
