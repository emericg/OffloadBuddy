import QtQuick 2.10
import QtQuick.Controls 2.3

import com.offloadbuddy.shared 1.0

Item {
    id: itemEncode
    width: 640
    height: 640

    function updateEncodePanel() {
        if (selectedItem.shot.type === Shared.SHOT_PICTURE_MULTI ||
            selectedItem.shot.type === Shared.SHOT_PICTURE_BURST ||
            selectedItem.shot.type === Shared.SHOT_PICTURE_TIMELAPSE ||
            selectedItem.shot.type === Shared.SHOT_PICTURE_NIGHTLAPSE) {
            rectangleTimelapse.visible = true
        } else {
            rectangleTimelapse.visible = false
        }

        // Handle destination(s)
        cbDestinations.clear()
        //cbDestinations.append( { "text": "auto" } )

        for (var child in settingsManager.directoriesList) {
            //console.log("destination: " + settingsManager.directoriesList[child].directoryPath)
            if (settingsManager.directoriesList[child].directoryContent < 2)
                cbDestinations.append( { "text": settingsManager.directoriesList[child].directoryPath } )
        }
    }

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
                text: "VP9"
                anchors.left: rbH265.right
                anchors.leftMargin: 16
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
                id: rbH264
                text: "H.264"
                checked: true
                anchors.left: text1.right
                anchors.leftMargin: 64
                anchors.verticalCenterOffset: 0
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
                from: 1
                to: 5
                stepSize: 1
                anchors.left: text2.right
                anchors.leftMargin: 64
                anchors.right: parent.right
                anchors.rightMargin: 64
                anchors.verticalCenter: parent.verticalCenter
                value: 3
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
                text: sliderFps.value + " " + qsTr("fps")
                anchors.left: text5.right
                anchors.leftMargin: 32
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 14
            }

            Slider {
                id: sliderFps
                width: 256
                to: 60
                from: 5
                stepSize: 1
                anchors.left: text6.right
                anchors.leftMargin: 32
                anchors.verticalCenter: parent.verticalCenter
                value: 30
            }
        }

        CheckBox {
            id: checkBox_stab
            x: 16
            y: 310
            text: qsTr("stabilization")
        }

        CheckBox {
            id: checkBox_defish
            x: 159
            y: 310
            text: qsTr("defisheye")
        }

        CheckBox {
            id: checkBox_crop
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
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: textDestinationTitle.right
            anchors.leftMargin: 16

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

                myDevice.reencodeSelected(selectedItemName, codec,
                                          sliderQuality.value,
                                          sliderSpeed.value,
                                          sliderFps.value)
                popupEncode.close()
            }
        }

        Button {
            id: buttonCancel
            y: 12
            text: qsTr("Cancel")
            font.pixelSize: 16
            anchors.left: buttonStart.right
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            onClicked: popupEncode.close()
        }
    }
}
