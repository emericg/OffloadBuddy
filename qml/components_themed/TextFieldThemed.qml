import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

TextField {
    id: control
    implicitWidth: 128
    implicitHeight: Theme.componentHeight

    property string colorText: Theme.colorComponentText
    property string colorPlaceholderText: Theme.colorSubText
    property string colorBorder: Theme.colorComponentBorder
    property string colorBackground: Theme.colorComponentBackground
    property string colorSelectedText: "white"
    property string colorSelection: Theme.colorPrimary

    placeholderText: ""
    placeholderTextColor: colorPlaceholderText

    text: ""
    color: colorText
    font.pixelSize: Theme.fontSizeComponent

    selectByMouse: false
    selectedTextColor: colorSelectedText
    selectionColor: colorSelection

    onEditingFinished: focus = false

    background: Rectangle {
        border.width: 2
        border.color: control.activeFocus ? Theme.colorPrimary : control.colorBorder
        radius: Theme.componentRadius
        color: control.colorBackground
    }
}
