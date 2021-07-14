import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
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

            ItemImageButtonTooltip {
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

            ItemImageButtonTooltip {
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

            ItemImageButton {
                id: button_open
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                highlightMode: "color"
                visible: directory.available
                source: "qrc:/assets/icons_material/baseline-folder_open-24px.svg"
                onClicked: {
                    utilsApp.openWith(directory.directoryPath)
                }
            }

            ItemImageButton {
                id: button_refresh
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                highlightMode: "color"
                visible: directory.available
                source: "qrc:/assets/icons_material/baseline-refresh-24px.svg"
                onClicked: mediaLibrary.searchMediaDirectory(directory.directoryPath)

                NumberAnimation on rotation {
                    id: refreshAnimation
                    duration: 1000
                    from: 0
                    to: 360
                    running: directory.scanning
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    easing.type: Easing.Linear
                }
            }

            ImageSvg {
                width: 24
                height: 24
                anchors.verticalCenter: parent.verticalCenter

                visible: !directory.available
                source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
                color: Theme.colorWarning
            }
        }
    }

    ////////////////

    Item {
        id: menus
        anchors.top: parent.top
        anchors.left: textField_path.right
        anchors.leftMargin: 16
        anchors.right: rowButtons.left
        anchors.rightMargin: 12
        anchors.bottom: parent.bottom

        property int memusmode: 0

        // this
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: 4
            visible: (menus.memusmode === 0 && directory.available)

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

        // or this
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: (menus.memusmode === 0 && !directory.available)

            ImageSvg {
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

        // or even that
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: (menus.memusmode === 1)

            CheckBoxThemed {
                id: checkBox_enabled
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Enabled")

                checked: directory.enabled
                onClicked: directory.enabled = checked
            }

            Text {
                id: textContent2
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Content")
                font.pixelSize: Theme.fontSizeComponent
                color: Theme.colorText
            }

            ComboBoxThemed {
                id: comboBox_content2
                width: 180
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                font.pixelSize: Theme.fontSizeContentSmall

                model: ListModel {
                    id: cbItemsContent2
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
                        directory.directoryContent = currentIndex
                    } else {
                        cbinit = true;
                    }
                }
            }

            ////////

            Text {
                id: textMediaHierarchy2
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Hierarchy")
                font.pixelSize: Theme.fontSizeComponent
                color: Theme.colorText
            }

            ComboBoxThemed {
                id: comboBoxContentHierarchy2
                width: 256
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                model: ListModel {
                    id: cbItemsContentHierarchy
                    ListElement { text: qsTr("/ SHOT / FILES"); }
                    ListElement { text: qsTr("/ date / SHOT / FILES"); }
                    ListElement { text: qsTr("/ date / device / SHOT / FILES"); }
                }

                Component.onCompleted: {
                    currentIndex = directory.directoryHierarchy
                    if (currentIndex === -1) { currentIndex = 0 }
                }
                property bool cbinit: false
                onCurrentIndexChanged: {
                    if (cbinit)
                        directory.directoryHierarchy = currentIndex
                    else
                        cbinit = true
                }
            }
        }
    }

    ////////////////

    Row {
        id: rowConfirmation
        anchors.left: comboBox_content.right
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
        anchors.verticalCenter: parent.verticalCenter

        visible: (menus.memusmode !== 3)

        ItemImageButton {
            id: rectangleSettings
            anchors.verticalCenter: parent.verticalCenter

            imgSize: 32
            iconColor: Theme.colorSubText
            highlightMode: "color"
            highlightColor: Theme.colorPrimary
            source: "qrc:/assets/icons_material/baseline-settings_applications-24px.svg"
            onClicked: {
                if (menus.memusmode !== 1) menus.memusmode = 1
                else menus.memusmode = 0
            }
        }

        ItemImageButton {
            id: rectangleDelete
            anchors.verticalCenter: parent.verticalCenter

            imgSize: 32
            iconColor: Theme.colorSubText
            highlightMode: "color"
            highlightColor: Theme.colorError
            source: "qrc:/assets/icons_material/baseline-delete-24px.svg"
            onClicked: {
                if (menus.memusmode !== 3) menus.memusmode = 3
                else menus.memusmode = 0
            }
        }
    }
}
