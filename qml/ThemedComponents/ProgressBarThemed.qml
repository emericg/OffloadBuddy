import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

ProgressBar {
    id: control
    implicitHeight: 8

    // theming
    background: Rectangle {
        implicitWidth: 200
        implicitHeight: control.height
        color: Theme.colorProgressBarBg
    }

    contentItem: Item {
        implicitWidth: 200
        implicitHeight: control.height

        Rectangle {
            width: control.visualPosition * parent.width
            height: control.height
            color: Theme.colorSecondary
        }
    }
}
