import QtQuick 2.10
import QtQuick.Controls 2.3

import com.offloadbuddy.style 1.0

TextField {
    id: control
    placeholderText: qsTr("Enter description")

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 40
        color: textField_path.activeFocus ? "white" : "white"
        border.color: textField_path.activeFocus ? ThemeEngine.colorApproved : ThemeEngine.colorButton
        border.width: textField_path.activeFocus ? 2 : 1
    }
}
