import QtQuick 2.8
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.1

import com.offloadbuddy.style 1.0
import "SpaceUtils.js" as SpaceUtils

Rectangle {
    id: itemMediaDirectory
    height: 48
    width: parent.width

    property var directory
    property bool directoryAvailable: directory.available
    property var settingsMgr

    signal chooseClicked()
    signal scanClicked()
    signal deleteClicked()

    Component.onCompleted: {
        if (directory.available === false)
            itemMediaDirectory.color = ThemeEngine.colorWarning
        else
            itemMediaDirectory.color = "white"
    }
    onDirectoryAvailableChanged: {
        if (directory.available === false)
            itemMediaDirectory.color = ThemeEngine.colorWarning
        else
            itemMediaDirectory.color = "white"
    }

    Rectangle {
        id: rectangleDelete
        width: 40
        height: 40
        color: ThemeEngine.colorDangerZone
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            id: mouseAreaDelete
            anchors.fill: parent
            onClicked: settingsMgr.deleteDirectory(textField_path.text)

            onPressed: {
                rectangleDelete.anchors.bottomMargin = rectangleDelete.anchors.bottomMargin + 2
                rectangleDelete.anchors.leftMargin = rectangleDelete.anchors.leftMargin + 2
                rectangleDelete.anchors.rightMargin = rectangleDelete.anchors.rightMargin + 2
                rectangleDelete.width = rectangleDelete.width - 4
                rectangleDelete.height = rectangleDelete.height - 4
            }
            onReleased: {
                rectangleDelete.anchors.bottomMargin = rectangleDelete.anchors.bottomMargin - 2
                rectangleDelete.anchors.leftMargin = rectangleDelete.anchors.leftMargin - 2
                rectangleDelete.anchors.rightMargin = rectangleDelete.anchors.rightMargin - 2
                rectangleDelete.width = rectangleDelete.width + 4
                rectangleDelete.height = rectangleDelete.height + 4
            }
        }

        Text {
            id: textDelete
            color: ThemeEngine.colorButtonText
            text: qsTr("X")
            anchors.fill: parent
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 24
        }
    }

    ProgressBar {
        id: progressBar
        y: 20
        height: 20
        anchors.right: rectangleDelete.left
        anchors.rightMargin: 16
        anchors.left: button_scan.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        value: directory.spaceUsedPercent
    }

    ComboBox {
        id: comboBox_content
        width: 140
        height: 40
        anchors.left: textField_path.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter

        model: ListModel {
            id: cbItemsContent
            ListElement { text: qsTr("all medias"); }
            ListElement { text: qsTr("videos"); }
            ListElement { text: qsTr("pictures"); }
        }
        Component.onCompleted: {
            currentIndex = directory.directoryContent;
            if (currentIndex === -1) { currentIndex = 0 }
        }
        property bool cbinit: false
        onCurrentIndexChanged: {
            if (cbinit) {
                directory.directoryContent = currentIndex;
                settingsMgr.directoryModified();
            } else
                cbinit = true;
        }
    }

    Button {
        id: button_scan
        text: qsTr("SCAN")
        enabled: false
        anchors.left: comboBox_content.right
        anchors.leftMargin: 16
        anchors.verticalCenterOffset: 0
        anchors.verticalCenter: parent.verticalCenter
    }

    TextField {
        id: textField_path
        width: 400
        height: 40
        text: directory.directoryPath
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 4

        FileDialog {
            id: fileDialogChange
            title: qsTr("Please choose a destination directory!")
            sidebarVisible: true
            selectExisting: true
            selectMultiple: false
            selectFolder: true

            onAccepted: {
                directory.directoryPath = SpaceUtils.urlToPath(fileDialogChange.fileUrl.toString());
                settingsMgr.directoryModified();
            }
        }

        Button {
            id: button_change
            x: 328
            y: 8
            width: 80
            height: 24
            text: qsTr("change")
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.log("fileDialog.folder: " + fileDialogChange.folder)
                    console.log("textField_path.text: " + textField_path.text)

                    fileDialogChange.folder =  "file:///" + textField_path.text
                    fileDialogChange.open()
                }
            }
        }
    }
}
