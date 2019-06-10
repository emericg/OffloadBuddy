import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.shared 1.0
import "UtilsString.js" as UtilsString

Item {
    id: itemEncode
    width: 600
    height: 500

    property var mediaProvider: null
    property var currentShot: null
    property int clipStartMs: -1
    property int clipDurationMs: -1

    function updateEncodePanel(shot) {
        currentShot = shot

        // GIF only appear for short videos
        if (shot.duration < 10000) {
            rbGIF.visible = true
        } else {
            rbGIF.visible = false
        }

        // Framerate handler
        if (shot.type === Shared.SHOT_PICTURE_MULTI ||
            shot.type === Shared.SHOT_PICTURE_BURST ||
            shot.type === Shared.SHOT_PICTURE_TIMELAPSE ||
            shot.type === Shared.SHOT_PICTURE_NIGHTLAPSE) {
            // timelapses
            sliderFps.value = 30
            sliderFps.from = 5
            sliderFps.to = 120
            sliderFps.stepSize = 1
        } else {
            // videos
            var divider = 1
            if (shot.framerate >= 220)
                divider = 8
            else if (shot.framerate >= 110)
                divider = 4
            else if (shot.framerate >= 48)
                divider = 2

            if (divider > 1) {
                sliderFps.visible = true
                sliderFps.value = (shot.framerate).toFixed(3)
                sliderFps.from = (shot.framerate/divider).toFixed(3)
                sliderFps.to = (shot.framerate).toFixed(3)
                sliderFps.stepSize = (shot.framerate/divider).toFixed(3)
            } else {
                sliderFps.visible = false
            }
        }

        // Clip handler
        setClip(-1, -1)

        // Filters
        rectangleFilter.visible = false

        // Handle destination(s)
        cbDestinations.clear()
        cbDestinations.append( { "text": qsTr("auto") } )

        for (var child in settingsManager.directoriesList) {
            //console.log("destination: " + settingsManager.directoriesList[child].directoryPath)
            if (settingsManager.directoriesList[child].available)
                if (settingsManager.directoriesList[child].directoryContent < 2)
                    cbDestinations.append( { "text": settingsManager.directoriesList[child].directoryPath } )
        }
        comboBoxDestination.currentIndex = 0
        comboBoxDestination.enabled = false
    }

    function setCopy() {
        if (cbCOPY.checked === true) {
            rbH264.enabled = false
            rbH265.enabled = false
            rbVP9.enabled = false
            rbGIF.enabled = false
            rectangleQuality.visible = false
            rectangleSpeed.visible = false
            rectangleFramerate.visible = false
        } else {
            rbH264.enabled = true
            rbH265.enabled = true
            rbVP9.enabled = true
            rbGIF.enabled = true
            rectangleQuality.visible = true
            rectangleSpeed.visible = true
            rectangleFramerate.visible = true
        }
    }

    function setClip(clipStart, clipStop) {
        if (clipStart > 0 || clipStop > 0) {
            if (clipStart < 0) clipStart = 0
            if (clipStop < 0) clipStop = currentShot.duration
            clipStartMs = clipStart
            clipDurationMs = clipStop - clipStart
            textField_clipstart.text = UtilsString.durationToString_ffmpeg(clipStart)
            textField_clipstop.text = UtilsString.durationToString_ffmpeg(clipStop)

            cbCOPY.visible = true
            cbCOPY.checked = true
            setCopy()
            rectangleClip.visible = true

            if (clipDurationMs < 10000) {
                rbGIF.visible = true
            } else {
                rbGIF.visible = false
            }
        } else {
            clipStartMs = -1
            clipDurationMs = -1

            cbCOPY.visible = false
            cbCOPY.checked = false
            setCopy()
            rectangleClip.visible = false
        }
    }

    // PANEL ///////////////////////////////////////////////////////////////////

    Rectangle {
        id: rectangleEncode
        color: "white"
        anchors.bottom: rectangleDestination.top
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.top: parent.top

        Text {
            id: titleEncode
            text: qsTr("Encoding settings")
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16
            font.pixelSize: 24
        }

        Item {
            id: rectangleCodec
            height: 40
            anchors.top: titleEncode.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            Text {
                id: textCodec
                text: qsTr("Codec")
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16
                font.pixelSize: 14
            }

            CheckBox {
                id: cbCOPY
                text: qsTr("COPY")
                anchors.left: textCodec.right
                anchors.leftMargin: 48
                anchors.verticalCenter: parent.verticalCenter
                onClicked: setCopy()
            }

            RadioButton {
                id: rbH264
                text: "H.264"
                checked: true
                anchors.left: cbCOPY.right
                anchors.leftMargin: 16
                anchors.verticalCenterOffset: 0
                anchors.verticalCenter: parent.verticalCenter
            }

            RadioButton {
                id: rbH265
                text: "H.265"
                anchors.left: rbH264.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
            }

            RadioButton {
                id: rbVP9
                text: "VP9"
                anchors.left: rbH265.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
            }

            RadioButton {
                id: rbGIF
                text: "GIF"
                anchors.left: rbVP9.right
                anchors.leftMargin: 16
                anchors.verticalCenterOffset: 0
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Item {
            id: rectangleSpeed
            height: 40
            anchors.top: rectangleCodec.bottom
            anchors.topMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            Text {
                id: textSpeed
                text: qsTr("Speed index")
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16
                font.pixelSize: 14
            }

            Slider {
                id: sliderSpeed
                from: 2
                wheelEnabled: true
                anchors.right: parent.right
                anchors.rightMargin: 48
                stepSize: 1
                to: 0
                anchors.left: textSpeed.right
                anchors.leftMargin: 48
                anchors.verticalCenter: parent.verticalCenter
                value: 1
            }
        }

        Item {
            id: rectangleQuality
            height: 40
            anchors.top: rectangleSpeed.bottom
            anchors.topMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            Text {
                id: textQuality
                text: qsTr("Quality index")
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16
                font.pixelSize: 14
            }

            Slider {
                id: sliderQuality
                anchors.verticalCenterOffset: 0
                from: 5
                to: 1
                stepSize: 1
                anchors.left: textQuality.right
                anchors.leftMargin: 48
                anchors.right: parent.right
                anchors.rightMargin: 48
                anchors.verticalCenter: parent.verticalCenter
                value: 3
            }
        }

        Item {
            id: rectangleFramerate
            height: 40
            anchors.top: rectangleQuality.bottom
            anchors.topMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            Text {
                id: textFramerate
                text: qsTr("Framerate")
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16
                font.pixelSize: 14
            }

            Text {
                id: textFps
                text: sliderFps.value + " " + qsTr("fps")
                anchors.left: textFramerate.right
                anchors.leftMargin: 32
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 14
            }

            Slider {
                id: sliderFps
                anchors.right: parent.right
                anchors.rightMargin: 48
                to: 60
                from: 5
                stepSize: 1
                anchors.left: textFps.right
                anchors.leftMargin: 48
                anchors.verticalCenter: parent.verticalCenter
                value: 30
            }
        }

        Item {
            id: rectangleClip
            height: 48
            anchors.top: rectangleFramerate.bottom
            anchors.topMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0

            Text {
                id: titleClip
                text: qsTr("Clip video")
                anchors.verticalCenter: parent.verticalCenter
                font.bold: false
                anchors.left: parent.left
                anchors.leftMargin: 16
                font.pixelSize: 24
            }

            TextField {
                id: textField_clipstart
                width: 128
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                anchors.left: titleClip.right
                anchors.leftMargin: 48

                placeholderText: "00:00:00"
                validator: RegExpValidator { regExp: /^(?:(?:([01]?\d|2[0-3]):)?([0-5]?\d):)?([0-5]?\d)$/ }
            }
            TextField {
                id: textField_clipstop
                width: 128
                anchors.left: textField_clipstart.right
                anchors.leftMargin: 16
                anchors.verticalCenter: textField_clipstart.verticalCenter
                horizontalAlignment: Text.AlignHCenter

                placeholderText: "00:00:00"
                validator: RegExpValidator { regExp: /^(?:(?:([01]?\d|2[0-3]):)?([0-5]?\d):)?([0-5]?\d)$/ }
            }
        }

        Item {
            id: rectangleFilter
            height: 96
            anchors.top: rectangleClip.bottom
            anchors.topMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0

            Text {
                id: titleFilter
                x: 16
                text: qsTr("Apply filters")
                anchors.top: parent.top
                anchors.topMargin: 16
                font.bold: false
                anchors.left: parent.left
                anchors.leftMargin: 16
                font.pixelSize: 24
            }

            CheckBox {
                id: checkBox_crop
                x: 280
                y: 61
                text: qsTr("crop")
                anchors.verticalCenter: checkBox_stab.verticalCenter
            }

            CheckBox {
                id: checkBox_defish
                x: 159
                y: 61
                text: qsTr("defisheye")
                anchors.verticalCenter: checkBox_stab.verticalCenter
            }

            CheckBox {
                id: checkBox_stab
                text: qsTr("stabilization")
                anchors.top: titleFilter.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 16
            }
        }
    }

    Rectangle {
        id: rectangleDestination
        height: 64
        color: "#f4f4f4"
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.bottom: rectangleAction.top
        anchors.left: parent.left

        Text {
            id: textDestinationTitle
            text: qsTr("Select destination")
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 12
            anchors.left: parent.left
            font.pixelSize: 16
        }

        ComboBox {
            id: comboBoxDestination
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: textDestinationTitle.right
            anchors.leftMargin: 12

            ListModel {
                id: cbDestinations
                ListElement { text: "auto"; }
            }

            model: cbDestinations
        }
    }

    Rectangle {
        id: rectangleAction
        y: 540
        height: 64
        color: "#c9c9c9"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        Button {
            id: buttonStart
            text: qsTr("Start encoding!")
            font.pixelSize: 16
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 12

            onClicked: {
                var codec = "H.264"
                if (rbH264.checked)
                    codec = rbH264.text
                else if (rbH265.checked)
                    codec = rbH265.text
                else if (rbVP9.checked)
                    codec = rbVP9.text
                else if (rbGIF.checked)
                    codec = rbGIF.text

                if (clipStartMs > 0 && clipDurationMs > 0)
                    if (cbCOPY.checked)
                        codec = "copy"

                var fps = -1;
                if (sliderFps.value.toFixed(3) !== currentShot.framerate.toFixed(3))
                    fps = sliderFps.value

                if (typeof currentDevice !== "undefined")
                    mediaProvider = currentDevice
                else if (typeof mediaLibrary !== "undefined")
                    mediaProvider = mediaLibrary

                mediaProvider.reencodeSelected(currentShot.uuid, codec,
                                          sliderQuality.value,
                                          sliderSpeed.value,
                                          fps,
                                          clipStartMs,
                                          clipDurationMs)
                popupEncode.close()
            }
        }

        Button {
            id: buttonCancel
            text: qsTr("Cancel")
            font.pixelSize: 16
            anchors.left: buttonStart.right
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            onClicked: popupEncode.close()
        }
    }
}
