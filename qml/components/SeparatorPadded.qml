import QtQuick

import ThemeEngine

Item { // padded separator
    anchors.left: parent.left
    anchors.right: parent.right
    height: Theme.componentMargin + Theme.componentBorderWidth

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: -Theme.componentMarginXL
        anchors.right: parent.right
        anchors.rightMargin: -Theme.componentMarginXL
        anchors.verticalCenter: parent.verticalCenter

        height: Theme.componentBorderWidth
        color: Theme.colorSeparator
        opacity: 0.5
    }
}
