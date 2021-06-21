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
            id: buttonOffload
            anchors.verticalCenter: parent.verticalCenter

            fullColor: true
            primaryColor: Theme.colorActionbarHighlight

            text: (appContent.state === "device") ? qsTr("Offload") : qsTr("Move")
            source: "qrc:/assets/icons_material/baseline-save_alt-24px.svg"
            onClicked: {
                if (appContent.state === "library") {
                    //
                } else if (appContent.state === "device") {
                    //
                }
            }
        }

        ButtonWireframeImage {
            id: buttonMergeShots
            anchors.verticalCenter: parent.verticalCenter
            visible: (appContent.state !== "device" && mediaGrid.selectionCount >= 2)

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
                    //
                } else if (appContent.state === "device") {
                    //
                }
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
                    confirmDeleteMultipleFilesPopup.files = mediaLibrary.getSelectedPaths(mediaGrid.selectionList);
                    confirmDeleteMultipleFilesPopup.open();
                } else if (appContent.state === "device") {
                    confirmDeleteMultipleFilesPopup.files = currentDevice.getSelectedPaths(mediaGrid.selectionList);
                    confirmDeleteMultipleFilesPopup.open();
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
