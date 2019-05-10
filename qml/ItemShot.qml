import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0
import com.offloadbuddy.shared 1.0
import "UtilsString.js" as UtilsString

Rectangle {
    id: itemShot
    width: 279
    height: Math.round(width / cellFormat)
    color: Theme.colorForeground

    property Shot shot: pointer
    property var shotDevice

    property real cellFormat: 4/3

    Connections {
        target: shot
        onStateUpdated: handleState()
    }

    function handleState() {
        icon_state.visible = true
        rectangleOverlay.visible = false
        if (shot.state === Shared.SHOT_STATE_QUEUED) {
            icon_state.source = "qrc:/icons_material/baseline-schedule-24px.svg"
        } else if (shot.state === Shared.SHOT_STATE_OFFLOADING) {
            icon_state.source = "qrc:/icons_material/baseline-save_alt-24px.svg"
        } else if (shot.state === Shared.SHOT_STATE_ENCODING) {
            icon_state.source = "qrc:/icons_material/baseline-memory-24px.svg"
        } else if (shot.state === Shared.SHOT_STATE_DONE) {
            icon_state.visible = false
            image_overlay.source = "qrc:/icons_material/baseline-check_circle_outline-24px.svg"
            rectangleOverlay.visible = true
        } else {
            icon_state.visible = false
        }
    }

    Component.onCompleted: {
        text_top.text = name
        text_top.visible = false

        if (typeof currentDevice !== "undefined")
            shotDevice = currentDevice

        handleState()
        if (shot.previewVideo)
            imageFs.source = "image://GridThumbnailer/" + shot.previewVideo
        else if (shot.previewPhoto)
            imageFs.source = "image://GridThumbnailer/" + shot.previewPhoto
        else if (shotDevice && shotDevice.deviceStorage === Shared.STORAGE_MTP)
        {
            imageMtp.enabled = true
            imageMtp.visible = true
            imageMtp.image = shot.getPreviewMtp()
        }

        text_right.visible = false
        text_left.visible = false
        if (type === Shared.SHOT_UNKNOWN) {
            icon_left.source = "qrc:/resources/minicons/unknown.svg"
        } else if (type < Shared.SHOT_PICTURE) {
            if (duration > 0) {
                text_left.visible = true
                text_left.text = UtilsString.durationToString_condensed(duration)
            }
            icon_left.source = "qrc:/resources/minicons/video.svg"
        } else {
            if (type >= Shared.SHOT_PICTURE_MULTI) {
                text_left.visible = true
                text_left.text = duration
                icon_left.source = "qrc:/resources/minicons/picture_multi.svg"
            } else {
                icon_left.source = "qrc:/resources/minicons/picture.svg"
            }
        }

        if (shot.highlightCount > 0) {
            icon_right.visible = true
            icon_right.source = "qrc:/resources/minicons/bookmark.svg"
            text_right.text = shot.highlightCount
        } else {
            icon_right.visible = false
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    ImageSvg {
        id: imageLoading
        width: 64
        height: 64
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        color: Theme.colorIcon
        source: "qrc:/icons_material/baseline-hourglass_empty-24px.svg"
    }

    // TODO loader between imageFs and imageMtp

    Image {
        id: imageFs
        anchors.fill: parent
        autoTransform: true
        asynchronous: true
        visible: (imageFs.progress === 1.0)

        fillMode: Image.PreserveAspectCrop
        antialiasing: false
        smooth: false // for perf reasons
        sourceSize.width: 512
        sourceSize.height: 512 // big enough so we have good quality regarding of the thumb size
    }

    ItemImage {
        id: imageMtp
        visible: false
        enabled: false
        anchors.fill: parent
    }

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
            styleColor: "#000000"
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
        }
    }

    Rectangle {
        id: rectangleOverlay
        color: "#80ffffff"
        anchors.fill: parent

        ImageSvg {
            id: image_overlay
            width: 64
            height: 64
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            source: "qrc:/icons_material/baseline-check_circle_outline-24px.svg"
            color: "white"
        }
    }

    MouseArea {
        id: mouseAreaItem
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property int thumbId: 1
        Timer {
            id: thumbTimer
            interval: 1500;
            running: false;
            repeat: true
            onTriggered: {
                if (shot.type > Shared.SHOT_UNKNOWN &&
                        shot.type < Shared.SHOT_PICTURE) {
                    var timecode_s = Math.round((shot.duration / 4000) * mouseAreaItem.thumbId)
                    if (++mouseAreaItem.thumbId > 3) mouseAreaItem.thumbId = 1

                    if (shot.previewVideo)
                        imageFs.source = "image://GridThumbnailer/" + shot.previewVideo + "@" + timecode_s
                    else if (shot.previewPhoto)
                        imageFs.source = "image://GridThumbnailer/" + shot.previewPhoto
                }
            }
        }
        onEntered: {
            text_top.visible = true

            if (!shotDevice || (shotDevice && shotDevice.deviceStorage !== Shared.STORAGE_MTP)) {
                if (shot.type > Shared.SHOT_UNKNOWN && shot.type < Shared.SHOT_PICTURE) {
                    thumbTimer.start()
                }
            }
        }
        onExited: {
            text_top.visible = false

            if (!shotDevice || (shotDevice && shotDevice.deviceStorage !== Shared.STORAGE_MTP)) {
                if (shot.type > Shared.SHOT_UNKNOWN && shot.type < Shared.SHOT_PICTURE) {
                    thumbId = 1
                    thumbTimer.stop()
                    if (shot.previewVideo)
                        imageFs.source = "image://GridThumbnailer/" + shot.previewVideo
                    else if (shot.previewPhoto)
                        imageFs.source = "image://GridThumbnailer/" + shot.previewPhoto
                }
            }
        }

        onClicked: {
            shotsview.currentIndex = index

            if (mouse.button === Qt.RightButton) {
                var folder = true
                var copy = true
                var merge = false
                var encode = false
                var telemetry_gpmf = false
                var telemetry_gps = false
                var remove = true

                if (shot.type < Shared.SHOT_PICTURE) {
                    if (shot.chapters > 1)
                        merge = true
                    encode = true
                } else if (shot.type > Shared.SHOT_PICTURE) {
                    encode = true
                }
                if (shot.hasGPMF)
                    telemetry_gpmf = true
                if (shot.hasGPS)
                    telemetry_gps = true
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
                actionMenu.x = mouseAreaOutsideView.mouseX + 8
                actionMenu.y = mouseAreaOutsideView.mouseY + 8
            } else {
                actionMenu.visible = false
            }
        }
        onDoubleClicked: {
            if (!shotDevice || (shotDevice && shotDevice.deviceStorage !== Shared.STORAGE_MTP)) {
                // Show the "shot details" screen
                actionMenu.visible = false
                shotsview.currentIndex = index

                shot.getMetadatasFromVideoGPMF();

                if (shotDevice)
                    screenDevice.state = "stateMediaDetails"
                else
                    screenLibrary.state = "stateMediaDetails"
            }
        }
    }
}
