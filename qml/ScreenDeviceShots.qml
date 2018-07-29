import QtQuick 2.10
import QtQuick.Controls 2.4

import com.offloadbuddy.style 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: screenDeviceShots
    width: 1280
    height: 720
    anchors.fill: parent

    property int selectedItem : shotsview.currentIndex

    function updateDeviceHeader() {
        deviceModelText.text = myDevice.brand + " " + myDevice.model;
        deviceSpaceText.text = StringUtils.bytesToString_short(myDevice.spaceUsed) + " used of " + StringUtils.bytesToString_short(myDevice.spaceTotal)
        deviceSpaceBar.value = myDevice.spaceUsedPercent

        if (myDevice.model.includes("HERO3") || myDevice.model.includes("HERO4")) {
            deviceImage.source = "qrc:/cameras/H4.svg"
        } else if (myDevice.model.includes("Session")) {
            deviceImage.source = "qrc:/cameras/session.svg"
        } else if (myDevice.model.includes("FUSION")) {
            deviceImage.source = "qrc:/cameras/fusion.svg"
        } else if (myDevice.model.includes("HERO5")) {
            deviceImage.source = "qrc:/cameras/H5.svg"
        } else if (myDevice.model.includes("HERO6")) {
            deviceImage.source = "qrc:/cameras/H6.svg"
        } else {
            deviceImage.source = "qrc:/cameras/generic.svg"
        }

        rectangleDelete.stopTheBlink();
    }

    function updateGridViewStuff() {
        if (shotsview.count > 0) {
            circleEmpty.visible = false;
        } else {
            shotsview.currentIndex = -1

            if (myDevice && myDevice.deviceType === 0)
                imageEmpty.source = "qrc:/icons/card.svg"
            else
                imageEmpty.source = "qrc:/icons/usb.svg"
            circleEmpty.visible = true;
        }
    }

    Rectangle {
        id: rectangleHeader
        height: 128
        color: ThemeEngine.colorHeaderBackground
        z: 1
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        Image {
            id: deviceImage
            x: 16
            width: 128
            height: 112
            antialiasing: true
            fillMode: Image.PreserveAspectFit
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 8
            source: "qrc:/cameras/generic.svg"
        }

        Text {
            id: deviceModelText
            x: 874
            y: 26
            width: 256
            height: 30
            text: "GoPro HERO"
            anchors.right: deviceImage.left
            anchors.rightMargin: 16
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            color: ThemeEngine.colorHeaderTitle
            font.bold: true
            font.pixelSize: 28
        }

        Text {
            id: deviceSpaceText
            width: 220
            height: 15
            text: "64GB available of 128GB"
            horizontalAlignment: Text.AlignRight
            anchors.right: deviceModelText.right
            anchors.rightMargin: 0
            anchors.top: deviceModelText.bottom
            anchors.topMargin: 8
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 15
        }

        ProgressBar {
            id: deviceSpaceBar
            width: 256
            height: 16
            anchors.right: deviceModelText.right
            anchors.rightMargin: 0
            anchors.top: deviceSpaceText.bottom
            anchors.topMargin: 8
            value: 0.5
        }

        Rectangle {
            id: rectangleTransfer
            y: 16
            width: 256
            height: 40
            color: "#00000000"
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16

            Rectangle {
                id: rectangleTransferDecorated
                color: ThemeEngine.colorDoIt
                width: parent.width
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
            }

            MouseArea {
                anchors.fill: parent
                onPressed: {
                    rectangleTransferDecorated.width = rectangleTransferDecorated.width - 8
                    rectangleTransferDecorated.height = rectangleTransferDecorated.height - 8
                }
                onReleased: {
                    rectangleTransferDecorated.width = rectangleTransferDecorated.width + 8
                    rectangleTransferDecorated.height = rectangleTransferDecorated.height + 8
                }
                onClicked: {
                    // TODO offload func
                }
            }

            Text {
                id: textTransfer
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Offload content")
                color: ThemeEngine.colorButtonText
                font.bold: true
                font.pixelSize: 16
            }
        }

        Rectangle {
            id: rectangleDelete
            x: 4
            y: 79
            width: 256
            height: 40
            color: "#00000000"
            anchors.left: rectangleTransfer.right
            anchors.leftMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16

            property bool weAreBlinking: false
            property double startTime: 0

            function startTheBlink() {
                if (weAreBlinking === true) {
                    if ((new Date().getTime() - startTime) > 500) {
                        stopTheBlink();
                        // TODO func to actually delete stuff
                    }
                } else {
                    startTime = new Date().getTime()
                    weAreBlinking = true;
                    timerReset.start();
                    blinkReset.start();
                    textReset.text = qsTr("!!! CONFIRM !!!");
                }
            }
            function stopTheBlink() {
                weAreBlinking = false;
                timerReset.stop();
                blinkReset.stop();
                textReset.text = qsTr("Delete ALL content!");
                rectangleDeleteDecorated.color = ThemeEngine.colorDangerZone;
            }

            Rectangle {
                id: rectangleDeleteDecorated
                color: ThemeEngine.colorDangerZone
                width: parent.width
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on color {
                    id: blinkReset
                    running: false
                    loops: Animation.Infinite
                    ColorAnimation { from: ThemeEngine.colorDangerZone; to: "#ff0000"; duration: 1000 }
                    ColorAnimation { from: "#ff0000"; to: ThemeEngine.colorDangerZone; duration: 1000 }
                }
            }

            Timer {
                id: timerReset
                interval: 4000
                running: false
                repeat: false
                onTriggered: {
                    rectangleDelete.stopTheBlink()
                }
            }

            MouseArea {
                anchors.fill: parent

                onPressed: {
                    rectangleDeleteDecorated.width = rectangleDeleteDecorated.width - 8
                    rectangleDeleteDecorated.height = rectangleDeleteDecorated.height - 8
                }
                onReleased: {
                    rectangleDeleteDecorated.width = rectangleDeleteDecorated.width + 8
                    rectangleDeleteDecorated.height = rectangleDeleteDecorated.height + 8
                }
                onClicked: {
                    rectangleDelete.startTheBlink()
                }
            }

            Text {
                id: textReset
                width: 256
                color: ThemeEngine.colorButtonText
                text: qsTr("Delete ALL content")
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 16
                font.bold: true
                anchors.fill: parent
            }
        }

        ComboBox {
            id: comboBox_filterby
            width: 256
            height: 40
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16
            displayText: "Filter by:"
        }

        Slider {
            id: sliderZoom
            y: 72
            width: 200
            height: 40
            anchors.verticalCenter: comboBox_filterby.verticalCenter
            anchors.left: textZoom.right
            anchors.leftMargin: 16
            stepSize: 1
            to: 3
            from: 1
            value: 2

            onValueChanged: {
                if (value == 1.0) {
                    shotsview.cellSize = 160;
                } else  if (value == 2.0) {
                    shotsview.cellSize = 256;
                } else  if (value == 3.0) {
                    shotsview.cellSize = 400;
                }
            }
        }

        Text {
            id: textZoom
            y: 72
            height: 40
            text: qsTr("Zoom:")
            anchors.verticalCenter: comboBox_filterby.verticalCenter
            anchors.left: comboBox_filterby.right
            anchors.leftMargin: 16
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 16
        }
    }

    Rectangle {
        id: rectangleDeviceShots
        color: ThemeEngine.colorContentBackground

        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        MouseArea {
            x: 0
            y: 0
            anchors.fill: parent
            onClicked: shotsview.currentIndex = -1
        }

        Component {
            id: highlight
            Rectangle {
                width: shotsview.cellSize;
                height: shotsview.cellSize
                color: "#00000000"
                border.width : 4
                border.color: ThemeEngine.colorDoIt
                x: {
                    if (shotsview.currentItem.x) {
                        x = shotsview.currentItem.x
                    } else {
                        x = 0
                    }
                }
                y: {
                    if (shotsview.currentItem.y) {
                        y = shotsview.currentItem.y
                    } else {
                        y = 0
                    }
                }
                z: 1
            }
        }

        Rectangle {
            id: circleEmpty
            width: 350
            height: 350
            radius: width*0.5
            color: ThemeEngine.colorHeaderBackground
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                id: imageEmpty
                width: 256
                height: 256
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                source: "qrc:/icons/card.svg"
            }
        }

        ScrollView {
            id: scrollView
            x: 0
            y: 0
            z: 0
            anchors.fill: parent

            GridView {
                id: shotsview

                onCountChanged: {
                    updateGridViewStuff()
                }

                Component.onCompleted: {
                    updateGridViewStuff()
                }

                flickableChildren: MouseArea {
                    anchors.fill: parent
                    onClicked: shotsview.currentIndex = -1
                }

                property int cellSize: 256
                property int cellMargin: 16
                //property int cellMargin: (parent.width%cellSize) / Math.floor(parent.width/cellSize);
                cellWidth: cellSize + cellMargin
                cellHeight: cellSize + 16

                anchors.rightMargin: 16
                anchors.leftMargin: 16
                anchors.bottomMargin: 16
                anchors.topMargin: 16
                anchors.fill: parent

                interactive: true
                model: myDevice.shotModel
                delegate: ItemShot { width: shotsview.cellSize }

                highlight: highlight
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 0
                focus: true
            }
        }
    }
}
