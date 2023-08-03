import QtQuick 2.15

import ThemeEngine 1.0

Item { // action menu separator
    anchors.left: parent.left
    anchors.leftMargin: Theme.componentMargin
    anchors.right: parent.right
    anchors.rightMargin: Theme.componentMargin
    height: Theme.componentMargin + 1

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 1
        color: Theme.colorSeparator
    }
}
