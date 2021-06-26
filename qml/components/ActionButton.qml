import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Rectangle {
    id: actionButton
    height: 34
    width: parent.width

    property int index
    property alias button_text: tButton.text
    property alias button_source: iButton.source

    signal buttonClicked

    property alias contentWidth: tButton.contentWidth

    ////////////////////////////////////////////////////////////////////////////

    radius: 2 // Theme.componentRadius
    color: "transparent"

    ImageSvg {
        id: iButton
        width: 20
        height: 20
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        color: "black"
    }

    Text {
        id: tButton
        width: parent.width
        anchors.left: iButton.right
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        color: "black"
        font.bold: false
        font.pixelSize: Theme.fontSizeComponent
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: isDesktop && visible

        onEntered: actionButton.state = "hovered"
        onExited: actionButton.state = "normal"
        onCanceled: actionButton.state = "normal"
        onClicked: buttonClicked()
    }

    states: [
        State {
            name: "normal";
            PropertyChanges { target: actionButton; color: "transparent"; }
            PropertyChanges { target: tButton; color: "black"; }
            PropertyChanges { target: iButton; color: "black"; }
        },
        State {
            name: "hovered";
            PropertyChanges { target: actionButton; color: Theme.colorSeparator; }
            PropertyChanges { target: tButton; color: { (tButton.text === qsTr("DELETE")) ? Theme.colorError : "black" } }
            PropertyChanges { target: iButton; color: { (tButton.text === qsTr("DELETE")) ? Theme.colorError : "black" } }
        }
    ]
}
