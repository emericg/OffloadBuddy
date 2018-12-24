import QtQuick 2.12
import QtQuick.Controls 2.12

import com.offloadbuddy.style 1.0

ProgressBar {
    id: control
    height: 6

    // theming
    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 6
        color: ThemeEngine.colorButtonDown
        radius: 2
    }

    contentItem: Item {
        implicitWidth: 200
        implicitHeight: 6

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: 2
            color: ThemeEngine.colorProgressBar
        }
    }
}
