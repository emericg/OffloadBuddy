import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

RadioButton {
    id: control
    text: qsTr("RadioButton")
    checked: false

    indicator: Rectangle {
        implicitWidth: 26
        implicitHeight: 26
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: 13
        border.color: control.down ? Theme.colorSecondary : Theme.colorButton

        Rectangle {
            width: 14
            height: 14
            x: 6
            y: 6
            radius: 8
            color: control.down ? Theme.colorButton : Theme.colorSecondary
            visible: control.checked
        }
    }

    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: control.down ? Theme.colorText : Theme.colorText
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing
    }
}
