import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

RangeSlider {
    id: control
    first.value: 0.25
    second.value: 0.75
    snapMode: RangeSlider.SnapAlways

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight / 2) - (height / 2)
        implicitWidth: 200
        implicitHeight: 4
        width: control.availableWidth
        height: implicitHeight
        radius: 2
        color: Theme.colorForeground

        Rectangle {
            x: (control.first.visualPosition * parent.width)
            width: (control.second.visualPosition * parent.width) - x
            height: parent.height
            color: Theme.colorPrimary
            radius: 2
        }
    }

    first.handle: Rectangle {
        x: control.leftPadding + first.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight / 2) - (height / 2)
        implicitWidth: 20
        implicitHeight: 20
        radius: 10
        color: first.pressed ? Theme.colorPrimary : Theme.colorPrimary
        border.color: Theme.colorPrimary
    }

    second.handle: Rectangle {
        x: control.leftPadding + second.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight / 2) - (height / 2)
        implicitWidth: 20
        implicitHeight: 20
        radius: 10
        color: second.pressed ? Theme.colorPrimary : Theme.colorPrimary
        border.color: Theme.colorPrimary
    }
}
