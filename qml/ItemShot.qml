import QtQuick 2.10
import QtQuick.Controls 2.3

import com.offloadbuddy.style 1.0
import com.offloadbuddy.shared 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: itemShot
    width: 256
    height: width
    color: "#eef0f1"

    property Shot shot: pointer
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

        handleState()

        if (preview) {
            image.source = "file:///" + preview
        }

        text_right.visible = false
        text_left.visible = false
        if (type < Shared.SHOT_PICTURE) {
            if (duration > 0) {
                text_left.visible = true
                text_left.text = StringUtils.durationToString_short(duration)
            }
            icon_left.source = "qrc:/resources/minicons/video.svg"

            if (!preview)
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
        //source: "qrc:/resources/other/placeholder_picture.svg"

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

        hoverEnabled: true
        onHoveredChanged: text_top.visible = !text_top.visible
        propagateComposedEvents: true

        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: {
            shotsview.currentIndex = index

            if (mouse.button === Qt.RightButton) {
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
            screenDevice.state = "shotdetails"
        }
    }

    Text {
        id: text_top
        x: 8
        y: 0
        height: 20
        color: "#ffffff"
        text: name
        style: Text.Raised
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.left: parent.left
        anchors.leftMargin: 8
        font.bold: true
        anchors.top: parent.top
        anchors.topMargin: 8
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
            anchors.leftMargin: 4
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
            fillMode: Image.PreserveAspectFit
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        Image {
            id: icon_right
            width: 24
            height: 24
            fillMode: Image.PreserveAspectFit
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 8
        }
    }
}
