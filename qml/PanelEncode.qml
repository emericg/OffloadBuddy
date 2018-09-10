import QtQuick 2.10
import QtQuick.Controls 2.3

Item {
    id: item1
    width: 640
    height: 640
    Rectangle {
        id: rectangleEncode
        color: "#ffffff"
        anchors.bottom: rectangleDestination.top
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.top: parent.top

        Text {
            id: textEncodeTitle
            text: qsTr("Encoding settings")
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16
            font.pixelSize: 24
        }

        Text {
            id: text4
            y: 266
            text: qsTr("Apply filters")
            font.bold: false
            anchors.left: parent.left
            anchors.leftMargin: 16
            font.pixelSize: 24
        }

        Rectangle {
            id: rectangleCodec
            height: 40
            color: "#ffffff"
            anchors.top: textEncodeTitle.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            RadioButton {
                id: rbVP9
                text: qsTr("VP9")
                anchors.left: rbH265.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
            }

            RadioButton {
                id: rbH265
                text: qsTr("H.265")
                anchors.left: rbH264.right
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
            }

            RadioButton {
                id: rbH264
                text: qsTr("H.264")
                checked: true
                anchors.left: text1.right
                anchors.leftMargin: 64
                anchors.verticalCenterOffset: 0
                anchors.verticalCenter: parent.verticalCenter
            }

            RadioButton {
                id: rbGIF
                text: qsTr("GIF")
                anchors.left: rbVP9.right
                anchors.leftMargin: 16
                anchors.verticalCenterOffset: 0
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: text1
                x: -114
                y: 30
                text: qsTr("Codec")
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16
                font.pixelSize: 14
            }




        }

        Rectangle {
            id: rectangleSpeed
            height: 40
            color: "#ffffff"
            anchors.top: rectangleCodec.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            Text {
                id: text3
                text: qsTr("Speed index")
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16
                font.pixelSize: 14
            }

            Slider {
                id: sliderSpeed
                anchors.right: parent.right
                anchors.rightMargin: 64
                stepSize: 1
                to: 2
                anchors.left: text3.right
                anchors.leftMargin: 64
                anchors.verticalCenter: parent.verticalCenter
                value: 1
            }
        }

        Rectangle {
            id: rectangleQuality
            height: 40
            color: "#ffffff"
            anchors.top: rectangleSpeed.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            Text {
                id: text2
                text: qsTr("Quality index")
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16
                font.pixelSize: 14
            }

            Slider {
                id: sliderQuality
                anchors.left: text2.right
                anchors.leftMargin: 64
                anchors.right: parent.right
                anchors.rightMargin: 64
                anchors.verticalCenter: parent.verticalCenter
                value: 0.5
            }
        }

        Rectangle {
            id: rectangleTimelapse
            height: 40
            color: "#ffffff"
            anchors.top: rectangleQuality.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            Text {
                id: text5
                text: qsTr("Timelapse interval")
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16
                font.pixelSize: 14
            }

            Text {
                id: text6
                text: qsTr("30fps")
                anchors.left: text5.right
                anchors.leftMargin: 32
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 14
            }

            Slider {
                id: slider
                width: 256
                anchors.left: text6.right
                anchors.leftMargin: 32
                anchors.verticalCenter: parent.verticalCenter
                value: 0.5
            }
        }

        CheckBox {
            id: checkBox
            x: 16
            y: 310
            text: qsTr("stabilization")
        }

        CheckBox {
            id: checkBox1
            x: 159
            y: 310
            text: qsTr("defishye")
        }

        CheckBox {
            id: checkBox2
            x: 280
            y: 310
            text: qsTr("crop")
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
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            anchors.left: parent.left
            font.pixelSize: 16
        }

        ComboBox {
            id: comboBoxDestination
            width: 256
            displayText: "auto"
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: textDestinationTitle.right
            anchors.leftMargin: 16
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
        }

        Button {
            id: buttonCancel
            y: 12
            text: qsTr("Cancel")
            font.pixelSize: 16
            anchors.left: buttonStart.right
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
        }
    }



}

/*##^## Designer {
    D{i:2;anchors_height:200;anchors_width:200}D{i:3;anchors_x:14;anchors_y:13}D{i:5;anchors_x:62;anchors_y:48}
D{i:6;anchors_x:34}D{i:7;anchors_x:23}D{i:8;anchors_x:16}D{i:9;anchors_x:16}D{i:4;anchors_x:16;anchors_y:65}
D{i:11;anchors_x:116}D{i:12;anchors_x:335}D{i:10;anchors_x:569}D{i:14;anchors_width:200;anchors_x:173;anchors_y:177}
D{i:15;anchors_width:200;anchors_x:79;anchors_y:120}D{i:13;anchors_x:466}D{i:17;anchors_width:200;anchors_x:230;anchors_y:197}
D{i:16;anchors_width:400;anchors_x:213}D{i:21;anchors_x:21}D{i:22;anchors_width:200}
D{i:1;anchors_height:350;anchors_width:200;anchors_x:84;anchors_y:184}D{i:24;anchors_x:67}
D{i:25;anchors_x:205}D{i:23;anchors_width:200;anchors_x:73}D{i:27;anchors_x:173}D{i:28;anchors_x:254}
}
 ##^##*/
