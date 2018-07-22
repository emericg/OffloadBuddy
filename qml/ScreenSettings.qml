import QtQuick 2.0
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.1

import com.offloadbuddy.style 1.0
import "SpaceUtils.js" as SpaceUtils

Rectangle {
    width: 1280
    height: 720

    property var mySettings

    Rectangle {
        id: rectangleHeader
        height: 64
        color: ThemeEngine.colorHeaderBackground
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        Text {
            id: textHeader
            y: 20
            width: 223
            height: 40
            color: ThemeEngine.colorHeaderTitle
            text: qsTr("SETTINGS")
            verticalAlignment: Text.AlignVCenter
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            font.bold: true
            font.pixelSize: 30
        }
    }

    Rectangle {
        id: rectangleContent
        color: ThemeEngine.colorContentBackground

        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        CheckBox {
            id: checkAutoLaunch
            width: 500
            height: 40
            text: qsTr("Launch OffloadBuddy when a new device is detected?")
            enabled: false
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16

            checked: mySettings.autolaunch
            onCheckStateChanged: {
                mySettings.autolaunch = checked
            }
        }

        CheckBox {
            id: checkIgnoreJunk
            width: 350
            height: 40
            text: qsTr("Ignore LRVs and THM files")
            anchors.top: checkAutoLaunch.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16

            checked: mySettings.ignorejunk
            onCheckStateChanged: {
                mySettings.ignorejunk = checked
            }
        }

        CheckBox {
            id: checkIgnoreAudio
            y: 72
            width: 350
            height: 40
            text: qsTr("Ignore HD audio files")
            anchors.left: checkIgnoreJunk.right
            anchors.leftMargin: 16
            anchors.verticalCenter: checkIgnoreJunk.verticalCenter

            checked: mySettings.ignorehdaudio
            onCheckStateChanged: {
                mySettings.ignorehdaudio = checked
            }
        }


        CheckBox {
            id: checkAutoMerge
            width: 350
            height: 40
            text: qsTr("Automatically merge video chapters")
            anchors.top: checkIgnoreJunk.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16

            checked: mySettings.automerge
            onCheckStateChanged: {
                mySettings.automerge = checked
            }
        }

        CheckBox {
            id: checkAutoMetadatas
            x: 7
            y: 128
            width: 350
            height: 40
            text: qsTr("Automatically extract metadatas")
            anchors.verticalCenter: checkAutoMerge.verticalCenter
            anchors.left: checkAutoMerge.right
            anchors.leftMargin: 16

            checked: mySettings.autometadata
            onCheckStateChanged: {
                mySettings.autometadata = checked
            }
        }

        CheckBox {
            id: checkAutoDelete
            y: 128
            width: 350
            height: 40
            text: qsTr("Automatically delete imported medias")
            anchors.left: checkAutoMetadatas.right
            anchors.leftMargin: 16
            anchors.verticalCenter: checkAutoMetadatas.verticalCenter

            checked: mySettings.autodelete
            onCheckStateChanged: {
                mySettings.autodelete = checked
            }
        }

        Rectangle {
            id: rectangleMedias
            color: ThemeEngine.colorContentBox

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.top: comboBoxContentHierarchy.bottom
            anchors.topMargin: 32
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16

            Text {
                id: textMediasTitle
                y: 10
                width: 300
                height: 40
                text: qsTr("Media directories")
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                anchors.left: parent.left
                anchors.leftMargin: 16
                font.pixelSize: 24
            }

            Button {
                id: buttonNew
                y: 10
                text: qsTr("Add new")
                anchors.left: textMediasTitle.right
                anchors.leftMargin: 16
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
                    mySettings.addDirectory(SpaceUtils.urlToPath(fileDialogAdd.fileUrl.toString()))
                }
            }

            ListView {
                id: mediadirectoriesview
                width: parent.width
                height: 64
                interactive: false
                model: mySettings.directoriesList
                delegate: ItemMediaDirectory { settingsMgr: mySettings;
                                               directory: modelData }

                spacing: 16
                anchors.top: textMediasTitle.bottom
                anchors.topMargin: 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 16
            }
        }

        ComboBox {
            id: comboBoxContentHierarchy
            y: 174
            width: 350
            height: 40
            anchors.verticalCenter: text4.verticalCenter
            anchors.left: text4.right
            anchors.leftMargin: 15

            model: ListModel {
                id: cbItemsContentHierarchy
                ListElement { text: qsTr("date"); }
                ListElement { text: qsTr("model > date"); }
                ListElement { text: qsTr("brand > model > date"); }
            }
            Component.onCompleted: {
                currentIndex = mySettings.contenthierarchy;
                if (currentIndex === -1) { currentIndex = 0 }
            }
            property bool cbinit: false
            onCurrentIndexChanged: {
                if (cbinit)
                    mySettings.contenthierarchy = currentIndex;
                else
                    cbinit = true;
            }
        }

        Text {
            id: text4
            width: 150
            height: 40
            text: qsTr("Import hierarchy:")
            anchors.top: checkAutoMerge.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 24
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: 14
        }
    }
}
