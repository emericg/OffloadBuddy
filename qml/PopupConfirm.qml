import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

Popup {
    id: popupConfirm
    width: 480
    height: 256

    signal confirmed()
    property string message
    property string files: []

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: Theme.colorBackground
        radius: 2
    }

    Text {
        id: textArea
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.top: parent.top
        anchors.topMargin: 24

        text: message
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        font.pixelSize: 20
    }

    Row {
        id: row
        height: 40
        spacing: 32
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter

        ButtonImageWireframe {
            id: buttonConfirm
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Confirm")
            source: "qrc:/icons_material/baseline-delete-24px.svg"
            fullColor: true
            primaryColor: Theme.colorError
            onClicked: {
                popupConfirm.confirmed();
                popupConfirm.close();
            }
        }

        ButtonWireframe {
            id: buttonCancel
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Cancel")
            onClicked: {
                popupConfirm.close();
            }
        }
    }
}
