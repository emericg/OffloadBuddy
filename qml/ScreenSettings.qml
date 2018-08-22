import QtQuick 2.10
import QtQuick.Dialogs 1.1
import QtQuick.Controls 2.3

import com.offloadbuddy.style 1.0
import "StringUtils.js" as StringUtils

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
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("SETTINGS")
            verticalAlignment: Text.AlignVCenter
            font.bold: true
            font.pixelSize: ThemeEngine.fontSizeHeaderTitle
            color: ThemeEngine.colorHeaderTitle
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
            anchors.top: text1.bottom
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
            enabled: false
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
            enabled: false
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
            font.pixelSize: ThemeEngine.fontSizeContentText

            anchors.left: checkAutoMetadatas.right
            anchors.leftMargin: 16
            anchors.verticalCenter: checkAutoMetadatas.verticalCenter

            checked: mySettings.autodelete
            onCheckStateChanged: {
                mySettings.autodelete = checked
            }
        }

        ComboBox {
            id: comboBoxContentHierarchy
            y: 174
            width: 256
            height: 40
            anchors.verticalCenter: text4.verticalCenter
            anchors.left: text4.right
            anchors.leftMargin: 32

            model: ListModel {
                id: cbItemsContentHierarchy
                ListElement { text: qsTr("/ date / FILES"); }
                ListElement { text: qsTr("/ date / device / FILES"); }
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
            height: 40
            anchors.top: checkAutoMerge.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 24
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            text: qsTr("Import hierarchy:")
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText
        }

        Text {
            id: text1
            y: 8
            height: 40
            text: qsTr("Application theme:")
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            anchors.left: parent.left
            anchors.leftMargin: 16
            font.pixelSize: ThemeEngine.fontSizeContentText
            color: ThemeEngine.colorContentText
        }

        ComboBox {
            id: comboBoxAppTheme
            y: 18
            width: 256
            height: 40
            anchors.left: text1.right
            anchors.leftMargin: 32
            anchors.verticalCenter: text1.verticalCenter

            model: ListModel {
                id: cbAppTheme
                ListElement { text: "PLAIN AND BORING"; }
                ListElement { text: "DARK AND SPOOKY"; }
                ListElement { text: "MIGHTY KITTEN"; }
            }

            Component.onCompleted: {
                currentIndex = mySettings.apptheme;
                if (currentIndex === -1) { currentIndex = 0 }
            }
            property bool cbinit: false
            onCurrentIndexChanged: {
                if (cbinit)
                    mySettings.apptheme = currentIndex;
                else
                    cbinit = true;

                ThemeEngine.loadTheme(currentIndex)
            }
        }

        Rectangle {
            id: rectangleMedias
            radius: 4
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
                height: 40
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 16

                text: qsTr("Media directories")
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentTitle
                color: ThemeEngine.colorContentTitle
            }

            Button {
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
                    mySettings.addDirectory(StringUtils.urlToPath(fileDialogAdd.fileUrl.toString()))
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
    }
}
