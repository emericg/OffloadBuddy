import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import StorageUtils 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Popup {
    id: popupMediaDirectory
    x: (appWindow.width / 2) - (width / 2) + (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 720
    padding: 0

    parent: Overlay.overlay

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    signal confirmed()

    ////////////////////////////////////////////////////////////////////////////

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.5; to: 1.0; duration: 133; } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 233; } }

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: Theme.colorBackground
        radius: Theme.componentRadius
        border.width: Theme.componentBorderWidth
        border.color: Theme.colorForeground
    }

    ////////////////////////////////////////////////////////////////////////////

    contentItem: Column {

        Rectangle {
            id: titleArea
            anchors.left: parent.left
            anchors.right: parent.right

            height: 64
            color: Theme.colorPrimary
            radius: Theme.componentRadius

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 1
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Media Directory settings")
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: "white"
            }
        }

        ////////////////

        Item {
            id: contentArea
            height: columnSettings.height
            anchors.left: parent.left
            anchors.right: parent.right

            Column {
                id: columnSettings
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 24
                topPadding: 16
                bottomPadding: 16

                ////////

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48

                    Text {
                        width: 128
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Enabled")
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContent
                    }

                    CheckBoxThemed {
                        id: checkBox_enabled
                        anchors.left: parent.left
                        anchors.leftMargin: 128 + 12
                        anchors.verticalCenter: parent.verticalCenter

                        checked: directory.enabled
                        onClicked: directory.enabled = checked
                    }
                }

                ////////

                Item {
                    anchors.right: parent.right
                    anchors.left: parent.left
                    height: 48

                    Text {
                        width: 128
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Content")
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContent
                    }

                    ComboBoxThemed {
                        width: 320
                        height: 36
                        anchors.left: parent.left
                        anchors.leftMargin: 128 + 16
                        anchors.verticalCenter: parent.verticalCenter

                        font.pixelSize: Theme.fontSizeContentSmall

                        model: ListModel {
                            ListElement { text: qsTr("all media"); }
                            ListElement { text: qsTr("audio"); }
                            ListElement { text: qsTr("videos"); }
                            ListElement { text: qsTr("pictures"); }
                        }
                        Component.onCompleted: {
                            currentIndex = directory.directoryContent
                            if (currentIndex === -1) currentIndex = 0
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
                }

                ////////

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48

                    Text {
                        id: textMediaHierarchy2
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Hierarchy")
                        font.pixelSize: Theme.fontSizeComponent
                        color: Theme.colorText
                    }

                    ComboBoxThemed {
                        width: 320
                        height: 36
                        anchors.left: parent.left
                        anchors.leftMargin: 128 + 16
                        anchors.verticalCenter: parent.verticalCenter

                        model: ListModel {
                            ListElement { text: qsTr("/ FILES"); }
                            ListElement { text: qsTr("/ SHOT / FILES"); }
                            ListElement { text: qsTr("/ date / SHOT / FILES"); }
                            ListElement { text: qsTr("/ date / device / SHOT / FILES"); }
                            ListElement { text: qsTr("CUSTOM"); }
                        }

                        Component.onCompleted: {
                            currentIndex = directory.directoryHierarchy
                            if (directory.directoryHierarchy === -1) currentIndex = 0
                            if (directory.directoryHierarchy === 32) currentIndex = 4
                        }
                        property bool cbinit: false
                        onCurrentIndexChanged: {
                            if (cbinit) {
                                if (currentIndex === 4) directory.directoryHierarchy = StorageUtils.HierarchyCustom
                                else directory.directoryHierarchy = currentIndex
                            } else {
                                cbinit = true
                            }
                        }
                    }
                }

                ////////

                Item {
                    anchors.right: parent.right
                    anchors.left: parent.left
                    anchors.leftMargin: 128 + 16
                    height: 48

                    visible: (directory.directoryHierarchy === StorageUtils.HierarchyCustom)

                    TextFieldThemed {
                        id: tfHC
                        anchors.right: parent.right
                        anchors.left: parent.left
                        height: 36
                        anchors.verticalCenter: parent.verticalCenter

                        selectByMouse: true
                        selectionColor: Theme.colorPrimary
                        selectedTextColor: "white"

                        text: directory.directoryHierarchyCustom
                        onTextChanged: directory.directoryHierarchyCustom = text
                    }
                }

                Flow {
                    anchors.right: parent.right
                    anchors.left: parent.left
                    anchors.leftMargin: 128 + 16
                    topPadding: 6
                    spacing: 12

                    visible: (directory.directoryHierarchy === StorageUtils.HierarchyCustom)

                    ItemTag { text: "DATE"; onClicked: tfHC.insert(tfHC.selectionStart, "$(DATE)"); }
                    ItemTag { text: "YEAR"; onClicked: tfHC.insert(tfHC.selectionStart, "$(YEAR)"); }
                    ItemTag { text: "MONTH"; onClicked: tfHC.insert(tfHC.selectionStart, "$(MONTH)"); }
                    ItemTag { text: "DAY"; onClicked: tfHC.insert(tfHC.selectionStart, "$(DAY)"); }
                    ItemTag { text: "SHOT NAME"; onClicked: tfHC.insert(tfHC.selectionStart, "$(SHOT_NAME)"); }
                    ItemTag { text: "CAMERA"; onClicked: tfHC.insert(tfHC.selectionStart, "$(CAMERA)"); }
                }

                ////////
            }
        }

        //////////////////

        Row {
            id: rowButtons
            height: Theme.componentHeight*2 + parent.spacing
            anchors.right: parent.right
            anchors.rightMargin: 24
            spacing: 24

            ButtonWireframeImage {
                id: buttonUpdate
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("OK")
                source: "qrc:/assets/icons_material/baseline-done-24px.svg"
                fullColor: true
                primaryColor: Theme.colorPrimary

                onClicked: {
                    popupMediaDirectory.close()
                }
            }
        }
    }
}