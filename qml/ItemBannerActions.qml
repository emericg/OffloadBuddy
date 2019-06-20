import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0
import "UtilsString.js" as UtilsString

Rectangle {
    id: menuSelection
    height: 56
    anchors.right: parent.right
    anchors.rightMargin: 0
    anchors.left: parent.left
    anchors.leftMargin: 0

    color: Theme.colorPrimary

    Row {
        id: row1
        spacing: 16
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 16

        ButtonImageWireframe {
            id: buttonOffload
            anchors.verticalCenter: parent.verticalCenter

            visible: applicationContent.state === "device"

            fullColor: true
            text: qsTr("Offload")
            source: "qrc:/icons_material/baseline-save_alt-24px.svg"
            onClicked: currentDevice.offloadCopySelection(mediaGrid.selectionList);
        }
        ButtonImageWireframe {
            id: buttonMerge
            anchors.verticalCenter: parent.verticalCenter

            visible: applicationContent.state === "device"

            fullColor: true
            text: qsTr("Merge")
            source: "qrc:/icons_material/baseline-save_alt-24px.svg"
            onClicked: currentDevice.offloadMergeSelection(mediaGrid.selectionList);
        }
        ButtonImageWireframe {
            id: buttonTelemetry
            anchors.verticalCenter: parent.verticalCenter

            fullColor: true
            text: qsTr("Extract metadatas")
            source: "qrc:/icons_material/baseline-insert_chart_outlined-24px.svg"
            onClicked: {
                if (applicationContent.state === "library") {
                    //mediaLibrary.extractTelemetrySelection(mediaGrid.selectionList);
                }
                else if (applicationContent.state === "device") {
                    //currentDevice.extractTelemetrySelection(mediaGrid.selectionList);
                }
            }
        }
        ButtonImageWireframe {
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
                }
                else if (applicationContent.state === "device") {
                    confirmDeleteMultipleFilesPopup.files = currentDevice.getSelectedPaths(mediaGrid.selectionList);
                    confirmDeleteMultipleFilesPopup.open();
                }
            }
        }
    }

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
        onClicked: mediaGrid.exitSelectionMode()
    }
}
