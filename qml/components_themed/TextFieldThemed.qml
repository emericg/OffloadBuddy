import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

TextField {
    id: textFieldThemed
    width: 128
    height: 40

    text: "textfield"
    color: Theme.colorText

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 40

        color: textFieldThemed.activeFocus ? Theme.colorComponentBackground : Theme.colorComponentBackground
        border.color: textFieldThemed.activeFocus ? Theme.colorPrimary : Theme.colorComponentBorder
        border.width: 2
    }
}
