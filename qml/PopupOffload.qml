import QtQuick 2.12
import QtQuick.Controls 2.12

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
        switchIgnoreJunk.checked = settingsManager.ignoreJunk
        switchIgnoreAudio.checked = settingsManager.ignoreHdAudio
        switchMerge.checked = settingsManager.autoMerge
        switchTelemetry.checked = settingsManager.autoTelemetry
        switchDelete.checked = settingsManager.autoDelete
    }

    Connections {
        // keep default settings up to date
        target: settingsManager
        onIgnoreJunkChanged: switchIgnoreJunk.checked = settingsManager.ignoreJunk
        onIgnoreHdAudioChanged: switchIgnoreAudio.checked = settingsManager.ignoreHdAudio
        onAutoMergeChanged: switchMerge.checked = settingsManager.autoMerge
        onAutoTelemetryChanged: switchTelemetry.checked = settingsManager.autoTelemetry
        onAutoDeleteChanged: switchDelete.checked = settingsManager.autoDelete
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
        files = []
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

                text: qsTr("Offloading")
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
                        checked: settingsManager.ignoreJunk
                        text: qsTr("Ignore LRVs and THM files")
                    }

                    SwitchThemedDesktop {
                        id: switchIgnoreAudio
                        anchors.verticalCenter: parent.verticalCenter

                        enabled: true
                        checked: settingsManager.ignoreHdAudio
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
                        checked: settingsManager.autoTelemetry
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
                        checked: settingsManager.autoMerge
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
                        checked: settingsManager.autoDelete
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
                    settingsOffload["extractTelemetry"] = switchTelemetry.checked
                    settingsOffload["mergeChapters"] = switchMerge.checked
                    settingsOffload["autoDelete"] = switchDelete.checked
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
