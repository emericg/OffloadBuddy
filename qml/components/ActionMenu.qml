import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Rectangle {
    id: actionMenu
    width: 220
    height: menuHolder.height
    visible: false
    focus: visible && !isMobile

    color: "white" // Theme.colorComponent
    radius: 2 // Theme.componentRadius
    border.color: Theme.colorSeparator
    border.width: Theme.componentBorderWidth

    signal menuSelected(var index)
    property int menuWidth: 0

    function open() { visible = true; updateSize(); }
    function close() { visible = false; }
    function openClose() { visible = !visible; updateSize(); }

    function updateSize() {
        // TODO
    }

    ////////////////////////////////////////////////////////////////////////////

    function setMenuButtons(offload, move, merge, encode, gpmf, gps, file, folder, remove) {
        shotOffload.visible = offload
        shotMove.visible = move
        shotMerge.visible = merge
        shotEncode.visible = encode
        telemetry.visible = (gpmf || gps)
        telemetryGPMF.visible = false
        telemetryGPS.visible = false
        openFile.visible = file
        openFolder.visible = folder
        removeSelected.visible = remove
    }

    ////////////////////////////////////////////////////////////////////////////

    Column {
        id: menuHolder
        width: parent.width
        height: children.height * children.length

        topPadding: 0
        bottomPadding: 0
        spacing: 0

        ////////

        ActionButton {
            id: shotOffload
            index: 1
            button_text: qsTr("Offload")
            button_source: "qrc:/assets/icons_material/baseline-save_alt-24px.svg"
            onButtonClicked: menuSelected(index)
        }
        ActionButton {
            id: shotMove
            index: 2
            button_text: qsTr("Move")
            button_source: "qrc:/assets/icons_material/baseline-save_alt-24px.svg"
            onButtonClicked: menuSelected(index)
        }
        ActionButton {
            id: shotMerge
            index: 3
            button_text: qsTr("Merge files")
            button_source: "qrc:/assets/icons_material/baseline-merge_type-24px.svg"
            onButtonClicked: menuSelected(index)
        }
        ActionButton {
            id: shotEncode
            index: 4
            button_text: qsTr("Encode")
            button_source: "qrc:/assets/icons_material/baseline-memory-24px.svg"
            onButtonClicked: menuSelected(index)
        }

        ////////

        Rectangle {
            id: telemetrySeparator
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            visible: telemetryGPMF.visible || telemetryGPS.visible
            color: Theme.colorSeparator
        }
        ActionButton {
            id: telemetry
            index: 8
            button_text: qsTr("Extract telemetry")
            button_source: "qrc:/assets/icons_material/baseline-insert_chart_outlined-24px.svg"
            onButtonClicked: menuSelected(index)
        }
        ActionButton {
            id: telemetryGPMF
            index: 9
            button_text: qsTr("Extract telemetry")
            button_source: "qrc:/assets/icons_material/baseline-insert_chart_outlined-24px.svg"
            onButtonClicked: menuSelected(index)
        }
        ActionButton {
            id: telemetryGPS
            index: 10
            button_text: qsTr("Extract GPS trace")
            button_source: "qrc:/assets/icons_material/baseline-map-24px.svg"
            onButtonClicked: menuSelected(index)
        }

        ////////

        Rectangle {
            id: openSeparator
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            visible: openFile.visible || openFolder.visible
            color: Theme.colorSeparator
        }
        ActionButton {
            id: openFile
            index: 12
            button_text: qsTr("Open file")
            button_source: "qrc:/assets/icons_material/baseline-folder-24px.svg"
            onButtonClicked: menuSelected(index)
        }
        ActionButton {
            id: openFolder
            index: 13
            button_text: qsTr("Open folder")
            button_source: "qrc:/assets/icons_material/baseline-folder_open-24px.svg"
            onButtonClicked: menuSelected(index)
        }

        ////////

        Rectangle {
            id: removeSeparator
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            visible: removeSelected.visible
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
