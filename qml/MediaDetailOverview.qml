import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import com.offloadbuddy.shared 1.0
import "qrc:/js/UtilsMedia.js" as UtilsMedia
import "qrc:/js/UtilsString.js" as UtilsString

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

    function updateOverview() {

        date.text = shot.date.toUTCString()
        size.text = UtilsString.bytesToString_short(shot.datasize)
        definition.text = shot.width + "x" + shot.height + "   (" + UtilsMedia.varToString(shot.width, shot.height) + ")"

        labelOrientation.visible = (shot.transformation)
        orientation.text = UtilsMedia.orientationExifToString(shot.transformation)

        // FILE_PICTURE
        if (shot.fileType === Shared.FILE_PICTURE) {
            mediaPreview.setImageMode()

            infosVideo.visible = false

            if (shot.duration > 1) {
                labelDuration.visible = true
                duration.text = shot.duration + " " + qsTr("pictures")
            } else {
                labelDuration.visible = false
            }

            if (shot.iso.length === 0 && shot.focal.length === 0 && shot.exposure.length === 0) {
                infosPicture.visible = false
            } else {
                infosPicture.visible = true

                labelISO.visible = (shot.iso.length)
                iso.text = qsTr("ISO") + " " + shot.iso
                labelFocal.visible = (shot.focal.length)
                focal.text = shot.focal
                labelExposure.visible = (shot.exposure.length)
                exposure.text = shot.exposure
                labelFlash.visible = (shot.flash)
                flash.text = qsTr("Enabled")
            }
        }

        // FILE_VIDEO
        if (shot.fileType === Shared.FILE_VIDEO) {
            mediaPreview.setVideoMode()

            infosPicture.visible = false
            infosVideo.visible = true

            labelChapters.visible = (shot.chapters > 1)
            chapters.text = shot.chapters + qsTr(" chapters")

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
        popupEncoding.setClip(mediaPreview.startLimit, mediaPreview.stopLimit)
        popupEncoding.setOrientation(mediaPreview.rotation, mediaPreview.hflipped, mediaPreview.vflipped)
        popupEncoding.setCrop(mediaPreview.cropX, mediaPreview.cropY,
                                 mediaPreview.cropW, mediaPreview.cropH)
        popupEncoding.open()
    }
    function openTelemetryPopup() {
        popupTelemetry.updateTelemetryPanel(shot)
        popupTelemetry.open()
    }
    function openDeletePopup() {
        popupDelete.open()
    }
    function openDatePopup() {
        popupDate.loadDates()
        popupDate.open()
    }

    // POPUPS //////////////////////////////////////////////////////////////////

    PopupDate {
        id: popupDate
        x: (appWindow.width / 2) - (popupDate.width / 2) - (appSidebar.width)
        y: (appWindow.height / 2) - (popupDate.height / 2) - (rectangleHeader.height)

        onConfirmed: {
            //
        }
    }

    PopupTelemetry {
        id: popupTelemetry
        x: (appWindow.width / 2) - (popupDate.width / 2) - (appSidebar.width)
        y: (appWindow.height / 2) - (popupDate.height / 2) - (rectangleHeader.height)

        onConfirmed: {
            //
        }
    }

    PopupDelete {
        id: popupDelete
        x: (appWindow.width / 2) - (popupDelete.width / 2) - (appSidebar.width)
        y: (appWindow.height / 2) - (popupDelete.height / 2) - (rectangleHeader.height)

        message: qsTr("Are you sure you want to delete the current shot?")
        onConfirmed: {
            if (appContent.state === "library") {
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

    PopupEncoding {
        id: popupEncoding
        x: (appWindow.width / 2) - (popupEncoding.width / 2) - (appSidebar.width)
        y: (appWindow.height / 2) - (popupEncoding.height / 2) - (rectangleHeader.height)

        onConfirmed: {
            //
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

        width: 320
        height: mediaPreview.overlayHeight
        visible: !mediaPreview.isFullScreen

        Column {
            id: infosGenericCol
            width: 320

            spacing: 8

            ImageSvg {
                id: labelDate
                width: 28
                height: 28

                source: "qrc:/assets/icons_material/baseline-date_range-24px.svg"
                color: Theme.colorText

                Text {
                    id: date
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: 16

                    color: Theme.colorText
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeContentSmall
                }
            }

            ImageSvg {
                id: labelCamera
                width: 28
                height: 28

                visible: shot && shot.camera
                source: "qrc:/assets/icons_material/baseline-camera-24px.svg"
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
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }
            }

            ImageSvg {
                id: labelDuration
                width: 28
                height: 28

                source: "qrc:/assets/icons_material/baseline-timer-24px.svg"
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
                    font.pixelSize: Theme.fontSizeContentSmall
                }
            }

            ImageSvg {
                id: labelOrientation
                width: 28
                height: 28

                source: "qrc:/assets/icons_material/baseline-screen_rotation-24px.svg"
                color: Theme.colorText

                Text {
                    id: orientation
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    color: Theme.colorText
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeContentSmall
                }
            }

            ImageSvg {
                id: labelSize
                width: 28
                height: 28

                source: "qrc:/assets/icons_material/baseline-folder-24px.svg"
                color: Theme.colorText

                Text {
                    id: size
                    height: 28
                    anchors.left: parent.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    color: Theme.colorText
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeContentSmall
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
                    id: labelDefinition
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons_material/baseline-aspect_ratio-24px.svg"
                    color: Theme.colorText

                    Text {
                        id: definition
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter

                        text: shot.width + "x" + shot.height + "   (" + UtilsMedia.varToString(shot.width, shot.height) + ")"
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeContentSmall
                        color: Theme.colorText
                    }
                }

                ImageSvg {
                    id: labelISO
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons_material/baseline-iso-24px.svg"
                    color: Theme.colorText

                    Text {
                        id: iso
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter

                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeContentSmall
                        color: Theme.colorText
                    }
                }

                ImageSvg {
                    id: labelFocal
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons_material/baseline-center_focus_weak-24px.svg"
                    color: Theme.colorText

                    Text {
                        id: focal
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter

                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeContentSmall
                        color: Theme.colorText
                    }
                }

                ImageSvg {
                    id: labelExposure
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons_material/baseline-shutter_speed-24px.svg"
                    color: Theme.colorText

                    Text {
                        id: exposure
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter

                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeContentSmall
                        color: Theme.colorText
                    }
                }

                ImageSvg {
                    id: labelFlash
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons_material/baseline-flash_on-24px.svg"
                    color: Theme.colorText

                    Text {
                        id: flash
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter

                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeContentSmall
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
                    id: labelDefinition2
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons_material/baseline-aspect_ratio-24px.svg"
                    color: Theme.colorText

                    Text {
                        id: definition2
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter

                        text: shot.width + "x" + shot.height + "   (" + UtilsMedia.varToString(shot.width, shot.height) + ")"
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeContentSmall
                        color: Theme.colorText
                    }
                }

                ImageSvg {
                    id: labelChapters
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons_material/baseline-video_library-24px.svg"
                    color: Theme.colorText

                    Text {
                        id: chapters
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter

                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeContentSmall
                        color: Theme.colorText
                    }
                }

                ImageSvg {
                    id: labelFramerate
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons_material/outline-local_movies-24px.svg"
                    color: Theme.colorText

                    Text {
                        id: framerate
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter

                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeContentSmall
                        color: Theme.colorText
                    }
                }

                ImageSvg {
                    id: labelCodec
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons_material/baseline-memory-24px.svg"
                    color: Theme.colorText

                    Text {
                        id: codec
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter

                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeContentSmall
                        color: Theme.colorText
                    }
                }

                ImageSvg {
                    id: labelBitrate
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons_material/baseline-insert_chart_outlined-24px.svg"
                    color: Theme.colorText

                    Text {
                        id: bitrate
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter

                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeContentSmall
                        color: Theme.colorText
                    }
                }

                ImageSvg {
                    id: labelAudioChannels
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons_material/baseline-speaker-24px.svg"
                    color: Theme.colorText

                    Text {
                        id: audioChannels
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter

                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeContentSmall
                        color: Theme.colorText
                    }
                }

                ImageSvg {
                    id: labelTimecode
                    width: 28
                    height: 28

                    source: "qrc:/assets/icons_material/baseline-av_timer-24px.svg"
                    color: Theme.colorText

                    Text {
                        id: timecode
                        height: 28
                        anchors.left: parent.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter

                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeContentSmall
                        color: Theme.colorText
                    }
                }
            }
        }
    }
}
