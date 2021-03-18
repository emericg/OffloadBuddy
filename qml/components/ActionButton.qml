import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Item {
    id: actionButtonItem
    height: 34
    width: parent.width

    property string button_text
    property string button_source
    property int index

    property bool clicked
    signal buttonClicked

    function viewButtonHovered() {
        viewButton.state = "hovered"
    }

    function viewButtonExited() {
        if (clicked == false) {
            viewButton.state = ""
        } else {
            viewButton.state = "clicked"
        }
    }

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

            hoverEnabled: isDesktop
            onClicked: buttonClicked()
            onEntered: viewButtonHovered()
            onExited: viewButtonExited()
        }

        states: [
            State {
                name: "clicked";
                PropertyChanges { target: viewButton; color: "transparent"; }
                PropertyChanges { target: tButton; color: "#286E1E"; }
                PropertyChanges { target: iButton; color: "#286E1E"; }
            },
            State {
                name: "hovered";
                PropertyChanges { target: viewButton; color: Theme.colorForeground; }
                PropertyChanges { target: tButton; color: { if (tButton.text === qsTr("DELETE")) Theme.colorWarning; else Theme.colorText; } }
                PropertyChanges { target: iButton; color: { if (tButton.text === qsTr("DELETE")) Theme.colorWarning; else Theme.colorText; } }
            },
            State {
                name: "normal";
                PropertyChanges { target: viewButton; color: "transparent"; }
                PropertyChanges { target: tButton; color: Theme.colorSubText; }
                PropertyChanges { target: iButton; color: Theme.colorSubText; }
            }
        ]
    }
}
