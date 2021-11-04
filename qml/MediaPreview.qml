import QtQuick 2.12
import QtQuick.Controls 2.12
import QtMultimedia 5.12 // Qt5
//import QtMultimedia // Qt6

import ThemeEngine 1.0
import MediaUtils 1.0

import "qrc:/js/UtilsMedia.js" as UtilsMedia
import "qrc:/js/UtilsNumber.js" as UtilsNumber
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: mediaArea
    anchors.fill: parent
    anchors.margins: isFullScreen ? 0 : 16
    anchors.rightMargin: isFullScreen ? 0 : (isFullSize ? 16 : infosGeneric.width + 16)

    focus: isFullScreen

    // keep that in UI
    property string mode: ""
    property bool isFullScreen: false
    property bool isFullSize: false
    property int overlayHeight: overlays.height

    ////////////////////////////////////////////////////////////////////////////

    function setImageMode() {
        if (shot.duration > 1) {
            //console.log("MediaPreview::setImageMode() > timelapse mode")
            mode = "timelapse"
        } else {
            //console.log("MediaPreview::setImageMode()  >  '" + shot.previewPhoto + "'")
            mode = "image"
        }

        imageOutput.visible = true
        videoOutput.visible = false

        mediaBanner.close()

        overlayTransform.visible = false
        overlayTransform.anchors.bottom = undefined
        overlayTransform.anchors.bottomMargin = 0
        overlayTransform.anchors.top = overlays.top
        overlayTransform.anchors.topMargin = 16

        overlayTrim.visible = false

        overlayCrop.editing = false
        overlayCrop.load()

        if (shot.previewPhoto) {
            if (shot.mediaPosition > 0 && shot.previewTimelapse[shot.mediaPosition]) {
                imageOutput.source = "file:///" + shot.previewTimelapse[shot.mediaPosition]
            } else {
                imageOutput.source = "file:///" + shot.previewPhoto
            }
        } else {
            // error icon?
        }

        computeTransformation()

        computeOverlaySize()
    }

    ////////

    function setVideoMode() {
        //console.log("MediaPreview::setVideoMode()  >  '" + shot.previewVideo + "'")
        mode = "video"

        imageOutput.visible = false
        videoOutput.visible = true

        overlayTransform.visible = false
        overlayTransform.anchors.top = undefined
        overlayTransform.anchors.topMargin = 0
        overlayTransform.anchors.bottom = overlays.bottom
        overlayTransform.anchors.bottomMargin = 56

        overlayTrim.visible = false

        overlayCrop.editing = false

        if (shot.previewVideo) {
            if (shot.chapterCount > 1) { // playlist
                //mode = "multivideo"
                videoPlayer.playlist = Qt.createQmlObject('import QtMultimedia 5.12; Playlist { id: playlist; }',
                                                          videoPlayer, "playlist")
                videoPlayer.playlist.clear()
                for (var i = 0; i < shot.chapterCount; i++)
                    videoPlayer.playlist.insertItem(i, "file:///" + shot.chapterPaths[i])
            } else if (shot.previewVideo) { // single video
                videoPlayer.source = "file:///" + shot.previewVideo
            }

            videoPlayer.play()
            restorePosition()
            videoPlayer.pause()

            timeline.visible = true
            cutline.visible = false
        } else {
            // error icon?
        }

        computeTransformation()

        computeOverlaySize()
    }

    ////////////////////////////////////////////////////////////////////////////

    function setPause() {
        if (mode === "timelapse") {
            timerTimelapse.stop()
        }
        if (mode === "video") {
            if (videoPlayer.isRunning) {
                videoPlayer.pause()
                videoPlayer.isRunning = false
            }
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
        if (mode === "timelapse") {
            if (timerTimelapse.running)
                timerTimelapse.stop()
            else
                timerTimelapse.start()
        }
    }

    ////////

    function savePosition() {
        if (videoPlayer.position > 0) {
            if (shot.chapterCount === 1) {
                shot.mediaPosition = videoPlayer.position
            } else if (shot.chapterCount > 1) {
                var pos = videoPlayer.position
                for (var i = 0; i < videoPlayer.playlist.currentIndex; i++) {
                    pos += shot.chapterDurations[i]
                }
                shot.mediaPosition = pos
            }
            //console.log("position saved: " + shot.mediaPosition)
        }
    }
    function restorePosition() {
        if (shot.mediaPosition > 0 && shot.mediaPosition < shot.duration) {
            mediaControls.seek_ms(shot.mediaPosition)
            //console.log("position restored: " + shot.mediaPosition)
        }
    }

    ////////

    function toggleTrim() {
        if (shot.trimStart > 0)  cutline.first.value = (shot.trimStart / shot.duration)
        else cutline.first.value = 0
        if (shot.trimStop > 0) cutline.second.value = (shot.trimStop / shot.duration)
        else cutline.second.value = 1
        cutline.visible = !cutline.visible

        overlayTrim.visible = !overlayTrim.visible
        overlayTransform.visible = false
        overlayCrop.editing = false
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

    function toggleInfoPanel() {
        if (typeof shot === "undefined" || !shot) return

        // Check if fullsize is necessary (preview is already maxed out)
        if (!mediaArea.isFullSize) {
            //console.log("Check if fullsize is necessary: " + (shot.width / shot.height) + " vs " + (mediaArea.width / mediaArea.height))
            if (shot.userRotation === 0 || shot.userRotation === 180) {
                if ((shot.width / shot.height) < (mediaArea.width / mediaArea.height))
                    return;
            } else {
                if ((shot.height / shot.width) < (mediaArea.width / mediaArea.height))
                    return;
            }
        }

        // Set fullsize
        mediaArea.isFullSize = !mediaArea.isFullSize

        computeOverlaySize()
    }

    function toggleFullScreen() {
        if (typeof shot === "undefined" || !shot) return

        if (!mediaArea.isFullScreen) {
            mediaArea.isFullScreen = true
            mediaArea.parent = videoWindowItem
            videoWindow.showFullScreen()
            mediaArea.focus = true
        } else {
            mediaArea.isFullScreen = false
            mediaArea.parent = contentOverview
            videoWindow.hide()
        }

        if (!videoPlayer.isRunning) {
            // force player to show one frame
            videoPlayer.play()
            videoPlayer.pause()
        }

        computeOverlaySize()
    }

    ////////

    function computeOverlaySize() {
        if (typeof shot === "undefined" || !shot) return
        //console.log("computeOverlaySize()")

        var mediaWidth = shot.width
        var mediaHeight = shot.height

        // no metadata?
        if (!mediaWidth || !mediaHeight) {
            mediaWidth = output.width
            mediaHeight = output.height
        }

        // rotated?
        if (shot.userRotation === 90 || shot.userRotation === 270) {
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
    Matrix4x4 { id: hflip; matrix: Qt.matrix4x4(-1, 0, 0, output.width, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
    Matrix4x4 { id: vflip; matrix: Qt.matrix4x4(1, 0, 0, 0, 0, -1, 0, output.height, 0, 0, 1, 0, 0, 0, 0, 1) }
    Matrix4x4 { id: vhflip; matrix: Qt.matrix4x4(-1, 0, 0, output.width, 0, -1, 0, output.height, 0, 0, 1, 0, 0, 0, 0, 1) }

    function computeTransformation() {
        if (shot.userVFlipped && shot.userHFlipped)
            output.transform = vhflip
        else if (shot.userVFlipped)
            output.transform = vflip
        else if (shot.userHFlipped)
            output.transform = hflip
        else
            output.transform = noflip
    }

    function setTransformation(value) {
        if (typeof shot === "undefined" || !shot) return
        //console.log("setTransformation(" + value + ")")

        if (value === "flip") {
            shot.userVFlipped = !shot.userVFlipped
        } else if (value === "mirror") {
            shot.userHFlipped = !shot.userHFlipped
        }

        computeTransformation()
    }

    function resetTransformation() {
        if (typeof shot === "undefined" || !shot) return
        //console.log("resetTransformation(" + shot.transformation + ")")

        transformToOrientation_qt(shot.transformation)
        computeTransformation()
        computeOverlaySize()
    }

    function addRotation(value) {
        if (typeof shot === "undefined" || !shot) return
        //console.log("addRotation(" + value + ")")

        shot.userRotation += value
        shot.userRotation = UtilsNumber.mod(shot.userRotation, 360)

        // rotate overlayCrop // TODO move it 'naturaly' too?
        if (shot.userRotation === 90 || shot.userRotation === 270) {
            if (shot.cropAR === MediaUtils.AspectRatio_4_3) shot.cropAR = MediaUtils.AspectRatio_3_4
            else if (shot.cropAR === MediaUtils.AspectRatio_16_9) shot.cropAR = MediaUtils.AspectRatio_9_16
            else if (shot.cropAR === MediaUtils.AspectRatio_21_9) shot.cropAR = MediaUtils.AspectRatio_9_21
        } else {
            if (shot.cropAR === MediaUtils.AspectRatio_3_4) shot.cropAR = MediaUtils.AspectRatio_4_3
            else if (shot.cropAR === MediaUtils.AspectRatio_9_16) shot.cropAR = MediaUtils.AspectRatio_16_9
            else if (shot.cropAR === MediaUtils.AspectRatio_9_21) shot.cropAR = MediaUtils.AspectRatio_21_9
        }

        computeOverlaySize()
    }

    function transformToOrientation_qt(transform) {
        //console.log("transformToOrientation_qt(" + transform +")")
        // QImageIOHandler::Transformation > rotation, horizontal flip, vertical flip

        var hflipped = false
        var vflipped = false
        var rotation = 0

        if (transform <= 0) {
            hflipped = false
            vflipped = false
            rotation = 0
        } else if (transform === 1) {
            hflipped = true
            vflipped = false
            rotation = 0
        } else if (transform === 2) {
            hflipped = false
            vflipped = true
            rotation = 0
        } else if (transform === 3) {
            hflipped = false
            vflipped = false
            rotation = 180
        } else if (transform === 4) {
            hflipped = false
            vflipped = false
            rotation = 90
        } else if (transform === 5) {
            hflipped = true
            vflipped = false
            rotation = 90
        } else if (transform === 6) {
            hflipped = false
            vflipped = true
            rotation = 90
        } else if (transform === 7) {
            hflipped = false
            vflipped = false
            rotation = 270
        } else {
            console.log("transformToOrientation_qt() unknown transformation: " + transform)
            hflipped = false
            vflipped = false
            rotation = 0
        }

        shot.userRotation = rotation
        shot.userHFlipped = hflipped
        shot.userVFlipped = vflipped
    }

    onWidthChanged: computeOverlaySize()
    onHeightChanged: computeOverlaySize()

    // KEYS HANDLING ///////////////////////////////////////////////////////////

    Keys.onPressed: {
        // UI
        if (event.key === Qt.Key_F) {
            event.accepted = true
            toggleFullScreen()
        }
        // Player
        else if (event.key === Qt.Key_Space) {
            event.accepted = true
            setPlayPause()
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        anchors.fill: overlays
        anchors.margins: 1
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

        property bool rotated: (shot.userRotation === 90 || shot.userRotation === 270)
        rotation: shot.userRotation

        Image {
            id: imageOutput
            width: output.rotated ? output.height : output.width
            height: output.rotated ? output.width : output.height
            anchors.centerIn: parent

            autoTransform: false
            fillMode: Image.Stretch

            sourceSize.width: width
            sourceSize.height: height
        }
        VideoOutput {
            id: videoOutput
            width: output.rotated ? output.height : output.width
            height: output.rotated ? output.width : output.height
            anchors.centerIn: parent

            autoOrientation: false // doesn't work anyway
            fillMode: Image.Stretch

            source: videoPlayer
            //flushMode: LastFrame // Qt 5.13
        }
    }

    ////////

    Timer {
        id: timerTimelapse
        interval: 100
        running: false
        repeat: true
        onTriggered: {
            if (shot.duration > 1) {
                shot.mediaPosition++
                if (shot.mediaPosition >= shot.duration) shot.mediaPosition = 0
                imageOutput.source = "file:///" + shot.previewTimelapse[shot.mediaPosition]
            }
        }
    }

    MediaPlayer {
        id: videoPlayer
        volume: 0.5
        autoLoad: true
        autoPlay: false // will be paused immediately
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
            savePosition()
        }
        onPaused: {
            buttonPlay.source = "qrc:/assets/icons_material/baseline-play_arrow-24px.svg"
            savePosition()
        }
        onStopped: {
            if (videoPlayer.position >= shot.duration) { // EOF
                isRunning = false
                videoPlayer.seek(0)
                savePosition()

                videoPlayer.play()
                videoPlayer.pause()

                // Note // on Qt 5.13+, same thing could be achieved with:
                //videoOutput.flushMode: LastFrame
            }
        }
        onPlaylistChanged: {
            //console.log("onPlaylistChanged()")
            videoPlayer.isRunning = false
            mediaBanner.close()
            overlayCrop.load()
        }
        onSourceChanged: {
            //console.log("onSourceChanged(" + source + ")")
            videoPlayer.isRunning = false
            mediaBanner.close()
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
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            property bool hovered: false

            onPressed: {
                // play/pause
                if (pressedButtons & Qt.RightButton) {
                    setPlayPause()
                    return
                }
            }
            onDoubleClicked: {
                if (pressedButtons & Qt.LeftButton) {
                    toggleInfoPanel()
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

                text: qsTr("trim from ") + UtilsString.durationToString_ISO8601_full(shot.trimStart) + qsTr(" to ") + UtilsString.durationToString_ISO8601_full(shot.trimStop > 0 ? shot.trimStop : shot.duration)
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

                visible: UtilsMedia.orientationToTransform_qt(shot.userRotation, shot.userHFlipped, shot.userVFlipped) !== shot.transformation
                source: "qrc:/assets/icons_material/baseline-save-24px.svg"
                //onClicked: shot.saveRotation(angle)
            }
            ItemImageButton {
                //id: buttonRotateClear
                iconColor: "white"
                background: true
                backgroundColor: "#222"
                highlightMode: "color"

                visible: UtilsMedia.orientationToTransform_qt(shot.userRotation, shot.userHFlipped, shot.userVFlipped) !== shot.transformation
                source: "qrc:/assets/icons_material/baseline-close-24px.svg"
                onClicked: resetTransformation()
            }
            ItemImageButton {
                //id: buttonRotateLeft
                iconColor: (shot.userRotation >= 180) ? Theme.colorPrimary : "white"
                background: true
                backgroundColor: "#222"
                highlightMode: "color"

                source: "qrc:/assets/icons_material/baseline-rotate_left-24px.svg"
                onClicked: mediaArea.addRotation(-90)
            }
            ItemImageButton {
                //id: buttonRotateRight
                iconColor: (shot.userRotation > 0 && shot.userRotation <= 180) ? Theme.colorPrimary : "white"
                background: true
                backgroundColor: "#222"
                highlightMode: "color"

                source: "qrc:/assets/icons_material/baseline-rotate_right-24px.svg"
                onClicked: mediaArea.addRotation(+90)
            }
            ItemImageButton {
                //id: buttonMirror
                iconColor: (shot.userHFlipped) ? Theme.colorPrimary : "white"
                background: true
                backgroundColor: "#222"
                highlightMode: "color"

                source: "qrc:/assets/icons_material/baseline-flip-24px.svg"
                onClicked: mediaArea.setTransformation("mirror")
            }
            ItemImageButton {
                //id: buttonFlip
                rotation: 90
                iconColor: (shot.userVFlipped) ? Theme.colorPrimary : "white"
                background: true
                backgroundColor: "#222"
                highlightMode: "color"

                source: "qrc:/assets/icons_material/baseline-flip-24px.svg"
                onClicked: mediaArea.setTransformation("flip")
            }
        }

        ////////////////

        ItemBannerMessage {
            id: mediaBanner
        }

        ////////////////

        Row {
            id: timelapseControls
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 32
            spacing: 8

            visible: (imageOutput.visible && shot.duration > 1)

            property bool wide: (maxrects > shot.duration)
            property int maxrects: (parent.width / (24+8))
            property int maxpoints: (parent.width / (12+8))
            property int points: (mediaArea.mode === "timelapse") ? ((shot.duration > maxpoints) ? maxpoints-3 : shot.duration) : 0
            property real divider: (shot.duration / points)

            ImageSvg {
                anchors.verticalCenter: parent.verticalCenter
                width: 28; height: 28;
                source: (timerTimelapse.running) ? "qrc:/assets/icons_material/baseline-pause-24px.svg"
                                                 : "qrc:/assets/icons_material/baseline-play_arrow-24px.svg"
                color: "white"

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: {
                        if (timerTimelapse.running)
                            timerTimelapse.stop()
                        else
                            timerTimelapse.start()
                    }
                }
            }

            Repeater {
                model: timelapseControls.points
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: timelapseControls.wide ? 24 : 12
                    height: timelapseControls.wide ? 8 : 12
                    radius: timelapseControls.wide ? 2 : 12

                    color: "white"
                    border.color: "#eee"
                    opacity: (Math.round(shot.mediaPosition / timelapseControls.divider) == index) ? 1 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 133 } }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        onClicked: {
                            shot.mediaPosition = Math.round(index * timelapseControls.divider)
                            imageOutput.source = "file:///" + shot.previewTimelapse[shot.mediaPosition]
                        }
                    }
                }
            }
        }

        ////////////////

        Item {
            id: mediaControls
            height: 40
            visible: (videoOutput.visible && !overlayCrop.editing)

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
                    shot.trimStart = shot.duration * first.value
                    mediaControls.seek_real(first.value)
                }
                second.onMoved: {
                    shot.trimStop = shot.duration * second.value
                    mediaControls.seek_real(second.value)
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

                onMoved: mediaControls.seek_real(value)
            }

            ////

            Rectangle {
                x: (parent.width * (shot.trimStart / shot.duration))
                width: (parent.width * ((shot.trimStop - shot.trimStart) / shot.duration))
                height: 4
                visible: (shot.trimStart > 0 || (shot.trimStop > 0 && shot.trimStop < shot.duration))
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

            function seek_ms(value) { // seek(milliseconds) with chapter awareness
                var seekpoint = value
                if (seekpoint === videoPlayer.position) return

                //
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
                savePosition()

                if (Qt.platform.os === "osx") {
                    if (wasRunning) {
                        videoPlayer.play()
                        videoPlayer.isRunning = true
                    }
                }
            }

            function seek_real(value) { // seek(0-1) instead of seek(milliseconds)
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
                savePosition()

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

                    visible: videoPlayer.hasAudio
                    enabled: videoPlayer.hasAudio

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
                        selected: parent.isHovered

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
                        onMoved: videoPlayer.volume = value
                    }
                }

                Text {
                    id: timecode
                    anchors.verticalCenter: parent.verticalCenter

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

                    source: "qrc:/assets/icons_material/baseline-content_cut-24px.svg"
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

                    source: "qrc:/assets/icons_material/duotone-rotate_90_degrees_ccw-24px.svg"
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

                    visible: true
                    iconColor: "white"
                    highlightColor: Theme.colorPrimary
                    highlightMode: "color"

                    source: "qrc:/assets/icons_material/duotone-camera_alt-24px.svg"
                    onClicked: {
                        if (typeof shot === "undefined" || !shot) return

                        var mediaProvider
                        if (typeof currentDevice !== "undefined")
                            mediaProvider = currentDevice
                        else if (typeof mediaLibrary !== "undefined")
                            mediaProvider = mediaLibrary
                        else
                            return

                        var screenshotParams = {}
                        screenshotParams["mode"] = "screenshot"
                        screenshotParams["folder"] = shot.folder
                        screenshotParams["image_codec"] = "JPEG"
                        screenshotParams["quality"] = 90
                        screenshotParams["clipStartMs"] = videoPlayer.position

                        var rotation = shot.userRotation
                        var hflip = shot.userHFlipped
                        var vflip = shot.userVFlipped
                        if (shot.userRotation || shot.userHFlipped || shot.userVFlipped) {
                            if (shot.rotation) rotation -= shot.rotation
                            if (shot.transformation) {
                                if (hflip && !vflip) { hflip = false; vflip = true; }
                                if (!hflip && vflip) { hflip = true; vflip = false; }
                            }
                            if (rotation || hflip || vflip) {
                                screenshotParams["transform"] = UtilsMedia.orientationToTransform_exif(rotation, hflip, vflip)
                            }
                        }
                        if (shot.cropX > 0.0 || shot.cropY > 0.0 ||
                            shot.cropW < 1.0 || shot.cropH < 1.0) {
                            var clipCropX = Math.round(shot.width * shot.cropX)
                            var clipCropY = Math.round(shot.height * shot.cropY)
                            var clipCropW = Math.round(shot.width * shot.cropW)
                            var clipCropH = Math.round(shot.height * shot.cropH)
                            if (shot.userRotation === 90 || shot.userRotation === 270) {
                                clipCropX = Math.round(shot.height * shot.cropX)
                                clipCropY = Math.round(shot.width * shot.cropY)
                                clipCropW = Math.round(shot.height * shot.cropW)
                                clipCropH = Math.round(shot.width * shot.cropH)
                            }
                            screenshotParams["crop"] = clipCropW + ":" + clipCropH + ":" + clipCropX + ":" + clipCropY
                        }

                        mediaProvider.reencodeSelected(shot.uuid, screenshotParams)
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
