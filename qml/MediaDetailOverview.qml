import QtQuick 2.9
import QtQuick.Controls 2.2
import QtMultimedia 5.9
import QtGraphicalEffects 1.0

import com.offloadbuddy.style 1.0
import com.offloadbuddy.shared 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: contentOverview
    width: 1280
    height: 720
    anchors.fill: parent
    color: "#00000000"

    property var selectedShot : shot
    property string selectedItemName : shot ? shot.name : ""

    // POPUPS //////////////////////////////////////////////////////////////////

    Popup {
        id: popupEncode
        modal: true
        focus: true
        x: (parent.width - panelEncode.width) / 2
        y: (parent.height - panelEncode.height) / 2
        closePolicy: Popup.CloseOnEscape /*| Popup.CloseOnPressOutsideParent*/

        PanelEncode {
            id: panelEncode
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        id: preview
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: rectangleMetadatas.left
        anchors.margins: 16
        color: "black"

        property bool isFullScreen: false
        property int startLimit: -1
        property int stopLimit: -1

        MouseArea {
            id: previewFullScreen
            anchors.fill: parent

            onDoubleClicked: toogleFullScreen()

            function toogleFullScreen() {
                preview.isFullScreen = !preview.isFullScreen

                if (preview.isFullScreen) {
                    buttonFullscreen.text = "⇱"
                    rectangleMetadatas.visible = true
                    preview.anchors.right = rectangleMetadatas.left
                } else {
                    buttonFullscreen.text = "⇲"
                    rectangleMetadatas.visible = false
                    preview.anchors.right = parent.parent.right
                }
            }
        }

        Image {
            id: image
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            //source: "qrc:/resources/other/placeholder_picture.svg"

            sourceSize.width: shot.width / 2
            sourceSize.height: shot.height / 2
        }

        VideoOutput {
            id: mediaOutput
            anchors.fill: parent
            source: mediaPlayer

            property int clipStart: 0
            property int clipStop: shot.duration

            MediaPlayer {
                id: mediaPlayer
                volume: 0.0 // will be set to 0.5 immediately
                autoPlay: true // will be paused immediately
                notifyInterval: 33

                property bool isRunning: false
                onError: {
                    if (platform.os === "windows")
                        mediaBanner.openMessage(qsTr("Codec pack installed?"))
                    else
                        mediaBanner.openMessage(qsTr("Oooops..."))
                }
                onStopped: {
                    isRunning = false
                }
                onSourceChanged: {
                    stop()
                    isRunning = false
                    mediaBanner.close()
                }
                onVolumeChanged: {
                    soundlinePosition.width = (soundline.width * volume)
                }
                onPositionChanged: {
                    timelinePosition.width = timeline.width * (mediaPlayer.position / mediaPlayer.duration);
                }
            }

            ItemBanner {
                id: mediaBanner
            }

            Rectangle {
                id: mediaControls
                height: 40
                color: "#d9d9d9"
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0

                Button {
                    id: buttonPlay
                    width: 40
                    height: 40
                    text: "▶"
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: {
                        if (mediaPlayer.isRunning) {
                            mediaPlayer.pause()
                            mediaPlayer.isRunning = false
                            buttonPlay.text = "▷"
                        } else {
                            mediaPlayer.play()
                            mediaPlayer.isRunning = true
                            buttonPlay.text = "▶"
                        }
                    }
                }

                Button {
                    id: buttonStop
                    width: 40
                    height: 40
                    text: "■"
                    anchors.left: buttonPlay.right
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: {
                        mediaPlayer.stop()
                        mediaPlayer.isRunning = false
                    }
                }

                Button {
                    id: buttonStartCut
                    width: 40
                    height: 40
                    text: "["
                    anchors.left: buttonStop.right
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: {
                        preview.startLimit = mediaPlayer.position
                        //clipStart = mediaPlayer.position
                        //console.log("clipStart: " + clipStart)
                        timelineLimitStart.width = timeline.width * (mediaPlayer.position / mediaPlayer.duration);
                    }
                }
                Button {
                    id: buttonStopCut
                    width: 40
                    height: 40
                    text: "]"
                    anchors.right: buttonScreenshot.left
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: {
                        preview.stopLimit = mediaPlayer.position
                        //clipStop = mediaPlayer.position
                        //console.log("clipStop: " + clipStart)
                        timelineLimitStop.width = timeline.width * (((mediaPlayer.duration - mediaPlayer.position) / mediaPlayer.duration));
                    }
                }
                Button {
                    id: buttonScreenshot
                    width: 40
                    height: 40
                    text: "⎔"
                    anchors.right: soundline.left
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: {
                        panelEncode.updateEncodePanel(shot)
                        panelEncode.setClip(preview.startLimit, preview.stopLimit)
                        popupEncode.open()
                    }
                }
                Button {
                    id: buttonFullscreen
                    width: 40
                    height: 40
                    text: "⇱"
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    onClicked: previewFullScreen.toogleFullScreen()
                }

                Rectangle {
                    id: timeline
                    height: 40
                    color: "#d0d0d0"
                    anchors.left: buttonStartCut.right
                    anchors.leftMargin: 0
                    anchors.right: buttonStopCut.left
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        id: timelinePosition
                        width: 0
                        height: 40
                        color: ThemeEngine.colorApproved
                        anchors.left: parent.left
                        anchors.leftMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    MouseArea {
                        id: timelineSeeker
                        anchors.fill: parent

                        onClicked: {
                            var fff = mouseX / timeline.width
                            //if (mediaPlayer.isRunning)
                            mediaPlayer.seek(mediaPlayer.duration * fff)
                        }
                    }

                    Rectangle {
                        id: timelineLimitStart
                        height: 40
                        color: "#cfa9ff"
                        anchors.left: parent.left
                        anchors.leftMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        id: timelineLimitStop
                        height: 40
                        color: "#cfa9ff"
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                    }
                }

                Rectangle {
                    id: soundline
                    width: 80
                    height: 40
                    color: "#d0d0d0"
                    anchors.right: buttonFullscreen.left
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        id: soundlinePosition
                        width: 0
                        height: 40
                        color: "#ffe695"
                        anchors.left: parent.left
                        anchors.leftMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        onClicked: mediaPlayer.volume = (mouseX / soundline.width)
                    }
                }
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    function setPause() {
        if (mediaPlayer.isRunning) {
            mediaPlayer.pause()
            mediaPlayer.isRunning = false
            buttonPlay.text = "▷"
        }
    }

    function updateOverview() {

        textFileList.text = shot.fileList

        if (shot.type >= Shared.SHOT_PICTURE) {
            rectanglePicture.visible = true
            rectangleVideo.visible = false

            image.visible = true
            mediaOutput.visible = false

            codecAudio.visible = false
            codecVideo.visible = true
            codecVideo.anchors.right = buttonOverview.left
            codecVideoText.text = "JPEG" // HACK

            if (shot.iso.length === 0 && shot.focal.length === 0 && shot.exposure.length === 0)
                rectanglePicture.visible = false

            if (shot.duration > 1) {
                labelDuration.visible = true
                labelDefinition.anchors.top = labelDuration.bottom
                duration.text = shot.duration + " " + qsTr("pictures")

                if (shot.previewPhoto)
                    image.source = "file:///" + shot.previewPhoto
                else
                    image.source = "qrc:/resources/other/placeholder_picture_multi.svg"
            } else {
                labelDuration.visible = false
                labelDefinition.anchors.top = labelCamera.bottom

                if (shot.previewPhoto)
                    image.source = "file:///" + shot.previewPhoto
                else
                    image.source = "qrc:/resources/other/placeholder_picture.svg"
            }
        } else {
            rectanglePicture.visible = false
            rectangleVideo.visible = true

            image.visible = false
            mediaOutput.visible = true

            //console.log("shot.previewPhoto :" + shot.previewVideo)

            if (shot.previewVideo)
                mediaPlayer.source = "file:///" + shot.previewVideo
            else
                image.source = "qrc:/resources/other/placeholder_video.svg"

            mediaPlayer.pause()
            mediaPlayer.volume = 0.5

            preview.startLimit = -1
            preview.stopLimit = -1
            timelineLimitStart.width = 0
            timelineLimitStop.width = 0

            codecVideo.visible = true
            if (shot.codecVideo.length)
                codecVideoText.text = shot.codecVideo
            else
                codecVideo.visible = false

            if (shot.codecAudio.length) {
                codecAudio.visible = true
                codecAudioText.text = shot.codecAudio
                codecVideo.anchors.right = codecAudio.left
            } else {
                codecVideo.anchors.right = buttonOverview.left
                codecAudio.visible = false
            }

            labelDuration.visible = true
            labelDefinition.anchors.top = labelDuration.bottom
            duration.text = StringUtils.durationToString(shot.duration)

            bitrate.text = StringUtils.bitrateToString(shot.bitrate)
            codec.text = shot.codecVideo
            framerate.text = StringUtils.framerateToString(shot.framerate)
            timecode.text = shot.timecode
        }

        if (shot.size !== shot.datasize) {
            size.text = StringUtils.bytesToString_short(shot.datasize) + "   (" + qsTr("full: ") + StringUtils.bytesToString_short(shot.size) + ")"
        }
    }

    Rectangle {
        id: rectangleMetadatas
        width: 320
        color: ThemeEngine.colorContentBox
        anchors.bottomMargin: 0
        anchors.rightMargin: 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 0
        anchors.top: parent.top

        Image {
            id: labelDate
            width: 28
            height: 28
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16

            source: "qrc:/icons_material/baseline-date_range-24px.svg"
            sourceSize.width: width
            sourceSize.height: height

            ColorOverlay {
                anchors.fill: parent
                source: parent
                color: ThemeEngine.colorContentText
                visible: ThemeEngine.colorContentText !== "#000000" ? true : false
            }

            Text {
                id: date
                height: 28
                anchors.left: parent.right
                anchors.leftMargin: 16

                color: ThemeEngine.colorContentText
                text: shot.date.toUTCString()
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: ThemeEngine.fontSizeContentText
            }
        }

        Image {
            id: labelCamera
            width: 28
            height: 28
            anchors.top: labelDate.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 16

            source: "qrc:/icons_material/baseline-camera-24px.svg"
            sourceSize.width: width
            sourceSize.height: height

            ColorOverlay {
                anchors.fill: parent
                source: parent
                color: ThemeEngine.colorContentText
                visible: ThemeEngine.colorContentText !== "#000000" ? true : false
            }

            Text {
                id: camera
                height: 28
                anchors.left: parent.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                text: shot.camera
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }
        }

        Image {
            id: labelDuration
            width: 28
            height: 28
            anchors.top: labelCamera.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 16

            source: "qrc:/icons_material/baseline-timer-24px.svg"
            sourceSize.width: width
            sourceSize.height: height

            ColorOverlay {
                anchors.fill: parent
                source: parent
                color: ThemeEngine.colorContentText
                visible: ThemeEngine.colorContentText !== "#000000" ? true : false
            }

            Text {
                id: duration
                height: 28
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.right
                anchors.leftMargin: 16
                horizontalAlignment: Text.AlignRight

                text: ""
                verticalAlignment: Text.AlignVCenter
                color: ThemeEngine.colorContentText
                font.pixelSize: ThemeEngine.fontSizeContentText
            }
        }

        Image {
            id: labelDefinition
            width: 28
            height: 28
            anchors.top: labelDuration.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 16

            source: "qrc:/icons_material/baseline-aspect_ratio-24px.svg"
            sourceSize.width: width
            sourceSize.height: height

            ColorOverlay {
                anchors.fill: parent
                source: parent
                color: ThemeEngine.colorContentText
                visible: ThemeEngine.colorContentText !== "#000000" ? true : false
            }

            Text {
                id: definition
                height: 28
                anchors.left: parent.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                text: shot.width + "x" + shot.height + "   (" + StringUtils.aspectratioToString(shot.width, shot.height) + ")"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }
        }

        Image {
            id: labelSize
            width: 28
            height: 28
            anchors.top: labelDefinition.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 16

            source: "qrc:/icons_material/baseline-folder-24px.svg"
            sourceSize.width: width
            sourceSize.height: height

            ColorOverlay {
                anchors.fill: parent
                source: parent
                color: ThemeEngine.colorContentText
                visible: ThemeEngine.colorContentText !== "#000000" ? true : false
            }

            Text {
                id: size
                height: 28
                anchors.left: parent.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                color: ThemeEngine.colorContentText
                text: StringUtils.bytesToString_short(shot.datasize)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                font.pixelSize: ThemeEngine.fontSizeContentText
            }
        }

        Rectangle {
            id: rectanglePicture
            height: 120
            color: "#00000000"
            anchors.top: labelSize.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            Image {
                id: labelISO
                width: 28
                height: 28
                anchors.top: parent.top
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 16

                source: "qrc:/icons_material/baseline-iso-24px.svg"
                sourceSize.width: width
                sourceSize.height: height

                ColorOverlay {
                    anchors.fill: parent
                    source: parent
                    color: ThemeEngine.colorContentText
                    visible: ThemeEngine.colorContentText !== "#000000" ? true : false
                }

                Text {
                    id: iso
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("ISO") + " " + shot.iso
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: ThemeEngine.fontSizeContentText
                    color: ThemeEngine.colorContentText
                }
            }

            Image {
                id: labelFocal
                width: 28
                height: 28
                anchors.top: labelISO.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 16

                source: "qrc:/icons_material/baseline-center_focus_weak-24px.svg"
                sourceSize.width: width
                sourceSize.height: height

                ColorOverlay {
                    anchors.fill: parent
                    source: parent
                    color: ThemeEngine.colorContentText
                    visible: ThemeEngine.colorContentText !== "#000000" ? true : false
                }

                Text {
                    id: focal
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: shot.focal
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: ThemeEngine.fontSizeContentText
                    color: ThemeEngine.colorContentText
                }
            }
            Image {
                id: labelExposure
                width: 28
                height: 28
                anchors.top: labelFocal.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 16

                source: "qrc:/icons_material/baseline-shutter_speed-24px.svg"
                sourceSize.width: width
                sourceSize.height: height

                ColorOverlay {
                    anchors.fill: parent
                    source: parent
                    color: ThemeEngine.colorContentText
                    visible: ThemeEngine.colorContentText !== "#000000" ? true : false
                }

                Text {
                    id: exposure
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: shot.exposure
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: ThemeEngine.fontSizeContentText
                    color: ThemeEngine.colorContentText
                }
            }
        }

        Rectangle {
            id: rectangleVideo
            height: 120
            color: "#00000000"
            anchors.top: labelSize.bottom
            anchors.topMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0

            Text {
                id: labelChapter
                width: 290
                height: 28
                color: ThemeEngine.colorContentText
                text: qsTr("Chapters:")
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.top: labelTimecode.bottom
                anchors.topMargin: 0
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentText

                Text {
                    id: chapters
                    width: 128
                    height: 32
                    text: shot.chapters
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: ThemeEngine.fontSizeContentText
                    color: ThemeEngine.colorContentText
                }
            }

            Text {
                id: labelTimecode
                width: 290
                height: 28
                text: qsTr("Timecode:")
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.top: labelBitrate.bottom
                anchors.topMargin: 0
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText

                Text {
                    id: timecode
                    width: 128
                    height: 32
                    text: ""
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    color: ThemeEngine.colorContentText
                    font.pixelSize: ThemeEngine.fontSizeContentText
                }
            }

            Text {
                id: labelCodec
                width: 290
                height: 28
                text: qsTr("Codec:")
                anchors.top: parent.top
                anchors.topMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 16
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText

                Text {
                    id: codec
                    width: 128
                    height: 32
                    text: ""
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    color: ThemeEngine.colorContentText
                    font.pixelSize: ThemeEngine.fontSizeContentText
                }
            }

            Text {
                id: labelBitrate
                width: 290
                height: 28
                color: ThemeEngine.colorContentText
                text: qsTr("Bitrate:")
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.top: labelFramerate.bottom
                anchors.topMargin: 0
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentText

                Text {
                    id: bitrate
                    width: 128
                    height: 32
                    text: ""
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    color: ThemeEngine.colorContentText
                    font.pixelSize: ThemeEngine.fontSizeContentText
                }
            }

            Text {
                id: labelFramerate
                width: 290
                height: 28
                color: ThemeEngine.colorContentText
                text: qsTr("Framerate:")
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.top: labelCodec.bottom
                anchors.topMargin: 0
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentText

                Text {
                    id: framerate
                    width: 128
                    height: 32
                    text: ""
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    color: ThemeEngine.colorContentText
                    font.pixelSize: ThemeEngine.fontSizeContentText
                }
            }
        }

        Rectangle {
            id: rectangleFiles
            height: 256
            color: ThemeEngine.colorContentSubBox
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0

            Text {
                id: labelFileCount
                height: 32
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.top: parent.top
                anchors.topMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 8

                text: qsTr("File(s):")
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                color: ThemeEngine.colorContentText
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentText
            }

            Text {
                id: textFileList
                anchors.rightMargin: 16
                anchors.leftMargin: 16
                anchors.bottomMargin: 8
                anchors.top: labelFileCount.bottom
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.topMargin: 0

                text: ""
                clip: true
                horizontalAlignment: Text.AlignRight
                color: ThemeEngine.colorContentText
                font.pixelSize: ThemeEngine.fontSizeContentText
            }
        }
    }
}
