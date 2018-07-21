import QtQuick 2.11
import QtQuick.Controls 2.4

import com.offloadbuddy.style 1.0
import "SpaceUtils.js" as SpaceUtils

Rectangle {
    width: 1280
    height: 720

    property var mySettings
    property var myDevice

    onMyDeviceChanged: {
        deviceModelText.text = myDevice.brand + " " + myDevice.model;
        deviceSpaceText.text = SpaceUtils.bytesToString(myDevice.spaceUsed) + " used of " + SpaceUtils.bytesToString(myDevice.spaceTotal)
        deviceSpaceBar.value = myDevice.spaceUsedPercent
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

        Component.onCompleted: {
            deviceModelText.text = myDevice.brand + " " + myDevice.model;
            deviceSpaceText.text = SpaceUtils.bytesToString(myDevice.spaceUsed) + " used of " + SpaceUtils.bytesToString(myDevice.spaceTotal)
            deviceSpaceBar.value = myDevice.spaceUsedPercent

            if (myDevice.model.includes("HERO3") ||
                myDevice.model.includes("HERO4")) {
                deviceImage.source = "qrc:/cameras/H4.svg"
            }
            else if (myDevice.model.includes("Session")) {
                deviceImage.source = "qrc:/cameras/session.svg"
            }
            else if (myDevice.model.includes("FUSION")) {
                deviceImage.source = "qrc:/cameras/fusion.svg"
            }
            else if (myDevice.model.includes("HERO5")) {
                deviceImage.source = "qrc:/cameras/H5.svg"
            }
            else if (myDevice.model.includes("HERO6")) {
                deviceImage.source = "qrc:/cameras/H6.svg"
            }
            else {
                deviceImage.source = "qrc:/cameras/generic.svg"
            }
        }

        Text {
            id: textHeader
            width: 200
            height: 40
            color: ThemeEngine.colorHeaderTitle
            text: qsTr("DEVICE")
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            font.bold: true
            font.pixelSize: 30
        }

        Image {
            id: deviceImage
            x: 16
            width: 128
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
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            font.pixelSize: 20
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
            font.pixelSize: 14
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
            width: 256
            height: 40
            color: ThemeEngine.colorDoIt
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.left: textHeader.right
            anchors.leftMargin: 16

            MouseArea {
                anchors.fill: parent

                onPressed: {
                    rectangleTransfer.anchors.bottomMargin = rectangleTransfer.anchors.bottomMargin + 4
                    rectangleTransfer.anchors.leftMargin = rectangleTransfer.anchors.leftMargin + 4
                    rectangleTransfer.anchors.rightMargin = rectangleTransfer.anchors.rightMargin + 4
                    rectangleTransfer.width = rectangleTransfer.width - 8
                    rectangleTransfer.height = rectangleTransfer.height - 8
                }
                onReleased: {
                    rectangleTransfer.anchors.bottomMargin = rectangleTransfer.anchors.bottomMargin - 4
                    rectangleTransfer.anchors.leftMargin = rectangleTransfer.anchors.leftMargin - 4
                    rectangleTransfer.anchors.rightMargin = rectangleTransfer.anchors.rightMargin - 4
                    rectangleTransfer.width = rectangleTransfer.width + 8
                    rectangleTransfer.height = rectangleTransfer.height + 8
                }
                onClicked: {
                    // TODO offload func
                }
            }

            Text {
                id: text1
                color: ThemeEngine.colorButtonText
                text: qsTr("Offload content")
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                anchors.fill: parent
                font.pixelSize: 16
            }
        }

        Rectangle {
            id: rectangleDelete
            x: 4
            width: 256
            height: 40
            color: ThemeEngine.colorDangerZone
            anchors.leftMargin: 16
            anchors.left: rectangleTransfer.right

            property bool weAreBlinking: false

            function startTheBlink() {
                if (weAreBlinking === true) {
                    // TODO func to delete stuff
                    stopTheBlink();
                } else {
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
                rectangleDelete.color = ThemeEngine.colorDangerZone;
            }

            SequentialAnimation on color {
                id: blinkReset
                running: false
                loops: Animation.Infinite
                ColorAnimation { from: ThemeEngine.colorDangerZone; to: "#ff0000"; duration: 1000 }
                ColorAnimation { from: "#ff0000"; to: ThemeEngine.colorDangerZone; duration: 1000 }
            }
            anchors.top: parent.top
            anchors.topMargin: 16

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
                    rectangleDelete.anchors.bottomMargin = rectangleDelete.anchors.bottomMargin + 4
                    rectangleDelete.anchors.leftMargin = rectangleDelete.anchors.leftMargin + 4
                    rectangleDelete.anchors.rightMargin = rectangleDelete.anchors.rightMargin + 4
                    rectangleDelete.width = rectangleDelete.width - 8
                    rectangleDelete.height = rectangleDelete.height - 8
                }
                onReleased: {
                    rectangleDelete.anchors.bottomMargin = rectangleDelete.anchors.bottomMargin - 4
                    rectangleDelete.anchors.leftMargin = rectangleDelete.anchors.leftMargin - 4
                    rectangleDelete.anchors.rightMargin = rectangleDelete.anchors.rightMargin - 4
                    rectangleDelete.width = rectangleDelete.width + 8
                    rectangleDelete.height = rectangleDelete.height + 8
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
            y: 74
            width: 256
            height: 40
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16
            displayText: "Filter by:"
        }

        Slider {
            id: sliderZoom
            y: 72
            width: 200
            height: 40
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
            anchors.left: comboBox_filterby.right
            anchors.leftMargin: 16
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 16
        }
    }

    Rectangle {
        id: rectangleContent
        color: ThemeEngine.colorContentBackground

        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        Component {
            id: highlight
            Rectangle {
                width: shotsview.cellSize;
                height: shotsview.cellSize
                color: "#00000000"
                border.width : 4
                border.color: ThemeEngine.colorDoIt
                x: shotsview.currentItem.x
                y: shotsview.currentItem.y
                z: 1
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: shotsview.currentIndex = -1
        }

        // http://doc.qt.io/qt-5/qtquick-modelviewsdata-cppmodels.html

        ScrollView {
            id: scrollView
            z: 0
            anchors.fill: parent

            GridView {
                id: shotsview

                Component.onCompleted: {
                    shotsview.currentIndex = -1
                    //console.log("parent.width:" +width)
                    //console.log("cellMargin:" +cellMargin)
                }
                //property int cellMargin: (parent.width%cellSize) / Math.floor(parent.width/cellSize);

                flickableChildren: MouseArea {
                    anchors.fill: parent
                    onClicked: shotsview.currentIndex = -1
                }

                property int cellSize: 256
                property int cellMargin: 16
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
/*
                model: myDevice.shotsList
                delegate: ItemShot { shot: modelData;
                                     width: shotsview.cellSize }
*/
                highlight: highlight
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 0
                focus: true
            }
        }
    }
}

/*##^## Designer {
    D{i:7;anchors_y:16}D{i:10;anchors_y:79}D{i:14;anchors_x:8}
}
 ##^##*/
