import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

Switch {
    id: control

    indicator: Rectangle {
        x: control.leftPadding
        y: (parent.height / 2) - (height / 2)
        width: 40
        height: 16
        radius: 16

        color: control.checked ? Theme.colorSecondary : Theme.colorComponent
        //border.color: control.checked ? Theme.colorSecondary : Theme.colorComponent

        Rectangle {
            x: control.checked ? (parent.width - width) : 0
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: width
            radius: width/2

            color: control.checked ? Theme.colorPrimary : Theme.colorComponentBackground
            border.color: control.checked ? Theme.colorPrimary : Theme.colorComponentBackground
        }
    }

    contentItem: Text {
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing

        text: control.text
        font: control.font
        //font.pixelSize: 14
        //font.bold: true
        color: Theme.colorText
        opacity: enabled ? 1.0 : 0.3
    }
}