import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12 // Qt5
//import Qt5Compat.GraphicalEffects // Qt6

import ThemeEngine 1.0
import ShotUtils 1.0
import ItemImage 1.0
import "qrc:/js/UtilsMedia.js" as UtilsMedia
import "qrc:/js/UtilsString.js" as UtilsString

Rectangle {
    id: itemShot
    width: 280
    height: Math.round(width / cellFormat)
    color: Theme.colorForeground

    property var shot: pointer
    property var shotDevice: null
    property real cellFormat: 4/3
    //property bool singleSelection: (mediaGridView.currentIndex === index)
    //property bool multiSelection: (shot && shot.selected)

    Connections {
        target: shot
        onStateUpdated: handleState()
    }

    function handleState() {
        icon_state.visible = true
        overlayWorkDone.visible = false

        if (shot.state === ShotUtils.SHOT_STATE_QUEUED) {
            icon_state.source = "qrc:/assets/icons_material/baseline-schedule-24px.svg"
            offloadAnimation.stop()
            encodeAnimation.stop()
        } else if (shot.state === ShotUtils.SHOT_STATE_OFFLOADING) {
            //icon_state.source = "qrc:/assets/icons_material/baseline-save_alt-24px.svg"
            offloadAnimation.start()
        } else if (shot.state === ShotUtils.SHOT_STATE_ENCODING) {
            //icon_state.source = "qrc:/assets/icons_material/baseline-memory-24px.svg"
            encodeAnimation.start()
        } else if (shot.state === ShotUtils.SHOT_STATE_DONE ||
                   shot.state === ShotUtils.SHOT_STATE_OFFLOADED ||
                   shot.state === ShotUtils.SHOT_STATE_ENCODED) {
            icon_state.visible = false
            image_overlay.source = "qrc:/assets/icons_material/outline-check_circle-24px.svg"
            overlayWorkDone.visible = true
            offloadAnimation.stop()
            encodeAnimation.stop()
        } else {
            icon_state.visible = false
            overlayWorkDone.visible = false
            offloadAnimation.stop()
            encodeAnimation.stop()
        }
    }

    Component.onCompleted: {
        if (typeof currentDevice !== "undefined")
            shotDevice = currentDevice

        handleState()
        if (shot.previewVideo)
            imageFs.source = "image://MediaThumbnailer/" + shot.previewVideo + "@" + (shot.duration/12000).toFixed()
        else if (shot.previewPhoto)
            imageFs.source = "image://MediaThumbnailer/" + shot.previewPhoto
        else if (shotDevice && shotDevice.deviceStorage === ShotUtils.STORAGE_MTP) {
            imageMtp.enabled = true
            imageMtp.visible = true
            imageMtp.image = shot.getPreviewMtp()
        }

        text_left.visible = false
        if (shot.fileType === ShotUtils.FILE_VIDEO) {
            if (shot.transformation === 4) {
                imageFs.rotation = 90
                imageFs.scale = cellFormat
            } else if (shot.transformation === 3) {
                imageFs.rotation = 180
            } else if (shot.transformation === 7) {
                imageFs.rotation = 270
                imageFs.scale = cellFormat
            }
            if (shot.duration > 0) {
                text_left.visible = true
                text_left.text = UtilsString.durationToString_ISO8601_compact_loose(shot.duration)
            }
            if (shot.chapterCount > 1)
                icon_left.source = "qrc:/assets/icons_material/baseline-video_library-24px.svg"
            else
                icon_left.source = "qrc:/assets/icons_material/baseline-video-24px.svg"
        } else if (shot.fileType === ShotUtils.FILE_PICTURE) {
            if (shot.shotType === ShotUtils.SHOT_PICTURE_BURST) {
                text_left.visible = true
                text_left.text = duration
                icon_left.source = "qrc:/assets/icons_material/baseline-burst_mode-24px.svg"
            } else if (shotType >= ShotUtils.SHOT_PICTURE_MULTI) {
                text_left.visible = true
                text_left.text = duration
                icon_left.source = "qrc:/assets/icons_material/baseline-photo_library-24px.svg"
            } else {
                icon_left.source = "qrc:/assets/icons_material/baseline-photo-24px.svg"
            }
        } else {
            icon_left.source = "qrc:/assets/icons_material/baseline-broken_image-24px.svg"
        }
    }

    function openShot(mouse) {
        if (mouse.button === Qt.LeftButton) {
            if (!shotDevice ||
                (shotDevice && shotDevice.deviceStorage !== ShotUtils.STORAGE_MTP)) {
                // Show the "shot details" screen
                actionMenu.visible = false
                shotsView.currentIndex = index

                if (shot.isValid()) {
                    shot.getMetadataFromVideoGPMF()
                    screenMedia.loadShot(shot)
                }
            }
        }
    }

    function selectShot() {
        //
    }

    function openMenu() {
        var move = false
        var offload = false
        var encode = shot.valid
        var telemetry_gpmf = false
        var telemetry_gps = false
        var file = true
        var folder = true
        var remove = true

        if (shot.fileType === ShotUtils.FILE_VIDEO) { // all kind of videos
            if (shot.hasGPMF)
                telemetry_gpmf = true
            if (shot.hasGPS)
                telemetry_gps = true
        } else if (shot.fileType === ShotUtils.FILE_PICTURE) { // all kind of photos
            if (shot.shotType > ShotUtils.SHOT_PICTURE) { // only multi picture
                //
            }
        }

        if (shotDevice) {
            move = false
            offload = true
            if (shotDevice.deviceStorage === ShotUtils.STORAGE_MTP) {
                file = false
                folder = false
                encode = false
            }
            if (shotDevice.readOnly)
                remove = false
        } else {
            move = true
            offload = false
        }

        actionMenu.setMenuButtons(move, offload, encode,
                                  telemetry_gpmf, telemetry_gps,
                                  file, folder, remove)

        actionMenu.visible = true

        if (appSidebar.width + mouseAreaOutsideView.mouseX + actionMenu.width < appWindow.width)
            actionMenu.x = mouseAreaOutsideView.mouseX + 8
        else
            actionMenu.x = mouseAreaOutsideView.mouseX - actionMenu.width

        if (rectangleHeader.height + mouseAreaOutsideView.mouseY + actionMenu.height < appWindow.height)
            actionMenu.y = mouseAreaOutsideView.mouseY + 8
        else
            actionMenu.y = mouseAreaOutsideView.mouseY - 4 - actionMenu.height
    }

    ////////////////////////////////////////////////////////////////////////////

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            x: itemShot.x
            y: itemShot.y
            width: itemShot.width
            height: itemShot.height
            radius: Theme.componentRadius
        }
    }

    ImageSvg {
        id: imageLoading
        width: itemShot.width > 320 ? 72 : 40
        height: width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        color: Theme.colorIcon
        source: shot.valid ? "qrc:/assets/icons_material/baseline-hourglass_empty-24px.svg"
                           : "qrc:/assets/icons_material/baseline-broken_image-24px.svg"
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
        Behavior on opacity { NumberAnimation { duration: 133 } }

        // extra filtering?
        smooth: (settingsManager.thumbQuality >= 1)
        // big enough so we have good quality regarding of the thumb size
        sourceSize.width: (sm.thumbQuality > 1) ? 512 : 400
        sourceSize.height: (sm.thumbQuality > 1) ? 512 : 400
    }

    ItemImage {
        id: imageMtp
        anchors.fill: parent
        visible: false
    }

    ////////////////////////////////////////////////////////////////////////////

    Item {
        id: overlayInfos
        anchors.fill: parent

        visible: (imageFs.progress === 1.0 || imageMtp.visible)

        Text {
            id: text_top
            height: 20
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8

            opacity: mouseAreaItem.isHovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 133 } }

            color: "white"
            text: shot.name
            elide: Text.ElideRight
            style: Text.Raised
            font.bold: true
            font.pixelSize: 13
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }

        ////

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

        ////

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            spacing: 4

            ImageSvg {
                id: icon_left
                width: 24
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                color: "white"
            }

            Text {
                id: text_left
                anchors.verticalCenter: parent.verticalCenter

                color: "white"
                text: "left"
                lineHeight: 1
                style: Text.Raised
                styleColor: "black"
                font.bold: true
                font.pixelSize: 13
            }
        }

        ////

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            spacing: 4

            Text {
                id: text_hmmt
                anchors.verticalCenter: parent.verticalCenter
                color: "white"
                visible: shot.hilightCount
                text: shot.hilightCount
                style: Text.Raised
                font.bold: true
                font.pixelSize: 13
            }
            ImageSvg {
                id: icon_hmmt
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                visible: shot.hilightCount
                rotation: 90
                color: "orange"
                source: "qrc:/assets/icons_material/baseline-label_important-24px.svg"
            }

            ImageSvg {
                id: icon_tlm
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                visible: (shot.fileType === ShotUtils.FILE_VIDEO && shot.hasGPS)
                color: "white"
                source: "qrc:/assets/icons_material/baseline-insert_chart-24px.svg"
            }

            ImageSvg {
                id: icon_gps
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                visible: shot.hasGPS
                color: "white"
                source: "qrc:/assets/icons_material/baseline-map-24px.svg"
            }
        }
    }

    Rectangle {
        id: overlaySelection
        anchors.fill: parent

        visible: shot.selected
        color: Theme.colorPrimary
        opacity: 0.33
    }

    Rectangle {
        id: overlayWorkDone
        anchors.fill: parent

        color: "#80ffffff"

        ImageSvg {
            id: image_overlay
            width: 64
            height: 64
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            source: "qrc:/assets/icons_material/outline-check_circle-24px.svg"
            color: "white"
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    MouseArea {
        id: mouseAreaItem
        anchors.fill: parent

        hoverEnabled: true
        propagateComposedEvents: false
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        property bool isHovered: false

        ////////

        property int thumbId: 1
        Timer {
            id: thumbTimer
            interval: 2000
            running: false
            repeat: true
            onTriggered: {
                if (shot.fileType === ShotUtils.FILE_VIDEO) {
                    var timecode_s = Math.round((shot.duration / 4000) * mouseAreaItem.thumbId)

                    if (++mouseAreaItem.thumbId > 3)
                        mouseAreaItem.thumbId = 1

                    if (shot.previewVideo)
                        imageFs.source = "image://MediaThumbnailer/" + shot.previewVideo + "@" + timecode_s
                    else if (shot.previewPhoto)
                        imageFs.source = "image://MediaThumbnailer/" + shot.previewPhoto
                }
            }
        }
        onEntered: {
            mouseAreaItem.isHovered = true
            shotsView.focus = true

            if (!shotDevice || (shotDevice && shotDevice.deviceStorage !== ShotUtils.STORAGE_MTP)) {
                if (shot.fileType === ShotUtils.FILE_VIDEO && settingsManager.thumbQuality > 1) {
                    thumbTimer.start()
                }
            }
        }
        onExited: {
            mouseAreaItem.isHovered = false

            if (!shotDevice || (shotDevice && shotDevice.deviceStorage !== ShotUtils.STORAGE_MTP)) {
                if (shot.fileType === ShotUtils.FILE_VIDEO && settingsManager.thumbQuality > 1) {
                    thumbId = 1
                    thumbTimer.stop()
                    if (shot.previewVideo)
                        imageFs.source = "image://MediaThumbnailer/" + shot.previewVideo + "@" + (shot.duration/12000).toFixed()
                    else if (shot.previewPhoto)
                        imageFs.source = "image://MediaThumbnailer/" + shot.previewPhoto
                }
            }
        }

        ////////

        onClicked: (mouse)=> {
            //console.log("ItemShot::onClicked")
            var lastIndex = shotsView.currentIndex
            shotsView.currentIndex = index

            // multi selection (range)
            if ((mouse.button === Qt.LeftButton) && (mouse.modifiers & Qt.ShiftModifier)) {
                //console.log("multiselection (with modifier), from " + lastIndex + " to " + index)

                if (lastIndex < index) {
                    for (var i = lastIndex; i <= index; i++)
                        mediaGrid.selectFile(i)
                } else if (lastIndex >= index) {
                    for (var j = index; j <= lastIndex; j++)
                        mediaGrid.selectFile(j)
                }
                return
            }

            // multi selection (add)
            if (mouse.button === Qt.MiddleButton ||
                ((mouse.button === Qt.LeftButton) && mediaGrid.selectionMode) ||
                ((mouse.button === Qt.LeftButton) && (mouse.modifiers & Qt.ControlModifier))) {
                //console.log("ItemShot::onClicked::Qt.MiddleButton")

                if (!shot.selected) {
                    mediaGrid.selectFile(index)
                } else {
                    mediaGrid.deselectFile(index)
                }
                actionMenu.visible = false
                return
            }

            // action menu
            if (mouse.button === Qt.RightButton && !mediaGrid.selectionMode)
                openMenu()
            else
                actionMenu.visible = false
        }
        onDoubleClicked: (mouse)=> {
            //console.log("ItemShot::onDoubleClicked")

            if (mouse.button === Qt.LeftButton) {
                openShot(mouse)
            }
        }
        onPressAndHold: {
            //console.log("ItemShot::onPressAndHold")

            // multi selection
            if (!shot.selected) {
                mediaGrid.selectFile(index)
            } else {
                mediaGrid.deselectFile(index)
            }
        }
    }
}
