import QtQuick
import QtQuick.Controls

import ThemeEngine

Popup {
    id: actionMenu
    width: 200

    padding: 0
    margins: 0

    //parent: Overlay.overlay
    modal: true
    dim: false
    focus: isMobile
    locale: Qt.locale()
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 133; } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 133; } }

    property int layoutDirection: Qt.RightToLeft

    signal menuSelected(var index)

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

    background: Rectangle {
        color: Theme.colorBackground
        radius: Theme.componentRadius
        border.color: Theme.colorSeparator
        border.width: Theme.componentBorderWidth
    }

    ////////////////////////////////////////////////////////////////////////////

    Column {
        anchors.left: parent.left
        anchors.right: parent.right

        topPadding: 8
        bottomPadding: 8
        spacing: 0

        ////////

        ActionMenuItem {
            id: shotOffload

            index: 1
            text: qsTr("Offload")
            source: "qrc:/assets/icons_material/duotone-save_alt-24px.svg"
            onClicked: menuSelected(index)
        }
        ActionMenuItem {
            id: shotMove
            index: 2
            text: qsTr("Move")
            source: "qrc:/assets/icons_material/duotone-save_alt-24px.svg"
            onClicked: menuSelected(index)
        }
        ActionMenuItem {
            id: shotMerge
            index: 3
            text: qsTr("Merge chapters")
            source: "qrc:/assets/icons_material/baseline-merge_type-24px.svg"
            onClicked: menuSelected(index)
        }
        ActionMenuItem {
            id: shotEncode
            index: 4
            text: qsTr("Encode")
            source: "qrc:/assets/icons_material/baseline-memory-24px.svg"
            onClicked: menuSelected(index)
        }

        ////////

        ActionMenuSeparator { // telemetrySeparator
            visible: (telemetry.visible || telemetryGPMF.visible || telemetryGPS.visible)
        }

        ////////

        ActionMenuItem {
            id: telemetry
            index: 8
            text: qsTr("Extract telemetry")
            source: "qrc:/assets/icons_material/duotone-insert_chart-24px.svg"
            onClicked: menuSelected(index)
        }
        ActionMenuItem {
            id: telemetryGPMF
            index: 9
            text: qsTr("Extract telemetry")
            source: "qrc:/assets/icons_material/duotone-insert_chart-24px.svg"
            onClicked: menuSelected(index)
        }
        ActionMenuItem {
            id: telemetryGPS
            index: 10
            text: qsTr("Extract GPS trace")
            source: "qrc:/assets/icons_material/baseline-map-24px.svg"
            onClicked: menuSelected(index)
        }

        ////////

        ActionMenuSeparator { // openSeparator
            visible: (openFile.visible || openFolder.visible)
        }

        ////////

        ActionMenuItem {
            id: openFile
            index: 12
            text: qsTr("Open file")
            source: "qrc:/assets/icons_material/baseline-folder-24px.svg"
            onClicked: menuSelected(index)
        }
        ActionMenuItem {
            id: openFolder
            index: 13
            text: qsTr("Open folder")
            source: "qrc:/assets/icons_material/baseline-folder_open-24px.svg"
            onClicked: menuSelected(index)
        }

        ////////

        ActionMenuSeparator { // removeSeparator
            visible: removeSelected.visible
        }

        ////////

        ActionMenuItem {
            id: removeSelected
            index: 16
            text: qsTr("DELETE")
            source: "qrc:/assets/icons_material/baseline-delete-24px.svg"
            onClicked: menuSelected(index)
        }
    }
}
