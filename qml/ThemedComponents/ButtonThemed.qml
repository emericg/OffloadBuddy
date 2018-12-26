import QtQuick 2.10
import QtQuick.Controls 2.3

import com.offloadbuddy.style 1.0

Button {
    id: control

    // theming
    background: Rectangle {
        implicitWidth: 100
        implicitHeight: 40
        opacity: enabled ? 1 : 0.3
        color: control.down ? ThemeEngine.colorButtonDown : ThemeEngine.colorButton
    }

    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: control.down ? ThemeEngine.colorButtonText : ThemeEngine.colorButtonText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
