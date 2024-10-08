import QtQuick
import QtQuick.Effects
import QtQuick.Controls

import ThemeEngine
import ShotUtils
import ItemImage
import "qrc:/utils/UtilsMedia.js" as UtilsMedia
import "qrc:/utils/UtilsString.js" as UtilsString

Rectangle {
    id: itemShot

    width: 400
    height: Math.round(width / cellFormat)
    radius: Theme.componentRadius
    color: Theme.colorForeground

    property var shot: pointer
    property var shotDevice: null
    property real cellFormat: 4/3

    property bool singleSelection: (shotsView.currentIndex === index)
    property bool multiSelection: (shot && shot.selected)
    property bool alreadyOffloaded: shotDevice && mediaLibrary.isShotAlreadyOffloaded(shot.name, shot.datasize)

    ////////////////////////////////////////////////////////////////////////////

    Component.onCompleted: {
        if (typeof currentDevice !== "undefined")
            shotDevice = currentDevice

        if (shot.previewVideo) {
            imageFs.source = "image://MediaThumbnailer/" + shot.previewVideo + "@" + (shot.duration/12000).toFixed()
        } else if (shot.previewPhoto) {
            imageFs.source = "image://MediaThumbnailer/" + shot.previewPhoto
        } else if (shotDevice && shotDevice.deviceStorage === ShotUtils.STORAGE_MTP) {
            imageMtp.enabled = true
            imageMtp.visible = true
            imageMtp.image = shot.getPreviewMtp()
        }

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
            if (shot.chapterCount > 1)
                icon_mediaType.source = "qrc:/assets/icons/material-icons/duotone/video_library.svg"
            else
                icon_mediaType.source = "qrc:/assets/icons/material-symbols/media/movie-fill.svg"
        } else if (shot.fileType === ShotUtils.FILE_PICTURE) {
            if (shot.shotType === ShotUtils.SHOT_PICTURE_BURST) {
                icon_mediaType.source = "qrc:/assets/icons/material-icons/duotone/burst_mode.svg"
            } else if (shotType >= ShotUtils.SHOT_PICTURE_MULTI) {
                icon_mediaType.source = "qrc:/assets/icons/material-icons/duotone/photo_library.svg"
            } else {
                icon_mediaType.source = "qrc:/assets/icons/material-symbols/media/image.svg"
            }
        } else {
            icon_mediaType.source = "qrc:/assets/icons/material-symbols/media/broken_image.svg"
        }
    }

    function openShot(mouse) {
        if (mouse.button === Qt.LeftButton) {
            if (!shotDevice ||
                (shotDevice && shotDevice.deviceStorage !== ShotUtils.STORAGE_MTP)) {
                // Show the "shot details" screen
                actionMenu.visible = false
                shotsView.currentIndex = index
                screenMedia.loadShot(shot)
            }
        }
    }

    function selectShot() {
        //
    }

    function openMenu() {
        var offload = false
        var move = false
        var merge = false
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
            if (shot.chapterCount > 1 && !shotDevice)
                merge = true // chaptered video
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

        actionMenu.setMenuButtons(offload, move, merge, encode,
                                  telemetry_gpmf, telemetry_gps,
                                  file, folder, remove)

        actionMenu.visible = true

        var positionInShotsView = mapToItem(shotsView, mouseAreaItem.mouseX, mouseAreaItem.mouseY)

        if ((appSidebar.width + positionInShotsView.x + actionMenu.width) < appWindow.width)
            actionMenu.x = positionInShotsView.x + 8
        else
            actionMenu.x = positionInShotsView.x - 4 - actionMenu.width

        if ((rectangleHeader.height + positionInShotsView.y + actionMenu.height) < appWindow.height)
            actionMenu.y = positionInShotsView.y + 8
        else
            actionMenu.y = positionInShotsView.y - 4 - actionMenu.height
    }

    ////////////////////////////////////////////////////////////////////////////

    IconSvg {
        id: imageLoading
        width: itemShot.width > 320 ? 72 : 40
        height: width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        color: Theme.colorIcon
        source: shot.valid ? "qrc:/assets/icons/material-icons/outlined/hourglass_empty.svg"
                           : "qrc:/assets/icons/material-symbols/media/broken_image.svg"
    }

    ////////////////////////////////////////////////////////////////////////////

    Item {
        id: imageArea
        anchors.fill: parent

        property bool imageLoaded: (imageFs.progress === 1.0 ||
                                    (imageMtpLoader.item && imageMtpLoader.item.visible))

        Image { // TODO // loader
            id: imageFs
            anchors.fill: parent

            autoTransform: true
            asynchronous: true
            //retainWhileLoading: true // QT 6.8+
            fillMode: Image.PreserveAspectCrop

            opacity: (imageFs.progress === 1.0) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 133 } }

            // extra filtering?
            smooth: (settingsManager.thumbQuality >= 1)
            // big enough so we have good quality regarding of the thumb size
            sourceSize.width: (settingsManager.thumbQuality > 1) ? 512 : 400
            sourceSize.height: (settingsManager.thumbQuality > 1) ? 512 : 400
        }

        Loader {
            id: imageMtpLoader
            anchors.fill: parent

            active: (shotDevice && shotDevice.deviceStorage === ShotUtils.STORAGE_MTP)
            asynchronous: true
            sourceComponent: ItemImage {
                id: imageMtp
                anchors.fill: parent
                image: shot.getPreviewMtp()
            }
        }

        Loader { // overlay "selection"
            anchors.fill: parent

            active: shot.selected
            asynchronous: true
            sourceComponent: Rectangle {
                radius: Theme.componentRadius
                color: Theme.colorPrimary
                opacity: 0.33
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskInverted: false
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            maskSpreadAtMax: 0.0
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    x: itemShot.x
                    y: itemShot.y
                    width: itemShot.width
                    height: itemShot.height
                    radius: Theme.componentRadius
                }
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Item { // overlayInfos
        anchors.fill: parent

        visible: imageArea.imageLoaded

        Text { // text_top
            height: 20
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8

            opacity: (mouseAreaItem.containsMouse || itemShot.singleSelection || itemShot.multiSelection) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 133 } }

            color: "white"
            text: shot.name
            textFormat: Text.PlainText
            elide: Text.ElideRight
            style: Text.Raised
            font.bold: true
            font.pixelSize: 13
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
        }

        ////

        Item {
            width: 24
            height: 24
            clip: true
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8

            IconSvg {
                id: icon_state
                width: 24
                height: 24

                visible: (shot.state === ShotUtils.SHOT_STATE_QUEUED ||
                          shot.state === ShotUtils.SHOT_STATE_OFFLOADING ||
                          shot.state === ShotUtils.SHOT_STATE_ENCODING)

                color: "white"
                source: {
                    if (shot.state === ShotUtils.SHOT_STATE_QUEUED) {
                        return "qrc:/assets/icons/material-icons/duotone/schedule.svg"
                    } else if (shot.state === ShotUtils.SHOT_STATE_OFFLOADING) {
                        return "qrc:/assets/icons/material-icons/duotone/save_alt.svg"
                    } else if (shot.state === ShotUtils.SHOT_STATE_ENCODING) {
                        return "qrc:/assets/icons/material-symbols/memory.svg"
                    } else {
                        return ""
                    }
                }

                NumberAnimation on rotation {
                    id: encodeAnimation
                    running: (shot.state === ShotUtils.SHOT_STATE_ENCODING)
                    loops: Animation.Infinite

                    onStopped: icon_state.rotation = 0
                    duration: 2000
                    from: 0
                    to: 360
                }
                SequentialAnimation {
                    id: offloadAnimation
                    running: (shot.state === ShotUtils.SHOT_STATE_OFFLOADING)
                    loops: Animation.Infinite

                    onStopped: icon_state.y = 0
                    NumberAnimation { target: icon_state; property: "y"; to: 24; duration: 500; }
                    NumberAnimation { target: icon_state; property: "y"; to: -24; duration: 500; }
                }
            }
        }

        ////

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            spacing: 4

            IconSvg {
                id: icon_mediaType
                width: 28
                height: 28
                anchors.verticalCenter: parent.verticalCenter
                color: "white"
            }

            Text {
                id: text_mediaDuration
                anchors.verticalCenter: parent.verticalCenter

                visible: (shot.duration > 1)
                text: (shot.fileType === ShotUtils.FILE_VIDEO) ?
                          UtilsString.durationToString_ISO8601_compact_loose(shot.duration) :
                          shot.duration

                textFormat: Text.PlainText
                color: "white"
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
            spacing: 0

            Text {
                id: text_hmmt
                anchors.verticalCenter: parent.verticalCenter
                color: "white"
                visible: shot.hilightCount
                text: shot.hilightCount
                textFormat: Text.PlainText
                style: Text.Raised
                font.bold: true
                font.pixelSize: 13
            }
            IconSvg {
                id: icon_hmmt
                width: 24
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                visible: shot.hilightCount
                rotation: 90
                color: "orange"
                source: "qrc:/assets/icons/material-symbols/label_important.svg"
            }

            IconSvg {
                id: icon_gps
                width: 24
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                visible: shot.hasGPS
                color: "white"
                source: "qrc:/assets/icons/material-symbols/location/map-fill.svg"
            }

            IconSvg {
                id: icon_tlm
                width: 24
                height: 24
                anchors.verticalCenter: parent.verticalCenter
                visible: (shot.fileType === ShotUtils.FILE_VIDEO && shot.hasGPS)
                color: "white"
                source: "qrc:/assets/icons/material-symbols/insert_chart.svg"
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Loader { // overlay "work done"
        anchors.fill: parent

        active: (shot.state === ShotUtils.SHOT_STATE_DONE ||
                 shot.state === ShotUtils.SHOT_STATE_OFFLOADED ||
                 shot.state === ShotUtils.SHOT_STATE_ENCODED ||
                 itemShot.alreadyOffloaded)

        asynchronous: true
        sourceComponent: Item {
            Canvas {
                id: canvas
                anchors.fill: parent
                opacity: 0.666

                Connections {
                    target: ThemeEngine
                    function onCurrentThemeChanged() { canvas.requestPaint() }
                }

                onPaint: {
                    var context = getContext("2d");
                    context.beginPath();
                    context.moveTo(itemShot.width, 0);
                    context.lineTo(itemShot.width, 72);
                    context.lineTo(itemShot.width - 72, 0);
                    context.closePath();
                    context.fillStyle = Theme.colorPrimary;
                    context.fill();
                }
            }

            IconSvg {
                width: 32
                height: 32
                anchors.top: parent.top
                anchors.topMargin: 3
                anchors.right: parent.right
                anchors.rightMargin: 3

                color: "white"
                source: {
                    if (shot.state === ShotUtils.SHOT_STATE_DONE ||
                        shot.state === ShotUtils.SHOT_STATE_OFFLOADED ||
                        shot.state === ShotUtils.SHOT_STATE_ENCODED) {
                        if (shot.state === ShotUtils.SHOT_STATE_OFFLOADED)
                            return "qrc:/assets/icons/material-icons/duotone/save_alt.svg"
                        else if (shot.state === ShotUtils.SHOT_STATE_ENCODED)
                            return "qrc:/assets/icons/material-symbols/memory.svg"
                        else
                            return "qrc:/assets/icons/material-symbols/check_circle.svg"
                    } else if (itemShot.alreadyOffloaded) {
                        return "qrc:/assets/icons/material-icons/duotone/save_alt.svg"
                    }
                }
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    MouseArea {
        id: mouseAreaItem
        anchors.fill: parent

        hoverEnabled: true
        propagateComposedEvents: false
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        ////////

        property int thumbId: 1
        Timer {
            id: thumbTimer
            interval: 2000
            running: false
            repeat: true
            onTriggered: {
                if (!shot || typeof shot === "undefined") return

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

        ////////

        onEntered: {
            if (!shot || typeof shot === "undefined") return

            if (!shotDevice || (shotDevice && shotDevice.deviceStorage !== ShotUtils.STORAGE_MTP)) {
                if (shot.fileType === ShotUtils.FILE_VIDEO && settingsManager.thumbQuality > 1) {
                    thumbTimer.start()
                }
            }
        }
        onExited: {
            if (!shot || typeof shot === "undefined") return

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

        onClicked: (mouse) => {
            if (!shot || typeof shot === "undefined") return
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
        onDoubleClicked: (mouse) => {
            if (!shot || typeof shot === "undefined") return
            //console.log("ItemShot::onDoubleClicked")

            if (mouse.button === Qt.LeftButton) {
                openShot(mouse)
            }
        }
        onPressAndHold: (mouse) => {
            if (!shot || typeof shot === "undefined") return
            //console.log("ItemShot::onPressAndHold")

            // multi selection
            if (!shot.selected) {
                mediaGrid.selectFile(index)
            } else {
                mediaGrid.deselectFile(index)
            }
        }

        ////////
    }

    ////////////////////////////////////////////////////////////////////////////
}
