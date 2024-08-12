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

    ////////////////

    function openMessage(message) {
        bannerMessage.height = 48
        bannerText.text = message
    }

    function close() {
        bannerMessage.height = 0
    }

    ////////////////

    Text {
        id: bannerText
        anchors.left: parent.left
        anchors.leftMargin: Theme.componentMargin
        anchors.verticalCenter: parent.verticalCenter

        textFormat: Text.PlainText
        color: Theme.colorActionbarContent
        font.pixelSize: Theme.fontSizeContentBig
    }

    RoundButtonSunken {
        id: rectangleClose
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        source: "qrc:/assets/icons/material-symbols/close.svg"
        colorIcon: Theme.colorActionbarContent
        colorBackground: Theme.colorActionbar

        onClicked: bannerMessage.close()
    }

    ////////////////
}
