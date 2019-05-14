import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

TextField {
    id: control
    placeholderText: qsTr("Enter description")

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 40
        color: textField_path.activeFocus ? "white" : "white"
        border.color: textField_path.activeFocus ? Theme.colorSecondary : Theme.colorButton
        border.width: textField_path.activeFocus ? 2 : 1
    }
}
