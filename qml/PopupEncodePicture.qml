import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Popup {
    id: popupEncodePicture
    width: 640
    height: 400
    padding: 24

    signal confirmed()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: Theme.colorBackground
        radius: Theme.componentRadius
    }

    /*contentItem:*/ Item {
        id: element
        anchors.fill: parent

        Text {
            id: textArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            text: qsTr("(Re)Encode picture")
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
                id: element1
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                Text {
                    id: rectangleCodec
                    width: 128
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Format")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: rectangleCodec.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    spacing: 16

                    RadioButtonThemed {
                        id: rbPNG
                        text: "PNG"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    RadioButtonThemed {
                        id: rbJPEG
                        text: "JPEG"
                        checked: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    RadioButtonThemed {
                        id: rbWEBP
                        text: "WebP"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    RadioButtonThemed {
                        id: rbAVIF
                        text: "AVIF"
                        anchors.verticalCenter: parent.verticalCenter
                        visible: false
                    }
                    RadioButtonThemed {
                        id: rbHEIF
                        text: "HEIF"
                        anchors.verticalCenter: parent.verticalCenter
                        visible: false
                    }
                }
            }

            Item {
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                visible: !rbPNG.checked

                Text {
                    id: element2
                    width: 128
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Quality")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                SliderThemed {
                    id: slider
                    anchors.left: element2.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    from: 5
                    to: 10
                    stepSize: 1
                    value: 8
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
                    popupEncodePicture.close();
                }
            }
            ButtonWireframeImage {
                id: buttonEncode
                width: 128
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Encode")
                source: "qrc:/icons_material/baseline-memory-24px.svg"
                fullColor: true
                primaryColor: Theme.colorPrimary
                onClicked: {
                    popupEncodePicture.confirmed();
                    popupEncodePicture.close();
                }
            }
        }
    }
}
