import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Item {
    id: actionButton
    height: 34
    width: parent.width

    property int index
    property string button_text
    property string button_source

    signal buttonClicked

    property alias contentWidth: tButton.contentWidth

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        id: viewButton
        height: parent.height
        width: parent.width
        color: "transparent"

        ImageSvg {
            id: iButton
            width: 20
            height: 20
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter

            source: button_source
            color: Theme.colorSubText
        }

        Text {
            id: tButton
            width: parent.width
            anchors.left: iButton.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr(button_text)
            font.bold: false
            font.pixelSize: Theme.fontSizeComponent
            color: Theme.colorSubText
        }

        MouseArea {
            anchors.fill: parent

            hoverEnabled: isDesktop && visible
            onEntered: viewButton.state = "hovered"
            onExited: viewButton.state = "normal"

            onClicked: buttonClicked()
        }

        states: [
            State {
                name: "normal";
                PropertyChanges { target: viewButton; color: "transparent"; }
                PropertyChanges { target: tButton; color: Theme.colorSubText; }
                PropertyChanges { target: iButton; color: Theme.colorSubText; }
            },
            State {
                name: "hovered";
                PropertyChanges { target: viewButton; color: Theme.colorComponentBorder; }
                PropertyChanges { target: tButton; color: { (tButton.text === qsTr("DELETE")) ? Theme.colorWarning : Theme.colorText } }
                PropertyChanges { target: iButton; color: { (tButton.text === qsTr("DELETE")) ? Theme.colorWarning : Theme.colorText } }
            }
        ]
    }
}
