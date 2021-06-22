import QtQuick 2.12
import QtQuick.Controls 2.12

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

        ButtonWireframeImage {
            id: buttonMove
            anchors.verticalCenter: parent.verticalCenter

            visible: (appContent.state === "library")
            fullColor: true
            primaryColor: Theme.colorActionbarHighlight

            text: qsTr("Move")
            source: "qrc:/assets/icons_material/baseline-save_alt-24px.svg"
            onClicked: {
                if (appContent.state === "library") {
                    popupMove.shots = mediaLibrary.getSelectedShotsNames(mediaGrid.selectionList)
                    popupMove.openSelection()
                } else if (appContent.state === "device") {
                    //
                }
            }
        }

        ButtonWireframeImage {
            id: buttonOffload
            anchors.verticalCenter: parent.verticalCenter

            visible: (appContent.state === "device")
            fullColor: true
            primaryColor: Theme.colorActionbarHighlight

            text: qsTr("Offload")
            source: "qrc:/assets/icons_material/baseline-save_alt-24px.svg"
            onClicked: {
                if (appContent.state === "library") {
                    popupOffload.shots = mediaLibrary.getSelectedShotsNames(mediaGrid.selectionList)
                } else if (appContent.state === "device") {
                    popupOffload.shots = currentDevice.getSelectedShotsNames(mediaGrid.selectionList)
                }
                popupOffload.openSelection()
            }
        }

        ButtonWireframeImage {
            id: buttonMergeShots
            anchors.verticalCenter: parent.verticalCenter
            visible: (appContent.state !== "device" && mediaGrid.selectionCount >= 2 && mediaGrid.selectionCount <= 4)

            enabled: false
            fullColor: true
            primaryColor: Theme.colorActionbarHighlight

            text: qsTr("Merge shots together")
            source: "qrc:/assets/icons_material/baseline-merge_type-24px.svg"
            onClicked: {
                //
            }
        }

        ButtonWireframeImage {
            id: buttonTelemetry
            anchors.verticalCenter: parent.verticalCenter

            fullColor: true
            primaryColor: Theme.colorActionbarHighlight

            text: qsTr("Extract telemetry")
            source: "qrc:/assets/icons_material/baseline-insert_chart_outlined-24px.svg"
            onClicked: {
                if (appContent.state === "library") {
                    popupTelemetry.shots = mediaLibrary.getSelectedShotsNames(mediaGrid.selectionList)
                } else if (appContent.state === "device") {
                    popupTelemetry.shots = currentDevice.getSelectedShotsNames(mediaGrid.selectionList)
                }
                popupTelemetry.openSelection()
            }
        }

        ButtonWireframeImage {
            id: buttonDelete
            anchors.verticalCenter: parent.verticalCenter

            fullColor: true
            primaryColor: Theme.colorWarning

            text: qsTr("Delete")
            source: "qrc:/assets/icons_material/baseline-delete-24px.svg"
            onClicked: {
                if (appContent.state === "library") {
                    popupDelete.shots = mediaLibrary.getSelectedShotsNames(mediaGrid.selectionList)
                    popupDelete.files = mediaLibrary.getSelectedFilesPaths(mediaGrid.selectionList)
                } else if (appContent.state === "device") {
                    popupDelete.shots = currentDevice.getSelectedShotsNames(mediaGrid.selectionList)
                    popupDelete.files = currentDevice.getSelectedFilesPaths(mediaGrid.selectionList)
                }
                popupDelete.openSelection()
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
        font.pixelSize: 16
        font.bold: true
    }

    ItemImageButton {
        id: rectangleClear
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        source: "qrc:/assets/icons_material/baseline-backspace-24px.svg"
        iconColor: Theme.colorActionbarContent
        backgroundColor: Theme.colorActionbarHighlight
        onClicked: mediaGrid.exitSelectionMode()
    }
}
