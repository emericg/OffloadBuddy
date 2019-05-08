import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0
import com.offloadbuddy.shared 1.0
import "UtilsString.js" as UtilsString

Item {
    id: screenMedia
    width: 1280
    height: 720
    anchors.fill: parent

    property Shot shot: null
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
        color: Theme.colorHeader

        ItemImageButton {
            id: buttonBack
            width: 48
            height: 48
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            highlightColor: Theme.colorPrimary
            iconColor: Theme.colorHeaderTitle

            source: "qrc:/icons_material/baseline-navigate_before-24px.svg"
            onClicked: {
                if (content.state == "library")
                    screenLibrary.state = "stateMediaGrid"
                else if (content.state == "device")
                    screenDevice.state = "stateMediaGrid"
            }
        }

        Text {
            id: textShotName
            height: 40
            anchors.leftMargin: 8
            anchors.left: buttonBack.right
            anchors.verticalCenter: parent.verticalCenter

            text: "SHOT NAME"
            color: Theme.colorHeaderTitle
            font.bold: true
            font.pixelSize: Theme.fontSizeHeaderTitle
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

        Row {
            id: row
            height: 28
            spacing: 16
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: textShotName.right
            anchors.leftMargin: 32

            Rectangle {
                id: codecVideo
                width: 80
                height: 28
                //anchors.verticalCenter: parent.verticalCenter
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
                //anchors.verticalCenter: parent.verticalCenter
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

    Item {
        id: rectangleContent

        anchors.top: rectangleHeader.bottom
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.topMargin: 0

        MediaDetailOverview {
            id: contentOverview
            visible: true
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
