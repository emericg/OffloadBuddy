import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Switch {
    id: control
    implicitHeight: Theme.componentHeight

    padding: 4
    spacing: 12
    font.pixelSize: Theme.fontSizeComponent

    indicator: Rectangle {
        x: control.leftPadding
        y: (parent.height / 2) - (height / 2)
        width: 48
        height: (width / 2)
        radius: (width / 2)

        color: Theme.colorComponentBackground
        Behavior on color { ColorAnimation { duration: 133; easing.type: Easing.InOutCirc; } }

        border.color: Theme.colorComponentBorder
        border.width: Theme.componentBorderWidth

        Rectangle {
            x: control.checked ? (parent.width - width) : 0
            Behavior on x { NumberAnimation { duration: 133 } }
            width: 24
            height: width
            radius: (width / 2)
            anchors.verticalCenter: parent.verticalCenter

            color: control.checked ? Theme.colorPrimary : Theme.colorComponentBorder
        }
    }

    contentItem: Text {
        leftPadding: control.indicator.width + control.spacing
        verticalAlignment: Text.AlignVCenter

        text: control.text
        textFormat: Text.PlainText
        font: control.font

        color: control.checked ? Theme.colorText : Theme.colorSubText
        opacity: enabled ? 1.0 : 0.33
    }
}
