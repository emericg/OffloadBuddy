import QtQuick

import ThemeEngine

Rectangle {
    anchors.left: parent.left
    anchors.leftMargin: -Theme.componentMarginXL
    anchors.right: parent.right
    anchors.rightMargin: -Theme.componentMarginXL

    height: Theme.componentBorderWidth
    color: Theme.colorSeparator
    opacity: 0.5
}
