import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

ScrollBar {
    id: control
    height: parent.height
    anchors.right: parent.right

    //size: 0.3
    //position: 0.2
    //active: true
    orientation: Qt.Vertical
    policy: ScrollBar.AsNeeded

    opacity: 0
    Behavior on opacity { OpacityAnimator { duration: 333; } }

    ////////

    Timer {
        id: visibleTimer
        interval: 1000
        repeat: false
        onTriggered: opacity = 0
    }
    onPositionChanged: {
        control.opacity = 1
        visibleTimer.start()
    }/*
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onEntered: control.opacity = 1
        onExited: visibleTimer.start()
    }*/

    ////////

    contentItem: Rectangle {
        height: control.height
        implicitWidth: 6
        implicitHeight: 100

        radius: 0
        color: control.pressed ? Theme.colorPrimary : Theme.colorSecondary
    }

    background: Rectangle {
        height: control.height
        implicitWidth: 6
        implicitHeight: 100
        color: Theme.colorForeground
    }
}
