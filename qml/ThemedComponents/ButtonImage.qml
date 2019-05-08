import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

Button {
    id: control

    property string imageSource: ""
    property int imageSize: 24

    // theming
    background: Rectangle {
        implicitWidth: 40
        implicitHeight: 40
        opacity: enabled ? 1 : 0.3
        color: control.down ? Theme.colorButtonDown : Theme.colorButton
    }

    contentItem: ImageSvg {
        width: imageSize
        height: imageSize
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        source: imageSource
        color: enabled ? Theme.colorButtonText : Theme.colorButtonDown
    }
}
