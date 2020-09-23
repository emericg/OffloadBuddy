import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import com.offloadbuddy.shared 1.0
import "qrc:/js/UtilsMedia.js" as UtilsMedia
import "qrc:/js/UtilsString.js" as UtilsString

Rectangle {
    id: itemShot
    width: 279
    height: Math.round(width / cellFormat)
    color: Theme.colorForeground

    property var shot: pointer
    property var shotDevice: null

    property real cellFormat: 4/3

    Connections {
        target: shot
        onStateUpdated: handleState()
    }

    function handleState() {
        icon_state.visible = true
        rectangleOverlay.visible = false

        if (shot.state === Shared.SHOT_STATE_QUEUED) {
            icon_state.source = "qrc:/assets/icons_material/baseline-schedule-24px.svg"
            offloadAnimation.stop()
            encodeAnimation.stop()
        } else if (shot.state === Shared.SHOT_STATE_OFFLOADING) {
            //icon_state.source = "qrc:/assets/icons_material/baseline-save_alt-24px.svg"
            offloadAnimation.start()
        } else if (shot.state === Shared.SHOT_STATE_ENCODING) {
            //icon_state.source = "qrc:/assets/icons_material/baseline-memory-24px.svg"
            encodeAnimation.start()
        } else if (shot.state === Shared.SHOT_STATE_DONE ||
                   shot.state === Shared.SHOT_STATE_OFFLOADED ||
                   shot.state === Shared.SHOT_STATE_ENCODED) {
            icon_state.visible = false
            image_overlay.source = "qrc:/assets/icons_material/baseline-check_circle_outline-24px.svg"
            rectangleOverlay.visible = true
            offloadAnimation.stop()
            encodeAnimation.stop()
        } else {
            icon_state.visible = false
            rectangleOverlay.visible = false
            offloadAnimation.stop()
            encodeAnimation.stop()
        }
    }

    Component.onCompleted: {
        text_top.text = name
        text_top.visible = false

        if (typeof currentDevice !== "undefined")
            shotDevice = currentDevice

        handleState()
        if (shot.previewVideo)
            imageFs.source = "image://GridThumbnailer/" + shot.previewVideo + "@" + (shot.duration/12000).toFixed()
        else if (shot.previewPhoto)
            imageFs.source = "image://GridThumbnailer/" + shot.previewPhoto
        else if (shotDevice && shotDevice.deviceStorage === Shared.STORAGE_MTP) {
            imageMtp.enabled = true
            imageMtp.visible = true
            imageMtp.image = shot.getPreviewMtp()
        }

        text_right.visible = false
        text_left.visible = false
        if (fileType === Shared.FILE_VIDEO) {
            if (duration > 0) {
                text_left.visible = true
                text_left.text = UtilsString.durationToString_ISO8601_compact_loose(duration)
            }
            if (shot.chapters > 1)
                icon_left.source = "qrc:/assets/icons_material/baseline-video_library-24px.svg"
            else
                icon_left.source = "qrc:/assets/icons_material/outline-local_movies-24px.svg"
        } else if (fileType === Shared.FILE_PICTURE) {
            if (shotType === Shared.SHOT_PICTURE_BURST) {
                text_left.visible = true
                text_left.text = duration
                icon_left.source = "qrc:/assets/icons_material/baseline-burst_mode-24px.svg"
            } else if (shotType >= Shared.SHOT_PICTURE_MULTI) {
                text_left.visible = true
                text_left.text = duration
                icon_left.source = "qrc:/assets/icons_material/baseline-photo_library-24px.svg"
            } else {
                icon_left.source = "qrc:/assets/icons_material/baseline-photo-24px.svg"
            }
        } else {
            icon_left.source = "qrc:/assets/icons_material/baseline-broken_image-24px.svg"
        }

        if (shot.highlightCount > 0) {
            icon_right.visible = true
            icon_right.color = "yellow"
            icon_right.source = "qrc:/assets/icons_material/baseline-label_important-24px.svg"
            text_right.text = shot.highlightCount
        } else {
            icon_right.visible = false
        }
    }

    function openShot(mouse) {
        if (mouse.button === Qt.LeftButton) {
            if (!shotDevice || (shotDevice && shotDevice.deviceStorage !== Shared.STORAGE_MTP)) {
                // Show the "shot details" screen
                actionMenu.visible = false
                shotsView.currentIndex = index

                shot.getMetadataFromVideoGPMF();

                if (shotDevice)
                    screenDevice.state = "stateMediaDetails"
                else
                    screenLibrary.state = "stateMediaDetails"
            }
        }
    }

    function selectShot() {
        //
    }

    function openMenu() {
        var folder = true
        var copy = true
        var merge = false
        var encode = true
        var telemetry_gpmf = false
        var telemetry_gps = false
        var remove = true

        if (shot.fileType === Shared.FILE_VIDEO) { // all kind of videos
            if (shot.chapters > 1)
                merge = true

            if (shot.hasGPMF)
                telemetry_gpmf = true
            if (shot.hasGPS)
                telemetry_gps = true
        } else if (shot.fileType === Shared.FILE_PICTURE) { // all kind of photos
            //
            if (shot.shotType > Shared.SHOT_PICTURE) { // only multi picture
                //
            }
        }

        if (shotDevice) {
            if (shotDevice.deviceStorage === Shared.STORAGE_MTP) {
                folder = false
                merge = false
                encode = false
            }
            if (shotDevice.readOnly)
                remove = false
        } else {
            copy = false
        }

        actionMenu.setMenuButtons(folder, copy, merge, encode, telemetry_gpmf, telemetry_gps, remove)

        actionMenu.visible = true
        actionMenu.x = mouseAreaOutsideView.mouseX + 4
        actionMenu.y = mouseAreaOutsideView.mouseY + 4
    }

    ////////////////////////////////////////////////////////////////////////////

    ImageSvg {
        id: imageLoading
        width: 64
        height: 64
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        color: Theme.colorIcon
        source: "qrc:/assets/icons_material/baseline-hourglass_empty-24px.svg"
    }

    // TODO loader between imageFs and imageMtp

    Image {
        id: imageFs
        anchors.fill: parent

        autoTransform: true
        asynchronous: true
        antialiasing: false
        fillMode: Image.PreserveAspectCrop

        //visible: (imageFs.progress === 1.0)
        opacity: (imageFs.progress === 1.0) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 333 } }

        // extra filtering?
        smooth: (settingsManager.thumbQuality === 2)
        // big enough so we have good quality regarding of the thumb size
        sourceSize.width: (sm.thumbQuality >= 1) ? 512 : 400
        sourceSize.height: (sm.thumbQuality >= 1) ? 512 : 400
    }

    ItemImage {
        id: imageMtp
        anchors.fill: parent
        visible: false
    }

    ////////////////////////////////////////////////////////////////////////////

    Item {
        id: legends
        anchors.fill: parent

        visible: (imageFs.visible || imageMtp.visible)

        ImageSvg {
            id: icon_left
            width: 24
            height: 24
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8

            color: "white"
        }
        Text {
            id: text_left
            color: "white"
            text: qsTr("left")
            anchors.verticalCenter: icon_left.verticalCenter
            anchors.left: icon_left.right
            anchors.leftMargin: 4
            lineHeight: 1
            style: Text.Raised
            styleColor: "black"
            font.bold: true
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 13
        }

        ImageSvg {
            id: icon_right
            width: 24
            height: 24
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8

            color: "white"
        }
        Text {
            id: text_right
            color: "white"
            text: qsTr("right")
            anchors.verticalCenter: icon_right.verticalCenter
            style: Text.Raised
            font.bold: true
            anchors.right: icon_right.left
            anchors.rightMargin: 4
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 13
        }

        Text {
            id: text_top
            x: 8
            y: 8
            height: 20
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 8

            color: "white"
            clip: true
            text: name
            style: Text.Raised
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            font.bold: true
            font.pixelSize: 13
        }

        ImageSvg {
            id: icon_state
            width: 24
            height: 24

            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8

            color: "white"

            NumberAnimation on rotation {
                id: encodeAnimation
                running: false

                onStarted: icon_state.source = "qrc:/assets/icons_material/baseline-memory-24px.svg"
                onStopped: icon_state.rotation = 0
                duration: 2000;
                from: 0;
                to: 360;
                loops: Animation.Infinite
            }
            SequentialAnimation {
                id: offloadAnimation
                running: false

                onStarted: icon_state.source = "qrc:/assets/icons_material/baseline-save_alt-24px.svg"
                onStopped: icon_state.y = 0
                NumberAnimation { target: icon_state; property: "y"; from: -40; to: 40; duration: 1000; }
                loops: Animation.Infinite
            }
        }
    }

    Rectangle {
        id: rectangleSelection
        anchors.fill: parent

        visible: shot.selected
        color: Theme.colorPrimary
        opacity: 0.33
    }
    Rectangle {
        id: rectangleOverlay
        anchors.fill: parent

        color: "#80ffffff"

        ImageSvg {
            id: image_overlay
            width: 64
            height: 64
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            source: "qrc:/assets/icons_material/baseline-check_circle_outline-24px.svg"
            color: "white"
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    MouseArea {
        id: mouseAreaItem
        anchors.fill: parent

        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        ////////

        property int thumbId: 1
        Timer {
            id: thumbTimer
            interval: 1500;
            running: false;
            repeat: true
            onTriggered: {
                if (shot.fileType === Shared.FILE_VIDEO) {
                    var timecode_s = Math.round((shot.duration / 4000) * mouseAreaItem.thumbId)

                    if (++mouseAreaItem.thumbId > 3)
                        mouseAreaItem.thumbId = 1

                    if (shot.previewVideo)
                        imageFs.source = "image://GridThumbnailer/" + shot.previewVideo + "@" + timecode_s
                    else if (shot.previewPhoto)
                        imageFs.source = "image://GridThumbnailer/" + shot.previewPhoto
                }
            }
        }
        onEntered: {
            shotsView.focus = true
            text_top.visible = true

            if (!shotDevice || (shotDevice && shotDevice.deviceStorage !== Shared.STORAGE_MTP)) {
                if (shot.fileType === Shared.FILE_VIDEO) {
                    thumbTimer.start()
                }
            }
        }
        onExited: {
            text_top.visible = false

            if (!shotDevice || (shotDevice && shotDevice.deviceStorage !== Shared.STORAGE_MTP)) {
                if (shot.fileType === Shared.FILE_VIDEO) {
                    thumbId = 1
                    thumbTimer.stop()
                    if (shot.previewVideo)
                        imageFs.source = "image://GridThumbnailer/" + shot.previewVideo + "@" + (shot.duration/12000).toFixed()
                    else if (shot.previewPhoto)
                        imageFs.source = "image://GridThumbnailer/" + shot.previewPhoto
                }
            }
        }

        ////////

        onClicked: {
            //console.log("ItemShot::onClicked")
            var lastIndex = shotsView.currentIndex
            shotsView.currentIndex = index

            // multi selection (range)
            if ((mouse.button === Qt.LeftButton) && (mouse.modifiers & Qt.ShiftModifier)) {
                //console.log("multiselection (with modifier), from " + lastIndex + " to " + index)

                if (lastIndex < index) {
                    for (var i = lastIndex; i <= index; i++)
                        mediaGrid.selectFile(i);
                } else if (lastIndex >= index) {
                    for (var j = index; j <= lastIndex; j++)
                        mediaGrid.selectFile(j);
                }
                return;
            }

            // multi selection (add)
            if (mouse.button === Qt.MiddleButton ||
                ((mouse.button === Qt.LeftButton) && mediaGrid.selectionMode) ||
                ((mouse.button === Qt.LeftButton) && (mouse.modifiers & Qt.ControlModifier))) {
                //console.log("ItemShot::onClicked::Qt.MiddleButton")

                if (!shot.selected) {
                    mediaGrid.selectFile(index);
                } else {
                    mediaGrid.deselectFile(index);
                }
                return;
            }

            // action menu
            if (mouse.button === Qt.RightButton && !mediaGrid.selectionMode)
                openMenu()
            else
                actionMenu.visible = false
        }
        onDoubleClicked: {
            //console.log("ItemShot::onDoubleClicked")
            openShot(mouse)
        }
        onPressAndHold: {
            //console.log("ItemShot::onPressAndHold")

            // multi selection
            if (!shot.selected) {
                mediaGrid.selectFile(index);
            } else {
                mediaGrid.deselectFile(index);
            }
        }
    }
}
