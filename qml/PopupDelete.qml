import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Popup {
    id: popupDelete

    x: (appWindow.width / 2) - (width / 2) - (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 640
    padding: 0

    signal confirmed()
    property string message
    property var files: []

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: Theme.colorBackground
        radius: Theme.componentRadius
        border.width: 1
        border.color: Theme.colorSeparator
    }

    contentItem: Column {
        spacing: 16

        Rectangle {
            id: titleArea
            height: 64
            anchors.left: parent.left
            anchors.right: parent.right
            radius: Theme.componentRadius
            color: ThemeEngine.colorPrimary

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Confirmation")
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: "white"
            }
        }

        ////////////////

        Text {
            id: textArea
            height: Theme.componentHeight
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24

            text: message
            font.pixelSize: Theme.fontSizeContent
            color: Theme.colorText
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.WordWrap
        }

        ////////////////

        Item {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24

            visible: files.length
            height: listArea.height > 400 ? 400 : listArea.height

            ImageSvg {
                id: listIcon
                anchors.top: parent.top
                anchors.left: parent.left
                color: Theme.colorText
                source: "qrc:/assets/icons_material/baseline-list-24px.svg"
            }

            ListView {
                id: listArea
                height: files.length * 16
                anchors.left: listIcon.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 0

                flickableDirection: Flickable.HorizontalAndVerticalFlick
                clip: true
                model: files
                delegate: Text { height: 16; text: modelData; font.pixelSize: 14; color: Theme.colorSubText; }
            }
        }

        ////////////////

        Row {
            id: rowButtons
            height: Theme.componentHeight*2 + parent.spacing
            anchors.right: parent.right
            anchors.rightMargin: 24
            spacing: 24

            ButtonWireframe {
                id: buttonCancel
                width: 96
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Cancel")
                fullColor: true
                primaryColor: Theme.colorGrey
                onClicked: popupDelete.close()
            }
            ButtonWireframeImage {
                id: buttonConfirm
                width: 128
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Delete")
                source: "qrc:/assets/icons_material/baseline-delete-24px.svg"
                fullColor: true
                primaryColor: Theme.colorError
                onClicked: {
                    popupDelete.confirmed()
                    popupDelete.close()
                }
            }
        }
    }
}
