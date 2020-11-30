import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

RangeSlider {
    id: control
    implicitWidth: 200
    implicitHeight: Theme.componentHeight
    leftPadding: 0
    rightPadding: 0

    first.value: 0.25
    second.value: 0.75
    snapMode: RangeSlider.SnapAlways

    ////////

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight / 2) - (height / 2)
        width: control.availableWidth
        height: 4
        radius: 2
        color: Theme.colorForeground

        Rectangle {
            x: (control.first.visualPosition * parent.width)
            width: (control.second.visualPosition * parent.width) - x
            height: parent.height
            radius: 2
            color: Theme.colorPrimary
        }
    }

    ////////

    first.handle: Rectangle {
        x: Math.round(first.visualPosition * parent.width - width/2)
        y: 0
        width: 14
        height: 10

        color: first.pressed ? Theme.colorSecondary : Theme.colorPrimary
        border.color: first.pressed ? Theme.colorSecondary : Theme.colorPrimary

        Rectangle {
            width: 10
            height: 10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.bottom

            rotation: 45
            color: parent.color
            border.color: parent.border.color
        }
    }

    second.handle: Rectangle {
        x: Math.round(second.visualPosition * parent.width - width/2)
        y: 0
        width: 14
        height: 10

        color: second.pressed ? Theme.colorSecondary : Theme.colorPrimary
        border.color: second.pressed ? Theme.colorSecondary : Theme.colorPrimary

        Rectangle {
            width: 10
            height: 10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.bottom

            rotation: 45
            color: parent.color
            border.color: parent.border.color
        }
    }
}
