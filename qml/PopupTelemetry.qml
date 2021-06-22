import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Popup {
    id: popupTelemetry
    x: (appWindow.width / 2) - (width / 2) - (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 720
    padding: 0

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    signal confirmed()

    ////////////////////////////////////////////////////////////////////////////

    property int popupMode: 0

    property var shots: []
    property var files: []
    property bool fileRecapOpened: false
    property bool fileRecapEnabled: true

    property var mediaProvider: null
    property var currentShot: null

    property string outputPath: ""
    property var outputSettings: null

    ////////

    function open() { return; }

    function openSingle(shot) {
        popupMode = 1
        shots = []
        files = []
        fileRecapEnabled = false
        fileRecapOpened = false
        mediaProvider = null
        currentShot = shot

        visible = true
    }

    function openSelection() {
        popupMode = 2
        if (shots.length === 0) return
        fileRecapEnabled = true
        fileRecapOpened = false
        mediaProvider = null
        currentShot = null

        visible = true
    }

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: fileRecapOpened ? ThemeEngine.colorForeground : ThemeEngine.colorBackground
        radius: Theme.componentRadius
        border.width: 1
        border.color: Theme.colorSeparator
    }

    ////////////////////////////////////////////////////////////////////////////

    contentItem: Column {
        spacing: 0

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

        ////////////////

        Rectangle {
            id: filesArea
            height: 48
            anchors.left: parent.left
            anchors.right: parent.right
            color: ThemeEngine.colorForeground

            visible: shots.length

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 48+16+16
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("%n shot(s) selected", "", shots.length)
                font.pixelSize: Theme.fontSizeContent
            }

            ItemImageButton {
                width: 48
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                source: "qrc:/assets/icons_material/baseline-navigate_next-24px.svg"
                rotation: fileRecapOpened ? -90 : 90
                onClicked: fileRecapOpened = !fileRecapOpened
            }
        }

        ////////////////

        Item {
            id: contentArea
            height: columnTelemetry.height
            anchors.left: parent.left
            anchors.right: parent.right

            ////////

            ListView {
                id: listArea
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24

                visible: fileRecapOpened

                model: shots
                delegate: Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: modelData
                    font.pixelSize: 14
                    elide: Text.ElideLeft
                    color: Theme.colorSubText
                }
            }

            ////////

            Column {
                id: columnTelemetry
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 24
                topPadding: 16
                bottomPadding: 16

                visible: !fileRecapOpened

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
                        enabled: false
                        text: qsTr("EGM96 correction")
                    }
                }

                Item {
                    id: elementGPS
                    height: 48
                    anchors.left: parent.left                    
                    anchors.right: parent.right

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
                            text: "GPX"
                            checked: true
                        }
                        RadioButtonThemed {
                            id: rbIGC
                            text: "IGC"
                            enabled: false
                        }
                        RadioButtonThemed {
                            id: rbKML
                            text: "KML"
                            enabled: false
                        }
                    }
                }

                Item {
                    id: elementTelemetry
                    height: 48
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Text {
                        id: titleTelemetry
                        width: 128
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Telemetry")
                        font.pixelSize: 16
                        color: Theme.colorSubText
                    }

                    Row {
                        anchors.left: titleTelemetry.right
                        anchors.leftMargin: 16
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16

                        RadioButtonThemed {
                            id: rbJSON
                            text: "JSON"
                            checked: true
                        }
                        RadioButtonThemed {
                            id: rbCSV
                            text: "CSV"
                            enabled: false
                        }
                    }
                }

                ////////////////
    /*
                Rectangle { // separator
                    height: 1; color: Theme.colorSeparator;
                    anchors.right: parent.right; anchors.left: parent.left; }
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

                Item {
                    height: 48
                    anchors.right: parent.right
                    anchors.left: parent.left

                    visible: (comboBoxDestination.currentIndex === (cbDestinations.count - 1))

                    TextFieldThemed {
                        id: textField_path
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter

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
                onClicked: popupTelemetry.close()
            }
            ButtonWireframeImage {
                id: buttonExtractTelemetry
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Extract telemetry")
                source: "qrc:/assets/icons_material/baseline-insert_chart-24px.svg"
                fullColor: true
                primaryColor: Theme.colorSecondary

                onClicked: {
                    if (currentShot) currentShot.exportTelemetry(textField_path.text, 0, 30, 2, switchEGM96.checked)
                    popupTelemetry.confirmed()
                    popupTelemetry.close()
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
                    if (currentShot) currentShot.exportGps(textField_path.text, 0, 2, switchEGM96.checked)
                    popupTelemetry.confirmed()
                    popupTelemetry.close()
                }
            }
        }
    }
}
