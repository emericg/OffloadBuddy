import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Popup {
    id: popupMove
    x: (appWindow.width / 2) - (width / 2) - (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 720
    padding: 0

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    signal confirmed()

    ////////

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

    function openAll() {
        popupMode = 3
        shots = []
        files = []
        fileRecapEnabled = false
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

                text: qsTr("Move")
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
            height: columnMove.height
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
                id: columnMove
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 24
                topPadding: 16
                bottomPadding: 16

                visible: !fileRecapOpened

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
                onClicked: popupMove.close()
            }
            ButtonWireframeImage {
                id: buttonOffload
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Move")
                source: "qrc:/assets/icons_material/baseline-archive-24px.svg"
                fullColor: true
                primaryColor: Theme.colorPrimary

                onClicked: {
                    popupMove.outputPath = textField_path.text
                    popupMove.confirmed()
                    popupMove.close()
                }
            }
        }
    }
}
