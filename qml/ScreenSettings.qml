import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Item {
    width: 1280
    height: 720

    Rectangle {
        id: rectangleHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        height: 64
        z: 5
        color: Theme.colorHeader

        DragHandler {
            // Drag on the sidebar to drag the whole window // Qt 5.15+
            // Also, prevent clicks below this area
            onActiveChanged: if (active) appWindow.startSystemMove();
            target: null
        }

        Text {
            id: textHeader
            height: 40
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("SETTINGS")
            verticalAlignment: Text.AlignVCenter
            font.bold: true
            font.pixelSize: Theme.fontSizeHeader
            color: Theme.colorHeaderContent
        }

        CsdWindows {
            anchors.top: parent.top
            anchors.right: parent.right
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    ScrollView {
        id: scrollView
        contentWidth: -1

        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        Column {
            anchors.topMargin: 24
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.fill: parent
            spacing: 8

            ////////

            Row {
                height: 40
                spacing: 24

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Application theme")
                    font.bold: true
                    font.pixelSize: Theme.fontSizeComponent
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    color: Theme.colorText
                }

                ComboBoxThemed {
                    id: comboBoxAppTheme
                    width: 256
                    anchors.verticalCenter: parent.verticalCenter

                    model: ListModel {
                        id: cbAppTheme
                        ListElement { text: "LIGHT AND WARM"; }
                        ListElement { text: "DARK AND SPOOKY"; }
                        ListElement { text: "PLAIN AND BORING"; }
                        ListElement { text: "BLOOD AND TEARS"; }
                        ListElement { text: "MIGHTY KITTENS"; }
                    }

                    Component.onCompleted: {
                        currentIndex = settingsManager.appTheme;
                        if (currentIndex === -1) { currentIndex = 0 }
                    }
                    property bool cbinit: false
                    onCurrentIndexChanged: {
                        if (cbinit)
                            settingsManager.appTheme = currentIndex;
                        else
                            cbinit = true;
                    }
                }
            }

            ////////

            Row {
                height: 40
                spacing: 32

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Unit system")
                    font.bold: true
                    font.pixelSize: Theme.fontSizeComponent
                    color: Theme.colorText
                }

                RadioButtonThemed {
                    id: radioButtonMetric
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Metric")

                    Component.onCompleted: { checked =  (settingsManager.appUnits === 0); }
                    onCheckedChanged: { if (checked === true) { settingsManager.appUnits = 0 }; }
                }

                RadioButtonThemed {
                    id: radioButtonImperial
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Imperial")

                    Component.onCompleted: { checked =  (settingsManager.appUnits === 1); }
                    onCheckedChanged: { if (checked === true) { settingsManager.appUnits = 1 }; }
                }
            }

            ////////

            Text {
                height: 40

                text: qsTr("Thumbnails")
                verticalAlignment: Text.AlignVCenter
                color: Theme.colorText
                font.bold: true
                font.pixelSize: Theme.fontSizeComponent
            }

            Row {
                height: 40
                spacing: 32

                Text {
                    id: titleQuality
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Quality")
                    font.pixelSize: Theme.fontSizeComponent
                    color: Theme.colorText
                }

                ItemLilMenu {
                    width: rowLilMenuQuality.width
                    height: 32
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: rowLilMenuQuality
                        height: parent.height

                        ItemLilMenuButton {
                            text: qsTr("Low")
                            selected: (settingsManager.thumbQuality === 0)
                            onClicked: settingsManager.thumbQuality = 0
                        }
                        ItemLilMenuButton {
                            text: qsTr("Balanced")
                            selected: (settingsManager.thumbQuality === 1)
                            onClicked: settingsManager.thumbQuality = 1
                        }
                        ItemLilMenuButton {
                            text: qsTr("High")
                            selected: (settingsManager.thumbQuality === 2)
                            onClicked: settingsManager.thumbQuality = 2
                        }
                    }
                }
            }

            ////////

            Row {
                height: 40
                spacing: 32

                Text {
                    id: titleAR
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Aspect ratio")
                    font.pixelSize: Theme.fontSizeComponent
                    color: Theme.colorText
                }

                ItemLilMenu {
                    anchors.verticalCenter: parent.verticalCenter
                    width: rowLilMenuAR.width
                    height: 32

                    Row {
                        id: rowLilMenuAR
                        height: parent.height

                        ItemLilMenuButton {
                            text: "1:1"
                            selected: (settingsManager.thumbFormat === 1)
                            onClicked: settingsManager.thumbFormat = 1
                        }
                        ItemLilMenuButton {
                            text: "4:3"
                            selected: (settingsManager.thumbFormat === 2)
                            onClicked: settingsManager.thumbFormat = 2
                        }
                        ItemLilMenuButton {
                            text: "16:9"
                            selected: (settingsManager.thumbFormat === 3)
                            onClicked: settingsManager.thumbFormat = 3
                        }
                    }
                }

                Text {
                    id: titleSize
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Default size")
                    font.pixelSize: Theme.fontSizeComponent
                    color: Theme.colorText
                }

                ItemLilMenu {
                    anchors.verticalCenter: parent.verticalCenter
                    width: rowLilMenuSize.width
                    height: 32

                    Row {
                        id: rowLilMenuSize
                        height: parent.height

                        ItemLilMenuButton {
                            text: qsTr("Small")
                            selected: (settingsManager.thumbSize === 1)
                            onClicked: settingsManager.thumbSize = 1
                        }
                        ItemLilMenuButton {
                            text: qsTr("Medium")
                            selected: (settingsManager.thumbSize === 2)
                            onClicked: settingsManager.thumbSize = 2
                        }
                        ItemLilMenuButton {
                            text: qsTr("Big")
                            selected: (settingsManager.thumbSize === 3)
                            onClicked: settingsManager.thumbSize = 3
                        }
                        ItemLilMenuButton {
                            text: qsTr("Huge")
                            selected: (settingsManager.thumbSize === 4)
                            onClicked: settingsManager.thumbSize = 4
                        }
                    }
                }
            }

            ////////

            Text {
                height: 40

                text: qsTr("Offloading")
                verticalAlignment: Text.AlignVCenter
                color: Theme.colorText
                font.bold: true
                font.pixelSize: Theme.fontSizeComponent
            }

            Row {
                height: 40
                spacing: 32

                CheckBoxThemed {
                    id: checkIgnoreJunk
                    width: 350
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Ignore LRVs and THM files")

                    checked: settingsManager.ignorejunk
                    onCheckStateChanged: settingsManager.ignorejunk = checked
                }

                CheckBoxThemed {
                    id: checkIgnoreAudio
                    width: 350
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Ignore HD audio files")

                    checked: settingsManager.ignorehdaudio
                    onCheckStateChanged: settingsManager.ignorehdaudio = checked
                }
            }

            Row {
                height: 40
                spacing: 32

                CheckBoxThemed {
                    id: checkAutoDelete
                    width: 350
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Automatically delete offloaded media")

                    checked: settingsManager.autodelete
                    onCheckStateChanged: settingsManager.autodelete = checked
                }

                CheckBoxThemed {
                    id: checkAutoMerge
                    width: 350
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Automatically merge video chapters")
                    enabled: false

                    checked: settingsManager.automerge
                    onCheckStateChanged: settingsManager.automerge = checked
                }

                CheckBoxThemed {
                    id: checkAutoMetadata
                    width: 350
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Automatically extract telemetry")
                    enabled: false

                    checked: settingsManager.autometadata
                    onCheckStateChanged: settingsManager.autometadata = checked
                }
            }

            ////////

            Row {
                height: 40
                spacing: 32

                Text {
                    id: textMediaHierarchy
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Media hierarchy")

                    font.pixelSize: Theme.fontSizeComponent
                    color: Theme.colorText
                }

                ComboBoxThemed {
                    id: comboBoxContentHierarchy
                    width: 256
                    anchors.verticalCenter: parent.verticalCenter

                    model: ListModel {
                        id: cbItemsContentHierarchy
                        ListElement { text: qsTr("/ date / FILES"); }
                        ListElement { text: qsTr("/ date / device / FILES"); }
                    }

                    Component.onCompleted: {
                        currentIndex = storageManager.contentHierarchy;
                        if (currentIndex === -1) { currentIndex = 0 }
                    }
                    property bool cbinit: false
                    onCurrentIndexChanged: {
                        if (cbinit)
                            storageManager.contentHierarchy = currentIndex;
                        else
                            cbinit = true;
                    }
                }
            }

            ////////

            Column {
                id: rectangleMedia
                spacing: 8

                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                Row {
                    height: 40
                    spacing: 32

                    Text {
                        id: textMediaTitle
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Media directories")
                        font.pixelSize: Theme.fontSizeComponent
                        font.bold: true
                        color: Theme.colorText
                    }

                    ItemImageButton {
                        id: buttonNew
                        anchors.verticalCenter: parent.verticalCenter

                        source: "qrc:/assets/icons_material/outline-create_new_folder-24px.svg"
                        tooltipText: qsTr("Add a new media directory")
                        onClicked: fileDialogAdd.open()
                    }

                    FileDialog {
                        id: fileDialogAdd
                        title: qsTr("Please choose a destination directory!")
                        sidebarVisible: true
                        selectExisting: true
                        selectMultiple: false
                        selectFolder: true
                        folder: shortcuts.home

                        onAccepted: {
                            storageManager.addDirectory(UtilsPath.cleanUrl(fileDialogAdd.fileUrl))
                        }
                    }
                }

                ListView {
                    id: mediadirectoriesview
                    width: parent.width
                    height: storageManager.directoriesList.length * 64 // 48px for the widget and 16px for spacing
                    anchors.left: parent.left
                    anchors.right: parent.right

                    spacing: 8
                    interactive: false
                    model: storageManager.directoriesList
                    delegate: ItemMediaDirectory { directory: modelData; }
                }
            }
        }
    }
}
