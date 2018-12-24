import QtQuick 2.12
import QtQuick.Controls 2.12

import com.offloadbuddy.style 1.0

ProgressBar {
    id: control
    anchors.verticalCenter: parent.verticalCenter
    implicitHeight: 8

    // theming
    background: Rectangle {
        implicitWidth: 200
        implicitHeight: control.height
        color: ThemeEngine.colorProgressBarBg
    }

    contentItem: Item {
        implicitWidth: 200
        implicitHeight: control.height

        Rectangle {
            width: control.visualPosition * parent.width
            height: control.height
            color: ThemeEngine.colorProgressBar
        }
    }
}
