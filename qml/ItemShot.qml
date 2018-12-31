import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.style 1.0
import com.offloadbuddy.shared 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: itemShot
    width: 272
    height: width
    color: "#eef0f1"

    property Shot shot: pointer
    property var shotDevice
    property var itemPassedWidth

    function handleState() {
        icon_state.visible = true
        rectangleOverlay.visible = false
        if (shot.state === Shared.SHOT_STATE_QUEUED) {
            icon_state.source = "qrc:/resources/minicons/queued.svg"
        } else if (shot.state === Shared.SHOT_STATE_OFFLOADING) {
            icon_state.source = "qrc:/resources/minicons/offloading.svg"
        } else if (shot.state === Shared.SHOT_STATE_ENCODING) {
            icon_state.source = "qrc:/resources/minicons/encoding.svg"
        } else if (shot.state === Shared.SHOT_STATE_DONE) {
            icon_state.visible = false
            image_overlay.source = "qrc:/icons/done.svg"
            rectangleOverlay.visible = true
        } else {
            icon_state.visible = false
        }
    }

    Connections {
        target: shot
        onStateUpdated: handleState()
    }

    Component.onCompleted: {
        text_top.text = name
        text_top.visible = false

        if (typeof currentDevice !== "undefined")
            shotDevice = currentDevice

        handleState()
        if (shot.previewVideo)
            image.source = "image://GridThumbnailer/" + shot.previewVideo
        else if (preview)
            image.source = "image://GridThumbnailer/" + preview

        text_right.visible = false
        text_left.visible = false
        if (type === Shared.SHOT_UNKNOWN) {
            icon_left.source = "qrc:/resources/minicons/unknown.svg"

            if (!preview && !shot.previewVideo)
                image.source = "qrc:/resources/other/placeholder_video.svg"
        } else if (type < Shared.SHOT_PICTURE) {
            if (duration > 0) {
                text_left.visible = true
                text_left.text = StringUtils.durationToString_condensed(duration)
            }
            icon_left.source = "qrc:/resources/minicons/video.svg"

            if (!preview && !shot.previewVideo)
                image.source = "qrc:/resources/other/placeholder_video.svg"
        } else {
            if (type >= Shared.SHOT_PICTURE_MULTI) {
                text_left.visible = true
                text_left.text = duration
                icon_left.source = "qrc:/resources/minicons/picture_multi.svg"

                if (!preview)
                    image.source = "qrc:/resources/other/placeholder_picture_multi.svg"
            } else {
                icon_left.source = "qrc:/resources/minicons/picture.svg"

                if (!preview)
                    image.source = "qrc:/resources/other/placeholder_picture.svg"
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

    Image {
        id: image
        anchors.fill: parent
        smooth: false
        antialiasing: false
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: "qrc:/resources/other/placeholder_loading.svg"

        sourceSize.width: 512
        sourceSize.height: 512
    }

    Image {
        id: icon_state
        width: 24
        height: 24
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 8
        fillMode: Image.PreserveAspectFit
    }

    MouseArea {
        id: mouseAreaItem
        anchors.fill: parent

        propagateComposedEvents: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        hoverEnabled: true
        onHoveredChanged: text_top.visible = !text_top.visible

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
                        image.source = "image://GridThumbnailer/" + shot.previewVideo + "@" + timecode_s
                    else if (preview)
                        image.source = "image://GridThumbnailer/" + preview + "@" + timecode_s
                }
            }
        }
        onEntered: {
            if (shot.type > Shared.SHOT_UNKNOWN &&
                shot.type < Shared.SHOT_PICTURE) {
                thumbTimer.start()
            }
        }
        onExited: {
            if (shot.type > Shared.SHOT_UNKNOWN &&
                shot.type < Shared.SHOT_PICTURE) {
                thumbId = 1
                thumbTimer.stop()
                if (shot.previewVideo)
                    image.source = "image://GridThumbnailer/" + shot.previewVideo
                else if (preview)
                    image.source = "image://GridThumbnailer/" + preview
            }
        }

        onClicked: {
            shotsview.currentIndex = index

            if (mouse.button === Qt.RightButton) {
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
                if (shotDevice) {
                    if (shotDevice.deviceStorage === 2) { // MTP
                        merge = false
                        encode = false
                    }
                    if (shotDevice.readOnly) {
                        remove = false
                    }
                } else {
                    copy = false
                    merge = false
                    encode = true
                }

                actionMenu.setMenuButtons(copy, merge, encode, remove)

                actionMenu.visible = true
                actionMenu.x = mouseAreaOutsideView.mouseX + 8
                actionMenu.y = mouseAreaOutsideView.mouseY + 8
            } else {
                actionMenu.visible = false
            }
        }
        onDoubleClicked: {
            // Show the "shot details" screen
            actionMenu.visible = false
            shotsview.currentIndex = index

            if (shotDevice)
                screenDevice.state = "stateMediaDetails"
            else
                screenLibrary.state = "stateMediaDetails"
        }
    }

    Text {
        id: text_top
        height: 20
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.top: parent.top
        anchors.topMargin: 8

        color: "#ffffff"
        clip: true
        text: name
        style: Text.Raised
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        font.bold: true
        font.pixelSize: 13
    }

    Rectangle {
        id: rectangleOverlay
        color: "#80ffffff"
        anchors.fill: parent

        Image {
            id: image_overlay
            x: 96
            y: 96
            width: 64
            height: 64
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            fillMode: Image.PreserveAspectCrop
            source: "qrc:/icons/done.svg"
        }
    }

    Rectangle {
        id: legendBottom
        height: 38
        color: "#00000000" // "#80e5e8e6"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0

        Text {
            id: text_left
            width: 124
            color: "#ffffff"
            text: qsTr("left")
            lineHeight: 1
            style: Text.Raised
            styleColor: "#000000"
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            font.bold: true
            anchors.left: icon_left.right
            anchors.leftMargin: 8
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 13
        }

        Text {
            id: text_right
            x: 142
            width: 124
            color: "#ffffff"
            text: qsTr("right")
            style: Text.Raised
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            font.bold: true
            anchors.right: icon_right.left
            anchors.rightMargin: 4
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 13
        }

        Image {
            id: icon_left
            width: 24
            height: 24
            sourceSize.width: 24
            sourceSize.height: 24
            fillMode: Image.PreserveAspectFit
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        Image {
            id: icon_right
            width: 24
            height: 24
            sourceSize.width: 24
            sourceSize.height: 24
            fillMode: Image.PreserveAspectFit
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 8
        }
    }
}
