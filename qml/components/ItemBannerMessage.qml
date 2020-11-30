import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Rectangle {
    id: bannerMessage
    height: 56
    anchors.left: parent.left
    anchors.right: parent.right

    z: 1
    color: Theme.colorActionbar

    Component.onCompleted: {
        bannerMessage.close()
    }

    function openMessage(message) {
        bannerMessage.visible = true
        bannerMessage.height = 56
        bannerText.text = message
    }

    function close() {
        bannerMessage.visible = false
        bannerMessage.height = 0
    }

    // prevent clicks below this area
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; }

    ////////////////////////////////////////////////////////////////////////////

    Text {
        id: bannerText
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter

        text: "banner text"
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
