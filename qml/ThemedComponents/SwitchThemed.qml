import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

Switch {
    id: control

    indicator: Rectangle {
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        implicitWidth: 48
        implicitHeight: 26
        radius: 13

        color: control.checked ? Theme.colorSecondary : "#ffffff"
        border.color: control.checked ? Theme.colorSecondary : "#cccccc"

        Rectangle {
            x: control.checked ? parent.width - width : 0
            anchors.verticalCenter: parent.verticalCenter

            width: 24
            height: width
            radius: width/2

            color: control.down ? "#cccccc" : "#ffffff"
            border.color: control.checked ? Theme.colorSecondary : "#999999"
        }
    }

    contentItem: Text {
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing

        text: control.text
        font: control.font
        color: Theme.colorText
        opacity: enabled ? 1.0 : 0.3
    }
}
