import QtQuick 2.9
import QtQuick.Controls 2.2

import ThemeEngine 1.0
import com.offloadbuddy.shared 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: screenMedia
    width: 1280
    height: 720
    anchors.fill: parent

    property Shot shot: null

    onShotChanged: {
        // if we 'just' changed shot, we reset the state // FIXME forward/backward reset it too
        screenMedia.state = "overview"
        updateShotDetails()

        // save state
        if (typeof deviceSavedState !== "undefined" && deviceSavedState)
            deviceSavedState.detail_shot = screenMedia.shot
    }

    onVisibleChanged: {
        if (visible === false)
            contentOverview.setPause()
    }

    function restoreState() {
        screenMedia.shot = deviceSavedState.detail_shot // ???
        screenMedia.state = deviceSavedState.detail_state
    }

    function updateShotDetails() {
        if (shot) {
            textShotName.text = shot.name

            if (shot.hasGPMF && shot.hasGPS) {
                //if (not static) {
                    contentTelemetry.updateMetadatas()
                //} else {
                //    contentMap.updateMap()
                //}
            } else {
                if (shot.latitude !== 0.0) {
                    contentMap.updateMap()
                } else {
                    //
                }
            }

            contentOverview.updateOverview()
        }
    }

    // KEYS HANDLING ///////////////////////////////////////////////////////////

    focus: (applicationContent.state === "device" && screenDevice.state === "stateMediaDetails") ||
           (applicationContent.state === "library" && screenLibrary.state === "stateMediaDetails")
    Keys.onPressed: {
        if (event.key === Qt.Key_Space) {
            if (screenMedia.state === "overview" && shot.fileType === Shared.FILE_VIDEO) {
                event.accepted = true;
                contentOverview.setPlayPause();
            }
        } else if (event.key === Qt.Key_Backspace) {
            event.accepted = true;
            if (applicationContent.state === "library")
                screenLibrary.state = "stateMediaGrid";
            else if (applicationContent.state === "device")
                screenDevice.state = "stateMediaGrid";
        } else if (event.key === Qt.Key_Delete) {
            event.accepted = true;
            contentOverview.openDeletePopup();
        }
    }

    ////////////////////////////////////////////////////////////////////////////

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

            iconColor: Theme.colorHeaderContent
            backgroundColor: Theme.colorForeground

            source: "qrc:/others/navigate_before_big.svg"
            onClicked: {
                if (applicationContent.state == "library")
                    screenLibrary.state = "stateMediaGrid"
                else if (applicationContent.state == "device")
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
            color: Theme.colorHeaderContent
            font.bold: true
            font.pixelSize: Theme.fontSizeHeaderTitle
            verticalAlignment: Text.AlignVCenter
        }

        Row {
            id: rowCodecs
            height: 28
            spacing: 16
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: textShotName.right
            anchors.leftMargin: 32

            ItemCodec {
                id: codecVideo
                text: qsTr("CODEC")
            }

            ItemCodec {
                id: codecAudio
                text: qsTr("CODEC")
            }
        }

        Row {
            id: rowActions
            anchors.right: rowMenus.left
            anchors.rightMargin: 32
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            ItemImageButton {
                id: buttonRotate
                width: 40
                height: 40
                source: "qrc:/icons_material/baseline-rotate_90_degrees_ccw-24px.svg"
                backgroundColor: Theme.colorForeground
                onClicked: contentOverview.toggleRotate()
            }

            ItemImageButton {
                id: buttonTimestamp
                width: 40
                height: 40
                source: "qrc:/icons_material/baseline-date_range-24px.svg"
                backgroundColor: Theme.colorForeground
                onClicked: contentOverview.openDatePopup()
            }

            ItemImageButton {
                id: buttonEncode
                width: 40
                height: 40
                source: "qrc:/icons_material/baseline-settings_applications-24px.svg"
                backgroundColor: Theme.colorForeground
                onClicked: contentOverview.openEncodePopup()
            }

            ItemImageButton {
                id: buttonTelemetry
                width: 40
                height: 40
                source: "qrc:/icons_material/baseline-insert_chart-24px.svg"
                visible: (shot && shot.hasGPMF && shot.hasGPS)
                backgroundColor: Theme.colorForeground
                onClicked: contentOverview.openTelemetryPopup()
            }

            ItemImageButton {
                id: buttonShowFolder
                width: 40
                height: 40
                source: "qrc:/icons_material/outline-folder-24px.svg"
                backgroundColor: Theme.colorForeground
                onClicked: shot.openFolder()
            }

            ItemImageButton {
                id: buttonDelete
                width: 40
                height: 40
                source: "qrc:/icons_material/baseline-delete-24px.svg"
                backgroundColor: Theme.colorForeground
                onClicked: contentOverview.openDeletePopup()
            }
        }

        Row {
            id: rowMenus
            anchors.right: parent.right
            anchors.rightMargin: 48
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0

            ItemMenuButton {
                id: menuOverview
                height: parent.height

                menuText: qsTr("Overview")
                source: "qrc:/icons_material/baseline-aspect_ratio-24px.svg"
                onClicked: screenMedia.state = "overview"
                selected: (screenMedia.state === "overview")
            }
            ItemMenuButton {
                id: menuTelemetry
                height: parent.height

                menuText: qsTr("Telemetry")
                source: "qrc:/icons_material/baseline-insert_chart-24px.svg"
                onClicked: screenMedia.state = "metadatas"
                selected: (screenMedia.state === "metadatas")
                visible: (shot && shot.hasGPMF && shot.hasGPS)
            }
            ItemMenuButton {
                id: menuMap
                height: parent.height

                menuText: qsTr("Map")
                source: "qrc:/icons_material/baseline-map-24px.svg"
                onClicked: screenMedia.state = "map"
                selected: (screenMedia.state === "map")
                visible: (shot && shot.fileType === Shared.FILE_PICTURE && shot.latitude !== 0.0)
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

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
