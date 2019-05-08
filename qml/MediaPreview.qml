import QtQuick 2.9
import QtQuick.Controls 2.2
import QtMultimedia 5.9
import QtGraphicalEffects 1.0

import com.offloadbuddy.theme 1.0
import com.offloadbuddy.shared 1.0
import "UtilsString.js" as UtilsString

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

    function setImageMode() {
        imageOutput.visible = true
        mediaOutput.visible = false

        if (shot.previewPhoto) {
            imageOutput.source = "file:///" + shot.previewPhoto
        } else {
            if (shot.duration > 1) {
                imageOutput.source = "qrc:/resources/other/placeholder_picture_multi.svg"
            } else {
                imageOutput.source = "qrc:/resources/other/placeholder_picture.svg"
            }
        }
    }

    function setVideoMode() {
        imageOutput.visible = false
        mediaOutput.visible = true

        if (shot.previewVideo)
            videoPlayer.source = "file:///" + shot.previewVideo
        else
            imageOutput.source = "qrc:/resources/other/placeholder_video.svg"

        videoPlayer.pause()
    }

    function setPause() {
        if (videoPlayer.isRunning) {
            videoPlayer.pause()
            videoPlayer.isRunning = false
        }
    }

    MouseArea {
        id: previewFullScreen
        anchors.fill: parent

        onDoubleClicked: toogleFullScreen()

        function toogleFullScreen() {
            preview.isFullScreen = !preview.isFullScreen

            if (preview.isFullScreen) {
                buttonFullscreen.imageSource = "qrc:/icons_material/baseline-fullscreen-24px.svg"
                rectangleMetadatas.visible = true
                preview.anchors.right = rectangleMetadatas.left
            } else {
                buttonFullscreen.imageSource = "qrc:/icons_material/baseline-fullscreen_exit-24px.svg"
                rectangleMetadatas.visible = false
                preview.anchors.right = parent.parent.right
            }

            if (videoPlayer.position > 0)
                timelinePosition.width = timeline.width * (videoPlayer.position / videoPlayer.duration)
        }
    }

    Image {
        id: imageOutput
        anchors.fill: parent
        autoTransform: true
        fillMode: Image.PreserveAspectFit

        sourceSize.width: shot.width / 2
        sourceSize.height: shot.height / 2
    }

    VideoOutput {
        id: mediaOutput
        anchors.fill: parent
        source: videoPlayer

        property int clipStart: 0
        property int clipStop: shot.duration

        MediaPlayer {
            id: videoPlayer
            volume: 0.5
            autoPlay: true // will be paused immediately
            notifyInterval: 33

            property bool isRunning: false
            onError: {
                if (platform.os === "windows")
                    mediaBanner.openMessage(qsTr("Codec pack installed?"))
                else
                    mediaBanner.openMessage(qsTr("Oooops..."))
            }
            onPlaying: {
                buttonPlay.imageSource = "qrc:/icons_material/baseline-pause-24px.svg"
            }
            onPaused: {
                buttonPlay.imageSource = "qrc:/icons_material/baseline-play_arrow-24px.svg"
            }
            onStopped: {
                isRunning = false
                timelinePosition.width = 0
                buttonPlay.imageSource = "qrc:/icons_material/baseline-play_arrow-24px.svg"
            }
            onSourceChanged: {
                stop()
                isRunning = false
                preview.startLimit = -1
                preview.stopLimit = -1
                timelineLimitStart.width = 0
                timelineLimitStop.width = 0
                timelinePosition.width = 0
                mediaBanner.close()
            }
            onVolumeChanged: {
                soundlinePosition.width = (soundline.width * volume)
            }
            onPositionChanged: {
                timelinePosition.width = timeline.width * (videoPlayer.position / videoPlayer.duration)
            }
        }

        ItemBanner {
            id: mediaBanner
        }

        Rectangle {
            id: mediaControls
            height: 40
            opacity: 1
            color: Theme.colorButton
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0

            ButtonImage {
                id: buttonPlay
                width: 40
                height: 40
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.verticalCenter: parent.verticalCenter

                imageSource: "qrc:/icons_material/baseline-play_arrow-24px.svg"
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
            ButtonImage {
                id: buttonStop
                width: 40
                height: 40
                anchors.left: buttonPlay.right
                anchors.leftMargin: 0
                anchors.verticalCenter: parent.verticalCenter

                onClicked: {
                    videoPlayer.stop()
                    videoPlayer.isRunning = false
                }

                imageSource: "qrc:/icons_material/baseline-stop-24px.svg"
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
                    preview.startLimit = videoPlayer.position
                    //clipStart = mediaPlayer.position
                    //console.log("clipStart: " + clipStart)
                    timelineLimitStart.width = timeline.width * (videoPlayer.position / videoPlayer.duration);
                }
            }
            Button {
                id: buttonStopCut
                width: 40
                height: 40
                text: "]"
                anchors.right: buttonSound.left
                anchors.rightMargin: 0
                anchors.verticalCenter: parent.verticalCenter

                onClicked: {
                    preview.stopLimit = videoPlayer.position
                    //clipStop = mediaPlayer.position
                    //console.log("clipStop: " + clipStart)
                    timelineLimitStop.width = timeline.width * (((videoPlayer.duration - videoPlayer.position) / videoPlayer.duration));
                }
            }
            ButtonImage {
                id: buttonSound
                width: 40
                height: 40
                anchors.right: soundline.left
                anchors.rightMargin: 0
                anchors.verticalCenter: parent.verticalCenter
                imageSource: "qrc:/icons_material/baseline-volume_up-24px.svg"

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

            ButtonImage {
                id: buttonScreenshot
                width: 40
                height: 40
                anchors.right: buttonEncode.left
                anchors.rightMargin: 0
                anchors.verticalCenter: parent.verticalCenter
                imageSource: "qrc:/icons_material/outline-camera_alt-24px.svg"

                onClicked: {
                    //
                }
            }
            ButtonImage {
                id: buttonEncode
                width: 40
                height: 40
                anchors.right: buttonFullscreen.left
                anchors.rightMargin: 0
                anchors.verticalCenter: parent.verticalCenter
                imageSource: "qrc:/icons_material/baseline-settings_applications-24px.svg"

                onClicked: {
                    panelEncode.updateEncodePanel(shot)
                    panelEncode.setClip(preview.startLimit, preview.stopLimit)
                    popupEncode.open()
                }
            }
            ButtonImage {
                id: buttonFullscreen
                width: 40
                height: 40
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.verticalCenter: parent.verticalCenter
                imageSource: "qrc:/icons_material/baseline-fullscreen-24px.svg"

                onClicked: previewFullScreen.toogleFullScreen()
            }

            Rectangle {
                id: timeline
                height: 40
                color: Theme.colorButton
                anchors.left: buttonStartCut.right
                anchors.leftMargin: 0
                anchors.right: buttonStopCut.left
                anchors.rightMargin: 0
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    id: timelinePosition
                    width: 0
                    height: 40
                    color: Theme.colorApproved
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
                        videoPlayer.seek(videoPlayer.duration * fff)
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
                height: 28
                //color: "#d0d0d0"
                border.width: 2
                border.color: Theme.colorApproved
                anchors.right: buttonScreenshot.left
                anchors.rightMargin: 0
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    id: soundlinePosition
                    width: 0
                    height: 28
                    color: Theme.colorApproved
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    onClicked: videoPlayer.volume = (mouseX / soundline.width)
                }
            }
        }
    }
}
