import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Item {
    id: itemMediaDirectory
    implicitWidth: 800
    implicitHeight: 48
    width: parent.width
    height: 48

    property var directory: null
    property bool confirmation: false

    Connections {
        target: directory
        onAvailableChanged: {
            deviceSpaceText.text = UtilsString.bytesToString_short(directory.spaceUsed) + " " + qsTr("used") + " / " +
                                   UtilsString.bytesToString_short(directory.spaceAvailable) + " " + qsTr("available") + " / " +
                                   UtilsString.bytesToString_short(directory.spaceTotal) + " " + qsTr("total")

            progressBar.value = directory.storageLevel
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    TextFieldThemed {
        id: textField_path
        width: (itemMediaDirectory.width < 720) ? 512 : 640
        height: 40
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter

        //readOnly: !directory.available
        colorBorder: directory.available ? Theme.colorComponentBorder : Theme.colorWarning
        text: directory.directoryPath

        onEditingFinished: {
            directory.directoryPath = textField_path.text
            settingsManager.directoryModified()
            focus = false
        }

        ImageSvg {
            width: 24
            height: 24
            anchors.right: button_change.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            visible: !directory.available
            source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
            color: Theme.colorWarning
        }

        ItemImageButton {
            id: button_refresh
            width: 32
            height: 32
            anchors.right: button_change.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter

            highlightMode: "color"
            visible: directory.available
            enabled: directory.available
            source: "qrc:/assets/icons_material/baseline-refresh-24px.svg"
            onClicked: {
                mediaLibrary.searchMediaDirectory(directory.directoryPath)
                refreshAnimation.start()
            }

            NumberAnimation on rotation {
                id: refreshAnimation
                duration: 1000
                from: 0
                to: 360
                //running: directory.scanning
                //loops: Animation.Infinite
                alwaysRunToEnd: true
                easing.type: Easing.Linear
            }
        }

        FileDialog {
            id: fileDialogChange
            title: qsTr("Please choose a destination directory!")
            sidebarVisible: true
            selectExisting: true
            selectMultiple: false
            selectFolder: true

            onAccepted: {
                directory.directoryPath = UtilsPath.cleanUrl(fileDialogChange.fileUrl)
                settingsManager.directoryModified()
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
                fileDialogChange.folder = UtilsPath.makeUrl(textField_path.text)
                fileDialogChange.open()
            }
        }
    }

    ComboBoxThemed {
        id: comboBox_content
        width: 180
        height: 40
        anchors.left: textField_path.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter

        font.pixelSize: 14

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

    Item {
        height: parent.height
        anchors.left: comboBox_content.right
        anchors.leftMargin: 16
        anchors.right: rectangleDelete.left
        anchors.rightMargin: 12
        clip: true

        // this
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 8
            visible: directory.available && !itemMediaDirectory.confirmation

            Text {
                id: deviceSpaceText
                width: parent.width

                visible: (deviceSpaceText.width > 400)
                color: Theme.colorText
                text: UtilsString.bytesToString_short(directory.spaceUsed) + qsTr(" used / ") +
                      UtilsString.bytesToString_short(directory.spaceAvailable) + qsTr(" available / ") +
                      UtilsString.bytesToString_short(directory.spaceTotal) + qsTr(" total")
            }
            ProgressBarThemed {
                id: progressBar
                height: 8
                width: parent.width

                value: directory.storageLevel
            }
        }

        // or that
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: !directory.available && !itemMediaDirectory.confirmation

            ImageSvg {
                id: imageError
                width: 28
                height: 28

                color: Theme.colorWarning
                source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                id: textError
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                visible: (deviceSpaceText.width > 400)

                text: qsTr("Directory is not available right now :/")
                color: Theme.colorWarning
                font.bold: true
                font.pixelSize: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    ItemImageButton {
        id: rectangleDelete
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        visible: !itemMediaDirectory.confirmation
        iconColor: Theme.colorSubText
        highlightMode: "color"
        highlightColor: Theme.colorError
        source: "qrc:/assets/icons_material/baseline-delete-24px.svg"
        onClicked: itemMediaDirectory.confirmation = true
    }

    ////////

    Row {
        id: rowConfirmation
        anchors.left: comboBox_content.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter

        spacing: 16
        layoutDirection: Qt.RightToLeft
        visible: (itemMediaDirectory.confirmation)
        clip: true

        ButtonWireframe {
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("YES")
            fullColor: true
            primaryColor: Theme.colorPrimary
            onClicked: settingsManager.removeDirectory(textField_path.text)
        }
        ButtonWireframe {
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("NO")
            fullColor: true
            primaryColor: Theme.colorSubText
            onClicked: itemMediaDirectory.confirmation = false
        }
        Text {
            id: textConfirmation
            height: 48
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Are you sure?")
            font.bold: true
            font.pixelSize: 18
            color: Theme.colorSubText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}