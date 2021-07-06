import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Item {
    id: screenSettings
    width: 1280
    height: 720

    Rectangle {
        id: rectangleHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        z: 1
        height: 64
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

        ////////

        CsdWindows { }

        ////////

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: 2
            opacity: 0.1
            color: Theme.colorHeaderContent
        }
        SimpleShadow {
            anchors.top: parent.bottom
            anchors.topMargin: -height
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: Theme.colorHighContrast
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    ScrollView {
        id: scrollView
        contentWidth: -1

        anchors.top: rectangleHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Column {
            anchors.fill: parent
            anchors.topMargin: 24
            anchors.leftMargin: 24
            anchors.rightMargin: 24
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
                    height: 36
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

                CheckBoxThemed {
                    id: applicationCSD
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Use Client Side Decoration")

                    checked: settingsManager.appThemeCSD
                    onClicked: settingsManager.appThemeCSD = checked
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

                    checked: (settingsManager.appUnits === 0)
                    onClicked: settingsManager.appUnits = 0
                }

                RadioButtonThemed {
                    id: radioButtonImperial
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Imperial")

                    checked: (settingsManager.appUnits === 1)
                    onClicked: settingsManager.appUnits = 1
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

                    checked: settingsManager.ignoreJunk
                    onClicked: settingsManager.ignoreJunk = checked
                }

                CheckBoxThemed {
                    id: checkIgnoreAudio
                    width: 350
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Ignore HD audio files")

                    checked: settingsManager.ignoreHdAudio
                    onClicked: settingsManager.ignoreHdAudio = checked
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

                    checked: settingsManager.autoDelete
                    onClicked: settingsManager.autoDelete = checked
                }

                CheckBoxThemed {
                    id: checkAutoMerge
                    width: 350
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Automatically merge video chapters")
                    enabled: false

                    checked: settingsManager.autoMerge
                    onClicked: settingsManager.autoMerge = checked
                }

                CheckBoxThemed {
                    id: checkAutoTelemetry
                    width: 350
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Automatically extract telemetry")

                    checked: settingsManager.autoTelemetry
                    onClicked: settingsManager.autoTelemetry = checked
                }
            }

            Row {
                height: 40
                spacing: 32

                CheckBoxThemed {
                    id: checkMoveToTrash
                    width: 450
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Move files to trash instead of deleting them")

                    visible: jobManager.hasMoveToTrash()
                    checked: settingsManager.moveToTrash
                    onClicked: settingsManager.moveToTrash = checked
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
                    height: 36
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
                    spacing: 24

                    Text {
                        id: textMediaTitle
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Media directories")
                        font.pixelSize: Theme.fontSizeComponent
                        font.bold: true
                        color: Theme.colorText
                    }

                    ItemImageButtonTooltip {
                        id: buttonNew
                        anchors.verticalCenter: parent.verticalCenter

                        source: "qrc:/assets/icons_material/outline-create_new_folder-24px.svg"
                        tooltipText: qsTr("Add a new media directory")
                        tooltipPosition: "right"
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
