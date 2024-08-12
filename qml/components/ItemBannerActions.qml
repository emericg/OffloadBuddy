import QtQuick
import QtQuick.Controls

import ThemeEngine
import "qrc:/utils/UtilsString.js" as UtilsString

Rectangle {
    id: bannerActions
    anchors.left: parent.left
    anchors.right: parent.right

    height: 0
    Behavior on height { NumberAnimation { duration: 133 } }

    clip: true
    visible: (height > 0)
    color: Theme.colorActionbar

    // prevent clicks below this area
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; }

    ////////////////

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.componentMargin
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.componentMargin

        ButtonFlat {
            id: buttonMoveOffload

            text: (appContent.state === "library") ? qsTr("Move") : qsTr("Offload")
            source: "qrc:/assets/icons/material-icons/duotone/save_alt.svg"
            color: Theme.colorActionbarHighlight
            colorText: Theme.colorText

            onClicked: {
                if (appContent.state === "library") {
                    // move
                    popupMove.shots_uuids = mediaLibrary.getSelectedShotsUuids(mediaGrid.selectionList)
                    popupMove.shots_names = mediaLibrary.getSelectedShotsNames(mediaGrid.selectionList)
                    popupMove.shots_files = mediaLibrary.getSelectedShotsFilepaths(mediaGrid.selectionList)
                    popupMove.openSelection(mediaLibrary)
                } else if (appContent.state === "device") {
                    // offload
                    popupOffload.shots_uuids = currentDevice.getSelectedShotsUuids(mediaGrid.selectionList)
                    popupOffload.shots_names = currentDevice.getSelectedShotsNames(mediaGrid.selectionList)
                    popupOffload.shots_files = currentDevice.getSelectedShotsFilepaths(mediaGrid.selectionList)
                    popupOffload.openSelection(currentDevice)
                }
            }
        }

        ButtonFlat {
            id: buttonMergeChapters

            visible: (appContent.state === "library")

            text: qsTr("Merge chapters")
            source: "qrc:/assets/icons/material-symbols/merge_type.svg"
            sourceRotation: 180
            color: Theme.colorActionbarHighlight
            colorText: Theme.colorText

            onClicked: {
                if (appContent.state === "library") {
                    popupMerge.shots_uuids = mediaLibrary.getSelectedShotsUuids(mediaGrid.selectionList)
                    popupMerge.shots_names = mediaLibrary.getSelectedShotsNames(mediaGrid.selectionList)
                    popupMerge.shots_files = mediaLibrary.getSelectedShotsFilepaths(mediaGrid.selectionList)
                    popupMerge.openSelection(mediaLibrary)
                } else if (appContent.state === "device") {
                    // no merge possible directly on a device
                }
            }
        }

        ButtonFlat {
            id: buttonMergeShots

            visible: (appContent.state !== "device" && mediaGrid.selectionCount >= 2 && mediaGrid.selectionCount <= 4)
            enabled: false

            text: qsTr("Merge shots")
            source: "qrc:/assets/icons/material-symbols/merge_type.svg"
            sourceRotation: 180
            color: Theme.colorActionbarHighlight
            colorText: Theme.colorText

            onClicked: {
                if (appContent.state === "library") {
                    // TODO
                } else if (appContent.state === "device") {
                    // no merge possible directly on a device
                }
            }
        }

        ButtonFlat {
            id: buttonEncode

            text: qsTr("Encoding")
            source: "qrc:/assets/icons/material-symbols/memory.svg"
            color: Theme.colorActionbarHighlight
            colorText: Theme.colorText

            onClicked: {
                if (appContent.state === "library") {
                    popupEncoding.shots_uuids = mediaLibrary.getSelectedShotsUuids(mediaGrid.selectionList)
                    popupEncoding.shots_names = mediaLibrary.getSelectedShotsNames(mediaGrid.selectionList)
                    popupEncoding.shots_files = mediaLibrary.getSelectedShotsFilepaths(mediaGrid.selectionList)
                    popupEncoding.updateEncodePanel()
                    popupEncoding.openSelection(mediaLibrary)
                } else if (appContent.state === "device") {
                    popupEncoding.shots_uuids = currentDevice.getSelectedShotsUuids(mediaGrid.selectionList)
                    popupEncoding.shots_names = currentDevice.getSelectedShotsNames(mediaGrid.selectionList)
                    popupEncoding.shots_files = currentDevice.getSelectedShotsFilepaths(mediaGrid.selectionList)
                    popupEncoding.updateEncodePanel()
                    popupEncoding.openSelection(currentDevice)
                }
            }
        }

        ButtonFlat {
            id: buttonTelemetry

            text: qsTr("Extract telemetry")
            source: "qrc:/assets/icons/material-icons/duotone/insert_chart.svg"
            color: Theme.colorActionbarHighlight
            colorText: Theme.colorText

            onClicked: {
                if (appContent.state === "library") {
                    popupTelemetry.shots_uuids = mediaLibrary.getSelectedShotsUuids(mediaGrid.selectionList)
                    popupTelemetry.shots_names = mediaLibrary.getSelectedShotsNames(mediaGrid.selectionList)
                    popupTelemetry.openSelection(mediaLibrary)
                } else if (appContent.state === "device") {
                    popupTelemetry.shots_uuids = currentDevice.getSelectedShotsUuids(mediaGrid.selectionList)
                    popupTelemetry.shots_names = currentDevice.getSelectedShotsNames(mediaGrid.selectionList)
                    popupTelemetry.openSelection(currentDevice)
                }
            }
        }

        ButtonFlat {
            id: buttonDelete

            text: qsTr("Delete")
            source: "qrc:/assets/icons/material-symbols/delete.svg"
            color: Theme.colorWarning

            onClicked: {
                if (appContent.state === "library") {
                    popupDelete.shots_uuids = mediaLibrary.getSelectedShotsUuids(mediaGrid.selectionList)
                    popupDelete.shots_names = mediaLibrary.getSelectedShotsNames(mediaGrid.selectionList)
                    popupDelete.shots_files = mediaLibrary.getSelectedShotsFilepaths(mediaGrid.selectionList)
                    popupDelete.openSelection(mediaLibrary)
                } else if (appContent.state === "device") {
                    popupDelete.shots_uuids = currentDevice.getSelectedShotsUuids(mediaGrid.selectionList)
                    popupDelete.shots_names = currentDevice.getSelectedShotsNames(mediaGrid.selectionList)
                    popupDelete.shots_files = currentDevice.getSelectedShotsFilepaths(mediaGrid.selectionList)
                    popupDelete.openSelection(currentDevice)
                }
            }
        }
    }

    ////////////////

    Text {
        id: elementCounter
        anchors.right: parent.right
        anchors.rightMargin: 56
        anchors.verticalCenter: parent.verticalCenter

        text: qsTr("%n element(s) selected", "", mediaGrid.selectionCount)
        textFormat: Text.PlainText
        color: Theme.colorActionbarContent
        font.pixelSize: Theme.fontSizeContent
        font.bold: true
    }

    RoundButtonSunken {
        id: rectangleClear
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        source: "qrc:/assets/icons/material-symbols/backspace-fill.svg"
        colorIcon: Theme.colorActionbarContent
        colorBackground: Theme.colorActionbar

        onClicked: mediaGrid.exitSelectionMode()
    }

    ////////////////
}
