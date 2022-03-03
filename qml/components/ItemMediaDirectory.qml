import QtQuick 2.15
import QtQuick.Controls 2.15

import ThemeEngine 1.0
import StorageUtils 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Item {
    id: itemMediaDirectory
    implicitWidth: 800
    implicitHeight: 48

    property var directory: null

    ////////////////

    FolderInputArea {
        id: textField_path
        width: (itemMediaDirectory.width < 720) ? 640 : 720
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
                source: "qrc:/assets/icons_material/outline-https-24px.svg"

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
                source: "qrc:/assets/icons_material/baseline-warning-24px.svg"

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
                source: "qrc:/assets/icons_material/baseline-refresh-24px.svg"

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
                source: "qrc:/assets/icons_material/baseline-folder_open-24px.svg"
                onClicked: utilsApp.openWith(directory.directoryPath)
            }

            RoundButtonIcon {
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                highlightMode: "off"
                visible: !directory.available
                source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
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
                    text: UtilsString.bytesToString_short(directory.spaceUsed) + qsTr(" used / ") +
                          UtilsString.bytesToString_short(directory.spaceAvailable) + qsTr(" available / ") +
                          UtilsString.bytesToString_short(directory.spaceTotal) + qsTr(" total")
                }
                ProgressBarThemed {
                    id: progressBar
                    width: parent.width
                    height: 8

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
                source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
            }
            Text {
                id: textError
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                visible: (deviceSpaceText.width > 400)

                text: qsTr("Directory is not available right now :/")
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

        ButtonWireframe {
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("NO")
            fullColor: true
            primaryColor: Theme.colorSubText
            onClicked: menus.memusmode = 0
        }
        ButtonWireframe {
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("YES")
            fullColor: true
            primaryColor: Theme.colorPrimary
            onClicked: storageManager.removeDirectory(textField_path.text)
        }
        Text {
            id: textConfirmation
            height: 48
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Are you sure?")
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
            source: "qrc:/assets/icons_material/baseline-settings_applications-24px.svg"
            sourceSize: 32

            onClicked: {
                var popupComponent = Qt.createComponent("qrc:/qml/PopupMediaDirectory.qml")
                var popupMediaDirectory = popupComponent.createObject(appWindow, { "parent": appWindow });
                popupMediaDirectory.open()
            }
        }

        RoundButtonIcon {
            id: rectangleDelete
            anchors.verticalCenter: parent.verticalCenter

            iconColor: Theme.colorSubText
            highlightMode: "color"
            highlightColor: Theme.colorError
            source: "qrc:/assets/icons_material/baseline-delete-24px.svg"
            sourceSize: 32

            onClicked: {
                if (menus.memusmode !== 3) menus.memusmode = 3
                else menus.memusmode = 0
            }
        }
    }
}
