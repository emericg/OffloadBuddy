import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

CheckBox {
    id: control
    implicitHeight: Theme.componentHeight
    leftPadding: 0
    rightPadding: 0

    checked: false
    text: "Check Box"
    font.pixelSize: Theme.fontSizeComponent

    indicator: Rectangle {
        x: control.leftPadding
        y: (parent.height / 2) - (height / 2)
        width: 24
        height: 24
        radius: Theme.componentRadius

        color: Theme.colorComponentBackground
        border.width: 1
        border.color: control.down ? Theme.colorSecondary : Theme.colorComponentBorder

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            width: 12
            height: 12

            color: Theme.colorSecondary
            opacity: control.checked ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 133 } }
        }
    }

    contentItem: Text {
        text: control.text
        font: control.font
        leftPadding: control.indicator.width + control.spacing
        verticalAlignment: Text.AlignVCenter

        color: Theme.colorText
        opacity: enabled ? 1.0 : 0.33
    }
}
