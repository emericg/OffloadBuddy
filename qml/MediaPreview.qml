import QtQuick 2.12
import QtQuick.Controls 2.12
import QtMultimedia 5.12

import ThemeEngine 1.0
import com.offloadbuddy.shared 1.0
import "qrc:/js/UtilsNumber.js" as UtilsNumber
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: mediaArea
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: isFullScreen ? parent.right : infosGeneric.left
    anchors.bottom: parent.bottom
    anchors.margins: 16

    property bool isFullScreen: false
    //color: (isFullScreen || (shot && shot.fileType === Shared.FILE_PICTURE)) ? "transparent" : "black"

    ////////

    property string mode: ""

    property int startLimit: -1
    property int stopLimit: -1

    property bool hflipped: false
    property bool vflipped: false
    property int rotation: 0

    property real cropX: 0.0
    property real cropY: 0.0
    property real cropW: 1.0
    property real cropH: 1.0

    property int overlayHeight: overlays.height

    ////////

    function setImageMode() {
        //console.log("MediaPreview::setImageMode()  >  '" + shot.previewPhoto + "'")
        mode = "image"

        overlayTransform.visible = false
        overlayTransform.anchors.bottom = undefined
        overlayTransform.anchors.bottomMargin = 0
        overlayTransform.anchors.top = overlays.top
        overlayTransform.anchors.topMargin = 16

        overlayTrim.visible = false

        overlayCrop.editing = false

        imageOutput.visible = true
        videoOutput.visible = false

        if (shot.previewPhoto) {
            imageOutput.source = "file:///" + shot.previewPhoto
        } else {
            // error icon?
        }

        computeTransformation()

        computeOverlaySize()
    }

    function setVideoMode() {
        //console.log("MediaPreview::setVideoMode()  >  '" + shot.previewVideo + "'")
        mode = "video"

        overlayTransform.visible = false
        overlayTransform.anchors.top = undefined
        overlayTransform.anchors.topMargin = 0
        overlayTransform.anchors.bottom = overlays.bottom
        overlayTransform.anchors.bottomMargin = 56

        overlayTrim.visible = false

        overlayCrop.editing = false

        imageOutput.visible = false
        videoOutput.visible = true

        if (shot.previewVideo) {
            if (shot.chapterCount > 1) { // playlist
                //mode = "multivideo"
                videoPlayer.playlist = Qt.createQmlObject('import QtMultimedia 5.12; Playlist { id: playlist; }',
                                                          videoPlayer, "playlist")
                videoPlayer.playlist.clear()
                for (var i = 0; i < shot.chapterCount; i++)
                    videoPlayer.playlist.insertItem(i, "file:///" + shot.chapterPaths[i])
                videoPlayer.play()
            } else if (shot.previewVideo) { // single video
                videoPlayer.source = "file:///" + shot.previewVideo
            }
            timeline.visible = true
            cutline.visible = false
            cutline.first.value = 0
            cutline.second.value = 1
        } else {
            // error icon?
        }

        videoPlayer.pause()

        computeTransformation()

        computeOverlaySize()
    }

    ////////

    function setPause() {
        if (videoPlayer.isRunning) {
            videoPlayer.pause()
            videoPlayer.isRunning = false
        }
    }

    function setPlayPause() {
        if (mode === "video") {
            if (videoPlayer.isRunning) {
                videoPlayer.pause()
                videoPlayer.isRunning = false
            } else {
                videoPlayer.play()
                videoPlayer.isRunning = true
            }
        }
    }

    function toggleTrim() {
        //timeline.visible = !timeline.visible
        cutline.visible = !cutline.visible
        overlayTrim.visible = !overlayTrim.visible

        overlayTransform.visible = false
        overlayCrop.editing = false

        if (mediaArea.startLimit < 0) mediaArea.startLimit = 0
        if (mediaArea.stopLimit < 0) mediaArea.stopLimit = shot.duration
    }

    function toggleTransform() {
        timeline.visible = true
        cutline.visible = false
        overlayTrim.visible = false

        overlayTransform.visible = !overlayTransform.visible
        overlayCrop.editing = false
    }

    function toggleCrop() {
        timeline.visible = true
        cutline.visible = false
        overlayTrim.visible = false

        overlayTransform.visible = false
        overlayCrop.editing = !overlayCrop.editing
    }

    function toggleFullScreen() {
        if (typeof shot === "undefined" || !shot) return

        // Check if fullscreen is necessary (preview is already maxed out)
        if (!mediaArea.isFullScreen) {
            //console.log("Check if fullscreen is necessary: " + (shot.width / shot.height) + " vs " + (mediaArea.width / mediaArea.height))
            if ((shot.width / shot.height) < (mediaArea.width / mediaArea.height))
                return;
            // TODO if rotated
        }

        // Set fullscreen
        mediaArea.isFullScreen = !mediaArea.isFullScreen

        computeOverlaySize()
    }

    ////////

    function computeTransformation() {
        //console.log("computeTransformation(" + shot.transformation + ")")

        hflipped = false
        vflipped = false
        rotation = 0

        if (shot.transformation <= 1) {
            //1 = Horizontal (normal)
            setFlip("")
            setRotation(0)
        } else if (shot.transformation === 2) {
            //2 = Mirror horizontal
            setFlip("horizontal")
            setRotation(0)
        } else if (shot.transformation === 3) {
            //3 = Rotate 180
            setFlip("")
            setRotation(180)
        } else if (shot.transformation === 4) {
            //4 = Mirror vertical
            setFlip("vertical")
            setRotation(0)
        } else if (shot.transformation === 5) {
            //5 = Mirror horizontal and rotate 270 CW
            setFlip("horizontal")
            setRotation(270)
        } else if (shot.transformation === 6) {
            //6 = Rotate 90 CW
            setFlip("")
            setRotation(90)
        } else if (shot.transformation === 7) {
            //7 = Mirror horizontal and rotate 90 CW
            setFlip("horizontal")
            setRotation(90)
        } else if (shot.transformation === 8) {
            //8 = Rotate 270 CW
            setFlip("")
            setRotation(270)
        }
    }

    function computeOverlaySize() {
        if (typeof shot === "undefined" || !shot) return
        //console.log("computeSize()")

        var mediaWidth = shot.width
        var mediaHeight = shot.height

        // no metadata?
        if (!mediaWidth || !mediaHeight) {
            mediaWidth = output.width
            mediaHeight = output.height
        }

        // rotated?
        if ((mediaArea.rotation % 360 == 90) || (mediaArea.rotation % 360 == 270)) {
            var tmp = mediaWidth
            mediaWidth = mediaHeight
            mediaHeight = tmp
        }

        var media_ar = (mediaWidth / mediaHeight)
        var area_ar = (mediaArea.width / mediaArea.height)
        var area_width_ratio = (mediaArea.width / mediaWidth)
        var area_height_ratio = (mediaArea.height / mediaHeight)

        if (media_ar > area_ar) {
            //console.log("media_ar > area_ar")
            overlays.width = Math.round(mediaWidth * area_width_ratio)
            overlays.height = Math.round(mediaHeight * area_width_ratio)
        } else {
            //console.log("media_ar < area_ar")
            overlays.width = Math.round(mediaWidth * area_height_ratio)
            overlays.height = Math.round(mediaHeight * area_height_ratio)
        }
/*
        console.log("---------------------------")
        console.log("- media aspect ratio: " + media_ar)
        console.log("- area aspect ratio : " + area_ar)
        console.log("- area width ratio  : " + area_width_ratio)
        console.log("- area height ratio : " + area_height_ratio)
        console.log("> media size    : " + mediaWidth + "x" + mediaHeight)
        console.log("> mediaArea size: " + mediaArea.width + "x" + mediaArea.height)
        console.log("> overlays size      : " + overlays.width + "x" + overlays.height)
*/
        overlayCrop.load()
    }

    Matrix4x4 { id: noflip; matrix: Qt.matrix4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
    Matrix4x4 { id: vflip; matrix: Qt.matrix4x4(-1, 0, 0, output.width, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
    Matrix4x4 { id: hflip; matrix: Qt.matrix4x4(1, 0, 0, 0, 0, -1, 0, output.height, 0, 0, 1, 0, 0, 0, 0, 1) }
    Matrix4x4 { id: vhflip; matrix: Qt.matrix4x4(-1, 0, 0, output.width, 0, -1, 0, output.height, 0, 0, 1, 0, 0, 0, 0, 1) }

    function setFlip(value) {
        //console.log("setflip() " + value)

        if (value === "vertical")
            mediaArea.vflipped = !mediaArea.vflipped
        else if (value === "horizontal")
            mediaArea.hflipped = !mediaArea.hflipped

        if (mediaArea.vflipped && mediaArea.hflipped)
            output.transform = vhflip
        else if (mediaArea.vflipped)
            output.transform = vflip
        else if (mediaArea.hflipped)
            output.transform = hflip
        else
            output.transform = noflip

        // TODO // flip overlayCrop?
    }

    function addRotation(value) {
        //console.log("addRotation() " + value)

        mediaArea.rotation += value
        mediaArea.rotation = UtilsNumber.mod(mediaArea.rotation, 360)

        output.rotation = mediaArea.rotation

        if (output.rotation == 90 || output.rotation == 270) {
            output.scale = mediaArea.height / mediaArea.width
        } else {
            output.scale = 1
        }

        // TODO // rotate overlayCrop instead?
        mediaArea.cropX = 0.0
        mediaArea.cropY = 0.0
        mediaArea.cropW = 1.0
        mediaArea.cropH = 1.0

        computeOverlaySize()
    }

    function setRotation(value) {
        //console.log("setRotation() " + value)

        mediaArea.rotation = value
        mediaArea.rotation = UtilsNumber.mod(mediaArea.rotation, 360)

        output.rotation = mediaArea.rotation

        if (output.rotation == 90 || output.rotation == 270) {
            //output.scale = shot.height / shot.width
            output.scale = mediaArea.height / mediaArea.width
        } else {
            output.scale = 1
        }

        computeOverlaySize()
    }

    onWidthChanged: computeOverlaySize()
    onHeightChanged: computeOverlaySize()

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        anchors.fill: overlays
        color: "black"

        ImageSvg {
            width: 48; height: 48;
            anchors.centerIn: parent

            color: Theme.colorIcon
            source: "qrc:/assets/icons_material/baseline-hourglass_empty-24px.svg"
        }
    }

    Item {
        id: output
        anchors.fill: overlays

        Image {
            id: imageOutput
            anchors.fill: parent

            autoTransform: true
            fillMode: Image.Stretch

            sourceSize.width: output.width
            sourceSize.height: output.height
        }

        VideoOutput {
            id: videoOutput
            anchors.fill: parent

            autoOrientation: false // doesn't work anyway
            fillMode: Image.Stretch

            source: videoPlayer
            //flushMode: LastFrame // Qt 5.13
        }
    }

    MediaPlayer {
        id: videoPlayer
        volume: 0.5
        autoLoad: true
        autoPlay: true // will be paused immediately
        notifyInterval: 33
        //playlist: Playlist { id: playlist; }

        property bool isRunning: false

        onError: {
            if (Qt.platform.os === "windows")
                mediaBanner.openMessage(qsTr("Codec pack installed?"))
            else
                mediaBanner.openMessage(qsTr("Oooops..."))
        }
        onPlaying: {
            buttonPlay.source = "qrc:/assets/icons_material/baseline-pause-24px.svg"
        }
        onPaused: {
            buttonPlay.source = "qrc:/assets/icons_material/baseline-play_arrow-24px.svg"
        }
        onStopped: {
            if (videoPlayer.position >= shot.duration) { // EOF
                isRunning = false
                videoPlayer.seek(0)
                videoPlayer.play()
                videoPlayer.pause()

                // Note // on Qt 5.13+, same thing could be achieved with:
                //videoOutput.flushMode: LastFrame
            }
        }
        onPlaylistChanged: {
            //console.log("onPlaylistChanged()")

            // reset player settings
            videoPlayer.isRunning = false

            mediaBanner.close()
            mediaArea.startLimit = -1
            mediaArea.stopLimit = -1

            mediaArea.hflipped = false
            mediaArea.vflipped = false
            mediaArea.rotation = 0

            mediaArea.cropX = 0.0
            mediaArea.cropY = 0.0
            mediaArea.cropW = 1.0
            mediaArea.cropH = 1.0
            overlayCrop.load()
        }
        onSourceChanged: {
            //console.log("onSourceChanged()")

            // reset player settings
            videoPlayer.isRunning = false

            mediaBanner.close()
            mediaArea.startLimit = -1
            mediaArea.stopLimit = -1

            mediaArea.hflipped = false
            mediaArea.vflipped = false
            mediaArea.rotation = 0

            mediaArea.cropX = 0.0
            mediaArea.cropY = 0.0
            mediaArea.cropW = 1.0
            mediaArea.cropH = 1.0
            overlayCrop.load()
        }
        onVolumeChanged: {
            //
        }
        onPositionChanged: {
            if (shot) {
                var videoPlayerPosition = videoPlayer.position
                if (shot.chapterCount > 1) {
                    for (var i = 0; i < videoPlayer.playlist.currentIndex && i < videoPlayer.playlist.itemCount; i++) {
                        videoPlayerPosition += shot.chapterDurations[i]
                    }
                }
                timeline.value = (videoPlayerPosition / shot.duration)
                timecode.text = UtilsString.durationToString_ISO8601_compact(videoPlayerPosition) + " / " + UtilsString.durationToString_ISO8601_compact(shot.duration)
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
            anchors.fill: parent
            z: 1
            opacity: 0.33
            color: "red"
            border.color: "red"
            border.width: 2
        }
*/
        ////////////////

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            //propagateComposedEvents: true

            property bool hovered: false

            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onPressed: {
                // play/pause
                if (pressedButtons & Qt.RightButton) {
                    setPlayPause();
                    return;
                }
            }
            onDoubleClicked: {
                if (pressedButtons & Qt.LeftButton) {
                    toggleFullScreen()
                }
            }
            onEntered: { hovered = true; }
            onExited: { hovered = false; }
        }


        ////////////////

        ResizeWidget {
            id: overlayCrop
            anchors.fill: parent
        }

        ////////////////

        Item {
            id: overlayTrim
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 56

            width: overlayTrimText.width + 16
            height: 32
            visible: false

            Rectangle {
                anchors.fill: parent
                radius: Theme.componentRadius
                color: "#222"
                opacity: 0.8
            }

            Text {
                id: overlayTrimText
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter

                text: qsTr("trim from ") + UtilsString.durationToString_ISO8601_full(mediaArea.startLimit) + qsTr(" to ") + UtilsString.durationToString_ISO8601_full(mediaArea.stopLimit)
                color: "white"
                font.bold: true
                font.pixelSize: 15
            }
        }

        Row {
            id: overlayTransform
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.bottomMargin: 56

            visible: false
            spacing: 4

            ItemImageButton {
                //id: buttonRotateSave
                iconColor: "white"
                background: true
                backgroundColor: "#222"
                highlightColor: "green"
                highlightMode: "color"
                visible: (output.rotation != 0 || mediaArea.vflipped || mediaArea.hflipped)
                source: "qrc:/assets/icons_material/baseline-save-24px.svg"
                //onClicked: shot.saveRotation(angle)
            }
            ItemImageButton {
                //id: buttonRotateClear
                iconColor: "white"
                background: true
                backgroundColor: "#222"
                highlightMode: "color"
                visible: (output.rotation != 0 || mediaArea.vflipped || mediaArea.hflipped)
                source: "qrc:/assets/icons_material/baseline-close-24px.svg"
                onClicked: computeTransformation()
            }
            ItemImageButton {
                //id: buttonRotateLeft
                iconColor: (output.rotation >= 180) ? Theme.colorPrimary : "white"
                background: true
                backgroundColor: "#222"
                highlightMode: "color"
                source: "qrc:/assets/icons_material/baseline-rotate_left-24px.svg"
                onClicked: mediaArea.addRotation(-90)
            }
            ItemImageButton {
                //id: buttonRotateRight
                iconColor: (output.rotation > 0 && output.rotation <= 180) ? Theme.colorPrimary : "white"
                background: true
                backgroundColor: "#222"
                highlightMode: "color"
                source: "qrc:/assets/icons_material/baseline-rotate_right-24px.svg"
                onClicked: mediaArea.addRotation(+90)
            }
            ItemImageButton {
                //id: buttonFlipV
                iconColor: (mediaArea.vflipped) ? Theme.colorPrimary : "white"
                background: true
                backgroundColor: "#222"
                highlightMode: "color"
                source: "qrc:/assets/icons_material/baseline-flip-24px.svg"
                onClicked: mediaArea.setFlip("vertical")
            }
            ItemImageButton {
                //id: buttonFlipH
                rotation: 90
                iconColor: (mediaArea.hflipped) ? Theme.colorPrimary : "white"
                background: true
                backgroundColor: "#222"
                highlightMode: "color"
                source: "qrc:/assets/icons_material/baseline-flip-24px.svg"
                onClicked: mediaArea.setFlip("horizontal")
            }
        }

        ////////////////

        ItemBannerMessage {
            id: mediaBanner
        }

        ////////////////

        Item {
            id: mediaControls
            height: 40
            visible: (videoOutput.visible /*&& mouseArea.hovered*/)

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
                color: "#222"
            }

            ////

            RangeSliderPlayer {
                id: cutline
                height: 40
                width: mediaControls.width
                anchors.top: parent.top
                anchors.topMargin: -(height/2 + 2)
                anchors.left: parent.left
                anchors.right: parent.right

                from: 0
                to: 1
                first.value: 0
                second.value: 1

                first.onMoved: {
                    mediaArea.startLimit = shot.duration * first.value
                    mediaControls.sseeekk(first.value)
                }
                second.onMoved: {
                    mediaArea.stopLimit = shot.duration * second.value
                    mediaControls.sseeekk(second.value)
                }
            }
            SliderPlayer {
                id: timeline
                height: 12
                width: mediaControls.width
                anchors.top: parent.top
                anchors.topMargin: -(height/2 + 2)
                anchors.left: parent.left
                anchors.leftMargin: -6
                anchors.right: parent.right
                anchors.rightMargin: -6

                z: 10
                from: 0
                to: 1

                onMoved: mediaControls.sseeekk(value)
            }

            ////

            Rectangle {
                x: (parent.width * (mediaArea.startLimit / shot.duration))
                width: (parent.width * ((mediaArea.stopLimit - mediaArea.startLimit) / shot.duration))
                height: 4
                visible: (mediaArea.startLimit >= 0 && mediaArea.stopLimit > 0 && mediaArea.stopLimit < shot.duration)
                color: Theme.colorSecondary

                Rectangle {
                    anchors.left: parent.left
                    width: 3
                    height: 6
                    color: "white"
                }
                Rectangle {
                    anchors.right: parent.right
                    width: 3
                    height: 6
                    color: "white"
                }
            }
/*
            Repeater {
                id: markersDuration
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                model: 40
                Rectangle {
                    x: (parent.width / 40) * index
                    width: 1
                    height: (index % 2 == 0) ? 6 : 3
                }
            }
*/
            Repeater {
                id: markersChapters
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                model: shot.chapterDurations
                Rectangle {
                    x: {
                        var pos = modelData
                        for (var i = 1; i <= index; i++) {
                            pos += shot.chapterDurations[i-1]
                        }
                        return (parent.width / (shot.duration / pos))
                    }
                    visible: (index+1 < shot.chapterCount)
                    width: 3
                    height: 6
                    color: "black"
                }
            }
            Repeater {
                id: markersHiLights
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                model: shot.hilight
                Rectangle {
                    x: (parent.width / (shot.duration / modelData))
                    width: 3
                    height: 6
                    color: "orange"
                }
            }

            ////

            function sseeekk(value) {
                var seekpoint = shot.duration * value
                if (seekpoint === videoPlayer.position) return

                var wasRunning = videoPlayer.isRunning
                if (Qt.platform.os === "osx") {
                    if (wasRunning) {
                        videoPlayer.pause()
                        videoPlayer.isRunning = false
                    }
                }

                if (shot.chapterCount > 1) {
                    var doff = 0;
                    var seekindex = 0;
                    for (var i = 0; i < videoPlayer.playlist.itemCount; i++) {
                        if (seekpoint > doff && seekpoint < (doff + shot.chapterDurations[i])) {
                            seekpoint -= doff
                            seekindex = i
                            break
                        }
                        doff += shot.chapterDurations[i]
                    }

                    if (videoPlayer.playlist.currentIndex !== seekindex)
                        videoPlayer.playlist.currentIndex = seekindex
                }

                videoPlayer.seek(seekpoint)

                if (Qt.platform.os === "osx") {
                    if (wasRunning) {
                        videoPlayer.play()
                        videoPlayer.isRunning = true
                    }
                }
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16

                ItemImageButton {
                    id: buttonPlay
                    width: 40
                    height: 40

                    iconColor: "white"
                    highlightColor: Theme.colorPrimary
                    highlightMode: "color"

                    source: "qrc:/assets/icons_material/baseline-play_arrow-24px.svg"
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

                MouseArea {
                    width: isHovered ? (40+128+4) : (40)
                    height: 40
                    clip: true
                    Behavior on width { NumberAnimation { duration: 133 } }

                    property bool isHovered: false
                    hoverEnabled: true
                    onEntered: isHovered = true
                    onExited: isHovered = false
                    propagateComposedEvents: true

                    ItemImageButton {
                        id: buttonSound
                        width: 36
                        height: 36
                        anchors.left: parent.left
                        anchors.leftMargin: 0
                        anchors.verticalCenter: parent.verticalCenter

                        iconColor: "white"
                        highlightColor: Theme.colorPrimary
                        highlightMode: "color"

                        source: (soundline.value === 0) ? "qrc:/assets/icons_material/baseline-volume_off-24px.svg" : "qrc:/assets/icons_material/baseline-volume_up-24px.svg"
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
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter

                        from: 0
                        to: 1
                        value: videoPlayer.volume
                        onValueChanged: videoPlayer.volume = value
                    }
                }

                Text {
                    id: timecode
                    anchors.verticalCenter: parent.verticalCenter

                    text: "0:12 / 0:24"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 15
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                ItemImageButton {
                    id: buttonToggleTrim
                    width: 36
                    height: 36
                    anchors.verticalCenter: parent.verticalCenter

                    iconColor: cutline.visible ? Theme.colorPrimary : "white"
                    highlightColor: Theme.colorPrimary
                    highlightMode: "color"

                    source: "qrc:/assets/icons_material/baseline-timer-24px.svg"
                    onClicked: toggleTrim()
                }
                ItemImageButton {
                    id: buttonToggleTransform
                    width: 36
                    height: 36
                    anchors.verticalCenter: parent.verticalCenter

                    iconColor: overlayTransform.visible ? Theme.colorPrimary : "white"
                    highlightColor: Theme.colorPrimary
                    highlightMode: "color"

                    source: "qrc:/assets/icons_material/baseline-rotate_90_degrees_ccw-24px.svg"
                    onClicked: toggleTransform()
                }
                ItemImageButton {
                    id: buttonToggleCrop
                    width: 36
                    height: 36
                    anchors.verticalCenter: parent.verticalCenter

                    iconColor: overlayCrop.editing ? Theme.colorPrimary : "white"
                    highlightColor: Theme.colorPrimary
                    highlightMode: "color"

                    source: "qrc:/assets/icons_material/baseline-crop-24px.svg"
                    onClicked: toggleCrop()
                }
                ItemImageButton {
                    id: buttonScreenshot
                    width: 36
                    height: 36
                    anchors.verticalCenter: parent.verticalCenter

                    visible: false
                    iconColor: "white"
                    highlightColor: Theme.colorPrimary
                    highlightMode: "color"

                    source: "qrc:/assets/icons_material/outline-camera_alt-24px.svg"
                    onClicked: {
                        //
                    }
                }
                ItemImageButton {
                    id: buttonFullscreen
                    width: 48
                    height: 48
                    anchors.verticalCenter: parent.verticalCenter

                    iconColor: "white"
                    highlightColor: Theme.colorPrimary
                    highlightMode: "color"

                    source: isFullScreen ? "qrc:/assets/icons_material/baseline-fullscreen_exit-24px.svg"
                                         : "qrc:/assets/icons_material/baseline-fullscreen-24px.svg"
                    onClicked: toggleFullScreen()
                }
            }
        }
    }
}
