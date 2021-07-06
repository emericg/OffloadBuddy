import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import com.offloadbuddy.shared 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: screenMedia
    width: 1280
    height: 720

    property string startedFrom: ""
    property var shot: null

    focus : (screenMedia.startedFrom === "device" && appContent.state === "device" && screenDevice.state === "stateMediaDetails") ||
            (screenMedia.startedFrom === "library" && appContent.state === "library" && screenLibrary.state === "stateMediaDetails")

    function loadShot(newshot) {
        //console.log("screenMedia - loadShot(" + newshot.name + ")")
        if (typeof newshot === "undefined" || !newshot) return
        if (!newshot.isValid()) return

        if (shot !== newshot) {
            shot = newshot
            updateShotDetails()
            screenMedia.state = "overview"

            // save state
            if (typeof deviceSavedState !== "undefined" && deviceSavedState) {
                if (screenMedia.shot) {
                    deviceSavedState.detail_shot = screenMedia.shot
                    deviceSavedState.mainState = "stateMediaDetails"
                }
            }
        }

        // change state
        if (appContent.state === "library") screenLibrary.state = "stateMediaDetails"
        else if (appContent.state === "device") screenDevice.state = "stateMediaDetails"
    }

    function restoreShot(load) {
        //console.log("screenMedia - restoreShot()")

        if (typeof deviceSavedState !== "undefined" && deviceSavedState) {
            if (typeof deviceSavedState.detail_shot === "undefined" || !deviceSavedState.detail_shot) return
            if (!deviceSavedState.detail_shot.isValid()) return

            if (screenMedia.shot !== deviceSavedState.detail_shot) {
                screenMedia.shot = deviceSavedState.detail_shot
                screenMedia.state = deviceSavedState.detail_state
                updateShotDetails()
            }
        } else {
            if (typeof screenMedia.shot === "undefined" || !screenMedia.shot) return
            if (!screenMedia.shot.isValid()) return
        }

        // forward/backward action? we need to change state too
        if (load) {
            if (appContent.state === "library") screenLibrary.state = "stateMediaDetails"
            else if (appContent.state === "device") screenDevice.state = "stateMediaDetails"
        }
    }

    function back() {
        //console.log("screenMedia - back()")

        // save state
        //if (typeof deviceSavedState !== "undefined" && deviceSavedState)
        //    if (screenMedia.shot)
        //        deviceSavedState.detail_shot = screenMedia.shot

        // go back
        if (appContent.state === "library") {
            screenLibrary.state = "stateMediaGrid"
        } else if (appContent.state === "device") {
            screenDevice.state = "stateMediaGrid"
            deviceSavedState.mainState = "stateMediaGrid"
        }
    }

    function updateFocus() {
        //focus = (screenMedia.startedFrom === "device" && appContent.state === "device" && screenDevice.state === "stateMediaDetails") ||
        //        (screenMedia.startedFrom === "library" && appContent.state === "library" && screenLibrary.state === "stateMediaDetails")

        if (focus === false) contentOverview.setPause()
    }

    function updateShotDetails() {
        if (screenMedia.shot) {
            textShotName.text = shot.name

            if (shot.hasGPMF && shot.hasGPS) {
                //if (not static) {
                    contentTelemetry.updateMetadata()
                //} else {
                //    contentMap.updateMap()
                //}
            } else {
                if (shot.latitude !== 0.0) {
                    contentTelemetry.updateMap()
                } else {
                    //
                }
            }

            contentOverview.updateOverview()
        }
    }

    // KEYS HANDLING ///////////////////////////////////////////////////////////

    Keys.onPressed: {
        if (event.key === Qt.Key_Space) {
            if (screenMedia.shot) {
                if (screenMedia.shot.fileType === Shared.FILE_VIDEO) {
                    event.accepted = true;
                    contentOverview.setPlayPause();
                }
            }
        } else if (event.key === Qt.Key_Backspace) {
            event.accepted = true;
            screenMedia.back();
        } else if (event.key === Qt.Key_Delete) {
            event.accepted = true;
            contentOverview.openDeletePopup();
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        id: rectangleHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        z: 1
        height: 64
        color: Theme.colorHeader

        DragHandler {
            // Drag on the sidebar to drag the whole window // Qt 5.15+
            // Also, prevent clicks below this area
            onActiveChanged: if (active) appWindow.startSystemMove();
            target: null
        }

        ItemImageButton {
            id: buttonBack
            width: 48
            height: 48
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            iconColor: Theme.colorHeaderContent
            backgroundColor: Theme.colorForeground

            source: "qrc:/assets/others/navigate_before_big.svg"
            onClicked: {
                if (appContent.state === "library") {
                    screenLibrary.state = "stateMediaGrid"
                } else if (appContent.state === "device") {
                    screenDevice.state = "stateMediaGrid"
                    deviceSavedState.mainState = "stateMediaGrid"
                }
            }
        }

        Text {
            id: textShotName
            height: 40
            anchors.left: buttonBack.right
            anchors.leftMargin: 8
            anchors.right: rowButtons.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            text: "SHOT NAME"
            color: Theme.colorHeaderContent
            fontSizeMode: Text.HorizontalFit
            font.bold: true
            font.pixelSize: Theme.fontSizeHeader
            minimumPixelSize: 22
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Row {
            id: rowCodecs
            anchors.verticalCenter: parent.verticalCenter
            x: (textShotName.x + textShotName.contentWidth + 16)
            visible: (textShotName.contentWidth + rowCodecs.width + 8 < textShotName.width)
            height: 28
            spacing: 16

            ItemCodec { id: codecVideo }

            ItemCodec { id: codecAudio }
        }

        ////////////////

        Row {
            id: rowButtons
            anchors.right: rowMenus.left
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Row {
                id: rowActions1
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                visible: (shot && shot.fileType !== Shared.FILE_VIDEO)

                ItemImageButton {
                    id: buttonTrim
                    width: 40
                    height: 40
                    source: "qrc:/assets/icons_material/baseline-timer-24px.svg"
                    visible: (shot && shot.fileType === Shared.FILE_VIDEO)
                    backgroundColor: Theme.colorForeground
                    onClicked: contentOverview.toggleTrim()
                }

                ItemImageButton {
                    id: buttonRotate
                    width: 40
                    height: 40
                    source: "qrc:/assets/icons_material/baseline-rotate_90_degrees_ccw-24px.svg"
                    backgroundColor: Theme.colorForeground
                    onClicked: contentOverview.toggleTransform()
                }

                ItemImageButton {
                    id: buttonCrop
                    width: 40
                    height: 40
                    source: "qrc:/assets/icons_material/baseline-crop-24px.svg"
                    backgroundColor: Theme.colorForeground
                    onClicked: contentOverview.toggleCrop()
                }
            }

            Rectangle { // separator
                width: 2; height: 40;
                anchors.verticalCenter: parent.verticalCenter
                visible: rowActions1.visible
                color: Theme.colorHeaderContent
                opacity: 0.1
            }

            Row {
                id: rowActions2
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                ItemImageButton {
                    id: buttonTimestamp
                    width: 40
                    height: 40
                    source: "qrc:/assets/icons_material/baseline-date_range-24px.svg"
                    backgroundColor: Theme.colorForeground
                    onClicked: contentOverview.openDatePopup()
                }

                ItemImageButton {
                    id: buttonTelemetry
                    width: 40
                    height: 40
                    source: "qrc:/assets/icons_material/baseline-insert_chart-24px.svg"
                    visible: (shot && shot.hasGPMF && shot.hasGPS)
                    backgroundColor: Theme.colorForeground
                    onClicked: contentOverview.openTelemetryPopup()
                }

                ItemImageButton {
                    id: buttonEncode
                    width: 40
                    height: 40
                    source: "qrc:/assets/icons_material/baseline-settings_applications-24px.svg"
                    backgroundColor: Theme.colorForeground
                    onClicked: contentOverview.openEncodingPopup()
                }
            }

            Rectangle { // separator
                width: 2; height: 40;
                anchors.verticalCenter: parent.verticalCenter
                visible: rowActions2.visible
                color: Theme.colorHeaderContent
                opacity: 0.1
            }

            Row {
                id: rowActions3
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                ItemImageButton {
                    id: buttonShowFolder
                    width: 40
                    height: 40
                    source: "qrc:/assets/icons_material/baseline-folder_open-24px.svg"
                    backgroundColor: Theme.colorForeground
                    onClicked: shot.openFolder()
                }

                ItemImageButton {
                    id: buttonDelete
                    width: 40
                    height: 40
                    source: "qrc:/assets/icons_material/baseline-delete-24px.svg"
                    backgroundColor: Theme.colorForeground
                    onClicked: contentOverview.openDeletePopup()
                }
            }
        }

        Rectangle { // separator
            width: 2; height: 40;
            anchors.right: rowMenus.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            //visible: (screenMedia.state !== "overview")
            color: Theme.colorHeaderContent
            opacity: 0.1
        }

        ////////////////

        Row {
            id: rowMenus
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.rightMargin: 40
            anchors.bottom: parent.bottom

            ItemMenuButton {
                id: menuOverview
                height: parent.height

                menuText: qsTr("Overview")
                source: "qrc:/assets/icons_material/baseline-aspect_ratio-24px.svg"
                selected: (screenMedia.state === "overview")
                onClicked: screenMedia.state = "overview"
            }
            ItemMenuButton {
                id: menuDetails
                height: parent.height

                visible: (shot && (shot.hasGoProMetadata || shot.fileCount > 1))

                menuText: qsTr("Details")
                source: "qrc:/assets/icons_material/baseline-list-24px.svg"
                selected: (screenMedia.state === "details")
                onClicked: screenMedia.state = "details"
            }
            ItemMenuButton {
                id: menuTelemetry
                height: parent.height

                visible: (shot && shot.hasGPMF && shot.hasGPS)

                menuText: qsTr("Telemetry")
                source: "qrc:/assets/icons_material/baseline-insert_chart_outlined-24px.svg"
                selected: (screenMedia.state === "metadata")
                onClicked: screenMedia.state = "metadata"
            }
            ItemMenuButton {
                id: menuMap
                height: parent.height

                visible: (shot && shot.fileType === Shared.FILE_PICTURE && shot.latitude !== 0.0)

                menuText: qsTr("Map")
                source: "qrc:/assets/icons_material/baseline-map-24px.svg"
                selected: (screenMedia.state === "metadata")
                onClicked: screenMedia.state = "metadata"
            }
        }

        ////////

        CsdWindows { }

        ////////

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: 2
            opacity: 0.1
            color: Theme.colorHeaderContent
        }
        SimpleShadow {
            anchors.top: parent.bottom
            anchors.topMargin: -height
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: Theme.colorHighContrast
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    onFocusChanged: {
        screenMedia.updateFocus()
    }
    onVisibleChanged: {
        screenMedia.updateFocus()
    }
    onStateChanged: {
        // save state
        if (typeof deviceSavedState !== "undefined" && deviceSavedState)
            deviceSavedState.detail_state = screenMedia.state

        screenMedia.updateFocus()
    }

    state: "overview"
    states: [
        State {
            name: "overview"
            PropertyChanges { target: contentOverview; visible: true; }
            PropertyChanges { target: contentDetails; visible: false; }
            PropertyChanges { target: contentTelemetry; visible: false; }
        },
        State {
            name: "details"
            PropertyChanges { target: contentOverview; visible: false; }
            PropertyChanges { target: contentDetails; visible: true; }
            PropertyChanges { target: contentTelemetry; visible: false; }
        },
        State {
            name: "metadata"
            PropertyChanges { target: contentOverview; visible: false; }
            PropertyChanges { target: contentDetails; visible: false; }
            PropertyChanges { target: contentTelemetry; visible: true; }
        }
    ]

    Item {
        id: rectangleContent

        anchors.top: rectangleHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        MediaDetailOverview {
            id: contentOverview
            visible: true
        }

        MediaDetailDetails {
            id: contentDetails
            visible: false
        }

        MediaDetailTelemetry {
            id: contentTelemetry
            visible: false
        }
    }
}
