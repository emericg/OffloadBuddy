import QtQuick
import QtQuick.Effects
import QtQuick.Controls.impl
import QtQuick.Templates as T
import Qt.labs.qmlmodels

import ThemeEngine

T.Popup {
    id: actionMenu

    width: 240
    height: contentColumn.height

    padding: 0
    margins: 0

    modal: true
    dim: false
    focus: isMobile
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside
    //parent: Overlay.overlay

    property string titleTxt
    property string titleSrc

    property int layoutDirection: Qt.RightToLeft

    signal menuSelected(var index)

    ////////////////

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

    ////////////////

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.33; to: 1.0; duration: 133; } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1.0; to: 0.33; duration: 133; } }

    background: Rectangle {
        color: Theme.colorComponentBackground
        radius: Theme.componentRadius
        border.color: Theme.colorSeparator
        border.width: Theme.componentBorderWidth

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowColor: "#44000000"
        }
    }

    ////////////////

    contentItem: Item {
        Column {
            id: contentColumn
            width: parent.width

            topPadding: 12
            bottomPadding: 12
            spacing: 2

            ////////

            ActionMenuItem {
                width: actionMenu.width
                visible: actionMenu.titleTxt
                text: actionMenu.titleTxt
                source: actionMenu.titleSrc
                opacity: 0.8
                layoutDirection: actionMenu.layoutDirection
                onClicked: actionMenu.close()
            }
            ActionMenuSeparator {
                width: actionMenu.width
                visible: actionMenu.titleTxt
                opacity: 0.8
            }

            ////////

            ActionMenuItem {
                id: shotOffload

                index: 1
                text: qsTr("Offload")
                source: "qrc:/assets/icons/material-icons/duotone/save_alt.svg"
                onClicked: menuSelected(index)
            }
            ActionMenuItem {
                id: shotMove
                index: 2
                text: qsTr("Move")
                source: "qrc:/assets/icons/material-icons/duotone/save_alt.svg"
                onClicked: menuSelected(index)
            }
            ActionMenuItem {
                id: shotMerge
                index: 3
                text: qsTr("Merge chapters")
                source: "qrc:/assets/icons/material-symbols/merge_type.svg"
                onClicked: menuSelected(index)
            }
            ActionMenuItem {
                id: shotEncode
                index: 4
                text: qsTr("Encode")
                source: "qrc:/assets/icons/material-symbols/memory.svg"
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
                source: "qrc:/assets/icons/material-icons/duotone/insert_chart.svg"
                onClicked: menuSelected(index)
            }
            ActionMenuItem {
                id: telemetryGPMF
                index: 9
                text: qsTr("Extract telemetry")
                source: "qrc:/assets/icons/material-icons/duotone/insert_chart.svg"
                onClicked: menuSelected(index)
            }
            ActionMenuItem {
                id: telemetryGPS
                index: 10
                text: qsTr("Extract GPS trace")
                source: "qrc:/assets/icons/material-symbols/location/map-fill.svg"
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
                source: "qrc:/assets/icons/material-symbols/folder.svg"
                onClicked: menuSelected(index)
            }
            ActionMenuItem {
                id: openFolder
                index: 13
                text: qsTr("Open folder")
                source: "qrc:/assets/icons/material-symbols/folder_open.svg"
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
                source: "qrc:/assets/icons/material-symbols/delete.svg"
                onClicked: menuSelected(index)
            }

            ////////
        }
    }

    ////////////////
}
