import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

Popup {
    id: popupConfirm
    width: 640
    height: (files.length) ? 320 : 180

    signal confirmed()
    property string message
    property var files: []

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
        color: Theme.colorText
    }

    ListView {
        id: listArea
        anchors.bottom: row.top
        anchors.bottomMargin: 24
        anchors.top: textArea.bottom
        anchors.topMargin: 24
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.left: parent.left
        anchors.leftMargin: 24

        visible: files.length
        clip: true
        model: files
        delegate: Text { text: modelData; color: Theme.colorText; }
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

            text: qsTr("Delete")
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
            primaryColor: Theme.colorPrimary
            onClicked: {
                popupConfirm.close();
            }
        }
    }
}
