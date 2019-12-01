import QtQuick 2.9
import QtQuick.Controls 2.2
import QtMultimedia 5.9

import ThemeEngine 1.0
import com.offloadbuddy.shared 1.0
import "qrc:/js/UtilsNumber.js" as UtilsNumber
import "qrc:/js/UtilsString.js" as UtilsString

Rectangle {
    id: mediaArea
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: infosGeneric.left
    anchors.margins: 16

    color: (isFullScreen || (shot && shot.fileType === Shared.FILE_PICTURE)) ? "transparent" : "black"

    property bool isFullScreen: false
    property int startLimit: -1
    property int stopLimit: -1

    function setImageMode() {
        console.log("MediaPreview::setImageMode()  >  '" + shot.previewPhoto + "'")

        output.scale = 1
        output.rotation = 0
        output.transform = noflip
        overlayRotations.visible = false

        imageOutput.visible = true
        mediaOutput.visible = false

        if (shot.previewPhoto) {
            imageOutput.source = "file:///" + shot.previewPhoto
        } else {
            // error icon?
        }

        computeSize(shot.width, shot.height)
    }

    function setVideoMode() {
        console.log("MediaPreview::setVideoMode()  >  '" + shot.previewVideo + "'")

        output.scale = 1
        output.rotation = 0
        output.transform = noflip
        overlayRotations.visible = false

        imageOutput.visible = false
        mediaOutput.visible = true

        if (shot.previewVideo) {
            videoPlayer.source = "file:///" + shot.previewVideo
            timeline.visible = true
            cutline.visible = false
            cutline.first.value = 0
            cutline.second.value = 1
        } else {
            // error icon?
        }

        computeSize(shot.width, shot.height)

        videoPlayer.pause()
    }

    function setPause() {
        if (videoPlayer.isRunning) {
            videoPlayer.pause()
            videoPlayer.isRunning = false
        }
    }

    function setPlayPause() {
        if (videoPlayer.isRunning) {
            videoPlayer.pause()
            videoPlayer.isRunning = false
        } else {
            videoPlayer.play()
            videoPlayer.isRunning = true
        }
    }

    function toggleRotate() {
        overlayRotations.visible = !overlayRotations.visible
    }

    function toogleFullScreen() {
        // Check if fullscreen is necessary (preview is already maxed out)
        if (!mediaArea.isFullScreen) {
            //console.log("Check if fullscreen is necessary: " + (shot.width / shot.height) + " vs " + (mediaArea.width / mediaArea.height))
            if ((shot.width / shot.height) < (mediaArea.width / mediaArea.height))
                return
        }

        // Set fullscreen
        mediaArea.isFullScreen = !mediaArea.isFullScreen

        if (!mediaArea.isFullScreen) {
            buttonFullscreen.source = "qrc:/icons_material/baseline-fullscreen-24px.svg"
            infosGeneric.visible = true
            //infosFiles.visible = true
            mediaArea.anchors.right = infosGeneric.left
/*
            mediaControls.anchors.top = mediaOutput.bottom
            mediaControls.anchors.topMargin = 0
            mediaControls.anchors.bottom = undefined
            mediaControls.anchors.bottomMargin = undefined
*/
        } else {
            buttonFullscreen.source = "qrc:/icons_material/baseline-fullscreen_exit-24px.svg"
            infosGeneric.visible = false
            //infosFiles.visible = false
            mediaArea.anchors.right = contentOverview.right
/*
            mediaControls.anchors.top = undefined
            mediaControls.anchors.topMargin = undefined
            mediaControls.anchors.bottom = mediaOutput.bottom
            mediaControls.anchors.bottomMargin = 0
*/
        }

        computeSize(shot.width, shot.height)

        //if (videoPlayer.position > 0)
        //    timelinePosition.width = timeline.width * (videoPlayer.position / videoPlayer.duration)
    }

    function computeSize(mediaWidth, mediaHeight) {
        //console.log("Check if fullscreen is necessary: " + (shot.width / shot.height) + " vs " + (mediaArea.width / mediaArea.height))
        //if ((shot.width / shot.height) < (mediaArea.width / mediaArea.height))

        var media_ar = (mediaWidth / mediaHeight)
        //console.log("media ratio: " + media_ar)
        var area_ar = (mediaArea.width / mediaArea.height)
        //console.log("area ratio: " + area_ar)

        var ratio = (mediaArea.width / mediaWidth)
        //console.log("mediaArea ratio: " + ratio)

        if (media_ar > area_ar) {
            //console.log(">1")
            overlays.width = Math.ceil(mediaWidth * ratio)
            overlays.height = Math.ceil(mediaHeight * ratio)
        } else {
            //console.log(">2")
            overlays.width = Math.ceil(mediaWidth * (mediaArea.height / mediaHeight)) + 1
            overlays.height = Math.ceil(mediaHeight * (mediaArea.height / mediaHeight))
        }

        //console.log("> media size    : " + mediaWidth + "x" + mediaHeight)
        //console.log("> mediaArea size: " + mediaArea.width + "x" + mediaArea.height)
        //console.log("> poc size      : " + overlays.width + "x" + overlays.height)
    }

    Matrix4x4 { id: noflip; matrix: Qt.matrix4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
    Matrix4x4 { id: vflip; matrix: Qt.matrix4x4(-1, 0, 0, output.width, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
    Matrix4x4 { id: hflip; matrix: Qt.matrix4x4(1, 0, 0, 0, 0, -1, 0, output.height, 0, 0, 1, 0, 0, 0, 0, 1) }
    Matrix4x4 { id: vhflip; matrix: Qt.matrix4x4(-1, 0, 0, output.width, 0, -1, 0, output.height, 0, 0, 1, 0, 0, 0, 0, 1) }

    function setFlip(value) {
        console.log("setflip() " + value)

        if (value === "vertical")
            output.vflipped = !output.vflipped
        if (value === "horizontal")
            output.hflipped = !output.hflipped

        if (output.vflipped && output.hflipped)
            output.transform = vhflip
        else if (output.vflipped)
            output.transform = vflip
        else if (output.hflipped)
            output.transform = hflip
        else
            output.transform = noflip
    }

    function setRotation(value) {
        console.log("setRotation() " + value)

        output.rotation += value
        output.rotation = UtilsNumber.mod(output.rotation, 360)

        if (output.rotation == 90 || output.rotation == 270) {
            output.scale = shot.height / shot.width
        } else {
            output.scale = 1
        }
    }

    onWidthChanged: if (shot) computeSize(shot.width, shot.height)
    onHeightChanged: if (shot) computeSize(shot.width, shot.height)

    ////////////////////////////////////////////////////////////////////////////

    Item {
        id: output
        anchors.fill: parent

        property bool vflipped: false
        property bool hflipped: false

        Image {
            id: imageOutput
            anchors.fill: parent
            autoTransform: true
            fillMode: Image.PreserveAspectFit

            sourceSize.width: if (shot) shot.width / 2
            sourceSize.height: if (shot) shot.height / 2
        }

        VideoOutput {
            id: mediaOutput
            source: videoPlayer

            anchors.fill: parent
            anchors.bottomMargin: 0 //mediaControls.visible ? 40 : 0

            property int clipStart: 0
            property int clipStop: (shot) ? shot.duration : 0

            MediaPlayer {
                id: videoPlayer
                volume: 0.5
                autoPlay: true // will be paused immediately
                notifyInterval: 33

                property bool isRunning: false
                onError: {
                    if (Qt.platform.os === "windows")
                        mediaBanner.openMessage(qsTr("Codec pack installed?"))
                    else
                        mediaBanner.openMessage(qsTr("Oooops..."))
                }
                onPlaying: {
                    buttonPlay.source = "qrc:/icons_material/baseline-pause-24px.svg"
                }
                onPaused: {
                    buttonPlay.source = "qrc:/icons_material/baseline-play_arrow-24px.svg"
                }
                onStopped: {
                    if (videoPlayer.position >= videoPlayer.duration) { // EOF
                        isRunning = false
                        videoPlayer.seek(0)
                        videoPlayer.pause()
                    }
                }
                onSourceChanged: {
                    //videoPlayer.stop()
                    isRunning = false
                    mediaArea.startLimit = -1
                    mediaArea.stopLimit = -1
                    //timelineLimitStart.width = 0
                    //timelineLimitStop.width = 0
                    //timelinePosition.width = 0
                    mediaBanner.close()
                }
                onVolumeChanged: {
                    //soundlinePosition.width = (soundline.width * volume)
                }
                onPositionChanged: {
                    //timelinePosition.width = timeline.width * (videoPlayer.position / videoPlayer.duration)
                    timeline.value = (videoPlayer.position / videoPlayer.duration)
                    timecode.text = UtilsString.durationToString_ISO8601_compact(videoPlayer.position) + " / " + UtilsString.durationToString_ISO8601_compact(videoPlayer.duration)
                }
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Item {
        id: overlays
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
/*
        Rectangle {
            id: poc
            z: 2
            color: "transparent"
            border.color: "red"
            border.width: 4
        }
*/
        ////////////////

        Item {
            id: overlayRotations
            anchors.fill: parent
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16

            visible: false // mouseArea.hovered
            opacity: 0.66

            Row {
                id: row
                Column {
                    ItemImageButton {
                        id: buttonRotateLeft
                        width: 40
                        height: 40

                        background: true
                        iconColor: "white"
                        highlightColor: Theme.colorForeground
                        source: "qrc:/icons_material/baseline-rotate_left-24px.svg"
                        onClicked: mediaArea.setRotation(-90)
                    }
                    ItemImageButton {
                        id: buttonRotateRight
                        width: 40
                        height: 40

                        background: true
                        iconColor: "white"
                        highlightColor: Theme.colorForeground
                        source: "qrc:/icons_material/baseline-rotate_right-24px.svg"
                        onClicked: mediaArea.setRotation(+90)
                    }
                }
                Column {
                    ItemImageButton {
                        id: buttonFlipV
                        width: 40
                        height: 40

                        background: true
                        iconColor: "white"
                        highlightColor: Theme.colorForeground
                        source: "qrc:/icons_material/baseline-flip-24px.svg"
                        onClicked: mediaArea.setFlip("vertical")
                    }
                    ItemImageButton {
                        id: buttonFlipH
                        width: 40
                        height: 40
                        rotation: 90

                        background: true
                        iconColor: "white"
                        highlightColor: Theme.colorForeground
                        source: "qrc:/icons_material/baseline-flip-24px.svg"
                        onClicked: mediaArea.setFlip("horizontal")
                    }
                }
            }
            ItemImageButton {
                id: buttonRotateSave
                width: 40
                height: 40
                anchors.horizontalCenter: row.horizontalCenter
                anchors.top: row.bottom

                background: true
                iconColor: "green"
                highlightColor: Theme.colorForeground
                visible: (output.rotation != 0 || output.vflipped || output.hflipped)
                source: "qrc:/icons_material/baseline-save-24px.svg"
                //onClicked: shot.saveRotation(angle)
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true

            property bool hovered: false

            onDoubleClicked: toogleFullScreen()
            onEntered: { hovered = true; }
            onExited: { hovered = false; }
        }

        ////////////////

        ItemBannerMessage {
            id: mediaBanner
        }

        ////////////////

        Item {
            id: mediaControls
            height: 40
            visible: (mediaOutput.visible /*&& mouseArea.hovered*/)

            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0

            Rectangle {
                id: mediaControlsBackground
                anchors.fill: parent
                opacity: 0.9
                color: "#222222"
            }

            RangeSliderThemed {
                id: cutline
                height: 12
                width: mediaControls.width
                anchors.top: parent.top
                anchors.topMargin: -(height/2 + 2)
                anchors.left: parent.left
                anchors.leftMargin: -6
                anchors.right: parent.right
                anchors.rightMargin: -6

                from: 0
                to: 1
                first.value: 0
                second.value: 1

                first.onMoved: {
                    mediaArea.startLimit = videoPlayer.duration * first.value
                    mediaControls.sseekk(first.value)
                }
                second.onMoved: {
                    mediaArea.stopLimit = videoPlayer.duration * second.value
                    mediaControls.sseekk(second.value)
                }
            }
            SliderThemed {
                id: timeline
                height: 12
                width: mediaControls.width
                anchors.top: parent.top
                anchors.topMargin: -(height/2 + 2)
                anchors.left: parent.left
                anchors.leftMargin: -6
                anchors.right: parent.right
                anchors.rightMargin: -6

                from: 0
                to: 1

                onMoved: mediaControls.sseekk(value)
            }

            function sseekk(value) {
                var wasRunning = videoPlayer.isRunning
                if (Qt.platform.os === "osx") {
                    if (wasRunning) {
                        videoPlayer.pause()
                        videoPlayer.isRunning = false
                    }
                }

                videoPlayer.seek(videoPlayer.duration * value)

                if (Qt.platform.os === "osx") {
                    if (wasRunning) {
                        videoPlayer.play()
                        videoPlayer.isRunning = true
                    }
                }
            }

            ItemImageButton {
                id: buttonPlay
                width: 40
                height: 40
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                iconColor: "white"
                highlightColor: Theme.colorPrimary
                highlightMode: "color"

                source: "qrc:/icons_material/baseline-play_arrow-24px.svg"
                onClicked: {
                    if (videoPlayer.isRunning) {
                        videoPlayer.pause()
                        videoPlayer.isRunning = false
                    } else {
                        videoPlayer.play()
                        videoPlayer.isRunning = true
                    }
                }
            }
            ItemImageButton {
                id: buttonSound
                width: 36
                height: 36
                anchors.left: buttonPlay.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                iconColor: "white"
                highlightColor: Theme.colorPrimary
                highlightMode: "color"

                source: "qrc:/icons_material/baseline-volume_up-24px.svg"
                property real savedVolume: videoPlayer.volume
                onClicked: {
                    if (videoPlayer.volume) {
                        savedVolume = videoPlayer.volume
                        videoPlayer.volume = 0
                    } else {
                        videoPlayer.volume = savedVolume
                    }
                }
            }
            SliderThemed {
                id: soundline
                width: 128
                anchors.left: buttonSound.right
                anchors.leftMargin: 0
                anchors.verticalCenter: parent.verticalCenter

                from: 0
                to: 1
                value: videoPlayer.volume
                onValueChanged: videoPlayer.volume = value
            }

            Text {
                id: timecode
                anchors.left: soundline.right
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter

                text: "0:12 / 0:24"
                color: "white"
                font.bold: true
                font.pixelSize: 15
            }

            ItemImageButton {
                id: buttonToggleRotate
                width: 36
                height: 36
                anchors.right: buttonToggleCut.left
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                iconColor: overlayRotations.visible ? "yellow" : "white"
                highlightColor: Theme.colorPrimary
                highlightMode: "color"

                source: "qrc:/icons_material/baseline-rotate_90_degrees_ccw-24px.svg"
                onClicked: {
                    overlayRotations.visible = !overlayRotations.visible
                }
            }
            ItemImageButton {
                id: buttonToggleCut
                width: 36
                height: 36
                anchors.right: buttonScreenshot.left
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                iconColor: cutline.visible ? "yellow" : "white"
                highlightColor: Theme.colorPrimary
                highlightMode: "color"

                source: "qrc:/icons_material/baseline-flip-24px.svg"
                onClicked: {
                    timeline.visible = !timeline.visible
                    cutline.visible = !cutline.visible
                }
            }
            ItemImageButton {
                id: buttonScreenshot
                width: 36
                height: 36
                anchors.right: buttonFullscreen.left
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                iconColor: "white"
                highlightColor: Theme.colorPrimary
                highlightMode: "color"

                source: "qrc:/icons_material/outline-camera_alt-24px.svg"
                onClicked: {
                    //
                }
            }
            ItemImageButton {
                id: buttonFullscreen
                width: 40
                height: 40
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                iconColor: "white"
                highlightColor: Theme.colorPrimary
                highlightMode: "color"

                source: "qrc:/icons_material/baseline-fullscreen-24px.svg"
                onClicked: mediaArea.toogleFullScreen()
            }
        }
    }
}
