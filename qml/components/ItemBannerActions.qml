import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Rectangle {
    id: bannerActions
    height: 56
    anchors.right: parent.right
    anchors.rightMargin: 0
    anchors.left: parent.left
    anchors.leftMargin: 0

    z: 1
    color: Theme.colorPrimary

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
            primaryColor: "#5483EF"

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
            primaryColor: "#5483EF"

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
            primaryColor: "#5483EF"

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
        color: "white"
        font.pixelSize: 16
        font.bold: true
    }

    ItemImageButton {
        id: rectangleClear
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        source: "qrc:/assets/icons_material/baseline-close-24px.svg"
        iconColor: "white"
        backgroundColor: Theme.colorWarning
        onClicked: mediaGrid.exitSelectionMode()
    }
}
