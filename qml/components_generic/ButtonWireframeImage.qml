import QtQuick 2.9
import QtQuick.Controls 2.2

import ThemeEngine 1.0

Button {
    id: control
    width: contentText.width + contentImage.width*3
    implicitHeight: Theme.componentHeight
    font.pixelSize: Theme.fontSizeComponent
    font.bold: false

    property url source: ""
    property int imgSize: (height / 1.5)

    property bool fullColor: false
    property string fulltextColor: "white"
    property string primaryColor: Theme.colorPrimary
    property string secondaryColor: Theme.colorComponentBackground

    contentItem: Item {
        ImageSvg {
            id: contentImage
            width: imgSize
            height: imgSize

            anchors.right: contentText.left
            anchors.rightMargin: (imgSize / 3)
            anchors.verticalCenter: parent.verticalCenter

            opacity: enabled ? 1.0 : 0.33
            source: control.source
            color: fullColor ? fulltextColor : control.primaryColor
        }
        Text {
            id: contentText
            height: parent.height

            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: (imgSize / 2)

            text: control.text
            font: control.font
            opacity: enabled ? (control.down ? 0.8 : 1.0) : 0.33
            color: fullColor ? fulltextColor : control.primaryColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    background: Rectangle {
        radius: Theme.componentRadius
        opacity: enabled ? (control.down ? 0.8 : 1.0) : 0.33
        color: fullColor ? control.primaryColor : control.secondaryColor
        border.width: 1
        border.color: fullColor ? control.primaryColor : Theme.colorComponentBorder
    }
}
