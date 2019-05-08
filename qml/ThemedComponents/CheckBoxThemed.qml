import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

CheckBox {
    id: control
    checked: false
/*
    indicator: Rectangle {
        implicitWidth: 26
        implicitHeight: 26
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        border.color: control.down ? Theme.colorApproved : Theme.colorButton

        Rectangle {
            width: 14
            height: 14
            x: 6
            y: 6
            color: Theme.colorApproved
            visible: control.checked
        }
    }
*/
    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: control.down ? Theme.colorTextDisabled : Theme.colorText
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + control.spacing
    }
}
