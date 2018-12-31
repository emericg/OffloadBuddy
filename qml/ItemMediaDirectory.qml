import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.1

import com.offloadbuddy.style 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: itemMediaDirectory
    width: parent.width
    implicitWidth: 800
    height: 48
    radius: 8

    property var directory
    property bool directoryAvailable: directory.available
    property bool directorySpace: directory.spaceAvailable
    property var settingsMgr

    Component.onCompleted: updateInfos()
    onDirectoryAvailableChanged: updateInfos()
    onDirectorySpaceChanged: updateInfos()

    function updateInfos() {
        if (directory.available === false)
            itemMediaDirectory.color = ThemeEngine.colorSomethingsWrong
        else
            itemMediaDirectory.color = "transparent"

        deviceSpaceText.text = StringUtils.bytesToString_short(directory.spaceUsed) + " used / "
                                + StringUtils.bytesToString_short(directory.spaceAvailable) + " available / "
                                + StringUtils.bytesToString_short(directory.spaceTotal) + " total"
    }

    TextFieldThemed {
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
                directory.directoryPath = StringUtils.urlToPath(fileDialogChange.fileUrl.toString());
                settingsMgr.directoryModified();
            }
        }

        ButtonImage {
            id: button_refresh
            width: 36
            height: 36
            anchors.right: button_change.left
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            enabled: directory.available

            imageSource: "qrc:/icons_material/baseline-refresh-24px.svg"
            onClicked: {
                mediaLibrary.searchMediaDirectory(directory.directoryPath)
            }
        }
        ButtonImage {
            id: button_change
            width: 36
            height: 36
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter

            imageSource: "qrc:/icons_material/outline-folder-24px.svg"
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
                settingsMgr.directoryModified();
            } else {
                cbinit = true;
            }
        }
    }

    Text {
        id: deviceSpaceText
        anchors.right: rectangleDelete.left
        anchors.rightMargin: 16
        anchors.left: comboBox_content.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -8

        text: StringUtils.bytesToString_short(directory.spaceUsed) + " used / " + StringUtils.bytesToString_short(directory.spaceAvailable) + " available / " + StringUtils.bytesToString_short(directory.spaceTotal) + " total"
        color: ThemeEngine.colorText
        visible: directory.available
    }

    ProgressBarThemed {
        id: progressBar
        height: 8
        anchors.right: rectangleDelete.left
        anchors.rightMargin: 16
        anchors.left: comboBox_content.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 8
        value: directory.spaceUsedPercent
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

    Rectangle {
        id: rectangleDelete
        width: 40
        height: 40
        color: "#00000000"
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        Image {
            id: imageDelete
            width: 40
            height: 40
            fillMode: Image.PreserveAspectFit
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            source: "qrc:/icons/process_stop.svg"
            sourceSize.width: 40
            sourceSize.height: 40
        }

        MouseArea {
            id: mouseAreaDelete
            anchors.fill: parent
            onClicked: settingsMgr.deleteDirectory(textField_path.text)

            onPressed: {
                imageDelete.width = imageDelete.width - 4
                imageDelete.height = imageDelete.height - 4
            }
            onReleased: {
                imageDelete.width = imageDelete.width + 4
                imageDelete.height = imageDelete.height + 4
            }
        }
    }
}
