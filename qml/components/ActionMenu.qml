import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Rectangle {
    width: 220
    height: menuHolder.height
    visible: isOpen
    focus: isOpen && !isMobile

    color: Theme.colorBackground
    radius: 2 // Theme.componentRadius

    signal menuSelected(var index)
    property bool isOpen: false

    function open() { isOpen = true; }
    function close() { isOpen = false; }
    function openClose() { isOpen = !isOpen; }

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
        width: parent.width
        height: children.height * children.length

        topPadding: 4
        bottomPadding: 4
        spacing: 0

        ActionButton {
            id: openFolder
            index: 0
            button_text: qsTr("Open folder")
            button_source: "qrc:/assets/icons_material/outline-folder-24px.svg"
            onButtonClicked: menuSelected(index)
        }

        ActionButton {
            id: offloadCopy
            index: 1
            button_text: qsTr("Offload (copy)")
            button_source: "qrc:/assets/icons_material/baseline-save_alt-24px.svg"
            onButtonClicked: menuSelected(index)
        }
        ActionButton {
            id: offloadMerge
            index: 2
            button_text: qsTr("Offload (merge)")
            button_source: "qrc:/assets/icons_material/baseline-merge_type-24px.svg"
            onButtonClicked: menuSelected(index)
        }
        ActionButton {
            id: offloadReencode
            index: 3
            button_text: qsTr("Reencode")
            button_source: "qrc:/assets/icons_material/baseline-memory-24px.svg"
            onButtonClicked: menuSelected(index)
        }
        Rectangle {
            id: telemetrySeparator
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.colorSeparator
        }
        ActionButton {
            id: telemetryGPMF
            index: 8
            button_text: qsTr("Extract telemetry")
            button_source: "qrc:/assets/icons_material/baseline-insert_chart_outlined-24px.svg"
            onButtonClicked: menuSelected(index)
        }
        ActionButton {
            id: telemetryGPS
            index: 9
            button_text: qsTr("Extract GPX trace")
            button_source: "qrc:/assets/icons_material/baseline-map-24px.svg"
            onButtonClicked: menuSelected(index)
        }
        Rectangle {
            id: removeSeparator
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.colorSeparator
        }
        ActionButton {
            id: removeSelected
            index: 16
            button_text: qsTr("DELETE")
            button_source: "qrc:/assets/icons_material/baseline-delete-24px.svg"
            onButtonClicked: menuSelected(index)
        }
    }
}
