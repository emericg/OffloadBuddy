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

    property bool isGoPro: true
    property bool isReadOnly: false

    Component.onCompleted: {
        // set default settings
        switchIgnoreJunk.checked = settingsManager.ignorejunk
        switchIgnoreAudio.checked = settingsManager.ignorehdaudio
        switchMerge.checked = settingsManager.automerge
        switchTelemetry.checked = settingsManager.autometadata
        switchDelete.checked = settingsManager.autodelete
    }

    Connections {
        // keep default settings up to date
        target: settingsManager
        onIgnoreJunkChanged: switchIgnoreJunk.checked = settingsManager.ignorejunk
        onIgnoreHdAudioChanged: switchIgnoreAudio.checked = settingsManager.ignorehdaudio
        onAutoMergeChanged: switchMerge.checked = settingsManager.automerge
        onAutoMetadataChanged: switchTelemetry.checked = settingsManager.autometadata
        onAutoDeleteChanged: switchDelete.checked = settingsManager.autodelete
    }

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
        mediaProvider = provider
        currentShot = null

        visible = true
    }

    function openAll(provider) {
        popupMode = 3
        recapEnabled = true
        recapOpened = false
        uuids = []
        shots = []
        files = []
        mediaProvider = provider
        currentShot = null

        visible = true
    }

    ////////////////////////////////////////////////////////////////////////////

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.33; to: 1.0; duration: 133; } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 333; } }

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: recapOpened ? ThemeEngine.colorForeground : ThemeEngine.colorBackground
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

                text: qsTr("Offloading")
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
                rotation: recapOpened ? -90 : 90
                onClicked: recapOpened = !recapOpened
            }
        }

        ////////////////

        Item {
            id: contentArea
            height: columnOffload.height
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
                id: columnOffload
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 24
                topPadding: 16
                bottomPadding: 16

                visible: !recapOpened

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48
                    spacing: 32

                    visible: isGoPro

                    SwitchThemedDesktop {
                        id: switchIgnoreJunk
                        anchors.verticalCenter: parent.verticalCenter

                        enabled: true
                        checked: settingsManager.ignorejunk
                        text: qsTr("Ignore LRVs and THM files")
                    }

                    SwitchThemedDesktop {
                        id: switchIgnoreAudio
                        anchors.verticalCenter: parent.verticalCenter

                        enabled: true
                        checked: settingsManager.ignorehdaudio
                        text: qsTr("Ignore HD Audio files")
                    }
                }

                Item {
                    height: 48
                    anchors.left: parent.left
                    anchors.right: parent.right

                    visible: isGoPro

                    SwitchThemedDesktop {
                        id: switchTelemetry
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        enabled: false
                        checked: settingsManager.autometadata
                        text: qsTr("Extract telemetry along with each shot")
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

                    visible: !isReadOnly

                    SwitchThemedDesktop {
                        id: switchDelete
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        enabled: true
                        checked: settingsManager.autodelete
                        text: qsTr("Delete offloaded files from device memory")
                    }
                }

                Item { width: 16; height: 16; } // spacer

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
                    var settingsOffload = {}
                    settingsOffload["ignoreJunk"] = switchIgnoreJunk.checked
                    settingsOffload["ignoreAudio"] = switchIgnoreAudio.checked
                    settingsOffload["telemetry"] = switchTelemetry.checked
                    settingsOffload["delete"] = switchDelete.checked
                    settingsOffload["path"] = textField_path.text

                    if (currentShot) {
                        mediaProvider.offloadSelected(currentShot.uuid, settingsOffload)
                    } else if (uuids.length > 0) {
                        mediaProvider.offloadSelection(uuids, settingsOffload)
                    } else if (popupMode === 3) {
                        mediaProvider.offloadAll(settingsOffload)
                    }

                    popupOffload.close()
                }
            }
        }
    }
}
