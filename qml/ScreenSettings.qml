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

    Item {
        id: rectangleContent

        anchors.top: rectangleHeader.bottom
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
            text: qsTr("Ignore LRVs and THM files")
            font.bold: false
            font.pixelSize: 16
            anchors.top: text1.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 32

            checked: settingsManager.ignorejunk
            onCheckStateChanged: {
                settingsManager.ignorejunk = checked
            }
        }

        CheckBoxThemed {
            id: checkIgnoreAudio
            width: 350
            height: 40
            text: qsTr("Ignore HD audio files")
            font.bold: false
            font.pixelSize: 16
            anchors.left: checkIgnoreJunk.right
            anchors.leftMargin: 16
            anchors.verticalCenter: checkIgnoreJunk.verticalCenter

            checked: settingsManager.ignorehdaudio
            onCheckStateChanged: {
                settingsManager.ignorehdaudio = checked
            }
        }

        CheckBoxThemed {
            id: checkAutoMerge
            width: 350
            height: 40
            text: qsTr("Automatically merge video chapters")
            font.bold: false
            font.pixelSize: 16
            enabled: false
            anchors.top: checkIgnoreJunk.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 32

            checked: settingsManager.automerge
            onCheckStateChanged: {
                settingsManager.automerge = checked
            }
        }

        CheckBoxThemed {
            id: checkAutoMetadatas
            width: 350
            height: 40
            text: qsTr("Automatically extract telemetry")
            font.pixelSize: 16
            enabled: false
            anchors.verticalCenter: checkAutoMerge.verticalCenter
            anchors.left: checkAutoMerge.right
            anchors.leftMargin: 16

            checked: settingsManager.autometadata
            onCheckStateChanged: {
                settingsManager.autometadata = checked
            }
        }

        CheckBoxThemed {
            id: checkAutoDelete
            y: 128
            width: 350
            height: 40
            text: qsTr("Automatically delete offloaded medias")
            font.bold: false
            font.pixelSize: 16

            anchors.left: checkAutoMetadatas.right
            anchors.leftMargin: 16
            anchors.verticalCenter: checkAutoMetadatas.verticalCenter

            checked: settingsManager.autodelete
            onCheckStateChanged: {
                settingsManager.autodelete = checked
            }
        }

        Text {
            id: text4
            height: 40
            anchors.top: checkAutoMerge.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 32
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            text: qsTr("Unit system")
            font.bold: true
            font.pixelSize: 16
            color: Theme.colorText
        }

        Text {
            id: text1
            height: 40
            text: qsTr("Application theme")
            font.bold: true
            font.pixelSize: 16
            anchors.top: parent.top
            anchors.topMargin: 32
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            anchors.left: parent.left
            anchors.leftMargin: 32
            color: Theme.colorText
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
                ListElement { text: "PLAIN AND BORING"; }
                ListElement { text: "DARK AND SPOOKY"; }
                ListElement { text: "BLOOD AND TEARS"; }
                ListElement { text: "MIGHTY KITTEN"; }
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

                Theme.loadTheme(currentIndex)
            }
        }

        RadioButtonThemed {
            id: radioButtonMetric
            text: qsTr("Metric")
            font.pixelSize: 16
            anchors.left: text4.right
            anchors.leftMargin: 16
            anchors.verticalCenter: text4.verticalCenter

            Component.onCompleted: {
                if (settingsManager.appunits === 0)
                    checked = true;
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
            text: qsTr("Imperial")
            font.pixelSize: 16
            anchors.left: radioButtonMetric.right
            anchors.leftMargin: 16
            anchors.verticalCenter: text4.verticalCenter

            Component.onCompleted: {
                if (settingsManager.appunits === 1)
                    checked = true;
            }
            onCheckedChanged: {
                if (checked === true) {
                    settingsManager.appunits = 1
                    settingsManager.changeAppUnits()
                }
            }
        }

        Item {
            id: rectangleMedias

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            anchors.top: text4.bottom
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

            ButtonThemed {
                id: buttonNew
                text: qsTr("Add new")
                anchors.left: textMediasTitle.right
                anchors.leftMargin: 32
                anchors.verticalCenter: textMediasTitle.verticalCenter
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
                height: 64
                interactive: false
                model: settingsManager.directoriesList
                delegate: ItemMediaDirectory { settingsMgr: settingsManager;
                                               directory: modelData }

                spacing: 16
                anchors.top: textMediasTitle.bottom
                anchors.topMargin: 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.right: parent.right
                anchors.rightMargin: 32
            }

            ComboBoxThemed {
                id: comboBoxContentHierarchy
                width: 256
                height: 40
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: text2.verticalCenter

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
                id: text2
                text: qsTr("Media hierarchy:")
                font.bold: true
                font.pixelSize: 16
                anchors.right: comboBoxContentHierarchy.left
                anchors.rightMargin: 16
                anchors.verticalCenter: textMediasTitle.verticalCenter
                color: Theme.colorText
            }
        }
    }
}
