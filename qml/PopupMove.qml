import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3 // Qt5

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
    property bool recapEnabled: true
    property bool recapOpened: false

    property var uuids: []
    property var shots: []
    property var files: []

    property var mediaProvider: null
    property var currentShot: null

    ////////

    function open() { return; }

    function openSingle(provider, shot) {
        popupMode = 1
        recapEnabled = false
        recapOpened = false
        uuids = []
        shots = []
        files = []
        mediaProvider = provider
        currentShot = shot

        visible = true
    }

    function openSelection(provider) {
        if (uuids.length === 0 || shots.length === 0) return

        popupMode = 2
        recapEnabled = true
        recapOpened = false
        files = []
        mediaProvider = provider
        currentShot = null

        visible = true
    }

    ////////////////////////////////////////////////////////////////////////////

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.5; to: 1.0; duration: 133; } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 233; } }

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: recapOpened ? Theme.colorForeground : Theme.colorBackground
        radius: Theme.componentRadius
        border.width: Theme.componentBorderWidth
        border.color: Theme.colorForeground
    }

    ////////////////////////////////////////////////////////////////////////////

    contentItem: Column {
        spacing: 0

        Rectangle {
            id: titleArea
            anchors.left: parent.left
            anchors.right: parent.right

            height: 64
            color: Theme.colorPrimary
            radius: Theme.componentRadius

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 1
                anchors.right: parent.right
                anchors.rightMargin: 0
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
            anchors.left: parent.left
            anchors.leftMargin: 1
            anchors.right: parent.right
            anchors.rightMargin: 0

            z: 1
            height: 48
            visible: shots.length
            color: Theme.colorForeground

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 48+16+16
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("%n shot(s) selected", "", shots.length)
                color: Theme.colorText
                font.pixelSize: Theme.fontSizeContent
            }

            ItemImageButton {
                width: 48
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                source: "qrc:/assets/icons_material/baseline-navigate_next-24px.svg"
                rotation: recapOpened ? -90 : 90
                onClicked: recapOpened = !recapOpened
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

                visible: recapOpened

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

                visible: !recapOpened

                Item { width: 16; height: 16; } // spacer

                Item {
                    id: rectangleDestination
                    height: 48
                    anchors.right: parent.right
                    anchors.left: parent.left

                    Text {
                        id: textDestinationTitle
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
                        anchors.verticalCenter: parent.verticalCenter
                        height: 36

                        ListModel { id: cbDestinations }
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

                            comboBoxDestination.currentIndex = 0 // TODO save value?
                        }

                        property bool cbinit: false
                        onCurrentIndexChanged: {
                            if (storageManager.directoriesCount <= 0) return

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

                FolderInputArea {
                    id: textField_path
                    anchors.left: parent.left
                    anchors.right: parent.right

                    visible: (comboBoxDestination.currentIndex === (cbDestinations.count - 1))
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
                    var settingsMove = {}
                    settingsMove["path"] = textField_path.text

                    if (currentShot) {
                        mediaProvider.moveSelected(currentShot.uuid, settingsMove)
                    } else if (uuids.length > 0) {
                        mediaProvider.moveSelection(uuids, settingsMove)
                    }

                    popupMove.close()
                }
            }
        }
    }
}
