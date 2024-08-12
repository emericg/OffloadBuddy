import QtQuick
import QtQuick.Effects
import QtQuick.Controls

import ThemeEngine
import StorageUtils

import "qrc:/utils/UtilsString.js" as UtilsString
import "qrc:/utils/UtilsPath.js" as UtilsPath

Popup {
    id: popupMediaDirectory

    x: (appWindow.width / 2) - (width / 2) + (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 720
    padding: 0

    dim: true
    modal: true
    focus: visible
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    parent: Overlay.overlay

    property int legendWidth: 96

    ////////////////////////////////////////////////////////////////////////////

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.333; to: 1.0; duration: 133; } }

    Overlay.modal: Rectangle {
        color: "#000"
        opacity: ThemeEngine.isLight ? 0.333 : 0.666
    }

    background: Rectangle {
        radius: Theme.componentRadius
        color: Theme.colorBackground

        Item {
            anchors.fill: parent

            Column {
                anchors.left: parent.left
                anchors.right: parent.right

                Rectangle { // title area
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 64
                    color: Theme.colorPrimary
                }

                Rectangle { // subtitle area
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48
                    color: Theme.colorForeground
                }
            }

            Rectangle { // border
                anchors.fill: parent
                radius: Theme.componentRadius
                color: "transparent"
                border.color: Theme.colorSeparator
                border.width: Theme.componentBorderWidth
                opacity: 0.4
            }

            layer.enabled: true
            layer.effect: MultiEffect { // clip
                maskEnabled: true
                maskInverted: false
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                maskSpreadAtMax: 0.0
                maskSource: ShaderEffectSource {
                    sourceItem: Rectangle {
                        x: background.x
                        y: background.y
                        width: background.width
                        height: background.height
                        radius: background.radius
                    }
                }
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect { // shadow
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowColor: ThemeEngine.isLight ? "#aa000000" : "#aaffffff"
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    contentItem: Column {

        ////////////////

        Item { // titleArea
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentMarginXL
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Media directory settings")
                textFormat: Text.PlainText
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: "white"
            }
        }

        ////////////////

        Item { // subtitleArea
            anchors.left: parent.left
            anchors.leftMargin: Theme.componentMarginXL
            anchors.right: parent.right
            anchors.rightMargin: Theme.componentMargin
            height: 48

            TextEditThemed {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: Theme.componentMargin + 40
                anchors.verticalCenter: parent.verticalCenter

                text: directory.directoryPath
                color: Theme.colorText
                font.pixelSize: Theme.fontSizeContent
                wrapMode: Text.WrapAnywhere
                readOnly: true
            }

            RoundButtonSunken {
                anchors.right: parent.right
                anchors.leftMargin: Theme.componentMargin
                anchors.verticalCenter: parent.verticalCenter

                width: 40
                height: 40
                colorBackground: Theme.colorForeground
                source: "qrc:/assets/icons/material-symbols/folder_open.svg"

                onClicked: {
                    utilsApp.openWith(directory.directoryPath)
                }
            }
        }

        ////////////////

        Column { // contentArea
            anchors.left: parent.left
            anchors.leftMargin: Theme.componentMarginXL
            anchors.right: parent.right
            anchors.rightMargin: Theme.componentMarginXL

            topPadding: Theme.componentMarginXL
            bottomPadding: Theme.componentMarginXL
            spacing: Theme.componentMarginXL

            ////////////

            Column {
                anchors.left: parent.left
                anchors.right: parent.right

                ////////

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 56

                    Text {
                        width: popupMediaDirectory.legendWidth
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Enabled")
                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContent
                    }

                    CheckBoxThemed {
                        id: checkBox_enabled
                        anchors.left: parent.left
                        anchors.leftMargin: popupMediaDirectory.legendWidth + 12
                        anchors.verticalCenter: parent.verticalCenter

                        checked: directory.enabled
                        onClicked: directory.enabled = checked
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: popupMediaDirectory.legendWidth + checkBox_enabled.width + 8
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("You can quickly enable/disable this directory if you don't need it at the moment, or if you dont want it to overload your media library.")
                        textFormat: Text.PlainText
                        font.pixelSize: Theme.fontSizeContentSmall
                        wrapMode: Text.WordWrap
                        color: Theme.colorSubText
                    }
                }

                ////////

                Item {
                    anchors.right: parent.right
                    anchors.left: parent.left
                    height: 56

                    Text {
                        width: popupMediaDirectory.legendWidth
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Content")
                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContent
                    }

                    ComboBoxThemed {
                        anchors.left: parent.left
                        anchors.leftMargin: popupMediaDirectory.legendWidth + 16
                        anchors.right: parent.right
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
                                cbinit = true
                            }
                        }
                    }
                }

                Item {
                    height: legendContent.contentHeight + 16
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Text {
                        id: legendContent
                        anchors.left: parent.left
                        anchors.leftMargin: popupMediaDirectory.legendWidth + 20
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -8

                        text: qsTr("Choose to restrict what kind of content can be saved into this media directory.")
                        textFormat: Text.PlainText
                        font.pixelSize: Theme.fontSizeContentSmall
                        wrapMode: Text.WordWrap
                        color: Theme.colorSubText
                    }
                }

                ////////

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 56

                    Text {
                        width: popupMediaDirectory.legendWidth
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Hierarchy")
                        textFormat: Text.PlainText
                        font.pixelSize: Theme.componentFontSize
                        color: Theme.colorText
                    }

                    ComboBoxThemed {
                        anchors.left: parent.left
                        anchors.leftMargin: popupMediaDirectory.legendWidth + 16
                        anchors.right: parent.right
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

                Item {
                    height: legendHierarchy.contentHeight + 16
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Text {
                        id: legendHierarchy
                        anchors.left: parent.left
                        anchors.leftMargin: popupMediaDirectory.legendWidth + 20
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -8

                        text: qsTr("How media will be stored in this directory. Choose an available hierarchy, or use the CUSTOM item to create your own.")
                        textFormat: Text.PlainText
                        font.pixelSize: Theme.fontSizeContentSmall
                        wrapMode: Text.WordWrap
                        color: Theme.colorSubText
                    }
                }

                ////////

                Item {
                    anchors.right: parent.right
                    anchors.left: parent.left
                    anchors.leftMargin: popupMediaDirectory.legendWidth + 16
                    height: 48

                    visible: (directory.directoryHierarchy === StorageUtils.HierarchyCustom)

                    TextFieldThemed {
                        id: tfHC
                        anchors.right: parent.right
                        anchors.left: parent.left
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
                    anchors.leftMargin: popupMediaDirectory.legendWidth + 16
                    topPadding: 6
                    spacing: 12

                    visible: (directory.directoryHierarchy === StorageUtils.HierarchyCustom)

                    TagButtonFlat { text: "DATE"; onClicked: tfHC.insert(tfHC.selectionStart, "$(DATE)"); }
                    TagButtonFlat { text: "YEAR"; onClicked: tfHC.insert(tfHC.selectionStart, "$(YEAR)"); }
                    TagButtonFlat { text: "MONTH"; onClicked: tfHC.insert(tfHC.selectionStart, "$(MONTH)"); }
                    TagButtonFlat { text: "DAY"; onClicked: tfHC.insert(tfHC.selectionStart, "$(DAY)"); }
                    TagButtonFlat { text: "SHOT NAME"; onClicked: tfHC.insert(tfHC.selectionStart, "$(SHOT_NAME)"); }
                    TagButtonFlat { text: "CAMERA"; onClicked: tfHC.insert(tfHC.selectionStart, "$(CAMERA)"); }
                }

                ////////
            }

            ////////////

            Row {
                anchors.right: parent.right
                spacing: Theme.componentMargin

                ButtonSolid {
                    text: qsTr("OK")
                    source: "qrc:/assets/icons/material-symbols/check.svg"

                    onClicked: popupMediaDirectory.close()
                }
            }

            ////////////
        }

        //////////////////
    }

    ////////////////////////////////////////////////////////////////////////////
}
