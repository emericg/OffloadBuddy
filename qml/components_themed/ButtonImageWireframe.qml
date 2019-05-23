import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

import com.offloadbuddy.theme 1.0

Button {
    id: control
    width: contenttext.width + imgSize*3

    property url source: ""
    property int imgSize: 28

    property bool fullColor: false
    property string primaryColor: "#5483EF"
    property string secondaryColor: "#D0D0D0"

    font.pixelSize: 18
    font.bold: false

    contentItem: Item {
        Text {
            id: contenttext
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: (imgSize/2 + imgSize/6)
            text: control.text
            font: control.font
            opacity: enabled ? (control.down ? 0.9 : 1.0) : 0.3
            color: fullColor ? "white" : control.primaryColor
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
            color: fullColor ? "white" : control.primaryColor
        }
    }

    background: Rectangle {
        implicitWidth: 128
        implicitHeight: 40
        radius: 4
        border.width: 1
        border.color: fullColor ? control.primaryColor : control.secondaryColor
        opacity: enabled ? (control.down ? 0.5 : 1.0) : 0.3
        color: fullColor ? control.primaryColor : "transparent"
    }
}
