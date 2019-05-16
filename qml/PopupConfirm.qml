import QtQuick 2.9
import QtQuick.Controls 2.2

Popup {
    id: popupConfirm
    width: 330
    height: 256

    signal confirmed()

    property string message: ""

    x: (applicationWindow.width / 2) - (popupConfirm.width / 2) - (applicationSidebar.width / 2)
    y: (applicationWindow.height / 2) - (popupConfirm.height / 2)
    //width: textMessage.contentWidth + padding * 2
    padding: 24

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: theme.backgroundColor
        radius: 8
    }

    Text {
        id: textArea
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.top: parent.top
        anchors.topMargin: 24

        text: qsTr("Ho men, are you sure you want to do that?")
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        font.pixelSize: 20
    }

    Row {
        id: row
        y: 192
        height: 40
        anchors.horizontalCenterOffset: 1
        spacing: 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter

        ButtonThemed {
            id: buttonConfirm
            text: qsTr("Confirm")
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                popupConfirm.confirmed();
                popupConfirm.close();
            }
        }

        ButtonThemed {
            id: buttonCancel
            text: qsTr("Cancel")
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                popupConfirm.close();
            }
        }
    }
}
