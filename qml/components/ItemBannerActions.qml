import QtQuick 2.15
import QtQuick.Controls 2.15

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString

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

    ////////////////////////////////////////////////////////////////////////////

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        ButtonSolid {
            id: buttonMoveOffload
            anchors.verticalCenter: parent.verticalCenter

            color: Theme.colorActionbarHighlight

            text: (appContent.state === "library") ? qsTr("Move") : qsTr("Offload")
            source: "qrc:/assets/icons/material-icons/duotone/save_alt.svg"
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

        ButtonSolid {
            id: buttonMergeChapters
            anchors.verticalCenter: parent.verticalCenter
            visible: (appContent.state === "library")

            color: Theme.colorActionbarHighlight

            text: qsTr("Merge chapters")
            source: "qrc:/assets/icons/material-symbols/merge_type.svg"
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

        ButtonSolid {
            id: buttonMergeShots
            anchors.verticalCenter: parent.verticalCenter
            visible: (appContent.state !== "device" && mediaGrid.selectionCount >= 2 && mediaGrid.selectionCount <= 4)

            enabled: false
            color: Theme.colorActionbarHighlight

            text: qsTr("Merge shots")
            source: "qrc:/assets/icons/material-symbols/merge_type.svg"
            onClicked: {
                if (appContent.state === "library") {
                    // TODO
                } else if (appContent.state === "device") {
                    // no merge possible directly on a device
                }
            }
        }

        ButtonSolid {
            id: buttonEncode
            anchors.verticalCenter: parent.verticalCenter

            color: Theme.colorActionbarHighlight

            text: qsTr("Encoding")
            source: "qrc:/assets/icons/material-symbols/memory.svg"
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

        ButtonSolid {
            id: buttonTelemetry
            anchors.verticalCenter: parent.verticalCenter

            color: Theme.colorActionbarHighlight

            text: qsTr("Extract telemetry")
            source: "qrc:/assets/icons/material-icons/duotone/insert_chart.svg"
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

        ButtonSolid {
            id: buttonDelete
            anchors.verticalCenter: parent.verticalCenter

            color: Theme.colorWarning

            text: qsTr("Delete")
            source: "qrc:/assets/icons/material-symbols/delete.svg"
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
        color: Theme.colorActionbarContent
        font.pixelSize: Theme.fontSizeContent
        font.bold: true
    }

    RoundButtonIcon {
        id: rectangleClear
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        source: "qrc:/assets/icons/material-symbols/backspace-fill.svg"
        iconColor: Theme.colorActionbarContent
        backgroundColor: Theme.colorActionbarHighlight
        onClicked: mediaGrid.exitSelectionMode()
    }
}
