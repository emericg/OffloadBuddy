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

    function setMenuButtons(merge, encode, remove) {
        if (merge)
            offloadMerge.visible = true
        else
            offloadMerge.visible = false
        if (encode)
            offloadReencode.visible = true
        else
            offloadReencode.visible = false
        if (remove) {
            removeSeparator.visible = true
            removeSelected.visible = true
        } else {
            removeSeparator.visible = false
            removeSelected.visible = false
        }
    }

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
        Item {
            id: removeSeparator
            height: 2
            anchors.left: parent.left
            anchors.leftMargin:  10
            anchors.right: parent.right
            anchors.rightMargin: 20
            Rectangle {
                height: 2
                width: parent.width
                color: "#c3c3c3"
            }
        }
        ActionButton {
            id: removeSelected
            index: 4
            button_text: qsTr("DELETE")
            onButtonClicked: menuSelected(index)
        }
    }
}
