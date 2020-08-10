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
    height: 520
    padding: 24

    signal confirmed()

    property var isGoPro: true
    property var isReadOnly: false

    property string selectedPath: ""

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: Theme.colorBackground
        radius: Theme.componentRadius
    }

    /*contentItem:*/ Item {
        anchors.fill: parent

        Text {
            id: textArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            text: qsTr("Offloading")
            font.pixelSize: 24
            color: Theme.colorText
        }

        /////////

        Column {
            id: column
            anchors.top: textArea.bottom
            anchors.topMargin: 16
            anchors.bottom: rowButtons.top
            anchors.bottomMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0

            Item {
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                visible: isGoPro

                SwitchThemedDesktop {
                    id: switchIgnoreJunk
                    anchors.left: labelIgnoreJunk.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    enabled: false
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

                    enabled: false
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
                anchors.rightMargin: 0
                anchors.leftMargin: 0

                visible: !isReadOnly

                SwitchThemedDesktop {
                    id: switchDelete
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    enabled: false
                    checked: settingsManager.autodelete
                    text: qsTr("Delete offloaded files")
                }
            }
/*
            Rectangle { // separator
                height: 1
                anchors.right: parent.right
                anchors.left: parent.left
                color: Theme.colorSeparator
            }
*/
            Item { // spacer
                height: 16
                anchors.right: parent.right
                anchors.left: parent.left
            }
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
                        target: settingsManager
                        onDirectoriesUpdated: comboBoxDestination.updateDestinations()
                    }

                    function updateDestinations() {
                        cbDestinations.clear()

                        for (var child in settingsManager.directoriesList) {
                            if (settingsManager.directoriesList[child].available &&
                                settingsManager.directoriesList[child].directoryContent !== 1)
                                cbDestinations.append( { "text": settingsManager.directoriesList[child].directoryPath } )
                        }
                        cbDestinations.append( { "text": qsTr("Select path manually") } )

                        comboBoxDestination.currentIndex = 0
                    }

                    property bool cbinit: false
                    onCurrentIndexChanged: {
                        if (settingsManager.directoriesList.length <= 0) return

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
                height: 40
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0

                visible: (comboBoxDestination.currentIndex === (cbDestinations.count - 1))

                FileDialog {
                    id: fileDialogChange
                    title: qsTr("Please choose a destination!")
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

        /////////

        Row {
            id: rowButtons
            height: 40
            spacing: 24
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0

            ButtonWireframe {
                id: buttonCancel
                width: 96
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Cancel")
                primaryColor: Theme.colorPrimary
                onClicked: {
                    popupOffload.close();
                }
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
                    popupOffload.confirmed();
                    popupOffload.close();
                }
            }
        }
    }
}
