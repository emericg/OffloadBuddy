import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Rectangle {
    id: itemMediaDirectory
    width: parent.width
    implicitWidth: 800
    height: 48
    radius: Theme.componentRadius
    color: (directory.available) ? "transparent" : Theme.colorWarning

    property var directory: null
    property bool confirmation: false

    Connections {
        target: directory
        onAvailableChanged: updateInfos()
    }

    function updateInfos() {
        deviceSpaceText.text = UtilsString.bytesToString_short(directory.spaceUsed) + " used / " +
                               UtilsString.bytesToString_short(directory.spaceAvailable) + " available / " +
                               UtilsString.bytesToString_short(directory.spaceTotal) + " total"

        progressBar.value = directory.storageLevel
    }

    ////////////////////////////////////////////////////////////////////////////

    TextFieldThemed {
        id: textField_path
        width: 512
        height: 40
        anchors.left: parent.left
        anchors.leftMargin: 4 // directory.available ? 0 : 4
        anchors.verticalCenter: parent.verticalCenter

        readOnly: !directory.available
        text: directory.directoryPath

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
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter

            visible: directory.available
            enabled: directory.available
            source: "qrc:/icons_material/baseline-refresh-24px.svg"
            onClicked: mediaLibrary.searchMediaDirectory(directory.directoryPath)

            NumberAnimation on rotation {
                id: refreshAnimation
                duration: 2000
                from: 0
                to: 360
                loops: Animation.Infinite
                running: directory.scanning
                onStopped: refreshAnimationStop.start()
            }
            NumberAnimation on rotation {
                id: refreshAnimationStop
                duration: 1000
                to: 360
                easing.type: Easing.Linear
                running: false
            }
        }
        ButtonThemed {
            id: button_change
            width: 72
            height: 36
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter

            embedded: true
            text: qsTr("change")
            onClicked: {
                fileDialogChange.folder =  "file:///" + textField_path.text
                fileDialogChange.open()
            }
        }
    }

    ComboBoxThemed {
        id: comboBox_content
        width: 160
        height: 40
        anchors.left: textField_path.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter

        model: ListModel {
            id: cbItemsContent
            ListElement { text: qsTr("all media"); }
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

        visible: directory.available && !itemMediaDirectory.confirmation
        value: directory.storageLevel
    }
    Text {
        id: deviceSpaceText
        anchors.right: rectangleDelete.left
        anchors.rightMargin: 16
        anchors.left: comboBox_content.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -6

        visible: directory.available && !itemMediaDirectory.confirmation && deviceSpaceText.width > 400
        color: Theme.colorText
        text: UtilsString.bytesToString_short(directory.spaceUsed) + " used / " +
              UtilsString.bytesToString_short(directory.spaceAvailable) + " available / " +
              UtilsString.bytesToString_short(directory.spaceTotal) + " total"
    }
    Text {
        id: textError
        height: 20
        visible: !directory.available && !itemMediaDirectory.confirmation
        anchors.right: rectangleDelete.left
        anchors.rightMargin: 16
        anchors.left: comboBox_content.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter

        text: qsTr("Directory is not available right now :/")
        clip: true
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

        visible: !itemMediaDirectory.confirmation

        iconColor: directory.available ? Theme.colorIcon : "white"
        highlightMode: "color"
        highlightColor: Theme.colorError
        source: "qrc:/icons_material/baseline-delete-24px.svg"
        onClicked: itemMediaDirectory.confirmation = true
    }

    ////////

    Rectangle {
        anchors.fill: rowConfirmation
        visible: itemMediaDirectory.confirmation
        color: itemMediaDirectory.color
    }
    Row {
        id: rowConfirmation
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter

        spacing: 16
        visible: (itemMediaDirectory.confirmation)

        Text {
            id: textConfirmation
            height: 32
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Are you sure ?")
            font.bold: true
            font.pixelSize: 16
            color: directory.available ? Theme.colorText : "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        ButtonWireframe {
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Cancel")
            primaryColor: Theme.colorPrimary
            onClicked: itemMediaDirectory.confirmation = false
        }
        ButtonWireframe {
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Yes")
            fullColor: true
            primaryColor: Theme.colorPrimary
            onClicked: settingsManager.removeDirectory(textField_path.text)
        }
    }
}
