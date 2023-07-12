import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Item {
    id: screenSettings
    width: 1280
    height: 720

    // HEADER //////////////////////////////////////////////////////////////////

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
            onActiveChanged: if (active) appWindow.startSystemMove()
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

        CsdLinux { }

        ////////

        Rectangle { // separator
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: 2
            opacity: 0.1
            color: Theme.colorHeaderContent
        }
    }
    Rectangle { // shadow
        anchors.top: rectangleHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        height: 8
        opacity: 0.66

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Theme.colorHeaderHighlight; }
            GradientStop { position: 1.0; color: Theme.colorBackground; }
        }
    }

    // CONTENT /////////////////////////////////////////////////////////////////

    Flickable {
        anchors.top: rectangleHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        contentWidth: -1
        contentHeight: columnSettings.height

        boundsBehavior: Flickable.OvershootBounds
        ScrollBar.vertical: ScrollBar { }

        Column {
            id: columnSettings
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24

            topPadding: 24
            bottomPadding: 24
            spacing: 8

            ////////

            Row {
                height: 40
                spacing: 24

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Application theme")
                    font.bold: true
                    font.pixelSize: Theme.componentFontSize
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
                        if (settingsManager.appTheme === "THEME_LIGHT_AND_WARM") currentIndex = 0
                        else if (settingsManager.appTheme === "THEME_DARK_AND_SPOOKY") currentIndex = 1
                        else if (settingsManager.appTheme === "THEME_PLAIN_AND_BORING") currentIndex = 2
                        else if (settingsManager.appTheme === "THEME_BLOOD_AND_TEARS") currentIndex = 3
                        else if (settingsManager.appTheme === "THEME_MIGHTY_KITTENS") currentIndex = 4
                    }

                    property bool cbinit: false
                    onCurrentTextChanged: {
                        if (cbinit) {
                            if (currentText === "LIGHT AND WARM") settingsManager.appTheme = "THEME_LIGHT_AND_WARM"
                            else if (currentText === "DARK AND SPOOKY") settingsManager.appTheme = "THEME_DARK_AND_SPOOKY"
                            else if (currentText === "PLAIN AND BORING") settingsManager.appTheme = "THEME_PLAIN_AND_BORING"
                            else if (currentText === "BLOOD AND TEARS") settingsManager.appTheme = "THEME_BLOOD_AND_TEARS"
                            else if (currentText === "MIGHTY KITTENS") settingsManager.appTheme = "THEME_MIGHTY_KITTENS"
                        } else {
                            cbinit = true
                        }
                    }
                }

                CheckBoxThemed {
                    id: applicationCSD
                    anchors.verticalCenter: parent.verticalCenter

                    visible: utilsApp.isDebugBuild()
                    text: qsTr("Use Client Side Decoration")

                    checked: settingsManager.appThemeCSD
                    onClicked: settingsManager.appThemeCSD = checked
                }
            }

            ////////

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                height: 16
                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: -24
                    anchors.right: parent.right
                    anchors.rightMargin: -24
                    anchors.verticalCenter: parent.verticalCenter
                    height: 2
                    opacity: 0.33
                    color: Theme.colorSeparator
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
                    font.pixelSize: Theme.componentFontSize
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

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                height: 16
                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: -24
                    anchors.right: parent.right
                    anchors.rightMargin: -24
                    anchors.verticalCenter: parent.verticalCenter
                    height: 2
                    opacity: 0.33
                    color: Theme.colorSeparator
                }
            }

            ////////

            Text {
                text: qsTr("Thumbnails")
                verticalAlignment: Text.AlignVCenter
                color: Theme.colorText
                font.bold: true
                font.pixelSize: Theme.componentFontSize
            }

            Row {
                height: 40
                spacing: 32

                Text {
                    id: titleAR
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Aspect ratio")
                    font.pixelSize: Theme.componentFontSize
                    color: Theme.colorText
                }

                SelectorMenuThemed {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 32

                    model: ListModel {
                        ListElement { idx: 1; txt: "1:1"; src: ""; sz: 0; }
                        ListElement { idx: 2; txt: "4:3"; src: ""; sz: 0; }
                        ListElement { idx: 3; txt: "16:9"; src: ""; sz: 0; }
                    }

                    currentSelection: settingsManager.thumbFormat
                    onMenuSelected: (index) => { settingsManager.thumbFormat = index }
                }

                Text {
                    id: titleSize
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Default size")
                    font.pixelSize: Theme.componentFontSize
                    color: Theme.colorText
                }

                SelectorMenuThemed {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 32

                    model: ListModel {
                        ListElement { idx: 1; txt: qsTr("Small"); src: ""; sz: 0; }
                        ListElement { idx: 2; txt: qsTr("Medium"); src: ""; sz: 0; }
                        ListElement { idx: 3; txt: qsTr("Big"); src: ""; sz: 0; }
                        ListElement { idx: 4; txt: qsTr("Huge"); src: ""; sz: 0; }
                    }

                    currentSelection: settingsManager.thumbSize
                    onMenuSelected: (index) => { settingsManager.thumbSize = index }
                }
            }

            Row {
                height: 40
                spacing: 32

                Text {
                    id: titleQuality
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Quality")
                    font.pixelSize: Theme.componentFontSize
                    color: Theme.colorText
                }

                SelectorMenuThemed {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 32

                    model: ListModel {
                        ListElement { idx: 0; txt: qsTr("Low"); src: ""; sz: 0; }
                        ListElement { idx: 1; txt: qsTr("Balanced"); src: ""; sz: 0; }
                        ListElement { idx: 2; txt: qsTr("High"); src: ""; sz: 0; }
                    }

                    currentSelection: settingsManager.thumbQuality
                    onMenuSelected: (index) => { settingsManager.thumbQuality = index }
                }
            }

            ////////

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                height: 16
                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: -24
                    anchors.right: parent.right
                    anchors.rightMargin: -24
                    anchors.verticalCenter: parent.verticalCenter
                    height: 2
                    opacity: 0.33
                    color: Theme.colorSeparator
                }
            }

            ////////

            Text {
                text: qsTr("Offloading")
                verticalAlignment: Text.AlignVCenter
                color: Theme.colorText
                font.bold: true
                font.pixelSize: Theme.componentFontSize
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

            Item {
                anchors.left: parent.left
                anchors.right: parent.right
                height: 16
                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: -24
                    anchors.right: parent.right
                    anchors.rightMargin: -24
                    anchors.verticalCenter: parent.verticalCenter
                    height: 2
                    opacity: 0.33
                    color: Theme.colorSeparator
                }
            }

            ////////

            Rectangle {
                id: rectangleMedia
                anchors.left: parent.left
                anchors.leftMargin: -24
                anchors.right: parent.right
                anchors.rightMargin: -24

                height: columnMedia.height
                color: storageManager.directoriesCount ? "transparent" : Theme.colorForeground

                Loader {
                    id: fileDialogLoader

                    active: false
                    asynchronous: false
                    sourceComponent: FolderDialog {
                        title: qsTr("Please choose a media directory!")
                        currentFolder: utilsApp.getStandardPath_url("home")

                        onAccepted: {
                            storageManager.addDirectory(UtilsPath.cleanUrl(selectedFolder))
                        }
                    }
                }

                Column {
                    id: columnMedia
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    anchors.right: parent.right
                    anchors.rightMargin: 24

                    topPadding: 0
                    bottomPadding: 24

                    Row {
                        height: 40
                        spacing: 24

                        Text {
                            id: textMediaTitle
                            anchors.verticalCenter: parent.verticalCenter

                            text: qsTr("Media directories")
                            font.pixelSize: Theme.componentFontSize
                            font.bold: true
                            color: Theme.colorText
                        }

                        RoundButtonIcon {
                            id: buttonNew
                            anchors.verticalCenter: parent.verticalCenter

                            source: "qrc:/assets/icons_material/outline-create_new_folder-24px.svg"
                            tooltipText: qsTr("Add a new media directory")
                            tooltipPosition: "right"
                            onClicked: {
                                fileDialogLoader.active = true
                                fileDialogLoader.item.open()
                            }
                        }
                    }

                    ////
/*
                    Row {
                        height: 40
                        spacing: 32

                        Text {
                            id: textMediaHierarchy
                            anchors.verticalCenter: parent.verticalCenter

                            text: qsTr("Default media hierarchy")

                            font.pixelSize: Theme.componentFontSize
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
                                currentIndex = storageManager.contentHierarchy
                                if (currentIndex === -1) { currentIndex = 0 }
                            }
                            property bool cbinit: false
                            onCurrentIndexChanged: {
                                if (cbinit)
                                    storageManager.contentHierarchy = currentIndex
                                else
                                    cbinit = true
                            }
                        }
                    }
*/
                    ////

                    Repeater {
                        id: mediadirectoriesview
                        anchors.left: parent.left
                        anchors.right: parent.right

                        model: storageManager.directoriesList
                        delegate: ItemMediaDirectory {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 52
                            directory: modelData
                        }
                    }

                    ////

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 8

                        visible: !storageManager.directoriesCount

                        Text {
                            id: name
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("There is no media directory configured :(")
                            font.pixelSize: Theme.fontSizeContent
                            color: Theme.colorSubText
                        }

                        ButtonWireframeIcon {
                            height: 36
                            anchors.horizontalCenter: parent.horizontalCenter

                            fullColor: true
                            text: qsTr("Add a new one")
                            onClicked:  {
                                fileDialogLoader.active = true
                                fileDialogLoader.item.open()
                            }
                            source: "qrc:/assets/icons_material/baseline-add-24px.svg"
                        }
                    }
                }
            }

            ////////

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: -24
                anchors.right: parent.right
                anchors.rightMargin: -24
                height: 2
                opacity: 0.33
                color: Theme.colorSeparator
            }
        }
    }
}
