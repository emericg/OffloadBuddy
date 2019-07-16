import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

Popup {
    id: popupEncodePicture
    width: 640
    height: 320
    padding: 24

    signal confirmed()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: Theme.colorBackground
        radius: 2
    }

    /*contentItem:*/ Item {
        id: element
        anchors.fill: parent

        Text {
            id: textArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.WordWrap
            font.pixelSize: 24
            color: Theme.colorText
            text: qsTr("Encode image")
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

            Row {
                height: 56
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                Text {
                    id: element1
                    width: 128
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Format")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                ComboBox {
                    id: comboBox
                    width: 400
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                height: 56
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                Text {
                    id: element2
                    width: 128
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Quality")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                Slider {
                    id: slider
                    width: 400
                    anchors.verticalCenter: parent.verticalCenter
                    value: 0.5
                }
            }

            Row {
                height: 56
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0
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
                    popupEncodePicture.close();
                }
            }
            ButtonImageWireframe {
                id: buttonExit
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Encode")
                source: "qrc:/icons_material/baseline-memory-24px.svg"
                fullColor: true
                primaryColor: Theme.colorHighlight
                onClicked: {
                    popupEncodePicture.confirmed();
                    popupEncodePicture.close();
                }
            }
        }
    }
}
