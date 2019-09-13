import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

Button {
    id: control

    property bool embedded: false

    contentItem: Text {
        text: control.text
        font: control.font
        opacity: enabled ? 1.0 : 0.3
        color: control.down ? Theme.colorComponentContent : Theme.colorComponentContent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 128
        implicitHeight: 40

        radius: embedded ? 0 : Theme.radiusComponent
        opacity: enabled ? 1 : 0.3
        color: control.down ? Theme.colorComponentDown : Theme.colorComponent
    }
}
