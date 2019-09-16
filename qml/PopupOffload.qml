import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2

import com.offloadbuddy.theme 1.0
import "UtilsString.js" as UtilsString
import "UtilsPath.js" as UtilsPath

Popup {
    id: popupOffload
    width: 640
    height: 480
    padding: 24

    signal confirmed()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: Theme.colorBackground
        radius: 2
    }

    /*contentItem:*/ Item {
        id: element
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

                Text {
                    id: labelIgnoreJunk
                    width: 128
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Ignore LRVs and THM files")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }
            }

            Item {
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.leftMargin: 0

                Text {
                    id: labelIgnoreAudio
                    width: 128
                    color: Theme.colorSubText
                    text: qsTr("Ignore HD Audio files")
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 16
                }
            }

            Item {
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                Text {
                    id: labelMerge
                    width: 128
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Merge chaptered files")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }
            }

            Item {
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 0
                anchors.rightMargin: 0

                Text {
                    id: labelMetadatas
                    width: 128
                    color: Theme.colorSubText
                    text: qsTr("Extract metadatas")
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 16
                }
            }

            Item {
                height: 48
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.leftMargin: 0

                Text {
                    id: labelDelete
                    width: 128
                    color: Theme.colorSubText
                    text: qsTr("Delete offloaded files")
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 16
                }
            }

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

                    Component.onCompleted: updateDestinations()
                    function updateDestinations() {
                        cbDestinations.clear()

                        for (var child in settingsManager.directoriesList) {
                            if (settingsManager.directoriesList[child].available &&
                                settingsManager.directoriesList[child].directoryContent !== 1)
                                cbDestinations.append( { "text": settingsManager.directoriesList[child].directoryPath } )
                        }
                        cbDestinations.append( { "text": qsTr("Select path manually") } )

                        comboBoxDestination.currentIndex = 0
                        textField_path.text = settingsManager.directoriesList[0].directoryPath
                    }

                    property bool cbinit: false
                    onCurrentIndexChanged: {
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
                //text: directory.directoryPath

                onVisibleChanged: {
                    //
                }

                FileDialog {
                    id: fileDialogChange
                    title: qsTr("Please choose a destination!")
                    sidebarVisible: true
                    selectExisting: true
                    selectMultiple: false
                    selectFolder: false

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

                    //imageSource: "qrc:/icons_material/outline-folder-24px.svg"
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
                width: 128
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Offload")
                source: "qrc:/icons_material/baseline-archive-24px.svg"
                fullColor: true
                primaryColor: Theme.colorPrimary
                onClicked: {
                    popupOffload.confirmed();
                    popupOffload.close();
                }
            }
        }
    }
}
