import QtQuick 2.15
import QtQuick.Controls.impl 2.15
import QtQuick.Templates 2.15 as T

import ThemeEngine 1.0

T.Slider {
    id: control
    implicitWidth: 200
    implicitHeight: 4
    padding: 0

    value: 0.5

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight / 2) - (height / 2)
        width: control.availableWidth
        height: 4
        radius: 0
        color: Theme.colorForeground
        opacity: 0.8

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            color: Theme.colorPrimary
            radius: 0
        }
    }

    handle: Rectangle {
        x: control.leftPadding + (control.visualPosition * (control.availableWidth - width))
        y: control.topPadding + (control.availableHeight / 2) - (height / 2)
        width: 8
        height: 4
        radius: 0
        color: "white"
    }
}
