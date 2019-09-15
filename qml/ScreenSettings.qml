import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2

import com.offloadbuddy.theme 1.0
import "UtilsString.js" as UtilsString
import "UtilsPath.js" as UtilsPath

Item {
    width: 1280
    height: 720

    Rectangle {
        id: rectangleHeader
        height: 64
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

    ScrollView {
        id: scrollView
        contentWidth: -1

        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.left: parent.left
        anchors.right: parent.right

        Item {
            id: rectangleContent
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            CheckBoxThemed {
                id: checkIgnoreJunk
                width: 350
                height: 40
                anchors.top: text3.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 32

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
                anchors.left: checkIgnoreJunk.right
                anchors.leftMargin: 16
                anchors.verticalCenter: checkIgnoreJunk.verticalCenter

                text: qsTr("Ignore HD audio files")
                font.bold: false
                font.pixelSize: 16

                checked: settingsManager.ignorehdaudio
                onCheckStateChanged: settingsManager.ignorehdaudio = checked
            }

            CheckBoxThemed {
                id: checkAutoMerge
                width: 350
                height: 40
                anchors.top: checkIgnoreJunk.bottom
                anchors.topMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 32

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
                anchors.verticalCenter: checkAutoMerge.verticalCenter
                anchors.left: checkAutoMerge.right
                anchors.leftMargin: 16

                text: qsTr("Automatically extract telemetry")
                font.pixelSize: 16
                enabled: false

                checked: settingsManager.autometadata
                onCheckStateChanged: settingsManager.autometadata = checked
            }

            CheckBoxThemed {
                id: checkAutoDelete
                y: 128
                width: 350
                height: 40
                anchors.left: checkAutoMetadatas.right
                anchors.leftMargin: 16
                anchors.verticalCenter: checkAutoMetadatas.verticalCenter

                text: qsTr("Automatically delete offloaded medias")
                font.bold: false
                font.pixelSize: 16

                checked: settingsManager.autodelete
                onCheckStateChanged: settingsManager.autodelete = checked
            }

            Text {
                id: text1
                height: 40
                anchors.top: parent.top
                anchors.topMargin: 32
                anchors.left: parent.left
                anchors.leftMargin: 32

                text: qsTr("Application theme")
                font.bold: true
                font.pixelSize: 16
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                color: Theme.colorText
            }

            Text {
                id: text3
                height: 40
                anchors.top: text2.bottom
                anchors.topMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 32

                text: qsTr("Offloading")
                verticalAlignment: Text.AlignVCenter
                color: Theme.colorText
                font.bold: true
                font.pixelSize: 16
            }

            Text {
                id: text2
                height: 40
                anchors.top: text1.bottom
                anchors.topMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 32

                text: qsTr("Unit system")
                font.bold: true
                font.pixelSize: 16
                color: Theme.colorText
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
            }

            ComboBoxThemed {
                id: comboBoxAppTheme
                width: 256
                height: 40
                anchors.left: text1.right
                anchors.leftMargin: 32
                anchors.verticalCenter: text1.verticalCenter

                model: ListModel {
                    id: cbAppTheme
                    ListElement { text: "LIGHT AND WARM"; }
                    ListElement { text: "DARK AND SPOOKY"; }
                    ListElement { text: "PLAIN AND BORING"; }
                    ListElement { text: "BLOOD AND TEARS"; }
                    ListElement { text: "MIGHTY KITTENS"; }
                }

                Component.onCompleted: {
                    currentIndex = settingsManager.apptheme;
                    if (currentIndex === -1) { currentIndex = 0 }
                }
                property bool cbinit: false
                onCurrentIndexChanged: {
                    if (cbinit)
                        settingsManager.apptheme = currentIndex;
                    else
                        cbinit = true;
                }
            }

            RadioButtonThemed {
                id: radioButtonMetric
                text: qsTr("Metric")
                font.pixelSize: 16
                anchors.left: text2.right
                anchors.leftMargin: 16
                anchors.verticalCenter: text2.verticalCenter

                Component.onCompleted: {
                    if (settingsManager.appunits === 0) {checked = true; }
                }
                onCheckedChanged: {
                    if (checked === true) {
                        settingsManager.appunits = 0
                        settingsManager.changeAppUnits()
                    }
                }
            }

            RadioButtonThemed {
                id: radioButtonImperial
                anchors.left: radioButtonMetric.right
                anchors.leftMargin: 16
                anchors.verticalCenter: text2.verticalCenter

                text: qsTr("Imperial")
                font.pixelSize: 16

                Component.onCompleted: {
                    if (settingsManager.appunits === 1) {checked = true; }
                }
                onCheckedChanged: {
                    if (checked === true) {
                        settingsManager.appunits = 1
                        settingsManager.changeAppUnits()
                    }
                }
            }

            ComboBoxThemed {
                id: comboBoxContentHierarchy
                width: 256
                height: 40
                anchors.left: textMediaHierarchy.right
                anchors.leftMargin: 30
                anchors.verticalCenter: textMediaHierarchy.verticalCenter

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

            Text {
                id: textMediaHierarchy
                height: 40
                text: qsTr("Media hierarchy")
                anchors.top: checkAutoMerge.bottom
                anchors.topMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 32
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: 16
                color: Theme.colorText
            }

            Item {
                id: rectangleMedias

                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0
                anchors.top: textMediaHierarchy.bottom
                anchors.topMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                Text {
                    id: textMediasTitle
                    height: 40
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    anchors.left: parent.left
                    anchors.leftMargin: 32

                    text: qsTr("Media directories")
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    color: Theme.colorText
                }

                ItemImageButton {
                    id: buttonNew
                    anchors.left: textMediasTitle.right
                    anchors.leftMargin: 32
                    anchors.verticalCenter: textMediasTitle.verticalCenter

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

                ListView {
                    id: mediadirectoriesview
                    width: parent.width
                    //height: 64
                    interactive: false
                    model: settingsManager.directoriesList
                    delegate: ItemMediaDirectory { directory: modelData; }

                    spacing: 8
                    anchors.top: textMediasTitle.bottom
                    anchors.topMargin: 8
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    anchors.left: parent.left
                    anchors.leftMargin: 32
                    anchors.right: parent.right
                    anchors.rightMargin: 32
                }
            }
        }
    }
}
