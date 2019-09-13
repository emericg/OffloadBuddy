import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

Popup {
    id: popupDelete
    width: 720
    height: (files.length) ? 320 : 180
    padding: 24

    signal confirmed()
    property string message
    property var files: []

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: Theme.colorBackground
        radius: 2
    }

    contentItem: Item {
        //anchors.fill: parent

        Text {
            id: textArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            text: message
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.WordWrap
            font.pixelSize: 24
            color: Theme.colorText
        }

        ////////////////

        ImageSvg {
            id: listIcon
            anchors.top: textArea.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.leftMargin: -2

            visible: files.length
            color: Theme.colorText
            source: "qrc:/icons_material/baseline-list-24px.svg"
        }

        ListView {
            id: listArea
            anchors.bottom: rowButtons.top
            anchors.bottomMargin: 12
            anchors.top: listIcon.top
            anchors.topMargin: 6
            anchors.right: parent.right
            anchors.left: listIcon.right
            anchors.leftMargin: 12

            visible: files.length
            flickableDirection: Flickable.HorizontalAndVerticalFlick
            clip: true
            model: files
            delegate: Text { text: modelData; font.pixelSize: 14; color: Theme.colorSubText; }
        }

        ////////////////

        Row {
            id: rowButtons
            height: 40
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            spacing: 24

            ButtonWireframe {
                id: buttonCancel
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Cancel")
                primaryColor: Theme.colorPrimary
                onClicked: {
                    popupDelete.close();
                }
            }
            ButtonWireframeImage {
                id: buttonConfirm
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Delete")
                source: "qrc:/icons_material/baseline-delete-24px.svg"
                fullColor: true
                primaryColor: Theme.colorError
                onClicked: {
                    popupDelete.confirmed();
                    popupDelete.close();
                }
            }
        }
    }
}
