import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Popup {
    id: popupExit
    x: (appWindow.width / 2) - (width / 2) - (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 640
    padding: 0

    signal confirmed()

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
            height: Theme.componentHeight
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24

            text: qsTr("A job is still running. Do you want to exit anyway?")
            font.pixelSize: Theme.fontSizeContent
            color: Theme.colorText
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.WordWrap
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
                onClicked: popupExit.close()
            }
            ButtonWireframeImage {
                id: buttonExit
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Exit")
                width: 128
                source: "qrc:/assets/icons_material/baseline-exit_to_app-24px.svg"
                fullColor: true
                primaryColor: Theme.colorWarning
                onClicked: {
                    popupExit.confirmed()
                    popupExit.close()
                }
            }
        }
    }
}
