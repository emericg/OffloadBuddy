import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Item {
    id: codec
    implicitWidth: 80
    implicitHeight: 28
    clip: true

    property string text: "CODEC"
    property string color: Theme.colorForeground
    property string colorText: Theme.colorText

    Rectangle {
        id: codecBackground
        width: parent.width
        height: parent.height
        opacity: 1
        radius: Theme.componentRadius
        color: codec.color

        Text {
            id: codecText
            anchors.fill: parent

            text: codec.text
            color: codec.colorText
            font.capitalization: Font.AllUppercase
            font.pixelSize: Theme.fontSizeComponent
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
