import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Popup {
    id: popupExtractTelemetry
    x: (appWindow.width / 2) - (width / 2) - (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 640
    padding: 0

    signal confirmed()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    ////////////////////////////////////////////////////////////////////////////

    property var mediaProvider: null
    property var currentShot: null

    function updateTelemetryPanel(shot) {
        currentShot = shot

        // TODO
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

                text: qsTr("Extract telemetry")
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: "white"
            }
        }

        //////////////////

        Column {
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.left: parent.left
            anchors.leftMargin: 24

            Item {
                id: elementGPS
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                Text {
                    id: titleGPS
                    width: 128
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("GPS trace")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                Row {
                    anchors.left: titleGPS.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    RadioButtonThemed {
                        id: rbGPX
                        anchors.verticalCenter: parent.verticalCenter
                        text: "GPX"
                        checked: true
                    }
                    RadioButtonThemed {
                        id: rbIGC
                        anchors.verticalCenter: parent.verticalCenter
                        text: "IGC"
                    }
                    RadioButtonThemed {
                        id: rbKML
                        anchors.verticalCenter: parent.verticalCenter
                        text: "KML"
                    }
                }
            }

            Item {
                id: elementAltitude
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                Text {
                    id: titleAltitude
                    width: 128
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Altitude")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                SwitchThemedDesktop {
                    id: switchEGM96
                    anchors.left: titleAltitude.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    checked: true
                    text: qsTr("EGM96 correction")
                }
            }

            Item {
                id: elementTelemetry
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                Text {
                    id: titleTelemetry
                    width: 128
                    anchors.verticalCenter: parent.verticalCenter

                    text: qsTr("Telemetry")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: titleTelemetry.right
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    spacing: 16

                    RadioButtonThemed {
                        id: rbJSON
                        anchors.verticalCenter: parent.verticalCenter
                        text: "JSON"
                        checked: true
                    }
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
                        ListElement { text: qsTr("Next to the video file"); }
                        ListElement { text: qsTr("Select path manually"); }
                    }

                    model: cbDestinations

                    property bool cbinit: false
                    onCurrentIndexChanged: {
                        if (currentShot) textField_path.text = currentShot.getFolderString()

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

                    text: qsTr("change")
                    embedded: true
                    onClicked: {
                        fileDialogChange.folder =  "file:///" + textField_path.text
                        fileDialogChange.open()
                    }
                }
            }
        }

        ////////////////

        Row {
            id: rowButtons
            height: Theme.componentHeight*2 + parent.spacing
            anchors.right: parent.right
            anchors.rightMargin: 24
            spacing: 16

            ButtonWireframe {
                id: buttonCancel
                width: 96
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Cancel")
                fullColor: true
                primaryColor: Theme.colorGrey
                onClicked: popupExtractTelemetry.close()
            }
            ButtonWireframeImage {
                id: buttonExtractTelemetry
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Extract telemetry")
                source: "qrc:/assets/icons_material/baseline-insert_chart-24px.svg"
                fullColor: true
                primaryColor: Theme.colorSecondary
                onClicked: {
                    popupExtractTelemetry.confirmed()
                    popupExtractTelemetry.close()
                }
            }
            ButtonWireframeImage {
                id: buttonExtractGps
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Extract GPS")
                source: "qrc:/assets/icons_material/baseline-map-24px.svg"
                fullColor: true
                primaryColor: Theme.colorPrimary
                onClicked: {
                    popupExtractTelemetry.confirmed()
                    popupExtractTelemetry.close()
                }
            }
        }
    }
}
