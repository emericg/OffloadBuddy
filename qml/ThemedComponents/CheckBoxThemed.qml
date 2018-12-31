import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.style 1.0

CheckBox {
    id: control
    checked: false
/*
    indicator: Rectangle {
        implicitWidth: 26
        implicitHeight: 26
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        border.color: control.down ? ThemeEngine.colorApproved : ThemeEngine.colorButton

        Rectangle {
            width: 14
            height: 14
            x: 6
            y: 6
            color: ThemeEngine.colorApproved
            visible: control.checked
        }
    }
*/
    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: control.down ? ThemeEngine.colorTextDisabled : ThemeEngine.colorText
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing
    }
}
