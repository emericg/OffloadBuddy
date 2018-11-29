import QtQuick 2.10
import QtQuick.Controls 2.3

import QtLocation 5.10
import QtPositioning 5.10
import QtMultimedia 5.10

import com.offloadbuddy.style 1.0
import com.offloadbuddy.shared 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: screenMedia
    width: 1280
    height: 720
    anchors.fill: parent

    property Shot shot
    onShotChanged: {
        // if we 'just' changed shot, we reset the state // FIXME forward/backward reset's it too
        screenMedia.state = "overview"
        updateDeviceDetails()

        // save state
        if (deviceState)
            deviceState.detail_shot = shot
        else
            libraryState.detail_shot = shot
    }

    onVisibleChanged: {
        if (visible === false)
            contentOverview.setPause()
    }

    function restoreState() {
        shot = deviceState.detail_shot
        screenMedia.state = deviceState.detail_state
    }

    function updateDeviceDetails() {
        if (shot) {
            textShotName.text = shot.name

            if (shot.type >= Shared.SHOT_PICTURE) {
                codecAudio.visible = false
                codecVideo.visible = true
                codecVideo.source = "qrc:/badges/JPEG.svg"
            }

            if (shot.hasGpmf) {
                buttonMetadata.visible = true
                buttonMetadata.width = 110

                // if (not static)
                //{
                    contentMetadatas.updateMetadatas()
                    buttonMap.visible = false
                    buttonMap.width = -16
                //} else {
                //    buttonMap.visible = true
                //    buttonMap.width = 64
                //
                //    contentMap.updateMap()
                //}
            } else {
                buttonMetadata.visible = false
                buttonMetadata.width = -16

                if (shot.latitude !== 0.0) {
                    buttonMap.visible = true
                    buttonMap.width = 64

                    contentMap.updateMap()
                } else {
                    buttonMap.visible = false
                    buttonMap.width = -16
                }
            }

            contentOverview.updateOverview()
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
            onClicked: {
                screenLibrary.state = "stateMediaGrid"
                screenDevice.state = "stateMediaGrid"
            }
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
            onClicked: screenMedia.state = "overview"
        }
        Button {
            id: buttonMetadata
            anchors.right: buttonMap.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Metadatas")
            onClicked: screenMedia.state = "metadatas"
        }
        Button {
            id: buttonMap
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: buttonOverview.verticalCenter

            text: qsTr("Map")
            onClicked: screenMedia.state = "map"
        }
    }

    onStateChanged: {
        // save state
        //libraryState.detail_state = state
        deviceState.detail_state = state
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
        },
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
        },
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

        MediaDetailOverview {
            id: contentOverview
        }

        MediaDetailMetadatas {
            id: contentMetadatas
            visible: false
        }

        MediaDetailMap {
            id: contentMap
            visible: false
        }
    }
}
