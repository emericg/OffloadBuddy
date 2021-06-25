import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Button {
    id: control
    implicitWidth: contentText.contentWidth + (contentText.contentWidth / 2)
    implicitHeight: Theme.componentHeight

    font.pixelSize: Theme.fontSizeComponent

    focusPolicy: Qt.NoFocus

    property bool embedded: false

    background: Rectangle {
        radius: embedded ? 0 : Theme.componentRadius
        opacity: enabled ? 1 : 0.33
        color: control.down ? Theme.colorComponentDown : Theme.colorComponent
    }

    contentItem: Text {
        id: contentText
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        text: control.text
        textFormat: Text.PlainText
        font: control.font
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        opacity: enabled ? 1.0 : 0.33
        color: control.down ? Theme.colorComponentContent : Theme.colorComponentContent
    }
}
