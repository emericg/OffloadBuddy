import QtQuick
import QtQuick.Controls

import ThemeEngine
import ShotUtils

import "qrc:/utils/UtilsMedia.js" as UtilsMedia
import "qrc:/utils/UtilsString.js" as UtilsString

Item {
    id: contentOverview
    width: 1280
    height: 720
    anchors.fill: parent

    function setPause() { mediaPreview.setPause() }
    function setPlayPause() { mediaPreview.setPlayPause() }
    function toggleTrim() { mediaPreview.toggleTrim() }
    function toggleTransform() { mediaPreview.toggleTransform() }
    function toggleCrop() { mediaPreview.toggleCrop() }
    function toggleInfoPanel() { mediaPreview.toggleInfoPanel() }
    function toggleFullScreen() { mediaPreview.toggleFullScreen() }

    function updateOverview() {

        // FILE_PICTURE
        if (shot.fileType === ShotUtils.FILE_PICTURE) {
            mediaPreview.setImageMode()

            infosVideo.visible = false
            labelChapters.visible = false

            if (shot.duration > 1) {
                labelDuration.visible = true
                duration.text = shot.duration + " " + qsTr("pictures")
            } else {
                labelDuration.visible = false
            }

            if ((!shot.iso || (shot.iso && shot.iso.length === 0)) &&
                (!shot.focal || (shot.focal && shot.focal.length === 0)) &&
                (!shot.exposure || (shot.exposure && shot.exposure.length === 0))) {
                infosPicture.visible = false
            } else {
                infosPicture.visible = true

                labelISO.visible = (shot.iso.length)
                iso.text = qsTr("ISO") + " " + shot.iso
                labelFocal.visible = (shot.focal.length)
                focal.text = shot.focal
                labelExposureTime.visible = (shot.exposureTime.length)
                exposuretime.text = shot.exposureTime
                labelMeteringMode.visible = (shot.meteringMode.length)
                meteringmode.text = shot.meteringMode
                labelFlash.visible = (shot.flash)
                flash.text = qsTr("Enabled")
            }
        }

        // FILE_VIDEO
        if (shot.fileType === ShotUtils.FILE_VIDEO) {
            mediaPreview.setVideoMode()

            infosPicture.visible = false
            infosVideo.visible = true

            labelChapters.visible = (shot.chapterCount > 1)
            chapters.text = shot.chapterCount + qsTr(" chapters")

            labelDuration.visible = true
            duration.text = UtilsString.durationToString_short(shot.duration)
            framerate.text = UtilsMedia.framerateToString(shot.framerate)
            bitrate.text = UtilsMedia.bitrateToString(shot.bitrate)

            labelAudioChannels.visible = (shot.audioCodec.length)
            if (shot.audioCodec.length) {
                if (shot.audioChannels === 1)
                    audioChannels.text = qsTr("Mono")
                else if (shot.audioChannels === 2)
                    audioChannels.text = qsTr("Stereo")
                else
                    audioChannels.text = shot.audioChannels + qsTr(" channels")

                //audioBitrate.text = UtilsMedia.bitrateToString(shot.audioBitrate)
                //audioSamplerate.text = shot.audioSamplerate
            }

            labelTimecode.visible = (shot.timecode)
            timecode.text = shot.timecode
        }

        if (shot.codecImage.length) {
            codecImage.visible = true
            codecImage.text = shot.codecImage
            //codecImage.textCapitalization = Font.AllUppercase
            codec.text = shot.codecImage
        } else {
            codecImage.visible = false
        }

        if (shot.codecVideo.length) {
            codecVideo.visible = true
            codecVideo.text = shot.codecVideo
            codec.text = shot.codecVideo
        } else {
            codecVideo.visible = false
        }

        if (shot.audioCodec.length) {
            codecAudio.visible = true
            codecAudio.text = shot.audioCodec
            codec.text +=  " / " + shot.audioCodec
        } else {
            codecAudio.visible = false
        }

        size.text = UtilsString.bytesToString_short(shot.datasize)
        if (shot.size !== shot.datasize) {
            size.text += "   (" + qsTr("full: ") + UtilsString.bytesToString_short(shot.size) + ")"
        }
    }

    function openEncodingPopup() {
        popupEncoding.updateEncodePanel(shot)

         // v2
        popupEncoding.setClip(shot.trimStart, shot.trimStop)
        popupEncoding.setOrientation(shot.userRotation, shot.userHFlipped, shot.userVFlipped)
        popupEncoding.setCrop(shot.cropX, shot.cropY, shot.cropW, shot.cropH)

        // v1
        //popupEncoding.setClip(mediaPreview.startLimit, mediaPreview.stopLimit)
        //popupEncoding.setOrientation(mediaPreview.rotation, mediaPreview.hflipped, mediaPreview.vflipped)
        //popupEncoding.setCrop(mediaPreview.cropX, mediaPreview.cropY, mediaPreview.cropW, mediaPreview.cropH)

        if (appContent.state === "library") {
            popupEncoding.openSingle(mediaLibrary, shot)
        } else if (appContent.state === "device") {
            popupEncoding.openSingle(currentDevice, shot)
        }
    }
    function openTelemetryPopup() {
        if (appContent.state === "library") {
            popupTelemetry.openSingle(mediaLibrary, shot)
        } else if (appContent.state === "device") {
            popupTelemetry.openSingle(currentDevice, shot)
        }
    }
    function openDeletePopup() {
        if (appContent.state === "library") {
            popupDelete.openSingle(mediaLibrary, shot)
        } else if (appContent.state === "device") {
            popupDelete.openSingle(currentDevice, shot)
        }
    }
    function openDatePopup() {
        popupDate.loadDates()
        popupDate.open()
    }

    // POPUPS //////////////////////////////////////////////////////////////////

    PopupDate {
        id: popupDate
    }

    PopupTelemetry {
        id: popupTelemetry
    }

    PopupEncoding {
        id: popupEncoding
    }

    PopupDelete {
        id: popupDelete

        onConfirmed: {
            if (appContent.state === "library") {
                // delete shot
                mediaLibrary.deleteSelected(screenMedia.shot.uuid)
                // then back to media grid
                screenLibrary.state = "stateMediaGrid"
            } else if (appContent.state === "device") {
                // delete shot
                screenDevice.currentDevice.deleteSelected(screenMedia.shot.uuid)
                // then back to media grid
                screenDevice.state = "stateMediaGrid"
            }
        }
    }

    // CONTENT /////////////////////////////////////////////////////////////////

    MediaPreview {
        id: mediaPreview
    }

    ////////////////

    Item {
        id: infosGeneric
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        width: parent.width * 0.20
        height: mediaPreview.overlayHeight
        visible: !mediaPreview.isFullSize

        Column {
            id: infosGenericCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            spacing: 8

            IconSvg {
                id: labelLocation
                width: 28
                height: 28

                visible: shot.location
                color: Theme.colorText
                source: "qrc:/assets/icons/material-icons/duotone/pin_drop.svg"

                Text {
                    id: location
                    height: 28
                    width: infosGenericCol.width-48
                    anchors.left: parent.right
                    anchors.leftMargin: Theme.componentMargin
                    anchors.verticalCenter: parent.verticalCenter

                    text: shot.location
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContentSmall
                    verticalAlignment: Text.AlignVCenter
                }
            }

            IconSvg {
                id: labelDate
                width: 28
                height: 28

                source: "qrc:/assets/icons/material-icons/duotone/date_range.svg"
                color: Theme.colorText

                Text {
                    id: date
                    height: 28
                    width: infosGenericCol.width-48
                    anchors.left: parent.right
                    anchors.leftMargin: Theme.componentMargin
                    anchors.verticalCenter: parent.verticalCenter

                    text: shot.date.toUTCString()
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContentSmall
                    verticalAlignment: Text.AlignVCenter
                }
            }

            IconSvg {
                id: labelDuration
                width: 28
                height: 28

                source: "qrc:/assets/icons/material-icons/duotone/timer.svg"
                color: Theme.colorText

                Text {
                    id: duration
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: Theme.componentMargin
                    anchors.verticalCenter: parent.verticalCenter

                    color: Theme.colorText
                    textFormat: Text.PlainText
                    font.pixelSize: Theme.fontSizeContentSmall
                    verticalAlignment: Text.AlignVCenter
                }
            }

            IconSvg {
                id: labelCamera
                width: 28
                height: 28

                visible: shot && shot.camera
                source: "qrc:/assets/icons/material-symbols/media/camera.svg"
                color: Theme.colorText

                Text {
                    id: camera
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: Theme.componentMargin
                    anchors.verticalCenter: parent.verticalCenter

                    text: shot.camera
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContentSmall
                    verticalAlignment: Text.AlignVCenter
                }
            }

            IconSvg {
                id: labelSize
                width: 28
                height: 28

                source: "qrc:/assets/icons/material-symbols/folder.svg"
                color: Theme.colorText

                Text {
                    id: size
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: Theme.componentMargin
                    anchors.verticalCenter: parent.verticalCenter

                    text: UtilsString.bytesToString_short(shot.datasize)
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContentSmall
                    verticalAlignment: Text.AlignVCenter
                }
            }

            IconSvg {
                id: labelChapters
                width: 28
                height: 28

                source: "qrc:/assets/icons/material-icons/duotone/video_library.svg"
                color: Theme.colorText

                Text {
                    id: chapters
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: Theme.componentMargin
                    anchors.verticalCenter: parent.verticalCenter

                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContentSmall
                    verticalAlignment: Text.AlignVCenter
                }
            }

            ////////////////

            Item { width: 16; height: 16; } // spacer

            IconSvg {
                id: labelDefinitionInternal
                width: 28
                height: 28

                source: "qrc:/assets/icons/material-icons/duotone/aspect_ratio.svg"
                color: Theme.colorText
                visible: (shot.width === shot.widthVisible)

                Text {
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: Theme.componentMargin
                    anchors.verticalCenter: parent.verticalCenter

                    text: shot.width + "x" + shot.height + "   (" + UtilsMedia.varToString(shot.width, shot.height) + ")"
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContentSmall
                    verticalAlignment: Text.AlignVCenter
                }
            }

            IconSvg {
                id: labelDefinitionVisible
                width: 28
                height: 28

                source: "qrc:/assets/icons/material-icons/duotone/aspect_ratio.svg"
                color: Theme.colorText
                visible: (shot.width !== shot.widthVisible)

                Text {
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: Theme.componentMargin
                    anchors.verticalCenter: parent.verticalCenter

                    text: shot.widthVisible + "x" + shot.heightVisible + "  (" + UtilsMedia.varToString(shot.widthVisible, shot.heightVisible) + ")  [rotated]"
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContentSmall
                    verticalAlignment: Text.AlignVCenter
                }
            }

            IconSvg {
                id: labelOrientation
                width: 28
                height: 28

                source: "qrc:/assets/icons/material-icons/duotone/rotate_90_degrees_ccw.svg"
                color: Theme.colorText
                visible: (shot.transformation)

                Text {
                    id: orientation
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: Theme.componentMargin
                    anchors.verticalCenter: parent.verticalCenter

                    text: UtilsMedia.orientationQtToString(shot.transformation)
                    textFormat: Text.PlainText
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContentSmall
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Column {
                id: infosPicture
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0

                spacing: 8

                IconSvg {
                    id: labelISO
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons/material-symbols/media/exposure.svg"
                    color: Theme.colorText

                    Text {
                        id: iso
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter

                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentSmall
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                IconSvg {
                    id: labelFocal
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons/material-symbols/media/center_focus_weak.svg"
                    color: Theme.colorText

                    Text {
                        id: focal
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter

                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentSmall
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                IconSvg {
                    id: labelExposureTime
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons/material-icons/duotone/shutter_speed.svg"
                    color: Theme.colorText

                    Text {
                        id: exposuretime
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter

                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentSmall
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                IconSvg {
                    id: labelMeteringMode
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons/material-symbols/media/filter_center_focus-fill.svg"
                    color: Theme.colorText

                    Text {
                        id: meteringmode
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter

                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentSmall
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                IconSvg {
                    id: labelFlash
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons/material-symbols/media/flash_on.svg"
                    color: Theme.colorText

                    Text {
                        id: flash
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter

                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentSmall
                        verticalAlignment: Text.AlignVCenter
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

                IconSvg {
                    id: labelFramerate
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons/material-symbols/media/theaters.svg"
                    color: Theme.colorText

                    Text {
                        id: framerate
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter

                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentSmall
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                IconSvg {
                    id: labelCodec
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons/material-icons/duotone/memory.svg"
                    color: Theme.colorText

                    Text {
                        id: codec
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter

                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentSmall
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                IconSvg {
                    id: labelBitrate
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons/material-icons/duotone/insert_chart.svg"
                    color: Theme.colorText

                    Text {
                        id: bitrate
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter

                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentSmall
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                IconSvg {
                    id: labelAudioChannels
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons/material-icons/duotone/speaker.svg"
                    color: Theme.colorText

                    Text {
                        id: audioChannels
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter

                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentSmall
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                IconSvg {
                    id: labelTimecode
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons/material-icons/duotone/av_timer.svg"
                    color: Theme.colorText

                    Text {
                        id: timecode
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter

                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentSmall
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            ////////////////
        }
    }

    ////////////////////////////////////////////////////////////////////////////
}
