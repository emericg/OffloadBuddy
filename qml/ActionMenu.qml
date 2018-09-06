import QtQuick 2.0
import QtQuick.Controls 1.1

Rectangle {
    id: actionMenuItem
    width: 165
    height: menuHolder.height + 12
    visible: isOpen
    focus: isOpen

    signal menuSelected(int index)
    property bool isOpen: false

    Column {
        id: menuHolder
        spacing: 1
        width: parent.width
        height: children.height * children.length
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 4 }

        ActionButton {
            id: offloadCopy
            index: 1
            button_text: qsTr("Offload (copy)")
            onButtonClicked: menuSelected(index)
        }
        ActionButton {
            id: offloadMerge
            index: 2
            button_text: qsTr("Offload (merge)")
            onButtonClicked: menuSelected(index)
        }
        ActionButton {
            id: offloadReencode
            index: 3
            button_text: qsTr("Reencode")
            onButtonClicked: menuSelected(index)
        }
        ActionButton {
            id: removeSelected
            index: 4
            button_text: qsTr("DELETE")
            onButtonClicked: menuSelected(index)
        }
    }
}
