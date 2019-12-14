import QtQuick 2.9
import QtQuick.Controls 2.2

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Rectangle {
    id: itemBannerActions
    height: 56
    anchors.right: parent.right
    anchors.rightMargin: 0
    anchors.left: parent.left
    anchors.leftMargin: 0

    color: Theme.colorPrimary

    Row {
        spacing: 16
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.bottom: parent.bottom

        ButtonWireframeImage {
            id: buttonOffload
            anchors.verticalCenter: parent.verticalCenter

            fullColor: true
            text: (applicationContent.state === "device") ? qsTr("Offload") : qsTr("Move")
            source: "qrc:/icons_material/baseline-save_alt-24px.svg"
            onClicked: {
                if (applicationContent.state === "library") {
                    //
                } else if (applicationContent.state === "device") {
                    //
                }
            }
        }

        ButtonWireframeImage {
            id: buttonMergeShots
            anchors.verticalCenter: parent.verticalCenter

            visible: (applicationContent.state !== "device" && mediaGrid.selectionCount >= 2)

            fullColor: true
            text: qsTr("Merge shots together")
            source: "qrc:/icons_material/baseline-merge_type-24px.svg"
            onClicked: {
                //
            }
        }
        ButtonWireframeImage {
            id: buttonTelemetry
            anchors.verticalCenter: parent.verticalCenter

            fullColor: true
            text: qsTr("Extract telemetry")
            source: "qrc:/icons_material/baseline-insert_chart_outlined-24px.svg"
            onClicked: {
                if (applicationContent.state === "library") {
                    //
                } else if (applicationContent.state === "device") {
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
            source: "qrc:/icons_material/baseline-delete-24px.svg"
            onClicked: {
                if (applicationContent.state === "library") {
                    confirmDeleteMultipleFilesPopup.files = mediaLibrary.getSelectedPaths(mediaGrid.selectionList);
                    confirmDeleteMultipleFilesPopup.open();
                } else if (applicationContent.state === "device") {
                    confirmDeleteMultipleFilesPopup.files = currentDevice.getSelectedPaths(mediaGrid.selectionList);
                    confirmDeleteMultipleFilesPopup.open();
                }
            }
        }
    }

    ////////

    Text {
        id: elementCounter
        anchors.right: parent.right
        anchors.rightMargin: 56
        anchors.verticalCenter: parent.verticalCenter

        text: qsTr("%n element(s) selected", "", mediaGrid.selectionCount)
        color: "white"
        font.pixelSize: 16
    }
    ItemImageButton {
        id: rectangleClear
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        source: "qrc:/icons_material/baseline-close-24px.svg"
        iconColor: "white"
        backgroundColor: Theme.colorWarning
        onClicked: mediaGrid.exitSelectionMode()
    }
}
