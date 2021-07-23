import QtQuick 2.12
import QtQuick.Controls 2.12

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
    property bool recapEnabled: false
    property bool recapOpened: false

    property var shots_uuids: []
    property var shots_names: []
    property var shots_files: []
    //property var shots: [] // TODO actual shot pointers

    property var mediaProvider: null
    property var currentShot: null

    ////////

    function open() { return; }

    function openSingle(provider, shot) {
        popupMode = 1
        mediaProvider = provider
        currentShot = shot
        visible = true
    }

    function openSelection(provider) {
        if (shots_uuids.length === 0 || shots_names.length === 0 || shots_files.length === 0) return

        popupMode = 2
        recapEnabled = true
        mediaProvider = provider
        visible = true
    }

    onClosed: {
        recapEnabled = false
        recapOpened = false
        shots_uuids = []
        shots_names = []
        shots_files = []
        mediaProvider = null
        currentShot = null
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
            visible: (recapEnabled && shots_files.length)
            color: Theme.colorForeground

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 48+16+16
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("%n shot(s) selected", "", shots_names.length) + " / " + qsTr("%n file(s) selected", "", shots_files.length)
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

                model: shots_files
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

                Item {
                    anchors.right: parent.right
                    anchors.left: parent.left

                    visible: !recapEnabled && currentShot.fileCount
                    height: 32

                    Text {
                        id: textSourceTitle
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("File(s)", "", currentShot.fileCount)
                        color: Theme.colorSubText
                        font.pixelSize: 16
                    }
                }

                ListView {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    clip: true
                    visible: !recapEnabled && currentShot.fileCount
                    height: Math.min(64, currentShot.fileCount*16)

                    model: currentShot.filesList
                    delegate: Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        text: modelData
                        font.pixelSize: 14
                        elide: Text.ElideLeft
                        color: Theme.colorText
                    }
                }

                Item {
                    height: 40
                    anchors.right: parent.right
                    anchors.left: parent.left

                    Text {
                        id: textDestinationTitle
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom

                        text: qsTr("Destination")
                        color: Theme.colorSubText
                        font.pixelSize: 16
                    }
                }

                Item {
                    height: 48
                    anchors.right: parent.right
                    anchors.left: parent.left

                    ComboBoxFolder {
                        id: comboBoxDestination
                        anchors.left: parent.left
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

                            // TODO save value instead of reset?
                            comboBoxDestination.currentIndex = 0
                        }

                        property bool cbinit: false
                        onCurrentIndexChanged: {
                            if (storageManager.directoriesCount <= 0) return

                            var previousDestination = comboBoxDestination.currentText
                            var selectedDestination = comboBoxDestination.textAt(comboBoxDestination.currentIndex)

                            if (cbinit) {
                                if (comboBoxDestination.currentIndex < cbDestinations.count) {
                                    folderInput.text = previousDestination
                                }
                            } else {
                                cbinit = true
                            }
                        }

                        folders: jobManager.getDestinationHierarchyDisplay(currentShot, currentText)
                    }
                }

                FolderInputArea {
                    id: folderInput
                    anchors.left: parent.left
                    anchors.right: parent.right

                    visible: (comboBoxDestination.currentIndex === (cbDestinations.count-1))
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
                    if (typeof mediaProvider === "undefined" || !mediaProvider) return

                    var settingsMove = {}

                    // destination
                    if (comboBoxDestination.currentIndex === (cbDestinations.count-1)) {
                        settingsMove["folder"] = folderInput.folder
                    } else {
                        settingsMove["mediaDirectory"] = comboBoxDestination.currentText
                    }

                    // dispatch job
                    if (currentShot) {
                        mediaProvider.moveSelected(currentShot.uuid, settingsMove)
                    } else if (shots_uuids.length > 0) {
                        mediaProvider.moveSelection(shots_uuids, settingsMove)
                    }
                    popupMove.close()
                }
            }
        }
    }
}
