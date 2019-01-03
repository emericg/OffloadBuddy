import QtQuick 2.9
import QtQuick.Controls 2.2

import QtGraphicalEffects 1.0

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
        updateShotDetails()

        // save state
        if (deviceSavedState && typeof deviceSavedState !== "undefined")
            deviceSavedState.detail_shot = shot
    }

    onVisibleChanged: {
        if (visible === false)
            contentOverview.setPause()
    }

    function restoreState() {
        shot = deviceSavedState.detail_shot
        screenMedia.state = deviceSavedState.detail_state
    }

    function updateShotDetails() {
        if (shot) {
            textShotName.text = shot.name

            if (shot.hasGPMF && shot.hasGPS) {
                buttonTelemetry.visible = true
                buttonTelemetry.width = 110

                // if (not static)
                //{
                    contentTelemetry.updateMetadatas()
                    buttonMap.visible = false
                    buttonMap.width = -16
                //} else {
                //    buttonMap.visible = true
                //    buttonMap.width = 64
                //
                //    contentMap.updateMap()
                //}
            } else {
                buttonTelemetry.visible = false
                buttonTelemetry.width = -16

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

        ButtonThemed {
            id: rectangleBack
            width: 40
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 16
            text: "<"
            font.bold: true
            font.pixelSize: ThemeEngine.fontSizeHeaderTitle

            contentItem: Text {
                anchors.fill: parent
                text: rectangleBack.text
                font: rectangleBack.font
                opacity: enabled ? 1.0 : 0.3
                color: rectangleBack.down ? ThemeEngine.colorHeaderTitle : ThemeEngine.colorButtonText
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

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

        ButtonThemed {
            id: buttonOverview
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: buttonTelemetry.left
            anchors.rightMargin: 16

            text: qsTr("Overview")
            onClicked: screenMedia.state = "overview"
        }
        ButtonThemed {
            id: buttonTelemetry
            anchors.right: buttonMap.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Telemetry")
            onClicked: screenMedia.state = "metadatas"
        }
        ButtonThemed {
            id: buttonMap
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: buttonOverview.verticalCenter

            text: qsTr("Map")
            onClicked: screenMedia.state = "map"
        }

        Rectangle {
            id: codecVideo
            width: 80
            height: 28
            anchors.right: codecAudio.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            color: "#dfdfdf"
            Text {
                id: codecVideoText
                anchors.fill: parent

                text: qsTr("CODEC")
                color: "dimgrey"
                font.capitalization: Font.AllUppercase
                font.pixelSize: 16
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Rectangle {
            id: codecAudio
            width: 80
            height: 28
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: buttonOverview.left
            anchors.rightMargin: 16

            color: "#dfdfdf"
            Text {
                id: codecAudioText
                anchors.fill: parent

                text: qsTr("CODEC")
                color: "dimgrey"
                font.capitalization: Font.AllUppercase
                font.pixelSize: 16
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    onStateChanged: {
        // save state
        if (deviceSavedState && typeof deviceSavedState !== "undefined")
            deviceSavedState.detail_state = state
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
                target: contentTelemetry
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
                target: contentTelemetry
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
                target: contentTelemetry
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

        MediaDetailTelemetry {
            id: contentTelemetry
            visible: false
        }

        MediaDetailMap {
            id: contentMap
            visible: false
        }
    }
}
