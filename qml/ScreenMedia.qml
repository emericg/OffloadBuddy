import QtQuick
import QtQuick.Controls

import ThemeEngine
import ShotUtils
import "qrc:/js/UtilsString.js" as UtilsString

Loader {
    id: screenMedia

    sourceComponent: undefined
    asynchronous: false

    property string startedFrom: ""
    property var shot: null

    function loadShot(newshot) {
        //console.log("screenMedia - loadShot(" + newshot.name + ")")
        if (typeof newshot === "undefined" || !newshot) return
        if (!newshot.isValid()) return
        if (shot !== newshot) {
            shot = newshot
            shot.getMetadataFromVideoGPMF()
        }

        // load screen
        if (!sourceComponent) {
            sourceComponent = componentScreenMedia
        }

        screenMedia.item.loadShot2()

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
                screenMedia.item.state = deviceSavedState.detail_state
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
        if (screenMedia.item) screenMedia.item.updateFocus()
    }

    function updateShotDetails() {
        if (screenMedia.item) screenMedia.item.updateShotDetails()
    }

    ////////////////////////////////////////////////////////////////////////////

    Component {
        id: componentScreenMedia

        Item {
            id: itemScreenMedia
            width: 1280
            height: 720

            focus: (screenMedia.startedFrom === "device" && appContent.state === "device" && screenDevice.state === "stateMediaDetails") ||
                   (screenMedia.startedFrom === "library" && appContent.state === "library" && screenLibrary.state === "stateMediaDetails")

            ////////////////////////////////////////////////////////////////////

            function loadShot(newshot) {
                //console.log("screenMedia - loadShot(" + newshot.name + ")")
                if (typeof newshot === "undefined" || !newshot) return
                if (!newshot.isValid()) return

                // load screen
                if (!sourceComponent) {
                    sourceComponent = componentScreenMedia
                }

                if (shot !== newshot) {
                    shot = newshot
                    shot.getMetadataFromVideoGPMF()
                    updateShotDetails()

                    itemScreenMedia.state = "overview"

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

            function loadShot2() {
                //console.log("screenMedia - loadShot(" + newshot.name + ")")

                updateShotDetails()

                itemScreenMedia.state = "overview"

                // save state
                if (typeof deviceSavedState !== "undefined" && deviceSavedState) {
                    if (screenMedia.shot) {
                        deviceSavedState.detail_shot = screenMedia.shot
                        deviceSavedState.mainState = "stateMediaDetails"
                    }
                }
            }


            function restoreShot(load) {
                //console.log("screenMedia - restoreShot()")

                if (typeof deviceSavedState !== "undefined" && deviceSavedState) {
                    if (typeof deviceSavedState.detail_shot === "undefined" || !deviceSavedState.detail_shot) return
                    if (!deviceSavedState.detail_shot.isValid()) return

                    if (screenMedia.shot !== deviceSavedState.detail_shot) {
                        screenMedia.shot = deviceSavedState.detail_shot
                        itemScreenMedia.state = deviceSavedState.detail_state
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
                // make sure we are not still viewing the video from the media screen
                if ((screenMedia.startedFrom === "device" && appContent.state === "device" && screenDevice.state === "stateMediaDetails") ||
                    (screenMedia.startedFrom === "library" && appContent.state === "library" && screenLibrary.state === "stateMediaDetails")) {
                    return
                }
                // if we are leaving the media screen, pause the video
                if (screenMedia.focus === false && videoWindow.visibility !== Qt.WindowFullScreen) {
                    contentOverview.setPause()
                }
            }

            function setPause() {
                contentOverview.setPause()
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

            // KEYS HANDLING ///////////////////////////////////////////////////

            Keys.onPressed: (event) => {
                // UI
                if (event.key === Qt.Key_F9) {
                    event.accepted = true
                    contentOverview.toggleInfoPanel()
                } else if (event.key === Qt.Key_Backspace) {
                    event.accepted = true
                    screenMedia.back()
                } else if (event.key === Qt.Key_Delete) {
                    event.accepted = true
                    contentOverview.openDeletePopup()
                } else if (event.key === Qt.Key_F) {
                    event.accepted = true
                    contentOverview.toggleFullScreen()
                }
                // Player
                else if (event.key === Qt.Key_Space) {
                    event.accepted = true
                    contentOverview.setPlayPause()
                } else if (event.key === Qt.Key_MediaPlay) {
                    console.log("Key_MediaPlay")
                } else if (event.key === Qt.Key_MediaPause) {
                    console.log("Key_MediaPause")
                } else if (event.key === Qt.Key_MediaTogglePlayPause) {
                    console.log("Key_MediaTogglePlayPause")
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

                ////////////////

                RoundButtonIcon {
                    id: buttonBack
                    width: 48
                    height: 48
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    iconColor: Theme.colorHeaderContent
                    backgroundColor: Theme.colorForeground

                    source: "qrc:/gfx/navigate_before_big.svg"
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

                    TagDesktop { id: codecImage }

                    TagDesktop { id: codecVideo }

                    TagDesktop { id: codecAudio }
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

                        visible: (shot && shot.fileType !== ShotUtils.FILE_VIDEO)

                        RoundButtonIcon {
                            id: buttonTrim
                            width: 40
                            height: 40
                            source: "qrc:/assets/icons/material-icons/duotone/timer.svg"
                            visible: (shot && shot.fileType === ShotUtils.FILE_VIDEO)
                            backgroundColor: Theme.colorForeground
                            onClicked: contentOverview.toggleTrim()
                        }

                        RoundButtonIcon {
                            id: buttonRotate
                            width: 40
                            height: 40
                            source: "qrc:/assets/icons/material-icons/duotone/rotate_90_degrees_ccw.svg"
                            backgroundColor: Theme.colorForeground
                            onClicked: contentOverview.toggleTransform()
                        }

                        RoundButtonIcon {
                            id: buttonCrop
                            width: 40
                            height: 40
                            source: "qrc:/assets/icons/material-symbols/media/crop.svg"
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

                        RoundButtonIcon {
                            id: buttonTimestamp
                            width: 40
                            height: 40
                            source: "qrc:/assets/icons/material-icons/duotone/date_range.svg"
                            backgroundColor: Theme.colorForeground
                            onClicked: contentOverview.openDatePopup()
                        }

                        RoundButtonIcon {
                            id: buttonTelemetry
                            width: 40
                            height: 40
                            source: "qrc:/assets/icons/material-symbols/insert_chart.svg"
                            visible: (shot && shot.hasGPMF && shot.hasGPS)
                            backgroundColor: Theme.colorForeground
                            onClicked: contentOverview.openTelemetryPopup()
                        }

                        RoundButtonIcon {
                            id: buttonEncode
                            width: 40
                            height: 40
                            source: "qrc:/assets/icons/material-symbols/settings_applications.svg"
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

                        RoundButtonIcon {
                            id: buttonShowFolder
                            width: 40
                            height: 40
                            source: "qrc:/assets/icons/material-symbols/folder_open.svg"
                            backgroundColor: Theme.colorForeground
                            onClicked: shot.openFolder()
                        }

                        RoundButtonIcon {
                            id: buttonDelete
                            width: 40
                            height: 40
                            source: "qrc:/assets/icons/material-symbols/delete.svg"
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
                    //visible: (itemScreenMedia.state !== "overview")
                    color: Theme.colorHeaderContent
                    opacity: 0.1
                }

                ////////////////

                Row {
                    id: rowMenus
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.rightMargin: 32
                    anchors.bottom: parent.bottom

                    DesktopHeaderItem {
                        id: menuOverview
                        height: parent.height

                        text: qsTr("Overview")
                        source: "qrc:/assets/icons/material-icons/duotone/aspect_ratio.svg"
                        colorContent: Theme.colorHeaderContent
                        colorHighlight: Theme.colorHeaderHighlight

                        highlighted: (itemScreenMedia.state === "overview")
                        onClicked: itemScreenMedia.state = "overview"
                    }
                    DesktopHeaderItem {
                        id: menuDetails
                        height: parent.height

                        visible: (shot && (shot.hasGoProMetadata || shot.fileCount > 1))

                        text: qsTr("Details")
                        source: "qrc:/assets/icons/material-icons/duotone/list.svg"

                        highlighted: (itemScreenMedia.state === "details")
                        onClicked: itemScreenMedia.state = "details"
                    }
                    DesktopHeaderItem {
                        id: menuTelemetry
                        height: parent.height

                        visible: (shot && shot.hasGPMF && shot.hasGPS)

                        text: qsTr("Telemetry")
                        source: "qrc:/assets/icons/material-icons/duotone/insert_chart.svg"

                        highlighted: (itemScreenMedia.state === "metadata")
                        onClicked: itemScreenMedia.state = "metadata"
                    }
                    DesktopHeaderItem {
                        id: menuMap
                        height: parent.height

                        visible: (shot && shot.fileType === ShotUtils.FILE_PICTURE && shot.latitude !== 0.0)

                        text: qsTr("Map")
                        source: "qrc:/assets/icons/material-symbols/location/map-fill.svg"

                        highlighted: (itemScreenMedia.state === "metadata")
                        onClicked: itemScreenMedia.state = "metadata"
                    }
                }

                ////////

                CsdWindows { }

                CsdLinux { }

                ////////

                Rectangle { // separator
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    height: 2
                    opacity: 0.1
                    color: Theme.colorHeaderContent
                }
            }
            Rectangle { // shadow
                anchors.top: rectangleHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right

                height: 8
                opacity: 0.5

                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Theme.colorHeaderHighlight; }
                    GradientStop { position: 1.0; color: Theme.colorBackground; }
                }
            }

            ////////////////////////////////////////////////////////////////////

            onFocusChanged: {
                screenMedia.updateFocus()
            }
            onVisibleChanged: {
                screenMedia.updateFocus()
            }
            onStateChanged: {
                // save state
                if (typeof deviceSavedState !== "undefined" && deviceSavedState)
                    deviceSavedState.detail_state = itemScreenMedia.state

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
    }
}
