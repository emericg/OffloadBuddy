import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Item {
    width: 1280
    height: 720

    Rectangle {
        id: rectangleHeader
        height: 64
        z: 5

        color: Theme.colorHeader
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        Text {
            id: textHeader
            height: 40
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("SETTINGS")
            verticalAlignment: Text.AlignVCenter
            font.bold: true
            font.pixelSize: Theme.fontSizeHeaderTitle
            color: Theme.colorHeaderContent
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    ScrollView {
        id: scrollView
        contentWidth: -1

        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.left: parent.left
        anchors.right: parent.right

        Column {
            anchors.topMargin: 32
            anchors.leftMargin: 32
            anchors.rightMargin: 24
            anchors.fill: parent
            spacing: 8

            ////////

            Row {
                height: 48
                spacing: 32

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Application theme")
                    font.bold: true
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    color: Theme.colorText
                }

                ComboBoxThemed {
                    id: comboBoxAppTheme
                    width: 256
                    height: 40
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
                    font.pixelSize: 16
                    color: Theme.colorText
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                }

                RadioButtonThemed {
                    id: radioButtonMetric
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Metric")
                    font.pixelSize: 16

                    Component.onCompleted: { checked =  (settingsManager.appUnits === 0); }
                    onCheckedChanged: { if (checked === true) { settingsManager.appUnits = 0 }; }
                }

                RadioButtonThemed {
                    id: radioButtonImperial
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Imperial")
                    font.pixelSize: 16

                    Component.onCompleted: { checked =  (settingsManager.appUnits === 1); }
                    onCheckedChanged: { if (checked === true) { settingsManager.appUnits = 1 }; }
                }
            }

            ////////

            Row {
                height: 40
                spacing: 32

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Thumbnail quality")
                    font.bold: true
                    font.pixelSize: 16
                    color: Theme.colorText
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                }

                Row {
                    height: 32
                    anchors.verticalCenter: parent.verticalCenter

                    ItemLilMenuButton {
                        height: parent.height
                        text: qsTr("Low")
                        selected: (settingsManager.thumbQuality === 0)
                        onClicked: settingsManager.thumbQuality = 0
                    }
                    ItemLilMenuButton {
                        height: parent.height
                        text: qsTr("Balanced")
                        selected: (settingsManager.thumbQuality === 1)
                        onClicked: settingsManager.thumbQuality = 1
                    }
                    ItemLilMenuButton {
                        height: parent.height
                        text: qsTr("Ludicrous")
                        selected: (settingsManager.thumbQuality === 2)
                        onClicked: settingsManager.thumbQuality = 2
                    }
                }
            }

            ////////

            Row {
                height: 40
                spacing: 32

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Thumbnail format")
                    font.bold: true
                    font.pixelSize: 16
                    color: Theme.colorText
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                }

                Row {
                    height: 32
                    anchors.verticalCenter: parent.verticalCenter

                    ItemLilMenuButton {
                        height: parent.height
                        text: "1:1"
                        selected: (settingsManager.thumbFormat === 1)
                        onClicked: settingsManager.thumbFormat = 1
                    }
                    ItemLilMenuButton {
                        height: parent.height
                        text: "4:3"
                        selected: (settingsManager.thumbFormat === 2)
                        onClicked: settingsManager.thumbFormat = 2
                    }
                    ItemLilMenuButton {
                        height: parent.height
                        text: "16:9"
                        selected: (settingsManager.thumbFormat === 3)
                        onClicked: settingsManager.thumbFormat = 3
                    }
                    ItemLilMenuButton {
                        height: parent.height
                        text: "2:1"
                        selected: (settingsManager.thumbFormat === 4)
                        onClicked: settingsManager.thumbFormat = 4
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
                font.pixelSize: 16
            }

            Row {
                height: 40
                spacing: 32

                CheckBoxThemed {
                    id: checkIgnoreJunk
                    width: 350
                    height: 40
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Ignore LRVs and THM files")
                    font.bold: false
                    font.pixelSize: 16

                    checked: settingsManager.ignorejunk
                    onCheckStateChanged: settingsManager.ignorejunk = checked
                }

                CheckBoxThemed {
                    id: checkIgnoreAudio
                    width: 350
                    height: 40
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Ignore HD audio files")
                    font.bold: false
                    font.pixelSize: 16

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
                    height: 40
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Automatically delete offloaded medias")
                    font.bold: false
                    font.pixelSize: 16

                    checked: settingsManager.autodelete
                    onCheckStateChanged: settingsManager.autodelete = checked
                }

                CheckBoxThemed {
                    id: checkAutoMerge
                    width: 350
                    height: 40
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Automatically merge video chapters")
                    font.bold: false
                    font.pixelSize: 16
                    enabled: false

                    checked: settingsManager.automerge
                    onCheckStateChanged: settingsManager.automerge = checked
                }

                CheckBoxThemed {
                    id: checkAutoMetadatas
                    width: 350
                    height: 40
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Automatically extract telemetry")
                    font.pixelSize: 16
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

                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    font.pixelSize: 16
                    color: Theme.colorText
                }

                ComboBoxThemed {
                    id: comboBoxContentHierarchy
                    width: 256
                    height: 40
                    anchors.verticalCenter: parent.verticalCenter

                    model: ListModel {
                        id: cbItemsContentHierarchy
                        ListElement { text: qsTr("/ date / FILES"); }
                        ListElement { text: qsTr("/ date / device / FILES"); }
                    }

                    Component.onCompleted: {
                        currentIndex = settingsManager.contenthierarchy;
                        if (currentIndex === -1) { currentIndex = 0 }
                    }
                    property bool cbinit: false
                    onCurrentIndexChanged: {
                        if (cbinit)
                            settingsManager.contenthierarchy = currentIndex;
                        else
                            cbinit = true;
                    }
                }
            }

            ////////

            Column {
                id: rectangleMedias
                spacing: 16

                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                Row {
                    height: 40
                    spacing: 32

                    Text {
                        id: textMediasTitle
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Media directories")
                        font.pixelSize: 16
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        color: Theme.colorText
                    }

                    ItemImageButton {
                        id: buttonNew
                        anchors.verticalCenter: parent.verticalCenter

                        source: "qrc:/icons_material/outline-create_new_folder-24px.svg"
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
                            settingsManager.addDirectory(UtilsPath.cleanUrl(fileDialogAdd.fileUrl))
                        }
                    }
                }

                ListView {
                    id: mediadirectoriesview
                    width: parent.width
                    height: 128 // WHATWHATWWHATHAT
                    interactive: false
                    model: settingsManager.directoriesList
                    delegate: ItemMediaDirectory { directory: modelData; }

                    spacing: 8
                    anchors.left: parent.left
                    anchors.right: parent.right
/*
                    anchors.top: textMediasTitle.bottom
                    anchors.topMargin: 8
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    anchors.left: parent.left
                    anchors.leftMargin: 32
                    anchors.right: parent.right
                    anchors.rightMargin: 32
*/
                }
            }
        }
    }
}
