import QtQuick 2.9
import QtQuick.Controls 2.2
import QtMultimedia 5.9

import com.offloadbuddy.theme 1.0
import com.offloadbuddy.shared 1.0
import "UtilsString.js" as UtilsString

Item {
    id: contentOverview
    width: 1280
    height: 720
    anchors.fill: parent

    function setPause() { mediaPreview.setPause() }
    function setPlayPause() { mediaPreview.setPlayPause() }

    function updateOverview() {

        textFileList.text = shot.fileList

        if (shot.camera) {
            labelCamera.visible = true
        } else {
            labelCamera.visible = false
        }

        if (shot.orientation) {
            labelOrientation.visible = true
        } else {
            labelOrientation.visible = false
        }

        if (shot.fileType === Shared.FILE_PICTURE) {
            mediaPreview.setImageMode()

            infosPicture.visible = true
            infosVideo.visible = false

            codecAudio.visible = false
            codecVideo.visible = true
            codecVideoText.text = shot.codecVideo

            if (shot.iso.length === 0 && shot.focal.length === 0 && shot.exposure.length === 0) {
                infosPicture.visible = false
            }

            if (shot.duration > 1) {
                labelDuration.visible = true
                duration.text = shot.duration + " " + qsTr("pictures")
            } else {
                labelDuration.visible = false
            }
        } else {
            mediaPreview.setVideoMode()

            infosPicture.visible = false
            infosVideo.visible = true

            //console.log("shot.previewPhoto :" + shot.previewVideo)

            if (shot.codecVideo.length) {
                codecVideo.visible = true
                codecVideoText.text = shot.codecVideo
            } else {
                codecVideo.visible = false
            }

            if (shot.codecAudio.length) {
                codecAudio.visible = true
                codecAudioText.text = shot.codecAudio
            } else {
                codecAudio.visible = false
            }

            labelDuration.visible = true
            duration.text = UtilsString.durationToString(shot.duration)

            bitrate.text = UtilsString.bitrateToString(shot.bitrate)
            codec.text = shot.codecVideo
            if (shot.codecAudio) codec.text +=  " / " + shot.codecAudio
            framerate.text = UtilsString.framerateToString(shot.framerate)
        }

        size.text = UtilsString.bytesToString_short(shot.datasize)
        if (shot.size !== shot.datasize) {
            size.text += "   (" + qsTr("full: ") + UtilsString.bytesToString_short(shot.size) + ")"
        }
    }

    function openEncodePopup() {
        panelEncode.updateEncodePanel(shot)
        panelEncode.setClip(mediaPreview.startLimit, mediaPreview.stopLimit)
        popupEncode.open()
    }
    function openDeletePopup() {
        popupDelete.open()
    }

    // POPUPS //////////////////////////////////////////////////////////////////

    PopupConfirm {
        id: popupDelete
        x: (applicationWindow.width / 2) - (popupDelete.width / 2) - (applicationSidebar.width)
        y: (applicationWindow.height / 2) - (popupDelete.height / 2) - (rectangleHeader.height)

        message: qsTr("Are you sure you want to delete the selected file?")
        onConfirmed: {
            if (applicationContent.state === "library") {
                // delete shot
                mediaLibrary.deleteSelected(screenMedia.shot.uuid)
                // then back to media grid
                screenLibrary.state = "stateMediaGrid"
            } else if (applicationContent.state === "device") {
                // delete shot
                screenDevice.currentDevice.deleteSelected(screenMedia.shot.uuid)
                // then back to media grid
                screenDevice.state = "stateMediaGrid"
            }
        }
    }

    Popup {
        id: popupEncode
        modal: true
        focus: true
        x: (parent.width - panelEncode.width) / 2
        y: (parent.height - 64 - panelEncode.height) / 2
        closePolicy: Popup.CloseOnEscape /*| Popup.CloseOnPressOutsideParent*/

        PanelEncode {
            id: panelEncode
        }
        background: Item {
            //
        }
    }

    // CONTENT /////////////////////////////////////////////////////////////////

    MediaPreview {
        id: mediaPreview
    }

    ////////////////

    Column {
        id: infosGeneric
        width: 320
        anchors.bottomMargin: 0
        anchors.rightMargin: 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 16
        anchors.top: parent.top

        spacing: 8

        ImageSvg {
            id: labelDate
            width: 28
            height: 28

            source: "qrc:/icons_material/baseline-date_range-24px.svg"
            color: Theme.colorText

            Text {
                id: date
                height: 28
                anchors.left: parent.right
                anchors.leftMargin: 16

                color: Theme.colorText
                text: shot.date.toUTCString()
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Theme.fontSizeContentText
            }
        }

        ImageSvg {
            id: labelCamera
            width: 28
            height: 28

            source: "qrc:/icons_material/baseline-camera-24px.svg"
            color: Theme.colorText

            Text {
                id: camera
                height: 28
                anchors.left: parent.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                text: shot.camera
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }
        }

        ImageSvg {
            id: labelDuration
            width: 28
            height: 28

            source: "qrc:/icons_material/baseline-timer-24px.svg"
            color: Theme.colorText

            Text {
                id: duration
                height: 28
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.right
                anchors.leftMargin: 16
                horizontalAlignment: Text.AlignRight

                verticalAlignment: Text.AlignVCenter
                color: Theme.colorText
                font.pixelSize: Theme.fontSizeContentText
            }
        }

        ImageSvg {
            id: labelDefinition
            width: 28
            height: 28

            source: "qrc:/icons_material/baseline-aspect_ratio-24px.svg"
            color: Theme.colorText

            Text {
                id: definition
                height: 28
                anchors.left: parent.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                text: shot.width + "x" + shot.height + "   (" + UtilsString.varToString(shot.width, shot.height) + ")"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }
        }

        ImageSvg {
            id: labelOrientation
            width: 28
            height: 28

            source: "qrc:/icons_material/baseline-screen_rotation-24px.svg"
            color: Theme.colorText

            Text {
                id: orientation
                height: 28
                anchors.left: parent.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                color: Theme.colorText
                text: UtilsString.orientationToString(shot.orientation)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Theme.fontSizeContentText
            }
        }

        ImageSvg {
            id: labelSize
            width: 28
            height: 28

            source: "qrc:/icons_material/baseline-folder-24px.svg"
            color: Theme.colorText

            Text {
                id: size
                height: 28
                anchors.left: parent.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                color: Theme.colorText
                text: UtilsString.bytesToString_short(shot.datasize)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Theme.fontSizeContentText
            }
        }

        ////////////////

        Column {
            id: infosPicture
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            spacing: 8

            Item { width: 16; height: 16; } // spacer

            ImageSvg {
                id: labelISO
                width: 28
                height: 28

                source: "qrc:/icons_material/baseline-iso-24px.svg"
                color: Theme.colorText

                Text {
                    id: iso
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("ISO") + " " + shot.iso
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeContentText
                    color: Theme.colorText
                }
            }

            ImageSvg {
                id: labelFocal
                width: 28
                height: 28

                source: "qrc:/icons_material/baseline-center_focus_weak-24px.svg"
                color: Theme.colorText

                Text {
                    id: focal
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: shot.focal
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeContentText
                    color: Theme.colorText
                }
            }

            ImageSvg {
                id: labelExposure
                width: 28
                height: 28

                source: "qrc:/icons_material/baseline-shutter_speed-24px.svg"
                color: Theme.colorText

                Text {
                    id: exposure
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: shot.exposure
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeContentText
                    color: Theme.colorText
                }
            }
        }

        ////////////////

        Column {
            id: infosVideo
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0

            spacing: 8

            Item { width: 16; height: 16; } // spacer

            ImageSvg {
                id: labelChapter
                width: 28
                height: 28

                visible: (shot.chapters > 1)
                source: "qrc:/icons_material/baseline-video_library-24px.svg"
                color: Theme.colorText

                Text {
                    id: chapter
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: shot.chapters + qsTr(" chapters")
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeContentText
                    color: Theme.colorText
                }
            }

            ImageSvg {
                id: labelCodec
                width: 28
                height: 28

                source: "qrc:/icons_material/baseline-memory-24px.svg"
                color: Theme.colorText

                Text {
                    id: codec
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: ""
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeContentText
                    color: Theme.colorText
                }
            }

            ImageSvg {
                id: labelFramerate
                width: 28
                height: 28

                source: "qrc:/icons_material/baseline-camera_roll-24px.svg"
                color: Theme.colorText

                Text {
                    id: framerate
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: ""
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeContentText
                    color: Theme.colorText
                }
            }

            ImageSvg {
                id: labelBitrate
                width: 28
                height: 28

                source: "qrc:/icons_material/baseline-insert_chart_outlined-24px.svg"
                color: Theme.colorText

                Text {
                    id: bitrate
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: ""
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeContentText
                    color: Theme.colorText
                }
            }

            ImageSvg {
                id: labelTimecode
                width: 28
                height: 28

                visible: shot.timecode
                source: "qrc:/icons_material/baseline-av_timer-24px.svg"
                color: Theme.colorText

                Text {
                    id: timecode
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    text: shot.timecode
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeContentText
                    color: Theme.colorText
                }
            }
        }
    }

    ////////////////

    Rectangle {
        id: infosFiles
        width: 320
        height: 256
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        color: Theme.colorForeground

        Text {
            id: labelFileCount
            height: 32
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 16

            text: qsTr("File(s):")
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            color: Theme.colorText
            font.bold: true
            font.pixelSize: Theme.fontSizeContentText
        }

        Text {
            id: textFileList
            anchors.rightMargin: 16
            anchors.leftMargin: 8
            anchors.bottomMargin: 16
            anchors.top: labelFileCount.bottom
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.topMargin: 0

            text: ""
            clip: true
            horizontalAlignment: Text.AlignRight
            color: Theme.colorText
            font.pixelSize: Theme.fontSizeContentText
        }
    }
}
