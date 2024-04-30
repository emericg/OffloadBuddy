import QtQuick
import QtQuick.Effects

import ThemeEngine

Item {
    width: 256
    height: 256
    z: 4

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: (Theme.componentRadius > 6) ? Theme.componentRadius-2 : 4
        border.width: 4
        border.color: Theme.colorPrimary
        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: true
            blurEnabled: true
            blur: 1.0
        }
    }
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: (Theme.componentRadius > 6) ? Theme.componentRadius-2 : 4
        border.width: 4
        border.color: Theme.colorPrimary
    }
}
