import QtQuick 2.9
import QtQuick.Controls 2.2

Rectangle {
    id: actionMenuItem
    width: 180
    height: menuHolder.height + 12
    visible: isOpen
    focus: isOpen
    radius: 2

    signal menuSelected(int index)
    property bool isOpen: false

    function setMenuButtons(folder, copy, merge, encode, gpmf, gps, remove) {
        if (folder)
            openFolder.visible = true
        else
            openFolder.visible = false
        if (copy)
            offloadCopy.visible = true
        else
            offloadCopy.visible = false
        if (merge)
            offloadMerge.visible = true
        else
            offloadMerge.visible = false
        if (encode)
            offloadReencode.visible = true
        else
            offloadReencode.visible = false
        if (gpmf) {
            telemetrySeparator.visible = true
            telemetryGPMF.visible = true
        } else {
            telemetrySeparator.visible = false
            telemetryGPMF.visible = false
        }
        if (gps) {
            telemetrySeparator.visible = true
            telemetryGPS.visible = true
        } else {
            telemetrySeparator.visible = false
            telemetryGPS.visible = false
        }
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
        spacing: 4
        width: parent.width
        height: children.height * children.length
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 4 }

        ActionButton {
            id: openFolder
            index: 0
            button_text: qsTr("Open folder")
            onButtonClicked: menuSelected(index)
        }

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

        Rectangle {
            id: telemetrySeparator
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 20

            height: 1
            color: "#c3c3c3"
        }
        ActionButton {
            id: telemetryGPMF
            index: 8
            button_text: qsTr("Extract telemetry")
            onButtonClicked: menuSelected(index)
        }
        ActionButton {
            id: telemetryGPS
            index: 9
            button_text: qsTr("Extract GPX trace")
            onButtonClicked: menuSelected(index)
        }

        Rectangle {
            id: removeSeparator
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 20

            height: 1
            color: "#c3c3c3"
        }
        ActionButton {
            id: removeSelected
            index: 16
            button_text: qsTr("DELETE")
            onButtonClicked: menuSelected(index)
        }
    }
}
