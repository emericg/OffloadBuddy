import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

import ThemeEngine 1.0

Item {
    id: itemMenuButton
    implicitWidth: 64
    implicitHeight: 32

    width: 16 + contentText.width + sourceSize + 16

    signal clicked()
    property bool selected: false
    property bool highlighted: false

    property string colorBackground: Theme.colorComponent
    property string colorHighlight: Theme.colorHighContrast
    property string colorContent: Theme.colorComponentContent

    property string text: ""
    property url source: ""
    property int sourceSize: source.isEmpty() ? 0 : implicitHeight

    MouseArea {
        anchors.fill: parent
        onClicked: itemMenuButton.clicked()

        hoverEnabled: true
        onEntered: {
            bgFocus.opacity = 0.1
            itemMenuButton.highlighted = true
        }
        onExited: {
            bgFocus.opacity = 0
            itemMenuButton.highlighted = false
        }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        color: itemMenuButton.colorBackground
    }
    Rectangle {
        id: bgHightlight
        anchors.fill: parent

        visible: parent.selected
        opacity: 0.1
        color: itemMenuButton.colorContent
    }
    Rectangle {
        id: bgFocus
        anchors.fill: parent

        opacity: 0
        color: itemMenuButton.colorHighlight
        Behavior on opacity { OpacityAnimator { duration: 233 } }
    }

    ImageSvg {
        id: contentImage
        width: parent.sourceSize
        height: parent.sourceSize
        anchors.verticalCenter: itemMenuButton.verticalCenter
        anchors.horizontalCenter: itemMenuButton.horizontalCenter

        source: itemMenuButton.source
        color: itemMenuButton.colorContent
        opacity: (itemMenuButton.selected) ? 1 : 0.66
    }
    Text {
        id: contentText
        height: parent.height
        anchors.verticalCenter: itemMenuButton.verticalCenter
        anchors.horizontalCenter: itemMenuButton.horizontalCenter

        text: parent.text
        font.pixelSize: 16
        color: itemMenuButton.colorContent
        opacity: (itemMenuButton.selected) ? 1 : 0.66
        verticalAlignment: Text.AlignVCenter
    }
}
