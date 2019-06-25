import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2

import com.offloadbuddy.theme 1.0
import "UtilsString.js" as UtilsString
import "UtilsPath.js" as UtilsPath

Rectangle {
    id: itemMediaDirectory
    width: parent.width
    implicitWidth: 800
    height: 48
    radius: 8

    property var directory
    property bool directoryAvailable: directory.available
    property bool directorySpace: directory.spaceAvailable

    Component.onCompleted: updateInfos()
    onDirectoryAvailableChanged: updateInfos()
    onDirectorySpaceChanged: updateInfos()

    function updateInfos() {
        if (directory.available === false)
            itemMediaDirectory.color = Theme.colorSomethingsWrong
        else
            itemMediaDirectory.color = "transparent"

        deviceSpaceText.text = UtilsString.bytesToString_short(directory.spaceUsed) + " used / "
                                + UtilsString.bytesToString_short(directory.spaceAvailable) + " available / "
                                + UtilsString.bytesToString_short(directory.spaceTotal) + " total"
    }

    TextFieldThemed {
        id: textField_path
        width: 400
        height: 40
        text: directory.directoryPath
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 0

        FileDialog {
            id: fileDialogChange
            title: qsTr("Please choose a destination directory!")
            sidebarVisible: true
            selectExisting: true
            selectMultiple: false
            selectFolder: true

            onAccepted: {
                directory.directoryPath = UtilsPath.cleanUrl(fileDialogChange.fileUrl);
                settingsManager.directoryModified();
            }
        }

        ItemImageButton {
            id: button_refresh
            width: 32
            height: 32
            anchors.right: button_change.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            enabled: directory.available

            source: "qrc:/icons_material/baseline-refresh-24px.svg"
            onClicked: mediaLibrary.searchMediaDirectory(directory.directoryPath)
        }
        ButtonThemed {
            id: button_change
            width: 72
            height: 36
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter

            //imageSource: "qrc:/icons_material/outline-folder-24px.svg"
            text: qsTr("change")
            onClicked: {
                fileDialogChange.folder =  "file:///" + textField_path.text
                fileDialogChange.open()
            }
        }
    }

    ComboBoxThemed {
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
                settingsManager.directoryModified();
            } else {
                cbinit = true;
            }
        }
    }

    ProgressBarThemed {
        id: progressBar
        height: 8
        anchors.right: rectangleDelete.left
        anchors.rightMargin: 16
        anchors.left: comboBox_content.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 10
        value: directory.storageLevel
        visible: directory.available
    }
    Text {
        id: deviceSpaceText
        anchors.right: rectangleDelete.left
        anchors.rightMargin: 16
        anchors.left: comboBox_content.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -6

        text: UtilsString.bytesToString_short(directory.spaceUsed) + " used / " + UtilsString.bytesToString_short(directory.spaceAvailable) + " available / " + UtilsString.bytesToString_short(directory.spaceTotal) + " total"
        color: Theme.colorText
        visible: directory.available
    }
    Text {
        id: textError
        height: 20
        visible: !directory.available
        anchors.right: rectangleDelete.left
        anchors.rightMargin: 16
        anchors.left: comboBox_content.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter

        text: qsTr("Directory is not available right now :/")
        color: "white"
        font.bold: true
        font.pixelSize: 18
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    ItemImageButton {
        id: rectangleDelete
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        highlightColor: Theme.colorError
        source: "qrc:/icons_material/baseline-delete-24px.svg"
        onClicked: settingsManager.deleteDirectory(textField_path.text)
    }
}
