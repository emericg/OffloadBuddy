import QtQuick 2.9
import QtQuick.Controls 2.2
import QtMultimedia 5.9
import QtGraphicalEffects 1.0

import com.offloadbuddy.theme 1.0
import com.offloadbuddy.shared 1.0
import "UtilsString.js" as UtilsString

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
        y: (parent.height - 64 - panelEncode.height) / 2
        closePolicy: Popup.CloseOnEscape /*| Popup.CloseOnPressOutsideParent*/

        PanelEncode {
            id: panelEncode
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    MediaPreview {
        id: mediaPreview
    }

    function setPause() {
        mediaPreview.setPause()
    }

    ////////////////////////////////////////////////////////////////////////////

    function updateOverview() {

        textFileList.text = shot.fileList

        if (shot.camera) {
            labelCamera.visible = true
            labelCamera.anchors.topMargin = 8
        } else {
            labelCamera.visible = false
            labelCamera.anchors.topMargin = -24
        }

        if (shot.orientation) {
            labelOrientation.visible = true
            labelOrientation.anchors.topMargin = 8
        } else {
            labelOrientation.visible = false
            labelOrientation.anchors.topMargin = -24
        }

        if (shot.type >= Shared.SHOT_PICTURE) {

            mediaPreview.setImageMode()

            rectanglePicture.visible = true
            rectangleVideo.visible = false

            codecAudio.visible = false
            codecVideo.visible = true
            codecVideo.anchors.right = buttonOverview.left
            codecVideoText.text = shot.codecVideo

            if (shot.iso.length === 0 && shot.focal.length === 0 && shot.exposure.length === 0) {
                rectanglePicture.visible = false
            }

            if (shot.duration > 1) {
                labelDuration.visible = true
                labelDuration.anchors.topMargin = 8
                duration.text = shot.duration + " " + qsTr("pictures")
            } else {
                labelDuration.visible = false
                labelDuration.anchors.topMargin = -24
            }
        } else {
            mediaPreview.setVideoMode()

            rectanglePicture.visible = false
            rectangleVideo.visible = true

            //console.log("shot.previewPhoto :" + shot.previewVideo)

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
            labelDuration.anchors.topMargin = 8
            duration.text = UtilsString.durationToString(shot.duration)

            bitrate.text = UtilsString.bitrateToString(shot.bitrate)
            codec.text = shot.codecVideo
            framerate.text = UtilsString.framerateToString(shot.framerate)
            timecode.text = shot.timecode
        }

        size.text = UtilsString.bytesToString_short(shot.datasize)
        if (shot.size !== shot.datasize) {
            size.text += "   (" + qsTr("full: ") + UtilsString.bytesToString_short(shot.size) + ")"
        }
    }

    Rectangle {
        id: rectangleMetadatas
        width: 320
        color: Theme.colorContentBox
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
                color: Theme.colorContentText
                visible: Theme.colorContentText !== "#000000" ? true : false
            }

            Text {
                id: date
                height: 28
                anchors.left: parent.right
                anchors.leftMargin: 16

                color: Theme.colorContentText
                text: shot.date.toUTCString()
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Theme.fontSizeContentText
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
                color: Theme.colorContentText
                visible: Theme.colorContentText !== "#000000" ? true : false
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
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorContentText
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
                color: Theme.colorContentText
                visible: Theme.colorContentText !== "#000000" ? true : false
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
                color: Theme.colorContentText
                font.pixelSize: Theme.fontSizeContentText
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
                color: Theme.colorContentText
                visible: Theme.colorContentText !== "#000000" ? true : false
            }

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
                color: Theme.colorContentText
            }
        }

        Image {
            id: labelOrientation
            width: 28
            height: 28
            anchors.top: labelDefinition.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 16

            source: "qrc:/icons_material/baseline-screen_rotation-24px.svg"
            sourceSize.width: width
            sourceSize.height: height

            ColorOverlay {
                anchors.fill: parent
                source: parent
                color: Theme.colorContentText
                visible: Theme.colorContentText !== "#000000" ? true : false
            }

            Text {
                id: orientation
                height: 28
                anchors.left: parent.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                color: Theme.colorContentText
                text: UtilsString.orientationToString(shot.orientation)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Theme.fontSizeContentText
            }
        }

        Image {
            id: labelSize
            width: 28
            height: 28
            anchors.top: labelOrientation.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 16

            source: "qrc:/icons_material/baseline-folder-24px.svg"
            sourceSize.width: width
            sourceSize.height: height

            ColorOverlay {
                anchors.fill: parent
                source: parent
                color: Theme.colorContentText
                visible: Theme.colorContentText !== "#000000" ? true : false
            }

            Text {
                id: size
                height: 28
                anchors.left: parent.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                color: Theme.colorContentText
                text: UtilsString.bytesToString_short(shot.datasize)
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Theme.fontSizeContentText
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
                    color: Theme.colorContentText
                    visible: Theme.colorContentText !== "#000000" ? true : false
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
                    font.pixelSize: Theme.fontSizeContentText
                    color: Theme.colorContentText
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
                    color: Theme.colorContentText
                    visible: Theme.colorContentText !== "#000000" ? true : false
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
                    font.pixelSize: Theme.fontSizeContentText
                    color: Theme.colorContentText
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
                    color: Theme.colorContentText
                    visible: Theme.colorContentText !== "#000000" ? true : false
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
                    font.pixelSize: Theme.fontSizeContentText
                    color: Theme.colorContentText
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
                color: Theme.colorContentText
                text: qsTr("Chapters:")
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.top: labelTimecode.bottom
                anchors.topMargin: 0
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: Theme.fontSizeContentText

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
                    font.pixelSize: Theme.fontSizeContentText
                    color: Theme.colorContentText
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
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorContentText

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
                    color: Theme.colorContentText
                    font.pixelSize: Theme.fontSizeContentText
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
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorContentText

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
                    color: Theme.colorContentText
                    font.pixelSize: Theme.fontSizeContentText
                }
            }

            Text {
                id: labelBitrate
                width: 290
                height: 28
                color: Theme.colorContentText
                text: qsTr("Bitrate:")
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.top: labelFramerate.bottom
                anchors.topMargin: 0
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: Theme.fontSizeContentText

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
                    color: Theme.colorContentText
                    font.pixelSize: Theme.fontSizeContentText
                }
            }

            Text {
                id: labelFramerate
                width: 290
                height: 28
                color: Theme.colorContentText
                text: qsTr("Framerate:")
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.top: labelCodec.bottom
                anchors.topMargin: 0
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: Theme.fontSizeContentText

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
                    color: Theme.colorContentText
                    font.pixelSize: Theme.fontSizeContentText
                }
            }
        }

        Rectangle {
            id: rectangleFiles
            height: 256
            color: Theme.colorContentSubBox
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
                color: Theme.colorContentText
                font.bold: true
                font.pixelSize: Theme.fontSizeContentText
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
                color: Theme.colorContentText
                font.pixelSize: Theme.fontSizeContentText
            }
        }
    }
}
