import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3

import ThemeEngine 1.0
import com.offloadbuddy.shared 1.0
import "qrc:/js/UtilsNumber.js" as UtilsNumber
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Popup {
    id: popupEncoding
    x: (appWindow.width / 2) - (width / 2) - (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 640
    padding: 0

    signal confirmed()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    ////////////////////////////////////////////////////////////////////////////

    property string mode: ""
    property var mediaProvider: null
    property var currentShot: null

    property int clipStartMs: -1
    property int clipDurationMs: -1

    property int clipTransformation: 0
    property int clipRotation: 0
    property bool clipVFlip: false
    property bool clipHFlip: false

    property int clipCropX: 0
    property int clipCropY: 0
    property int clipCropW: 0
    property int clipCropH: 0

    function updateEncodePanel(shot) {
        currentShot = shot

        // Set mode
        if (shot.shotType === Shared.SHOT_PICTURE) {
            // image
            setImageMode()
        } else if (shot.shotType === Shared.SHOT_PICTURE_MULTI || shot.shotType === Shared.SHOT_PICTURE_BURST ||
                   shot.shotType === Shared.SHOT_PICTURE_TIMELAPSE || shot.shotType === Shared.SHOT_PICTURE_NIGHTLAPSE) {
            // timelapse
           setTimelapseMode()

            // GIF only appear for short timelapse
            if (shot.duration < 1000) { // check value
                rbGIF.visible = true
            } else {
                rbGIF.visible = false
            }
        } else {
            // video
            setVideoMode()

            // GIF only appear for short videos (7s)
            if (shot.duration < 7500) {
                rbGIF.visible = true
            } else {
                rbGIF.visible = false
            }
        }

        // Clip handler
        setClip(-1, -1)

        // Resolution

        // Orientation
        setOrientation(0, false, false)

        // Crop
        rectangleCrop.visible = false

        // Filters
        rectangleFilter.visible = false

        // Handle destination(s)
        comboBoxDestination.updateDestinations()
    }

    function setClip(clipStart, clipStop) {
        //console.log("setClip() " + clipStart + "/" + clipStop)

        if (shot.shotType >= Shared.SHOT_PICTURE) {
            clipStartMs = -1
            clipDurationMs = -1

            cbCOPY.visible = false
            cbCOPY.checked = false
            rectangleClip.visible = false

            return
        }

        if (clipStart > 0 || (clipStop > 0 && clipStop < currentShot.duration)) {
            if (clipStart < 0) clipStart = 0
            if (clipStop < 0) clipStop = currentShot.duration
            clipStartMs = clipStart
            clipDurationMs = clipStop - clipStart
            textField_clipstart.text = UtilsString.durationToString_ISO8601_full(clipStart)
            textField_clipstop.text = UtilsString.durationToString_ISO8601_full(clipStop)

            cbCOPY.visible = true
            cbCOPY.checked = true
            toggleCopy()
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
            toggleCopy()
            rectangleClip.visible = false
        }
    }

    function setOrientation(rotation, vflip, hflip) {
        //console.log("setOrientation() " + rotation + " " + vflip + " " + hflip)

        if (rotation || vflip || hflip) {
            rectangleOrientation.visible = true
            clipRotation = rotation
            clipVFlip = vflip
            clipHFlip = hflip

            if (vflip && hflip) {
                clipRotation += 180
                clipRotation %= 360
                clipVFlip = false
                clipHFlip = false
            }

            if (clipRotation === 0 && !clipHFlip && !clipVFlip)
                clipTransformation = 1
            if (clipRotation === 0 && clipHFlip && !clipVFlip)
                clipTransformation = 2
            if (clipRotation === 180 && !clipHFlip && !clipVFlip)
                clipTransformation = 3
            if (clipRotation === 0 && !clipHFlip && clipVFlip)
                clipTransformation = 4
            if (clipRotation === 270 && clipHFlip && !clipVFlip)
                clipTransformation = 5
            if (clipRotation === 90 && !clipHFlip && !clipVFlip)
                clipTransformation = 6
            if (clipRotation === 90 && clipHFlip && !clipVFlip)
                clipTransformation = 7
            if (clipRotation === 270 && !clipHFlip && !clipVFlip)
                clipTransformation = 8
        } else {
            rectangleOrientation.visible = false
            clipTransformation = 1
            clipRotation = 0
            clipVFlip = false
            clipHFlip = false
        }
    }

    function setCrop(x, y, width, height) {
        //console.log("setCrop() " + x + ":" + y + " " + width + "x" + height)

        if (x > 0.0 || y > 0.0 || width < 1.0 || height < 1.0) {
            rectangleCrop.visible = true
            clipCropX = Math.round(currentShot.width * x)
            clipCropY = Math.round(currentShot.height * y)
            clipCropW = Math.round(currentShot.width * width)
            clipCropH = Math.round(currentShot.height * height)
            textField_cropCoord.text = clipCropX + ":" + clipCropY
            textField_cropSize.text = clipCropW + "x" + clipCropH
        } else {
            rectangleCrop.visible = false
        }
    }

    ////////

    function setImageMode() {
        titleText.text = qsTr("Image encoding")
        mode = "image"
    }

    function setVideoMode() {
        titleText.text = qsTr("Video encoding")
        mode = "video"

        cbTimelapse.checked = false
        cbTimelapse.visible = true

        timelapseFramerate.from = 1
        timelapseFramerate.to = 15
        timelapseFramerate.value = 10

        if (!rbGIF.visible && rbGIF.checked) rbH264.checked = true
    }

    function setTimelapseMode() {
        titleText.text = qsTr("Timelapse encoding")
        mode = "timelapse"

        cbTimelapse.checked = false
        cbTimelapse.visible = false

        timelapseFramerate.from = 1
        timelapseFramerate.to = 60
        timelapseFramerate.value = 15

        if (!rbGIF.visible && rbGIF.checked) rbH264.checked = true
    }

    ////////

    function toggleTimelapse() {
        //
    }

    function toggleCopy() {
        if (cbCOPY.checked === true) {
            rbH264.enabled = false
            rbH265.enabled = false
            rbVP9.enabled = false
            rbGIF.enabled = false
        } else {
            rbH264.enabled = true
            rbH265.enabled = true
            rbVP9.enabled = true
            rbGIF.enabled = true
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: Theme.colorBackground
        radius: Theme.componentRadius
    }

    contentItem: Column {
        id: contentColumn
        spacing: 16

        property int legendWidth: 128

        Rectangle {
            id: titleArea
            height: 64
            anchors.left: parent.left
            anchors.right: parent.right
            radius: Theme.componentRadius
            color: ThemeEngine.colorPrimary

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }

            Text {
                id: titleText
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("(Re)Encode video")
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: "white"
            }
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24

            //////////////////

            Item {
                id: rectangleVideoCodec
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right

                visible: (mode === "video" || mode === "timelapse")

                Text {
                    id: textCodec
                    width: contentColumn.legendWidth
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
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("COPY")
                        onClicked: toggleCopy()
                    }
                    RadioButtonThemed {
                        id: rbH264
                        anchors.verticalCenter: parent.verticalCenter
                        text: "H.264"
                        checked: true
                    }
                    RadioButtonThemed {
                        id: rbH265
                        anchors.verticalCenter: parent.verticalCenter
                        text: "H.265"
                    }
                    RadioButtonThemed {
                        id: rbVP9
                        anchors.verticalCenter: parent.verticalCenter
                        text: "VP9"
                    }
                    RadioButtonThemed {
                        id: rbAV1
                        anchors.verticalCenter: parent.verticalCenter
                        text: "AV1"
                        visible: false
                    }
                    RadioButtonThemed {
                        id: rbProRes
                        anchors.verticalCenter: parent.verticalCenter
                        text: "ProRes"
                        visible: false
                    }
                    RadioButtonThemed {
                        id: rbGIF
                        anchors.verticalCenter: parent.verticalCenter
                        text: "GIF"
                    }
                }
            }

            Item {
                id: rectangleImageCodec
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right

                visible: (mode === "image")

                Text {
                    id: textFormat
                    width: contentColumn.legendWidth
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Format")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                Row {
                    anchors.left: textFormat.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    RadioButtonThemed {
                        id: rbPNG
                        anchors.verticalCenter: parent.verticalCenter
                        text: "PNG"
                    }
                    RadioButtonThemed {
                        id: rbJPEG
                        anchors.verticalCenter: parent.verticalCenter
                        text: "JPEG"
                        checked: true
                    }
                    RadioButtonThemed {
                        id: rbWEBP
                        anchors.verticalCenter: parent.verticalCenter
                        text: "WebP"
                    }
                    RadioButtonThemed {
                        id: rbAVIF
                        anchors.verticalCenter: parent.verticalCenter
                        text: "AVIF"
                        visible: false
                    }
                    RadioButtonThemed {
                        id: rbHEIF
                        anchors.verticalCenter: parent.verticalCenter
                        text: "HEIF"
                        visible: false
                    }
                }
            }

            ////////////////

            Item {
                id: rectangleEncodingQuality
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right

                visible: !cbCOPY.checked && !rbGIF.checked && !rbPNG.checked

                Text {
                    id: textQuality
                    width: contentColumn.legendWidth
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Quality index")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                SliderThemed {
                    id: sliderQuality
                    anchors.left: textQuality.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 0

                    from: -2
                    to: 2
                    stepSize: 1
                    value: 0
                }
            }

            Item {
                id: rectangleEncodingSpeed
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right

                visible: (mode === "video" || mode === "timelapse") && !cbCOPY.checked && !rbGIF.checked

                Text {
                    id: textSpeed
                    width: contentColumn.legendWidth
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

            //////////////////

            Row {
                id: rectangleDefinition
                anchors.left: parent.left
                anchors.right: parent.right
                height: 48
                spacing: 16

                Text {
                    width: contentColumn.legendWidth
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Definition")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                ItemLilMenu {
                    anchors.verticalCenter: parent.verticalCenter
                    width: selectorGifRes.width

                    visible: rbGIF.checked

                    Row {
                        id: selectorGifRes
                        height: parent.height

                        property int res: 400

                        ItemLilMenuButton {
                            text: "240p"
                            selected: selectorGifRes.res === 240
                            onClicked: selectorGifRes.res = 240
                        }
                        ItemLilMenuButton {
                            text: "320p"
                            selected: selectorGifRes.res === 320
                            onClicked: selectorGifRes.res = 320
                        }
                        ItemLilMenuButton {
                            text: "400p"
                            selected: selectorGifRes.res === 400
                            onClicked: selectorGifRes.res = 400
                        }
                        ItemLilMenuButton {
                            text: "480p"
                            selected: selectorGifRes.res === 480
                            onClicked: selectorGifRes.res = 480
                        }
                    }
                }

                ItemLilMenu {
                    anchors.verticalCenter: parent.verticalCenter
                    width: selectorVideoRes.width

                    visible: !rbGIF.checked

                    Row {
                        id: selectorVideoRes
                        height: parent.height

                        property int res: 1080

                        ItemLilMenuButton {
                            text: "480p"
                            visible: shot.height >= 480
                            selected: selectorVideoRes.res === 480
                            onClicked: selectorVideoRes.res = 480
                        }
                        ItemLilMenuButton {
                            text: "720p"
                            visible: shot.height >= 720
                            selected: selectorVideoRes.res === 720
                            onClicked: selectorVideoRes.res = 720
                        }
                        ItemLilMenuButton {
                            text: "1080p"
                            visible: shot.height >= 1080
                            selected: selectorVideoRes.res === 1080
                            onClicked: selectorVideoRes.res = 1080
                        }
                        ItemLilMenuButton {
                            text: "1440p"
                            visible: shot.height >= 1440
                            selected: selectorVideoRes.res === 1440
                            onClicked: selectorVideoRes.res = 1440
                        }
                        ItemLilMenuButton {
                            text: "2160p"
                            visible: shot.height >= 2160
                            selected: selectorVideoRes.res === 2160
                            onClicked: selectorVideoRes.res = 2160
                        }
                        ItemLilMenuButton {
                            text: "2880p"
                            visible: shot.height >= 2880
                            selected: selectorVideoRes.res === 2880
                            onClicked: selectorVideoRes.res = 2880
                        }
                        ItemLilMenuButton {
                            text: "4320p"
                            visible: shot.height >= 4320
                            selected: selectorVideoRes.res === 4320
                            onClicked: selectorVideoRes.res = 4320
                        }
                    }
                }
            }

            //////////////////

            Row {
                id: rectangleFramerate
                anchors.left: parent.left
                anchors.right: parent.right
                height: 48
                spacing: 16

                visible: (mode === "video" && !cbCOPY.checked)

                Text {
                    width: contentColumn.legendWidth
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Framerate")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                ItemLilMenu {
                    anchors.verticalCenter: parent.verticalCenter
                    width: selectorGifFps.width

                    visible: rbGIF.checked || cbTimelapse.checked

                    Row {
                        id: selectorGifFps
                        height: parent.height

                        property var fps: 15

                        ItemLilMenuButton {
                            text: "10" + (selected ? " " + qsTr("fps") : "")
                            selected: selectorGifFps.fps === 10
                            onClicked: selectorGifFps.fps = 10
                        }
                        ItemLilMenuButton {
                            text: "15" + (selected ? " " + qsTr("fps") : "")
                            selected: selectorGifFps.fps === 15
                            onClicked: selectorGifFps.fps = 15
                        }
                        ItemLilMenuButton {
                            text: "20" + (selected ? " " + qsTr("fps") : "")
                            selected: selectorGifFps.fps === 20
                            onClicked: selectorGifFps.fps = 20
                        }
                        ItemLilMenuButton {
                            text: "24" + (selected ? " " + qsTr("fps") : "")
                            selected: selectorGifFps.fps === 24
                            onClicked: selectorGifFps.fps = 24
                        }
                    }
                }

                ItemLilMenu {
                    anchors.verticalCenter: parent.verticalCenter
                    width: selectorVideoFps.width

                    visible: !rbGIF.checked && !cbTimelapse.checked

                    Row {
                        id: selectorVideoFps
                        height: parent.height

                        property var fps: Math.round(currentShot.framerate)

                        ItemLilMenuButton {
                            text: "30" + (selected ? " " + qsTr("fps") : "")
                            visible: shot.framerate >= 29
                            selected: selectorVideoFps.fps === 30
                            onClicked: selectorVideoFps.fps = 30
                        }
                        ItemLilMenuButton {
                            text: "60" + (selected ? " " + qsTr("fps") : "")
                            visible: shot.framerate >= 59
                            selected: selectorVideoFps.fps === 60
                            onClicked: selectorVideoFps.fps = 60
                        }
                        ItemLilMenuButton {
                            text: "120" + (selected ? " " + qsTr("fps") : "")
                            visible: shot.framerate >= 119
                            selected: selectorVideoFps.fps === 120
                            onClicked: selectorVideoFps.fps = 120
                        }
                        ItemLilMenuButton {
                            text: "240" + (selected ? " " + qsTr("fps") : "")
                            visible: shot.framerate >= 239
                            selected: selectorVideoFps.fps === 240
                            onClicked: selectorVideoFps.fps = 240
                        }
                    }
                }
            }

            Row {
                id: rectangleTimelapse
                anchors.left: parent.left
                anchors.right: parent.right
                height: 48
                spacing: 16

                Text {
                    width: contentColumn.legendWidth
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Timelapse")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                CheckBoxThemed {
                    id: cbTimelapse
                    anchors.verticalCenter: parent.verticalCenter
                    checked: false
                    text: qsTr("Enable")
                }

                SliderValueFilled {
                    id: timelapseFramerate
                    width: parent.width - contentColumn.legendWidth - cbTimelapse.width - 32
                    anchors.verticalCenter: parent.verticalCenter

                    visible: cbTimelapse.checked || mode === "timelapse"
                    from: 1
                    to: 15
                    value: 10
                }
            }

            //////////////////

            Item {
                id: rectangleOrientation
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right

                Text {
                    id: titleOrientation
                    width: contentColumn.legendWidth
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Orientation")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                Row {
                    anchors.left: titleOrientation.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: clipRotation != 0
                        text: qsTr("rotation")
                        color: Theme.colorSubText
                    }
                    TextFieldThemed {
                        width: 56
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter

                        enabled: false
                        visible: clipRotation != 0
                        text: clipRotation + "°"
                    }

                    CheckBoxThemed {
                        id: checkBox_hflip
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("horizontal flip")
                        checked: clipHFlip
                        enabled: false
                    }
                    CheckBoxThemed {
                        id: checkBox_vflip
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("vertical flip")
                        checked: clipVFlip
                        enabled: false
                    }
                }
            }

            //////////////////

            Item {
                id: rectangleClip
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right

                Text {
                    id: titleClip
                    width: contentColumn.legendWidth
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Clip video")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                Row {
                    anchors.left: titleClip.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    Text {
                        text: qsTr("from")
                        color: Theme.colorSubText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    TextFieldThemed {
                        id: textField_clipstart
                        width: 128
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignHCenter

                        enabled: false
                        placeholderText: "00:00:00"
                        validator: RegExpValidator { regExp: /^(?:(?:([01]?\d|2[0-3]):)?([0-5]?\d):)?([0-5]?\d)$/ }
                    }
                    Text {
                        text: qsTr("to")
                        color: Theme.colorSubText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    TextFieldThemed {
                        id: textField_clipstop
                        width: 128
                        height: 32
                        anchors.verticalCenter: textField_clipstart.verticalCenter
                        horizontalAlignment: Text.AlignHCenter

                        enabled: false
                        placeholderText: "00:00:00"
                        validator: RegExpValidator { regExp: /^(?:(?:([01]?\d|2[0-3]):)?([0-5]?\d):)?([0-5]?\d)$/ }
                    }
                }
            }

            //////////////////

            Item {
                id: rectangleCrop
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right

                Text {
                    id: titleCrop
                    width: contentColumn.legendWidth
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Crop area")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                Row {
                    anchors.left: titleCrop.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("position")
                        color: Theme.colorSubText
                    }
                    TextFieldThemed {
                        id: textField_cropCoord
                        width: 128
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter

                        enabled: false
                        horizontalAlignment: Text.AlignHCenter
                        placeholderText: "0:0"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("size")
                        color: Theme.colorSubText
                    }
                    TextFieldThemed {
                        id: textField_cropSize
                        width: 128
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter

                        enabled: false
                        horizontalAlignment: Text.AlignHCenter
                        placeholderText: "0x0"
                    }
                }
            }

            //////////////////

            Item {
                id: rectangleGifEffects
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right

                visible: rbGIF.checked

                Text {
                    id: titleGifEffects
                    width: contentColumn.legendWidth
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("GIF effect")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                Row {
                    anchors.left: titleGifEffects.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    RadioButtonThemed {
                        id: rbGifEffectForward
                        text: qsTr("Forward")
                        checked: true
                    }
                    RadioButtonThemed {
                        id: rbGifEffectBackward
                        text: qsTr("Backward")
                    }
                    RadioButtonThemed {
                        id: rbGifEffectBackandForth
                        text: qsTr("Back and Forth")
                    }
                }
            }

            Item {
                id: rectangleFilter
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right

                Text {
                    id: titleFilter
                    width: contentColumn.legendWidth
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 0

                    text: qsTr("Apply filters")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                CheckBoxThemed {
                    id: checkBox_defish
                    text: qsTr("defisheye")
                    anchors.left: titleFilter.right
                    anchors.leftMargin: 16
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

            //////////////////
/*
            Rectangle { // separator
                height: 1; color: Theme.colorSeparator;
                anchors.right: parent.right; anchors.left: parent.left; }
*/
            Item { height: 16; anchors.right: parent.right; anchors.left: parent.left; } // spacer

            Item {
                id: rectangleDestination
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right

                Text {
                    id: textDestinationTitle
                    width: contentColumn.legendWidth
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

                    function updateDestinations() {
                        cbDestinations.clear()

                        for (var child in settingsManager.directoriesList) {
                            if (settingsManager.directoriesList[child].available &&
                                settingsManager.directoriesList[child].directoryContent !== 2)
                                cbDestinations.append( { "text": settingsManager.directoriesList[child].directoryPath } )
                        }
                        cbDestinations.append( { "text": qsTr("Select path manually") } )

                        comboBoxDestination.currentIndex = 0
                    }

                    property bool cbinit: false
                    onCurrentIndexChanged: {
                        if (settingsManager.directoriesList.length <= 0) return

                        if (comboBoxDestination.currentIndex < cbDestinations.count)
                            textField_path.text = comboBoxDestination.displayText

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
                anchors.left: parent.left
                anchors.right: parent.right

                visible: (comboBoxDestination.currentIndex === (cbDestinations.count - 1))

                onVisibleChanged: {
                    //
                }

                FileDialog {
                    id: fileDialogChange
                    title: qsTr("Please choose a destination!")
                    sidebarVisible: true
                    selectExisting: true
                    selectMultiple: false
                    selectFolder: true

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

                    embedded: true
                    text: qsTr("change")
                    onClicked: {
                        fileDialogChange.folder =  "file:///" + textField_path.text
                        fileDialogChange.open()
                    }
                }
            }
        }

        ////////////////////////////////////////////////////////////////////////

        Row {
            id: rowButtons
            height: Theme.componentHeight*2 + parent.spacing
            anchors.right: parent.right
            anchors.rightMargin: 24
            spacing: 24

            ButtonWireframe {
                id: buttonCancel
                width: 96
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Cancel")
                fullColor: true
                primaryColor: Theme.colorGrey
                onClicked: popupEncoding.close()
            }

            ButtonWireframeImage {
                id: buttonEncode
                width: 128
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Encode")
                source: "qrc:/assets/icons_material/baseline-memory-24px.svg"
                fullColor: true
                primaryColor: Theme.colorPrimary
                onClicked: {
                    if (typeof currentShot === "undefined" || !currentShot) return

                    var encodingParams = {}

                    if (rectangleImageCodec.visible) {
                        if (rbPNG.checked)
                            encodingParams["codec"] = "PNG";
                        else if (rbJPEG.checked)
                            encodingParams["codec"] = "JPEG";
                        else if (rbWEBP.checked)
                            encodingParams["codec"] = "WEBP";
                        else if (rbAVIF.checked)
                            encodingParams["codec"] = "AVIF";
                        else if (rbHEIF.checked)
                            encodingParams["codec"] = "HEIF";
                    }

                    if (rectangleVideoCodec.visible) {
                        if (rbH264.checked)
                            encodingParams["codec"] = "H.264";
                        else if (rbH265.checked)
                            encodingParams["codec"] = "H.265";
                        else if (rbVP9.checked)
                            encodingParams["codec"] = "VP9";
                        else if (rbAV1.checked)
                            encodingParams["codec"] = "AV1";
                        else if (rbProRes.checked)
                            encodingParams["codec"] = "PRORES";
                        else if (rbGIF.checked)
                            encodingParams["codec"] = "GIF";

                        if (clipStartMs > 0 && clipDurationMs > 0) {
                            if (cbCOPY.checked)
                                encodingParams["codec"] = "copy";
                        }

                        encodingParams["speed"] = sliderSpeed.value;

                        if (selectorVideoFps.visible && selectorVideoFps.fps != Math.round(currentShot.framerate))
                            encodingParams["fps"] = selectorVideoFps.fps;

                        if (selectorGifFps.visible)
                            encodingParams["fps"] = selectorGifFps.fps;

                        if (clipStartMs > 0)
                            encodingParams["clipStartMs"] = clipStartMs;
                        if (clipDurationMs > 0) // && (clipStartMs + clipDurationMs) < currentShot.duration)
                            encodingParams["clipDurationMs"] = clipDurationMs;
                    }

                    if (selectorGifRes.visible && selectorGifRes.res !== currentShot.height) {
                        encodingParams["resolution"] = selectorGifRes.res;
                        encodingParams["scale"] = "-2:" + selectorGifRes.res;
                    }
                    if (selectorVideoRes.visible && selectorVideoRes.res !== currentShot.height) {
                        encodingParams["resolution"] = selectorVideoRes.res;
                        encodingParams["scale"] = "-2:" + selectorVideoRes.res;
                    }

                    if (clipCropX > 0 || clipCropY > 0 ||
                        (clipCropW > 0 && clipCropW < currentShot.width) ||
                        (clipCropH > 0 && clipCropH < currentShot.height)) {
                        encodingParams["crop"] = clipCropW + ":" + clipCropH + ":" + clipCropX + ":" + clipCropY

                        var cropAR = 1.0
                        if (clipCropW > clipCropH) cropAR = clipCropW / clipCropH
                        else if (clipCropW < clipCropH) cropAR = clipCropH / clipCropW

                        encodingParams["scale"] = UtilsNumber.round2((encodingParams["resolution"] * cropAR)) + ":" + encodingParams["resolution"]
                    }

                    if (rbGIF.checked) {
                        // Make sure we feed the complex graph
                        encodingParams["fps"] = selectorGifFps.fps;
                        encodingParams["resolution"] = selectorGifRes.res;
                        encodingParams["scale"] = "-2:" + selectorGifRes.res;
                        if (clipStartMs <= 0) encodingParams["clipStartMs"] = 0;
                        if (clipDurationMs <= 0) encodingParams["clipDurationMs"] = currentShot.duration;
                        if (clipCropX <= 0 && clipCropY <= 0 && clipCropW <= 0 && clipCropH <= 0)
                            encodingParams["crop"] = currentShot.width + ":" + currentShot.height + ":" + 0 + ":" + 0

                        // Effect
                        if (rbGifEffectBackward.checked) encodingParams["gif_effect"] = "backward"
                        else if (rbGifEffectBackandForth.checked) encodingParams["gif_effect"] = "forwardbackward"
                    }

                    if (timelapseFramerate.visible)
                        encodingParams["timelapse_fps"] = timelapseFramerate.value.toFixed(0)

                    encodingParams["transform"] = clipTransformation

                    encodingParams["quality"] = sliderQuality.value

                    encodingParams["path"] = textField_path.text

                    ////

                    if (typeof currentDevice !== "undefined")
                        mediaProvider = currentDevice;
                    else if (typeof mediaLibrary !== "undefined")
                        mediaProvider = mediaLibrary;
                    else
                        return

                    mediaProvider.reencodeSelected(currentShot.uuid, encodingParams)
                    popupEncoding.close()
                }
            }
        }
    }
}
