import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Switch {
    id: control

    leftPadding: 0
    rightPadding: 0
    spacing: 16
    font.pixelSize: Theme.fontSizeComponent

    indicator: Rectangle {
        x: control.leftPadding
        y: (parent.height / 2) - (height / 2)
        width: 48
        height: (width / 2)
        radius: (width / 2)

        color: Theme.colorComponentBackground
        border.color: Theme.colorComponentBorder

        Rectangle {
            x: control.checked ? (parent.width - width) : 0
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: width
            radius: (width / 2)

            color: control.checked ? Theme.colorPrimary : Theme.colorComponentDown
            border.color: control.checked ? Theme.colorPrimary : Theme.colorComponentDown

            Behavior on x { NumberAnimation { duration: 133 } }
        }
    }

    contentItem: Text {
        leftPadding: control.indicator.width + control.spacing
        verticalAlignment: Text.AlignVCenter

        text: control.text
        font: control.font
        color: Theme.colorText
        opacity: enabled ? 1.0 : 0.33
    }
}
