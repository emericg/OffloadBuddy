import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import ShotUtils 1.0
import "qrc:/js/UtilsNumber.js" as UtilsNumber
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Popup {
    id: popupEncoding
    x: (appWindow.width / 2) - (width / 2) - (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 720
    padding: 0

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    signal confirmed()

    ////////

    property int popupMode: 0
    property bool recapEnabled: false
    property bool recapOpened: false

    property var shots_uuids: []
    property var shots_names: []
    property var shots_files: []
    //property var shots: [] // TODO actual shot pointers

    property var mediaProvider: null
    property var currentShot: null

    ////////

    function open() { return; }

    function openSingle(provider, shot) {
        popupMode = 1
        mediaProvider = provider
        currentShot = shot

        visible = true
    }

    function openSelection(provider) {
        if (shots_uuids.length === 0 || shots_names.length === 0 || shots_files.length === 0) return

        popupMode = 2
        recapEnabled = true
        mediaProvider = provider

        visible = true
    }

    onClosed: {
        recapEnabled = false
        recapOpened = false
        shots_uuids = []
        shots_names = []
        shots_files = []
        mediaProvider = null
        currentShot = null
    }

    ////////////////////////////////////////////////////////////////////////////

    property string encodingMode: ""

    property int legendWidth: 128

    property int clipStartMs: -1
    property int clipDurationMs: -1

    property int clipTransformation_qt: 0
    property int clipTransformation_exif: 1
    property int clipRotation: 0
    property bool clipVFlip: false
    property bool clipHFlip: false

    property int clipCropX: 0
    property int clipCropY: 0
    property int clipCropW: 0
    property int clipCropH: 0

    property bool clipIsShort: false
    property bool clipCanBeCopied: false

    function updateEncodePanel(shot) {

        // Set mode
        if (typeof shot === "undefined" || !shot) {
            titleText.text = qsTr("Batch encoding")
            encodingMode = "batch"
        } else {
            currentShot = shot

            if (shot.shotType === ShotUtils.SHOT_PICTURE) {
                titleText.text = qsTr("Image encoding")
                encodingMode = "image"
            } else if (shot.shotType === ShotUtils.SHOT_PICTURE_MULTI || shot.shotType === ShotUtils.SHOT_PICTURE_BURST ||
                       shot.shotType === ShotUtils.SHOT_PICTURE_TIMELAPSE || shot.shotType === ShotUtils.SHOT_PICTURE_NIGHTLAPSE) {
                titleText.text = qsTr("Timelapse encoding")
                encodingMode = "timelapse"

                cbTimelapse.checked = false
                cbTimelapse.visible = false

                timelapseFramerate.from = 1
                timelapseFramerate.to = 60
                timelapseFramerate.value = 15

            } else {
                titleText.text = qsTr("Video encoding")
                encodingMode = "video"

                cbTimelapse.checked = false
                cbTimelapse.visible = true

                timelapseFramerate.from = 1
                timelapseFramerate.to = 15
                timelapseFramerate.value = 10
            }
        }

        if (!rbGIF.enabled && rbGIF.checked) { rbH264.checked = true; }
        if (!cbCOPY.enabled && cbCOPY.checked) { cbCOPY.checked = false; bH264.checked = true; }

        changeCodec()

        // Clip handler
        setClip(-1, -1)

        // Resolution?

        // Orientation
        setOrientation(0, false, false)

        // Crop
        rectangleCrop.visible = false

        // Filters
        rectangleFilter.visible = false

        // Handle destination(s)
        comboBoxDestination.updateDestinations()
    }

    ////////////////

    function setClip(clipStart, clipStop) {
        //console.log("setClip() " + clipStart + "/" + clipStop)

        if (typeof currentShot === "undefined" || !currentShot) {
            clipStartMs = -1
            clipDurationMs = -1
            clipCanBeCopied = false
            rectangleClip.visible = false
            return
        }

        if (currentShot.shotType >= ShotUtils.SHOT_PICTURE) {
            clipStartMs = -1
            clipDurationMs = -1
            clipCanBeCopied = false
            rectangleClip.visible = false

            // GIF only appear for short timelapse
            if (currentShot.duration < 1000) { // check value
                clipIsShort = true
            } else {
                clipIsShort = false
            }
        }

        if (clipStart > 0 || (clipStop > 0 && clipStop < currentShot.duration)) {
            if (clipStart < 0) clipStart = 0
            if (clipStop < 0) clipStop = currentShot.duration
            clipStartMs = clipStart
            clipDurationMs = clipStop - clipStart
            clipCanBeCopied = true
            rectangleClip.visible = true

            textField_clipstart.text = UtilsString.durationToString_ISO8601_full(clipStart)
            textField_clipstop.text = UtilsString.durationToString_ISO8601_full(clipStop)
        } else {
            clipStartMs = -1
            clipDurationMs = -1
            clipCanBeCopied = false
            rectangleClip.visible = false
        }

        // GIF only appear for short videos (7.5s)
        if ((clipDurationMs > 0 && clipDurationMs < 7500) || currentShot.duration < 7500)
            clipIsShort = true
        else
            clipIsShort = false
    }

    function setOrientation(rotation, hflip, vflip) {
        //console.log("setOrientation() " + rotation + " " + vflip + " " + hflip)

        if (rotation || vflip || hflip) {
            rectangleOrientation.visible = true
            clipRotation = rotation
            clipVFlip = vflip
            clipHFlip = hflip

            clipTransformation_qt = mediaPreview.orientationToTransform_qt(rotation, hflip, vflip)
            clipTransformation_exif = mediaPreview.orientationToTransform_exif(rotation, hflip, vflip)
        } else {
            rectangleOrientation.visible = false
            clipTransformation_qt = 0
            clipTransformation_exif = 1
            clipRotation = 0
            clipVFlip = false
            clipHFlip = false
        }
    }

    function setCrop(x, y, width, height) {
        //console.log("setCrop() " + x + ":" + y + " " + width + "x" + height)

        if (currentShot && (x > 0.0 || y > 0.0 || width < 1.0 || height < 1.0)) {
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

    ////////////////

    function changeCodec() {
        if (encodingMode === "video" || encodingMode === "timelapse") {
            if (cbCOPY.checked) {
                //fileInput.extension = currentShot.e
                text = qsTr("With this mode you can trim the duration without reencoding the video, so no quality will be lost. But you cannot apply any other transformation.")
            } else {
                if (rbH264.checked) {
                    fileInput.extension = "mp4"
                    textCodecHelp.text = qsTr("The most widely used codec today. It provides the best balance of compression, speed, and excellent support for every kind devices.")
                } else if (rbH265.checked) {
                    fileInput.extension = "mp4"
                    textCodecHelp.text = qsTr("The successor of H.264. It provides excellent compression, slower encoding speed, and good support with most kind of devices.")
                } else if (rbVP9.checked) {
                    fileInput.extension = "mkv"
                    textCodecHelp.text = qsTr("Good balance of next gen compression, speed, and software support. Use it if you know what you are doing though.")
                } else if (rbAV1.checked) {
                    fileInput.extension = "mkv"
                    textCodecHelp.text = qsTr("AV1 has the best compression for video, but is VERY slow to encode, and while software support is good, device support is still poor as of today.")
                } else if (rbProRes.checked) {
                    fileInput.extension = "mp4"
                    textCodecHelp.text = qsTr("Almost lossless compression, so HUGE file size but very good quality and speed.")
                } else if (rbGIF.checked) {
                    fileInput.extension = "gif"
                    textCodecHelp.text = qsTr("The meme maker. Go nuts with this oO")
                }
            }
        } else {
            if (rbPNG.checked) {
                fileInput.extension = "png"
                textCodecHelp.text = qsTr("Lossless compression for your picture. Big files, but no quality lost.")
            } else if (rbJPEG.checked) {
                fileInput.extension = "jpg"
                textCodecHelp.text = qsTr("The most widely used image format.")
            } else if (rbWEBP.checked) {
                fileInput.extension = "webp"
                textCodecHelp.text = qsTr("Better compression and quality than JPEG.")
            } else if (rbAVIF.checked) {
                fileInput.extension = "avif"
                textCodecHelp.text = qsTr("AVIF is an AV1 based image format. It has excellent compression but very poor support from various devices, web browser and other.")
            } else if (rbHEIF.checked) {
                fileInput.extension = "heif"
                textCodecHelp.text = qsTr("HEIF is an H.265 based image format. It has excellent compression but very poor support from various devices, web browser and other.")
            } else {
                textCodecHelp.text = ""
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.5; to: 1.0; duration: 133; } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 233; } }

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: recapOpened ? Theme.colorForeground : Theme.colorBackground
        radius: Theme.componentRadius
        border.width: Theme.componentBorderWidth
        border.color: Theme.colorForeground
    }

    ////////////////////////////////////////////////////////////////////////////

    contentItem: Column {

        Rectangle {
            id: titleArea
            anchors.left: parent.left
            anchors.right: parent.right

            height: 64
            color: Theme.colorPrimary
            radius: Theme.componentRadius

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 1
                anchors.right: parent.right
                anchors.rightMargin: 0
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

        ////////////////

        Rectangle {
            id: filesArea
            anchors.left: parent.left
            anchors.leftMargin: 1
            anchors.right: parent.right
            anchors.rightMargin: 0

            z: 1
            height: 48
            visible: (recapEnabled && shots_files.length)
            color: Theme.colorForeground

            MouseArea {
                anchors.fill: parent
                onClicked: recapOpened = !recapOpened
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 48+16+16
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("%n shot(s) selected", "", shots_names.length)
                color: Theme.colorText
                font.pixelSize: Theme.fontSizeContent
            }

            ItemImageButton {
                width: 48
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                source: "qrc:/assets/icons_material/baseline-navigate_next-24px.svg"
                rotation: recapOpened ? -90 : 90
                onClicked: recapOpened = !recapOpened
            }
        }

        ////////////////

        Item {
            id: contentArea
            height: columnEncoding.height
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24

            ////////

            ListView {
                id: listArea
                anchors.fill: parent

                visible: recapOpened

                model: shots_names
                delegate: Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: modelData
                    font.pixelSize: 14
                    elide: Text.ElideLeft
                    color: Theme.colorSubText
                }
            }

            ////////

            Column {
                id: columnEncoding
                anchors.left: parent.left
                anchors.right: parent.right
                topPadding: 16
                bottomPadding: 16

                visible: !recapOpened

                Column {
                    id: columnVideo
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Item {
                        id: rectangleVideoCodec
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: (encodingMode === "video" || encodingMode === "timelapse" || encodingMode === "batch")

                        Text {
                            id: textCodec
                            width: popupEncoding.legendWidth
                            anchors.verticalCenter: parent.verticalCenter

                            text: qsTr("Video codec")
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
                                visible: clipCanBeCopied
                                onVisibleChanged: if (!visible) checked = false
                                onClicked: changeCodec()
                            }
                            RadioButtonThemed {
                                id: rbH264
                                anchors.verticalCenter: parent.verticalCenter
                                text: "H.264"
                                enabled: !cbCOPY.checked
                                checked: true
                                onClicked: changeCodec()
                            }
                            RadioButtonThemed {
                                id: rbH265
                                anchors.verticalCenter: parent.verticalCenter
                                text: "H.265"
                                enabled: !cbCOPY.checked
                                onClicked: changeCodec()
                            }
                            RadioButtonThemed {
                                id: rbVP9
                                anchors.verticalCenter: parent.verticalCenter
                                text: "VP9"
                                enabled: !cbCOPY.checked
                                onClicked: changeCodec()
                            }
                            RadioButtonThemed {
                                id: rbAV1
                                anchors.verticalCenter: parent.verticalCenter
                                text: "AV1"
                                enabled: !cbCOPY.checked
                                visible: false
                                onClicked: changeCodec()
                            }
                            RadioButtonThemed {
                                id: rbProRes
                                anchors.verticalCenter: parent.verticalCenter
                                text: "ProRes"
                                enabled: !cbCOPY.checked
                                visible: false
                                onClicked: changeCodec()
                            }
                            RadioButtonThemed {
                                id: rbGIF
                                anchors.verticalCenter: parent.verticalCenter
                                enabled: !cbCOPY.checked && clipIsShort
                                text: clipIsShort ? "GIF" : "GIF (video too long)"
                                onClicked: changeCodec()
                            }
                        }
                    }

                    Item {
                        id: rectangleImageCodec
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: (encodingMode === "image" || encodingMode === "batch")

                        Text {
                            id: textFormat
                            width: popupEncoding.legendWidth
                            anchors.verticalCenter: parent.verticalCenter

                            text: qsTr("Image format")
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
                                onClicked: changeCodec()
                            }
                            RadioButtonThemed {
                                id: rbJPEG
                                anchors.verticalCenter: parent.verticalCenter
                                text: "JPEG"
                                checked: true
                                onClicked: changeCodec()
                            }
                            RadioButtonThemed {
                                id: rbWEBP
                                anchors.verticalCenter: parent.verticalCenter
                                text: "WebP"
                                onClicked: changeCodec()
                            }
                            RadioButtonThemed {
                                id: rbAVIF
                                anchors.verticalCenter: parent.verticalCenter
                                text: "AVIF"
                                visible: false
                                onClicked: changeCodec()
                            }
                            RadioButtonThemed {
                                id: rbHEIF
                                anchors.verticalCenter: parent.verticalCenter
                                text: "HEIF"
                                visible: false
                                onClicked: changeCodec()
                            }
                        }
                    }

                    Item {
                        id: rectangleCodecHelp
                        height: textCodecHelp.contentHeight + 8
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: textCodecHelp.text

                        Text {
                            id: textCodecHelp
                            anchors.left: parent.left
                            anchors.leftMargin: popupEncoding.legendWidth + 16
                            anchors.right: parent.right

                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                            color: Theme.colorSubText
                        }
                    }

                    ////////

                    Item {
                        id: rectangleEncodingQuality
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: !cbCOPY.checked && !rbGIF.checked && !rbPNG.checked

                        Text {
                            id: textQuality
                            width: popupEncoding.legendWidth
                            anchors.verticalCenter: parent.verticalCenter

                            text: qsTr("Quality index")
                            font.pixelSize: 16
                            color: Theme.colorSubText
                        }

                        SliderArrow {
                            id: sliderQuality
                            anchors.left: textQuality.right
                            anchors.leftMargin: 16
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            wheelEnabled: true
                            stepSize: 1

                            from: -2
                            to: 2
                            value: 0
                        }
                    }

                    Item {
                        id: rectangleEncodingSpeed
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: (encodingMode === "video" || encodingMode === "timelapse") && !cbCOPY.checked && !rbGIF.checked

                        Text {
                            id: textSpeed
                            width: popupEncoding.legendWidth
                            anchors.verticalCenter: parent.verticalCenter

                            text: qsTr("Speed index")
                            font.pixelSize: 16
                            color: Theme.colorSubText
                        }

                        SliderArrow {
                            id: sliderSpeed
                            anchors.left: textSpeed.right
                            anchors.leftMargin: 16
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            wheelEnabled: true
                            stepSize: 1

                            from: 2
                            to: 0
                            value: 1
                        }
                    }

                    ////////

                    Row {
                        id: rectangleDefinition
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 48
                        spacing: 16

                        visible: !cbCOPY.checked

                        Text {
                            width: popupEncoding.legendWidth
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

                    ////////

                    Row {
                        id: rectangleFramerate
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 48
                        spacing: 16

                        visible: (encodingMode === "video" && !cbCOPY.checked)

                        Text {
                            width: popupEncoding.legendWidth
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

                                property int fps: 15

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

                                property int fps: {
                                    if (typeof currentShot === "undefined" || !currentShot) return 30
                                    return Math.round(currentShot.framerate)
                                }

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

                        visible: (encodingMode === "timelapse") || (encodingMode === "video" && !cbCOPY.checked && shot.duration > 60000)

                        Text {
                            width: popupEncoding.legendWidth
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

                        SliderValueSolid {
                            id: timelapseFramerate
                            width: parent.width - popupEncoding.legendWidth - (cbTimelapse.visible ? cbTimelapse.width + 16 : 0) - 16
                            anchors.verticalCenter: parent.verticalCenter

                            visible: (cbTimelapse.checked || encodingMode === "timelapse")
                            from: 1
                            to: 15
                            value: 10
                            snapMode: Slider.SnapAlways
                        }
                    }

                    ////////

                    Item {
                        id: rectangleOrientation
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: !cbCOPY.checked

                        Text {
                            id: titleOrientation
                            width: popupEncoding.legendWidth
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

                    ////////

                    Item {
                        id: rectangleClip
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        Text {
                            id: titleClip
                            width: popupEncoding.legendWidth
                            anchors.left: parent.left
                            anchors.leftMargin: 0
                            anchors.verticalCenter: parent.verticalCenter

                            text: qsTr("Trim duration")
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

                    ////////

                    Item {
                        id: rectangleCrop
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        Text {
                            id: titleCrop
                            width: popupEncoding.legendWidth
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

                    ////////

                    Item {
                        id: rectangleGifEffects
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: rbGIF.checked

                        Text {
                            id: titleGifEffects
                            width: popupEncoding.legendWidth
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
                            RadioButtonThemed {
                                id: rbGifEffectForthandBack
                                text: qsTr("F and B")
                            }
                        }
                    }

                    ////////

                    Item {
                        id: rectangleFilter
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        Text {
                            id: titleFilter
                            width: popupEncoding.legendWidth
                            anchors.left: parent.left
                            anchors.leftMargin: 0
                            anchors.verticalCenter: parent.verticalCenter

                            text: qsTr("Apply filters")
                            font.pixelSize: 16
                            color: Theme.colorSubText
                        }

                        CheckBoxThemed {
                            id: checkBox_defisheye
                            anchors.left: titleFilter.right
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter

                            //visible: isGoPro
                            text: qsTr("defisheye")
                        }

                        CheckBoxThemed {
                            id: checkBox_deshake
                            anchors.left: checkBox_defisheye.right
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter

                            visible: (encodingMode !== "image")
                            text: qsTr("stabilization")
                        }
                    }

                    ////////

                    Item {
                        id: rectangleTelemetryWarning
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: (shot.fileType === ShotUtils.FILE_VIDEO && shot.hasGPS)

                        Text {
                            id: telemetryWarning
                            width: popupEncoding.legendWidth
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter

                            text: qsTr("Telemetry")
                            font.pixelSize: 16
                            color: Theme.colorSubText
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: popupEncoding.legendWidth + 16
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            text: qsTr("GPS and telemetry tracks will NOT be caried to the reencoded files. You can export them separately if you want.")
                            font.pixelSize: 14
                            wrapMode: Text.WordWrap
                            color: Theme.colorSubText
                        }
                    }
                }

                ////////

                Item { // delimiter
                    anchors.left: parent.left
                    anchors.leftMargin: -23
                    anchors.right: parent.right
                    anchors.rightMargin: -23
                    height: 32

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: Theme.componentBorderWidth
                        color: Theme.colorForeground
                    }
                }

                ////////

                Column {
                    id: columnDestination
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Item {
                        height: 24
                        anchors.left: parent.left
                        anchors.right: parent.right

                        Text {
                            id: textDestinationTitle
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom

                            text: qsTr("Destination")
                            color: Theme.colorSubText
                            font.pixelSize: 16
                        }
                    }

                    Item {
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        ComboBoxFolder {
                            id: comboBoxDestination
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 36

                            ListModel { id: cbDestinations }
                            model: cbDestinations

                            Component.onCompleted: comboBoxDestination.updateDestinations()
                            Connections {
                                target: storageManager
                                onDirectoriesUpdated: comboBoxDestination.updateDestinations()
                            }

                            function updateDestinations() {
                                cbDestinations.clear()

                                if (currentShot)
                                    cbDestinations.append( { "text": qsTr("Next to the video file") } )

                                for (var child in storageManager.directoriesList) {
                                    if (storageManager.directoriesList[child].available &&
                                        storageManager.directoriesList[child].directoryContent !== 2)
                                        cbDestinations.append( { "text": storageManager.directoriesList[child].directoryPath } )
                                }
                                cbDestinations.append( { "text": qsTr("Select path manually") } )

                                // TODO save value instead of reset?
                                comboBoxDestination.currentIndex = 0
                            }

                            property bool cbinit: false
                            onCurrentIndexChanged: {
                                if (storageManager.directoriesCount <= 0) return

                                var selectedDestination = comboBoxDestination.textAt(comboBoxDestination.currentIndex)
                                var previousDestination = comboBoxDestination.currentText
                                if (previousDestination === qsTr("Next to the video file")) previousDestination = currentShot.folder

                                if (cbinit) {
                                    if (currentShot) {
                                        if (comboBoxDestination.currentIndex === 0) {
                                            fileInput.folder = currentShot.folder + jobManager.getDestinationHierarchy(currentShot, selectedDestination)
                                        } else if (comboBoxDestination.currentIndex === (cbDestinations.count-1)) {
                                            fileInput.folder = previousDestination + jobManager.getDestinationHierarchy(currentShot, previousDestination)
                                        } else if (comboBoxDestination.currentIndex < cbDestinations.count) {
                                            fileInput.folder = selectedDestination + jobManager.getDestinationHierarchy(currentShot, selectedDestination)
                                        }
                                        fileInput.file = currentShot.name + "_reencoded"
                                    } else {
                                        if (comboBoxDestination.currentIndex === (cbDestinations.count-1)) {
                                            folderInput.folder = previousDestination
                                        } else if (comboBoxDestination.currentIndex < cbDestinations.count) {
                                            folderInput.folder = selectedDestination
                                        }
                                    }
                                } else {
                                    cbinit = true
                                }
                            }

                            folders: jobManager.getDestinationHierarchyDisplay(currentShot, currentText)
                        }
                    }

                    Item {
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: (popupMode === 1)
                        enabled: (comboBoxDestination.currentIndex === (cbDestinations.count-1))

                        FileInputArea {
                            id: fileInput
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            onPathChanged: {
                                rectangleFileWarning.visible = jobManager.fileExists(fileInput.path)
                            }
                        }
                    }

                    Item {
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: (popupMode === 2) && (comboBoxDestination.currentIndex === (cbDestinations.count-1))
                        enabled: (comboBoxDestination.currentIndex === (cbDestinations.count-1))

                        FolderInputArea {
                            id: folderInput
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        id: rectangleFileWarning
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 48
                        spacing: 16

                        visible: false

                        ImageSvg {
                            width: 28
                            height: 28
                            anchors.verticalCenter: parent.verticalCenter

                            color: Theme.colorWarning
                            source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Warning, this file exists already and will be overwritten...")
                            color: Theme.colorText
                            font.bold: false
                            font.pixelSize: Theme.fontSizeContent
                            wrapMode: Text.WordWrap
                        }
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

                enabled: fileInput.isValid

                onClicked: {
                    if (typeof currentShot === "undefined" || !currentShot) return
                    if (typeof mediaProvider === "undefined" || !mediaProvider) return

                    var settingsEncoding = {}

                    // destination
                    if (popupMode === 1) {
                        if (comboBoxDestination.currentIndex === 0) {
                            settingsEncoding["folder"] = currentShot.folder
                            settingsEncoding["file"] = fileInput.file
                            settingsEncoding["extension"] = fileInput.extension
                        } else if (comboBoxDestination.currentIndex === (cbDestinations.count-1)) {
                            settingsEncoding["folder"] = fileInput.folder
                            settingsEncoding["file"] = fileInput.file
                            settingsEncoding["extension"] = fileInput.extension
                        } else {
                            settingsEncoding["mediaDirectory"] = comboBoxDestination.currentText
                        }
                    } else if (popupMode === 2) {
                        if (comboBoxDestination.currentIndex === (cbDestinations.count-1)) {
                           settingsEncoding["folder"] = folderInput.folder
                       } else {
                           settingsEncoding["mediaDirectory"] = comboBoxDestination.currentText
                       }
                    }

                    // settings
                    if (encodingMode === "image") {
                        if (rbPNG.checked)
                            settingsEncoding["codec"] = "PNG";
                        else if (rbJPEG.checked)
                            settingsEncoding["codec"] = "JPEG";
                        else if (rbWEBP.checked)
                            settingsEncoding["codec"] = "WEBP";
                        else if (rbAVIF.checked)
                            settingsEncoding["codec"] = "AVIF";
                        else if (rbHEIF.checked)
                            settingsEncoding["codec"] = "HEIF";
                    }

                    if (encodingMode === "video" || encodingMode === "timelapse") {
                        if (rbH264.checked)
                            settingsEncoding["codec"] = "H.264";
                        else if (rbH265.checked)
                            settingsEncoding["codec"] = "H.265";
                        else if (rbVP9.checked)
                            settingsEncoding["codec"] = "VP9";
                        else if (rbAV1.checked)
                            settingsEncoding["codec"] = "AV1";
                        else if (rbProRes.checked)
                            settingsEncoding["codec"] = "PRORES";
                        else if (rbGIF.checked)
                            settingsEncoding["codec"] = "GIF";

                        if (clipStartMs > 0 && clipDurationMs > 0) {
                            if (cbCOPY.checked)
                                settingsEncoding["codec"] = "copy";
                        }

                        settingsEncoding["speed"] = sliderSpeed.value;

                        if (selectorVideoFps.visible && selectorVideoFps.fps != Math.round(currentShot.framerate))
                            settingsEncoding["fps"] = selectorVideoFps.fps;

                        if (selectorGifFps.visible)
                            settingsEncoding["fps"] = selectorGifFps.fps;

                        if (clipStartMs > 0)
                            settingsEncoding["clipStartMs"] = clipStartMs;
                        if (clipDurationMs > 0) // && (clipStartMs + clipDurationMs) < currentShot.duration)
                            settingsEncoding["clipDurationMs"] = clipDurationMs;
                    }

                    if (selectorGifRes.visible &&
                        (!currentShot || (currentShot && selectorGifRes.res !== currentShot.height))) {
                        settingsEncoding["resolution"] = selectorGifRes.res;
                        settingsEncoding["scale"] = "-2:" + selectorGifRes.res;
                    }
                    if (selectorVideoRes.visible &&
                        (!currentShot || (currentShot && selectorVideoRes.res !== currentShot.height))) {
                        settingsEncoding["resolution"] = selectorVideoRes.res;
                        settingsEncoding["scale"] = "-2:" + selectorVideoRes.res;
                    }

                    if (clipCropX > 0 || clipCropY > 0 ||
                        (clipCropW > 0 && clipCropW < currentShot.width) ||
                        (clipCropH > 0 && clipCropH < currentShot.height)) {
                        settingsEncoding["crop"] = clipCropW + ":" + clipCropH + ":" + clipCropX + ":" + clipCropY

                        var cropAR = 1.0
                        if (clipCropW > clipCropH) cropAR = clipCropW / clipCropH
                        else if (clipCropW < clipCropH) cropAR = clipCropH / clipCropW

                        settingsEncoding["scale"] = UtilsNumber.round2((settingsEncoding["resolution"] * cropAR)) + ":" + settingsEncoding["resolution"]
                    }

                    if (rbGIF.checked) {
                        // Make sure we feed the complex graph
                        settingsEncoding["fps"] = selectorGifFps.fps;
                        settingsEncoding["resolution"] = selectorGifRes.res;
                        settingsEncoding["scale"] = "-2:" + selectorGifRes.res;
                        if (clipStartMs <= 0) settingsEncoding["clipStartMs"] = 0;
                        if (clipDurationMs <= 0) settingsEncoding["clipDurationMs"] = currentShot.duration;
                        if (currentShot.shotType > ShotUtils.SHOT_PICTURE)settingsEncoding["clipDurationMs"] = currentShot.duration*33;
                        if (clipCropX > 0 || clipCropY > 0 ||
                            (clipCropW > 0 && clipCropW < currentShot.width) ||
                            (clipCropH > 0 && clipCropH < currentShot.height)) {
                            if (clipRotation == 0 || clipRotation == 180)
                                settingsEncoding["crop"] = clipCropW + ":" + clipCropH + ":" + clipCropX + ":" + clipCropY
                            else
                                settingsEncoding["crop"] = clipCropH + ":" + clipCropW + ":" + clipCropX + ":" + clipCropY
                        }
                        if (clipCropX <= 0 && clipCropY <= 0 && clipCropW <= 0 && clipCropH <= 0) {
                            if (clipRotation == 0 || clipRotation == 180)
                                settingsEncoding["crop"] = currentShot.width + ":" + currentShot.height + ":" + 0 + ":" + 0
                            else
                                settingsEncoding["crop"] = currentShot.height + ":" + currentShot.width + ":" + 0 + ":" + 0
                        }
                        // TODO // transform

                        // Effect
                        if (rbGifEffectBackward.checked) settingsEncoding["gif_effect"] = "backward"
                        else if (rbGifEffectBackandForth.checked) settingsEncoding["gif_effect"] = "forwardbackward"
                        else if (rbGifEffectForthandBack.checked) settingsEncoding["gif_effect"] = "backwardforward"
                    }

                    if (timelapseFramerate.visible)
                        settingsEncoding["timelapse_fps"] = timelapseFramerate.value.toFixed(0)

                    settingsEncoding["transform"] = clipTransformation_exif

                    settingsEncoding["quality"] = sliderQuality.value

                    settingsEncoding["path"] = fileInput.text

                    // Filters
                    if (checkBox_defisheye.checked) settingsEncoding["defisheye"] = checkBox_defisheye.checked
                    if (checkBox_deshake.checked) settingsEncoding["deshake"] = checkBox_deshake.checked

                    // dispatch job
                    if (currentShot) {
                        mediaProvider.reencodeSelected(currentShot.uuid, settingsEncoding)
                    } else if (shots_uuids.length > 0) {
                        mediaProvider.reencodeSelection(shots_uuids, settingsEncoding)
                    }
                    popupEncoding.close()
                }
            }
        }
    }
}
