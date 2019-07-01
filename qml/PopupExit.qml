import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

Popup {
    id: popupExit
    width: 640
    height: 256

    signal confirmed()

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

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        font.pixelSize: 20
        color: Theme.colorText
        text: "A job is still running. Do you want to exit anyway?"
    }

    Row {
        id: row
        height: 40
        spacing: 32
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter

        ButtonImageWireframe {
            id: buttonExit
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Exit")
            source: "qrc:/icons_material/baseline-close-24px.svg"
            fullColor: true
            primaryColor: Theme.colorWarning
            onClicked: {
                popupExit.confirmed();
                popupExit.close();
            }
        }

        ButtonWireframe {
            id: buttonCancel
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Cancel")
            primaryColor: Theme.colorPrimary
            onClicked: {
                popupExit.close();
            }
        }
    }
}
