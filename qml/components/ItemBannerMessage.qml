import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString

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
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter

        color: Theme.colorActionbarContent
        font.pixelSize: Theme.fontSizeContentBig
    }

    ItemImageButton {
        id: rectangleClose
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        source: "qrc:/assets/icons_material/baseline-close-24px.svg"
        iconColor: "white"
        backgroundColor: Theme.colorActionbarHighlight
        onClicked: bannerMessage.close()
    }
}
