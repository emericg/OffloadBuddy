import QtQuick 2.10
import QtQuick.Controls 2.3

import com.offloadbuddy.style 1.0

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
        border.color: control.down ? ThemeEngine.colorApproved : ThemeEngine.colorButton

        Rectangle {
            width: 14
            height: 14
            x: 6
            y: 6
            radius: 8
            color: control.down ? ThemeEngine.colorApproved : ThemeEngine.colorApproved
            visible: control.checked
        }
    }

    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: control.down ? ThemeEngine.colorText : ThemeEngine.colorText
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing
    }
}
