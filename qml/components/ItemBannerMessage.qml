import QtQuick
import QtQuick.Controls

import ThemeEngine
import "qrc:/utils/UtilsString.js" as UtilsString

Rectangle {
    id: bannerMessage
    anchors.left: parent.left
    anchors.right: parent.right

    height: 0
    Behavior on height { NumberAnimation { duration: 133 } }

    clip: true
    visible: (height > 0)
    color: Theme.colorActionbar

    // prevent clicks below this area
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; }

    ////////////////////////////////////////////////////////////////////////////

    function openMessage(message) {
        bannerMessage.height = 48
        bannerText.text = message
    }

    function close() {
        bannerMessage.height = 0
    }

    ////////////////////////////////////////////////////////////////////////////

    Text {
        id: bannerText
        anchors.left: parent.left
        anchors.leftMargin: Theme.componentMargin
        anchors.verticalCenter: parent.verticalCenter

        color: Theme.colorActionbarContent
        font.pixelSize: Theme.fontSizeContentBig
    }

    RoundButtonIcon {
        id: rectangleClose
        anchors.right: parent.right
        anchors.rightMargin: Theme.componentMargin/2
        anchors.verticalCenter: parent.verticalCenter

        source: "qrc:/assets/icons/material-symbols/close.svg"
        iconColor: "white"
        backgroundColor: Theme.colorActionbarHighlight
        onClicked: bannerMessage.close()
    }
}
