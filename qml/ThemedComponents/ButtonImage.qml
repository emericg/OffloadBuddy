import QtQuick 2.10
import QtQuick.Controls 2.3
import QtGraphicalEffects 1.0

import com.offloadbuddy.style 1.0

Button {
    id: control

    property string imageSource: ""

    // theming
    background: Rectangle {
        implicitWidth: 40
        implicitHeight: 40
        opacity: enabled ? 1 : 0.3
        color: control.down ? ThemeEngine.colorButtonDown : ThemeEngine.colorButton
    }

    contentItem: Image {
        width: 24
        height: 24
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        source: imageSource
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectCrop

        ColorOverlay {
            anchors.fill: parent
            source: parent
            color: enabled ? ThemeEngine.colorButtonText : ThemeEngine.colorButtonDown
        }
    }
}
