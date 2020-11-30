import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12

import ThemeEngine 1.0

Rectangle {
    id: itemLilMenu
    implicitWidth: 256
    implicitHeight: 32

    color: Theme.colorComponent
    radius: Theme.componentRadius

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            x: itemLilMenu.x
            y: itemLilMenu.y
            width: itemLilMenu.width
            height: itemLilMenu.height
            radius: itemLilMenu.radius
        }
    }
/*
    // How to use this component:
    Row {
        id: rowLilMenuItems
        height: parent.height

        ItemLilMenuButton {
            id: lilmenu1
            text: "menu1"
            onClicked: lilmenu1.selected = true
        }
        ItemLilMenuButton {
            id: lilmenu2
            text: "menu2"
            onClicked: lilmenu2.selected = true
        }
        }
*/
}
