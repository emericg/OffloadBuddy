import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.12

import com.offloadbuddy.theme 1.0

Button {
    id: control
    width: contenttext.width + imgSize*3

    property url source: ""
    property int imgSize: 28

    contentItem: Item {
        Text {
            id: contenttext
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: (imgSize/2 + imgSize/6)
            text: control.text
            font: control.font
            opacity: enabled ? 1.0 : 0.3
            color: control.down ? Theme.colorButtonText : Theme.colorButtonText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        ImageSvg {
            id: contentimage
            width: imgSize
            height: imgSize

            anchors.right: contenttext.left
            anchors.rightMargin: imgSize/3
            anchors.verticalCenter: parent.verticalCenter

            opacity: enabled ? 1.0 : 0.3
            source: control.source
            color: Theme.colorIcon
        }
    }

    background: Rectangle {
        implicitWidth: 128
        implicitHeight: 40
        radius: 4
        opacity: enabled ? 1 : 0.3
        color: control.down ? Theme.colorButtonDown : Theme.colorButton
    }
}
