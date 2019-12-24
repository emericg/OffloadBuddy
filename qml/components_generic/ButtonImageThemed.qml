import QtQuick 2.9
import QtQuick.Controls 2.2

import ThemeEngine 1.0

Button {
    id: control
    width: contentText.width + imgSize*3
    implicitHeight: Theme.componentHeight

    property url source: ""
    property int imgSize: 28

    contentItem: Item {
        Text {
            id: contentText
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: (imgSize/2 + imgSize/6)

            text: control.text
            font: control.font
            opacity: enabled ? 1.0 : 0.3
            color: control.down ? Theme.colorComponentContent : Theme.colorComponentContent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        ImageSvg {
            id: contentImage
            width: imgSize
            height: imgSize

            anchors.right: contentText.left
            anchors.rightMargin: imgSize/3
            anchors.verticalCenter: parent.verticalCenter

            opacity: enabled ? 1.0 : 0.3
            source: control.source
            color: Theme.colorIcon
        }
    }

    background: Rectangle {
        radius: Theme.componentRadius
        opacity: enabled ? 1 : 0.3
        color: control.down ? Theme.colorComponentDown : Theme.colorComponent
    }
}
