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
            screenDeviceShotDetails.state = "overview"

            textShotName.text = shot.name

            if (shot.preview) {
                image.source = "file:///" + shot.preview
            } else {
                image.source = "qrc:/resources/other/placeholder.png"
            }

            textFileList.text = shot.fileList

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
                rectangleVideo.visible = true

                codecVideo.visible = true
                if (shot.codecVideo === "H.264")
                    codecVideo.source = "qrc:/badges/H264.svg"
                else if (shot.codecVideo === "H.265")
                    codecVideo.source = "qrc:/badges/H265.svg"
                else
                    codecVideo.visible = false

                codecAudio.visible = true
                if (shot.codecAudio === "MP3")
                    codecAudio.source = "qrc:/badges/MP3.svg"
                else if (shot.codecAudio === "AAC")
                    codecAudio.source = "qrc:/badges/AAC.svg"
                else
                    codecAudio.visible = false

                labelDuration.visible = true
                labelDuration.height = 40
                duration.text = StringUtils.durationToString(shot.duration)

                bitrate.text = StringUtils.bitrateToString(shot.bitrate)
                codec.text = shot.codecVideo
                framerate.text = StringUtils.framerateToString(shot.framerate)
                timecode.text = shot.timecode
            }

            ar.text = StringUtils.aspectratioToString(shot.width, shot.height)

            if (shot.size !== shot.datasize) {
                labelSizeFull.visible = true
            } else {
                labelSizeFull.visible = false
            }

            if (shot.altitude !== 0.0) {
                mapGPS.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
                mapGPS.zoomLevel = 12
                mapGPS.anchors.topMargin = 48
                mapMarker.visible = true
                mapMarker.coordinate = QtPositioning.coordinate(shot.latitude, shot.longitude)
                button_map_dezoom.enabled = true
                button_map_zoom.enabled = true
                button_gps_export.visible = true
                button_gps_export.enabled = false

                rectangleCoordinates.visible = true
                coordinates.text = shot.latitudeString + "    " + shot.longitudeString
                altitude.text = shot.altitudeString
            } else {
                mapGPS.center = QtPositioning.coordinate(45.5, 6)
                mapGPS.zoomLevel = 2
                mapGPS.anchors.topMargin = 16
                mapMarker.visible = false
                rectangleCoordinates.visible = false
                button_map_dezoom.enabled = false
                button_map_zoom.enabled = false
                button_gps_export.visible = false
            }
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
            anchors.right: codecVideo.left
            anchors.rightMargin: 16
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
            anchors.right: buttonMetadata.left
            anchors.rightMargin: 16

            text: qsTr("Overview")
            onClicked: screenDeviceShotDetails.state = "overview"
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
                target: contentMetadatas
                visible: false
            }
            PropertyChanges {
                target: contentMap
                visible: false
            }
        },/*
        State {
            name: "metadatas"

            PropertyChanges {
                target: contentOverview
                visible: false
            }
            PropertyChanges {
                target: contentMetadatas
                visible: true
            }
            PropertyChanges {
                target: contentMap
                visible: false
            }
        },*/
        State {
            name: "map"

            PropertyChanges {
                target: contentOverview
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
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: rectangleMetadatas.left
                anchors.margins: 16
                fillMode: Image.PreserveAspectFit
                source: "qrc:/resources/other/placeholder.png"

                sourceSize.width: shot.width / 2
                sourceSize.height: shot.height / 2
                property  bool isFullScreen: false

                MouseArea {
                    id: imageFullScreenOrNot
                    anchors.fill: parent

                    onDoubleClicked: {
                        image.isFullScreen = !image.isFullScreen

                        if (image.isFullScreen) {
                            rectangleMetadatas.visible = true
                            image.anchors.right = rectangleMetadatas.left
                        } else {
                            rectangleMetadatas.visible = false
                            image.anchors.right = parent.parent.right
                        }
                    }
                }
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
                    id: labelDate
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
                        height: 32
                        color: ThemeEngine.colorContentText
                        text: shot.date.toUTCString()
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: ThemeEngine.fontSizeContentText
                    }
                }

                Text {
                    id: labelCamera
                    height: 40
                    anchors.top: labelDate.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    color: ThemeEngine.colorContentText
                    text: qsTr("Camera:")
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    font.pixelSize: ThemeEngine.fontSizeContentText

                    Text {
                        id: camera
                        height: 32
                        text: shot.camera
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        font.pixelSize: ThemeEngine.fontSizeContentText
                        color: ThemeEngine.colorContentText
                    }
                }

                Text {
                    id: labelDuration
                    height: 40
                    text: qsTr("Duration:")
                    anchors.top: labelCamera.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    font.pixelSize: ThemeEngine.fontSizeContentText
                    color: ThemeEngine.colorContentText

                    Text {
                        id: duration
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Text")
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        color: ThemeEngine.colorContentText
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
                        text: shot.width + "x" + shot.height
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
                            width: 128
                            height: 32
                            text: shot.chapters
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            anchors.right: parent.right
                            anchors.rightMargin: 0
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: ThemeEngine.fontSizeContentText
                            color: ThemeEngine.colorContentText
                        }
                    }

                    Text {
                        id: labelTimecode
                        width: 240
                        height: 40
                        text: qsTr("Timecode:")
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.top: labelFramerate.bottom
                        anchors.topMargin: 0
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: ThemeEngine.fontSizeContentText
                        color: ThemeEngine.colorContentText

                        Text {
                            id: timecode
                            width: 128
                            height: 32
                            text: qsTr("Text")
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            anchors.right: parent.right
                            anchors.rightMargin: 0
                            anchors.verticalCenter: parent.verticalCenter
                            color: ThemeEngine.colorContentText
                            font.pixelSize: ThemeEngine.fontSizeContentText
                        }
                    }

                    Text {
                        id: labelCodec
                        width: 240
                        height: 40
                        text: qsTr("Codec:")
                        anchors.top: parent.top
                        anchors.topMargin: 0
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: ThemeEngine.fontSizeContentText
                        color: ThemeEngine.colorContentText

                        Text {
                            id: codec
                            width: 128
                            height: 32
                            text: qsTr("Text")
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            anchors.right: parent.right
                            anchors.rightMargin: 0
                            anchors.verticalCenter: parent.verticalCenter
                            color: ThemeEngine.colorContentText
                            font.pixelSize: ThemeEngine.fontSizeContentText
                        }
                    }

                    Text {
                        id: labelBitrate
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

                        Text {
                            id: bitrate
                            width: 128
                            height: 32
                            text: qsTr("Text")
                            anchors.right: parent.right
                            anchors.rightMargin: 0
                            anchors.verticalCenter: parent.verticalCenter
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            color: ThemeEngine.colorContentText
                            font.pixelSize: ThemeEngine.fontSizeContentText
                        }
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

                        Text {
                            id: framerate
                            width: 128
                            height: 32
                            text: qsTr("Text")
                            anchors.right: parent.right
                            anchors.rightMargin: 0
                            anchors.verticalCenter: parent.verticalCenter
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            color: ThemeEngine.colorContentText
                            font.pixelSize: ThemeEngine.fontSizeContentText
                        }
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
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8

                        text: qsTr("Files:")
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        color: ThemeEngine.colorContentText
                        font.bold: true
                        font.pixelSize: ThemeEngine.fontSizeContentText
                    }

                    Text {
                        id: textFileList
                        anchors.rightMargin: 8
                        anchors.leftMargin: 8
                        anchors.bottomMargin: 8
                        anchors.top: labelFileCount.bottom
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.topMargin: 0

                        text: qsTr("Text")
                        //color: ThemeEngine.colorContentText
                        font.pixelSize: ThemeEngine.fontSizeContentText
                    }
                }
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
                copyrightsVisible: false
                anchors.topMargin: 48
                anchors.fill: parent
                anchors.margins: 16

                gesture.enabled: false
                z: parent.z + 1
                plugin: Plugin { name: "osm" } // "osm", "mapboxgl", "esri"
                center: QtPositioning.coordinate(45.5, 6)
                zoomLevel: 2

                MapQuickItem {
                    id: mapMarker
                    visible: false
                    anchorPoint.x: mapMarkerImg.width/2
                    anchorPoint.y: mapMarkerImg.height/2
                    sourceItem: Image {
                        id: mapMarkerImg
                        source: "qrc:/resources/other/marker.svg"
                    }
                }

                Row {
                    id: row
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    spacing: 16

                    Button {
                        id: button_map_dezoom
                        width: 40
                        height: 40
                        text: "-"
                        font.bold: true
                        font.pointSize: 16
                        opacity: 0.90

                        onClicked: parent.parent.zoomLevel--
                    }

                    Button {
                        id: button_map_zoom
                        width: 40
                        height: 40
                        text: "+"
                        font.bold: true
                        font.pointSize: 14
                        opacity: 0.90

                        onClicked: parent.parent.zoomLevel++
                    }
                }
/*
                MapPolyline {
                    id: mapTrace
                    visible: false
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

            Rectangle {
                id: rectangleCoordinates
                height: 32
                color: ThemeEngine.colorContentSubBox
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.top: parent.top
                anchors.topMargin: 8

                Text {
                    id: labelCoodrinates
                    text: qsTr("GPS coordinates:")
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 16
                }

                Text {
                    id: labelAltitude
                    text: qsTr("Altitude:")
                    anchors.verticalCenterOffset: 0
                    anchors.left: coordinates.right
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 16
                    anchors.leftMargin: 64
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }

                Text {
                    id: coordinates
                    text: qsTr("Text")
                    anchors.left: labelCoodrinates.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                }

                Text {
                    id: altitude
                    text: qsTr("Text")
                    anchors.left: labelAltitude.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 16
                }

                Button {
                    id: button_gps_export
                    text: qsTr("Export GPS trace")
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
