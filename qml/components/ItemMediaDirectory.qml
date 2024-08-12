import QtQuick
import QtQuick.Controls

import ThemeEngine
import StorageUtils
import "qrc:/utils/UtilsString.js" as UtilsString
import "qrc:/utils/UtilsPath.js" as UtilsPath

Item {
    id: itemMediaDirectory

    implicitWidth: 800
    implicitHeight: 48

    property var directory: null

    ////////////////

    FolderInputArea {
        id: textField_path
        width: (itemMediaDirectory.width / 2)
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        text: directory.directoryPath

        onPathChanged: {
            directory.directoryPath = path
            focus = false
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: textField_path.buttonWidth + 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            RoundButtonIcon {
                id: button_ro
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                highlightMode: "color"
                visible: directory.readOnly
                iconColor: Theme.colorWarning
                source: "qrc:/assets/icons/material-symbols/lock.svg"

                tooltipText: "Storage is read only"
                tooltipPosition: "left"
            }

            RoundButtonIcon {
                id: button_lfs
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                highlightMode: "color"
                visible: !directory.largeFileSupport
                iconColor: Theme.colorWarning
                source: "qrc:/assets/icons/material-symbols/warning.svg"

                tooltipText: "Storage is 4 GiB limited"
                tooltipPosition: "left"
            }

            RoundButtonIcon {
                id: button_refresh
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                highlightMode: "color"
                visible: directory.available
                enabled: directory.enabled
                source: "qrc:/assets/icons/material-symbols/refresh.svg"

                animation: "rotate"
                animationRunning: directory.scanning

                onClicked: mediaLibrary.searchMediaDirectory(directory.directoryPath)
            }

            RoundButtonIcon {
                id: button_open
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                highlightMode: "color"
                visible: directory.available
                source: "qrc:/assets/icons/material-symbols/folder_open.svg"
                onClicked: utilsApp.openWith(directory.directoryPath)
            }

            RoundButtonIcon {
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                highlightMode: "off"
                visible: !directory.available
                source: "qrc:/assets/icons/material-symbols/warning.svg"
                iconColor: Theme.colorWarning
            }
        }
    }

    ////////////////

    Item {
        id: menus
        anchors.top: parent.top
        anchors.left: textField_path.right
        anchors.leftMargin: 12
        anchors.right: rowButtons.left
        anchors.rightMargin: 12
        anchors.bottom: parent.bottom

        property int memusmode: 0

        // this
        Row {
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            visible: (menus.memusmode === 0 && directory.available)

            CheckBoxThemed {
                id: checkBox_enabled
                anchors.verticalCenter: parent.verticalCenter

                checked: directory.enabled
                onClicked: directory.enabled = checked
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - checkBox_enabled.width
                spacing: 4

                Text {
                    id: deviceSpaceText
                    width: parent.width

                    visible: (deviceSpaceText.width > 400)
                    color: Theme.colorText
                    textFormat: Text.PlainText
                    text: UtilsString.bytesToString_short(directory.spaceUsed) + qsTr(" used / ") +
                          UtilsString.bytesToString_short(directory.spaceAvailable) + qsTr(" available / ") +
                          UtilsString.bytesToString_short(directory.spaceTotal) + qsTr(" total")
                }
                ProgressBarThemed {
                    id: progressBar
                    width: parent.width

                    value: directory.storageLevel
                }
            }
        }

        // or that
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: (menus.memusmode === 0 && !directory.available)

            IconSvg {
                id: imageError
                width: 28
                height: 28
                anchors.verticalCenter: parent.verticalCenter

                color: Theme.colorWarning
                source: "qrc:/assets/icons/material-symbols/warning.svg"
            }
            Text {
                id: textError
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                visible: (deviceSpaceText.width > 400)

                text: qsTr("Directory is not available right now :/")
                textFormat: Text.PlainText
                color: Theme.colorWarning
                font.bold: true
                font.pixelSize: Theme.fontSizeContent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    ////////////////

    Row {
        id: rowConfirmation
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        spacing: 12
        layoutDirection: Qt.RightToLeft
        visible: (menus.memusmode === 3)

        ButtonSolid {
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("NO")
            color: Theme.colorSubText
            onClicked: menus.memusmode = 0
        }
        ButtonSolid {
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("YES")
            color: Theme.colorPrimary
            onClicked: storageManager.removeDirectory(textField_path.text)
        }
        Text {
            id: textConfirmation
            height: 48
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Are you sure?")
            textFormat: Text.PlainText
            font.bold: true
            font.pixelSize: Theme.fontSizeContent
            color: Theme.colorSubText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    ////////////////

    Row {
        id: rowButtons
        anchors.right: parent.right
        anchors.rightMargin: -8
        anchors.verticalCenter: parent.verticalCenter

        visible: (menus.memusmode !== 3)

        RoundButtonIcon {
            id: rectangleSettings
            anchors.verticalCenter: parent.verticalCenter

            iconColor: Theme.colorSubText
            highlightMode: "color"
            highlightColor: Theme.colorPrimary
            source: "qrc:/assets/icons/material-symbols/settings_applications.svg"
            sourceSize: 24

            onClicked: {
                popupMediaDirectory_loader.active = true
                popupMediaDirectory_loader.item.open()
            }

            Loader {
                id: popupMediaDirectory_loader

                active: false
                asynchronous: false
                sourceComponent: PopupMediaDirectory {
                    id: popupMediaDirectory
                    parent: appWindow.contentItem
                }
            }
        }

        RoundButtonIcon {
            id: rectangleDelete
            anchors.verticalCenter: parent.verticalCenter

            iconColor: Theme.colorSubText
            highlightMode: "color"
            highlightColor: Theme.colorError
            source: "qrc:/assets/icons/material-symbols/delete.svg"
            sourceSize: 24

            onClicked: {
                if (menus.memusmode !== 3) menus.memusmode = 3
                else menus.memusmode = 0
            }
        }
    }

    ////////////////
}
