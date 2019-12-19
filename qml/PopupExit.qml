import QtQuick 2.9
import QtQuick.Controls 2.2

import ThemeEngine 1.0

Popup {
    id: popupExit
    x: (applicationWindow.width / 2) - (width / 2) - (applicationSidebar.width / 2)
    y: (applicationWindow.height / 2) - (height / 2)
    width: 640
    height: 160
    padding: 24

    signal confirmed()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: Theme.colorBackground
        radius: Theme.componentRadius
    }

    contentItem: Item {
        //anchors.fill: parent

        Text {
            id: textArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.WordWrap
            font.pixelSize: 20
            color: Theme.colorText
            text: qsTr("A job is still running. Do you want to exit anyway?")
        }

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
                width: 96
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Cancel")
                primaryColor: Theme.colorPrimary
                onClicked: {
                    popupExit.close();
                }
            }
            ButtonWireframeImage {
                id: buttonExit
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Exit")
                width: 128
                source: "qrc:/icons_material/baseline-exit_to_app-24px.svg"
                fullColor: true
                primaryColor: Theme.colorWarning
                onClicked: {
                    popupExit.confirmed();
                    popupExit.close();
                }
            }
        }
    }
}
