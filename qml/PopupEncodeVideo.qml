import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2

import com.offloadbuddy.theme 1.0
import com.offloadbuddy.shared 1.0
import "UtilsString.js" as UtilsString
import "UtilsPath.js" as UtilsPath

Popup {
    id: popupEncodeVideo
    width: 640
    height: 480
    padding: 24

    signal confirmed()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    ////////////////////////////////////////////////////////////////////////////

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
        if (shot.shotType === Shared.SHOT_PICTURE_MULTI ||
                shot.shotType === Shared.SHOT_PICTURE_BURST ||
                shot.shotType === Shared.SHOT_PICTURE_TIMELAPSE ||
                shot.shotType === Shared.SHOT_PICTURE_NIGHTLAPSE) {
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

        // Crop
        rectangleCrop.visible = false

        // Filters
        rectangleFilter.visible = false
/*
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
*/
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

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: Theme.colorBackground
        radius: 2
    }

    /*contentItem: */Item {
        id: element
        anchors.fill: parent

        Text {
            id: textArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            text: qsTr("(Re)Encode video")
            font.pixelSize: 24
            color: Theme.colorText
        }

        /////////

        Column {
            id: column
            anchors.top: textArea.bottom
            anchors.topMargin: 16
            anchors.bottom: rowButtons.top
            anchors.bottomMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0

            Item {
                id: rectangleCodec
                height: 48
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0

                Text {
                    id: textCodec
                    width: 128
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Codec")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                Row {
                    anchors.left: textCodec.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    CheckBoxThemed {
                        id: cbCOPY
                        text: qsTr("COPY")
                        onClicked: setCopy()
                    }
                    RadioButtonThemed {
                        id: rbH264
                        text: "H.264"
                        checked: true
                    }
                    RadioButtonThemed {
                        id: rbH265
                        text: "H.265"
                    }
                    RadioButtonThemed {
                        id: rbVP9
                        text: "VP9"
                    }
                    RadioButtonThemed {
                        id: rbAV1
                        text: "AV1"
                        visible: false
                    }
                    RadioButtonThemed {
                        id: rbProRes
                        text: "ProRes"
                        visible: false
                    }
                    RadioButtonThemed {
                        id: rbGIF
                        text: "GIF"
                    }
                }
            }

            Item {
                id: rectangleSpeed
                height: 48
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0

                Text {
                    id: textSpeed
                    width: 128
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Speed index")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                SliderThemed {
                    id: sliderSpeed
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    wheelEnabled: true
                    anchors.left: textSpeed.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    stepSize: 1
                    from: 2
                    to: 0
                    value: 1
                }
            }

            Item {
                id: rectangleQuality
                height: 48
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0

                Text {
                    id: textQuality
                    width: 128
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Quality index")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                SliderThemed {
                    id: sliderQuality
                    anchors.verticalCenterOffset: 0
                    anchors.left: textQuality.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    from: 5
                    to: 1
                    stepSize: 1
                    value: 3
                }
            }

            Item {
                id: rectangleFramerate
                height: 48
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0

                Text {
                    id: textFramerate
                    width: 128
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Framerate")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                Text {
                    id: textFps
                    text: sliderFps.value + " " + qsTr("fps")
                    anchors.left: textFramerate.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 16
                    color: Theme.colorText
                }

                SliderThemed {
                    id: sliderFps
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    to: 60
                    from: 5
                    stepSize: 1
                    anchors.left: textFps.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    value: 30
                }
            }

            Item {
                id: rectangleClip
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                Text {
                    id: titleClip
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Clip video")
                    font.pixelSize: 24
                    color: Theme.colorText
                }

                TextFieldThemed {
                    id: textField_clipstart
                    width: 128
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    anchors.left: titleClip.right
                    anchors.leftMargin: 48

                    placeholderText: "00:00:00"
                    validator: RegExpValidator { regExp: /^(?:(?:([01]?\d|2[0-3]):)?([0-5]?\d):)?([0-5]?\d)$/ }
                }
                TextFieldThemed {
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
                id: rectangleCrop
                height: 48
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0

                Text {
                    id: titleCrop
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Crop video")
                    font.pixelSize: 24
                    color: Theme.colorText
                }
            }

            Item {
                id: rectangleFilter
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                Text {
                    id: titleFilter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 0

                    text: qsTr("Apply filters")
                    font.pixelSize: 24
                    color: Theme.colorText
                }

                CheckBoxThemed {
                    id: checkBox_defish
                    text: qsTr("defisheye")
                    anchors.left: titleFilter.right
                    anchors.leftMargin: 48
                    anchors.verticalCenter: parent.verticalCenter
                }

                CheckBoxThemed {
                    id: checkBox_stab
                    text: qsTr("stabilization")
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: checkBox_defish.right
                    anchors.leftMargin: 16
                }
            }
/*
            Rectangle { // separator
                height: 1
                anchors.right: parent.right
                anchors.left: parent.left
                color: Theme.colorSeparator
            }
*/
            Item { // spacer
                height: 16
                anchors.right: parent.right
                anchors.left: parent.left
            }
            Item {
                id: rectangleDestination
                height: 48
                anchors.right: parent.right
                anchors.left: parent.left

                Text {
                    id: textDestinationTitle
                    width: 128
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Destination")
                    color: Theme.colorSubText
                    font.pixelSize: 16
                }

                ComboBoxThemed {
                    id: comboBoxDestination
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: textDestinationTitle.right
                    anchors.leftMargin: 16

                    ListModel {
                        id: cbDestinations
                        //ListElement { text: "auto"; }
                    }

                    model: cbDestinations

                    Component.onCompleted: updateDestinations()
                    function updateDestinations() {
                        cbDestinations.clear()

                        for (var child in settingsManager.directoriesList) {
                            if (settingsManager.directoriesList[child].available &&
                                    settingsManager.directoriesList[child].directoryContent !== 2)
                                cbDestinations.append( { "text": settingsManager.directoriesList[child].directoryPath } )
                        }
                        cbDestinations.append( { "text": qsTr("Select path manually") } )

                        comboBoxDestination.currentIndex = 0
                        textField_path.text = settingsManager.directoriesList[0].directoryPath
                    }

                    property bool cbinit: false
                    onCurrentIndexChanged: {
                        if (cbinit) {
                            if (comboBoxDestination.currentIndex === cbDestinations.count) {
                                //
                            }
                        } else {
                            cbinit = true;
                        }
                    }
                }
            }

            TextFieldThemed {
                id: textField_path
                height: 40
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0

                visible: (comboBoxDestination.currentIndex === (cbDestinations.count - 1))
                //text: directory.directoryPath

                onVisibleChanged: {
                    //
                }

                FileDialog {
                    id: fileDialogChange
                    title: qsTr("Please choose a destination!")
                    sidebarVisible: true
                    selectExisting: true
                    selectMultiple: false
                    selectFolder: false

                    onAccepted: {
                        textField_path.text = UtilsPath.cleanUrl(fileDialogChange.fileUrl);
                    }
                }

                ButtonThemed {
                    id: button_change
                    width: 72
                    height: 36
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    anchors.verticalCenter: parent.verticalCenter

                    //imageSource: "qrc:/icons_material/outline-folder-24px.svg"
                    text: qsTr("change")
                    onClicked: {
                        fileDialogChange.folder =  "file:///" + textField_path.text
                        fileDialogChange.open()
                    }
                }
            }
        }

        /////////

        Row {
            id: rowButtons
            height: 40
            spacing: 24
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0

            ButtonWireframe {
                id: buttonCancel
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Cancel")
                primaryColor: Theme.colorPrimary
                onClicked: {
                    popupEncodeVideo.close();
                }
            }
            ButtonWireframeImage {
                id: buttonEncode
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Encode")
                source: "qrc:/icons_material/baseline-memory-24px.svg"
                fullColor: true
                primaryColor: Theme.colorPrimary
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
                    popupEncodeVideo.close()
                }
            }
        }
    }
}
