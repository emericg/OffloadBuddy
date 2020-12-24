import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Popup {
    id: popupOffload
    x: (appWindow.width / 2) - (width / 2) - (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 640
    padding: 0

    signal confirmed()

    property var isGoPro: true
    property var isReadOnly: false

    property string selectedPath: ""

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Component.onCompleted: {
        switchIgnoreJunk.checked = settingsManager.ignorejunk
        switchIgnoreAudio.checked = settingsManager.ignorehdaudio
        switchMerge.checked = settingsManager.automerge
        switchMetadata.checked = settingsManager.autometadata
        switchDelete.checked = settingsManager.autodelete
    }

    Connections {
        target: settingsManager
        onIgnoreJunkChanged: switchIgnoreJunk.checked = settingsManager.ignorejunk
        onIgnoreHdAudioChanged: switchIgnoreAudio.checked = settingsManager.ignorehdaudio
        onAutoMergeChanged: switchMerge.checked = settingsManager.automerge
        onAutoMetadataChanged: switchMetadata.checked = settingsManager.autometadata
        onAutoDeleteChanged: switchDelete.checked = settingsManager.autodelete
    }

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: Theme.colorBackground
        radius: Theme.componentRadius
    }

    contentItem: Column {
        spacing: 16

        Rectangle {
            id: titleArea
            height: 64
            anchors.left: parent.left
            anchors.right: parent.right
            radius: Theme.componentRadius
            color: ThemeEngine.colorPrimary

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Offloading")
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: "white"
            }
        }

        ////////////////

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24

            Item {
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right

                visible: isGoPro

                SwitchThemedDesktop {
                    id: switchIgnoreJunk
                    anchors.left: labelIgnoreJunk.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    enabled: true
                    checked: settingsManager.ignorejunk
                    text: qsTr("Ignore LRVs and THM files")
                }
            }

            Item {
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right

                visible: isGoPro

                SwitchThemedDesktop {
                    id: switchIgnoreAudio
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    enabled: true
                    checked: settingsManager.ignorehdaudio
                    text: qsTr("Ignore HD Audio files")
                }
            }

            Item {
                height: 48
                anchors.right: parent.right
                anchors.left: parent.left

                visible: isGoPro

                SwitchThemedDesktop {
                    id: switchMerge
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    enabled: false
                    checked: settingsManager.automerge
                    text: qsTr("Merge chaptered files together")
                }
            }

            Item {
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right

                visible: isGoPro

                SwitchThemedDesktop {
                    id: switchMetadata
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    enabled: false
                    checked: settingsManager.autometadata
                    text: qsTr("Extract telemetry along with each shot")
                }
            }

            Item {
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right

                visible: !isReadOnly

                SwitchThemedDesktop {
                    id: switchDelete
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    enabled: true
                    checked: settingsManager.autodelete
                    text: qsTr("Delete offloaded files")
                }
            }

            //////////////////
/*
            Rectangle {
                height: 1; color: Theme.colorSeparator;
                anchors.right: parent.right; anchors.left: parent.left;
            } // separator
*/
            Item { height: 16; anchors.right: parent.right; anchors.left: parent.left; } // spacer

            Item {
                id: rectangleDestination
                height: 48
                anchors.right: parent.right
                anchors.left: parent.left

                Text {
                    id: textDestinationTitle
                    width: 128
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Destination")
                    color: Theme.colorSubText
                    font.pixelSize: 16
                }

                ComboBoxThemed {
                    id: comboBoxDestination
                    anchors.left: textDestinationTitle.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    ListModel {
                        id: cbDestinations
                        //ListElement { text: "auto"; }
                    }

                    model: cbDestinations

                    Component.onCompleted: comboBoxDestination.updateDestinations()
                    Connections {
                        target: storageManager
                        onDirectoriesUpdated: comboBoxDestination.updateDestinations()
                    }

                    function updateDestinations() {
                        cbDestinations.clear()

                        for (var child in storageManager.directoriesList) {
                            if (storageManager.directoriesList[child].available &&
                                storageManager.directoriesList[child].directoryContent !== 1)
                                cbDestinations.append( { "text": storageManager.directoriesList[child].directoryPath } )
                        }
                        cbDestinations.append( { "text": qsTr("Select path manually") } )

                        comboBoxDestination.currentIndex = 0
                    }

                    property bool cbinit: false
                    onCurrentIndexChanged: {
                        if (storageManager.directoriesList.length <= 0) return

                        if (comboBoxDestination.currentIndex < cbDestinations.count)
                            textField_path.text = comboBoxDestination.displayText

                        if (cbinit) {
                            if (comboBoxDestination.currentIndex === cbDestinations.count) {
                                //
                            }
                        } else {
                            cbinit = true;
                        }
                    }
                }
            }

            TextFieldThemed {
                id: textField_path
                anchors.left: parent.left
                anchors.right: parent.right

                visible: (comboBoxDestination.currentIndex === (cbDestinations.count - 1))

                FileDialog {
                    id: fileDialogChange
                    title: qsTr("Please choose a destination directory!")
                    sidebarVisible: true
                    selectExisting: true
                    selectMultiple: false
                    selectFolder: true

                    onAccepted: {
                        textField_path.text = UtilsPath.cleanUrl(fileDialogChange.fileUrl);
                    }
                }

                ButtonThemed {
                    id: button_change
                    width: 72
                    height: 36
                    anchors.right: parent.right
                    anchors.rightMargin: 2
                    anchors.verticalCenter: parent.verticalCenter

                    embedded: true
                    text: qsTr("change")
                    onClicked: {
                        fileDialogChange.folder =  "file:///" + textField_path.text
                        fileDialogChange.open()
                    }
                }
            }
        }

        //////////////////

        Row {
            id: rowButtons
            height: Theme.componentHeight*2 + parent.spacing
            anchors.right: parent.right
            anchors.rightMargin: 24
            spacing: 24

            ButtonWireframe {
                id: buttonCancel
                width: 96
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Cancel")
                fullColor: true
                primaryColor: Theme.colorGrey
                onClicked: popupOffload.close()
            }
            ButtonWireframeImage {
                id: buttonOffload
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Offload")
                source: "qrc:/assets/icons_material/baseline-archive-24px.svg"
                fullColor: true
                primaryColor: Theme.colorPrimary
                onClicked: {
                    popupOffload.selectedPath = textField_path.text
                    popupOffload.confirmed()
                    popupOffload.close()
                }
            }
        }
    }
}
