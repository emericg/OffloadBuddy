import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

TextField {
    id: control
    placeholderText: "TextField"

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 40
        color: control.activeFocus ? "white" : "white"
        border.color: control.activeFocus ? Theme.colorSecondary : Theme.colorButton
        border.width: control.activeFocus ? 2 : 2
    }
}
