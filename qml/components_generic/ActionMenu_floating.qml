import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt.labs.qmlmodels 1.0

import ThemeEngine 1.0

Popup {
    id: actionMenu

    width: 200
    padding: 0
    margins: 0

    modal: true
    dim: false
    focus: isMobile
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    //parent: Overlay.overlay

    property var model: null

    property int layoutDirection: Qt.LeftToRight

    signal menuSelected(var index)

    ////////////////////////////////////////////////////////////////////////////

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 133; } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 133; } }

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: Theme.colorBackground
        radius: Theme.componentRadius
        border.color: Theme.colorSeparator
        border.width: Theme.componentBorderWidth
    }

    ////////////////////////////////////////////////////////////////////////////

    contentItem: Column {
        topPadding: 8
        bottomPadding: 8
        spacing: 4

        DelegateChooser {
            id: chooser
            role: "t"
            DelegateChoice {
                roleValue: "sep"
                ListSeparatorPadded {
                    anchors.leftMargin: Theme.componentMargin
                    anchors.rightMargin: Theme.componentMargin
                    height: 9
                }
            }
            DelegateChoice {
                roleValue: "itm"
                ActionMenuItem {
                    width: actionMenu.width
                    index: idx
                    text: txt
                    source: src
                    layoutDirection: actionMenu.layoutDirection
                    onClicked: {
                        actionMenu.menuSelected(idx)
                        actionMenu.close()
                    }
                }
            }
        }

        Repeater {
            model: actionMenu.model
            delegate: chooser
        }
    }

    ////////////////////////////////////////////////////////////////////////////
}
