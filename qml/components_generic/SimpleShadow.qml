import QtQuick 2.12
import QtGraphicalEffects 1.12

import ThemeEngine 1.0

Item {
    property alias radius: rect.radius

    property string color: "#666"
    property bool filled: true

    z: -1

    Rectangle {
        id: rect
        anchors.fill: parent

        visible: false
        color: filled ? parent.color : "transparent"

        border.width: filled ? 0 : 1
        border.color: parent.color
    }
    DropShadow {
        anchors.fill: rect
        source: rect

        cached: true
        radius: 12.0
        samples: 25
        color: parent.color
        horizontalOffset: 0
        verticalOffset: 0
    }
}
