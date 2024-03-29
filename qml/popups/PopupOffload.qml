import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import ThemeEngine
import StorageUtils

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
    property bool recapEnabled: false
    property bool recapOpened: false

    property var shots_uuids: []
    property var shots_names: []
    property var shots_files: []
    //property var shots: [] // TODO actual shot pointers

    property var mediaProvider: null
    property var currentShot: null

    ////////

    property bool isGoPro: true
    property bool isReadOnly: false

    Connections {
        // keep default settings up to date
        target: settingsManager
        function onIgnoreJunkChanged() { switchIgnoreJunk.checked = settingsManager.ignoreJunk }
        function onIgnoreHdAudioChanged() { switchIgnoreAudio.checked = settingsManager.ignoreHdAudio }
        function onAutoMergeChanged() { switchMerge.checked = settingsManager.autoMerge }
        function onAutoTelemetryChanged() { switchTelemetry.checked = settingsManager.autoTelemetry }
        function onAutoDeleteChanged() { switchDelete.checked = settingsManager.autoDelete }
    }

    ////////

    function open() { return; }

    function openSingle(provider, shot) {
        popupMode = 1
        mediaProvider = provider
        currentShot = shot

        visible = true
    }

    function openSelection(provider) {
        if (shots_uuids.length === 0 || shots_names.length === 0) return

        popupMode = 2
        recapEnabled = true
        mediaProvider = provider

        visible = true
    }

    function openAll(provider) {
        popupMode = 3
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

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.33; to: 1.0; duration: 133; } }

    background: Item {
        Rectangle {
            id: bgrect
            anchors.fill: parent

            radius: Theme.componentRadius
            color: Theme.colorBackground
            border.color: Theme.colorSeparator
            border.width: Theme.componentBorderWidth
        }
        DropShadow {
            anchors.fill: parent
            source: bgrect
            color: "#60000000"
            radius: 24
            samples: radius*2+1
            cached: true
        }
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
                anchors.rightMargin: 1
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
            anchors.leftMargin: Theme.componentBorderWidth
            anchors.right: parent.right
            anchors.rightMargin: Theme.componentBorderWidth

            z: 1
            height: 48
            visible: (recapEnabled && shots_files.length)
            color: Theme.colorForeground

            MouseArea {
                anchors.fill: parent
                onClicked: recapOpened = !recapOpened
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 48+16+16
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("%n shot(s) selected", "", shots_names.length)
                color: Theme.colorText
                font.pixelSize: Theme.fontSizeContent
            }

            RoundButtonIcon {
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

                model: shots_names
                delegate: Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: modelData
                    font.pixelSize: Theme.fontSizeContentSmall
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

                        checked: settingsManager.ignoreJunk
                        text: qsTr("Ignore LRVs and THM files")
                    }

                    SwitchThemedDesktop {
                        id: switchIgnoreAudio
                        anchors.verticalCenter: parent.verticalCenter

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

                        checked: settingsManager.autoDelete
                        text: qsTr("Delete offloaded files from device storage")
                    }
                }

                ////////

                Item { // delimiter
                    anchors.left: parent.left
                    anchors.leftMargin: -23
                    anchors.right: parent.right
                    anchors.rightMargin: -23
                    height: 32

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: Theme.componentBorderWidth
                        color: Theme.colorForeground
                    }
                }

                ////////

                Item {
                    height: 24
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Text {
                        id: textDestinationTitle
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom

                        text: qsTr("Destination")
                        color: Theme.colorSubText
                        font.pixelSize: Theme.fontSizeContent
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
                            function onDirectoriesUpdated() { comboBoxDestination.updateDestinations() }
                        }

                        function updateDestinations() {
                            cbDestinations.clear()

                            for (var child in storageManager.directoriesList) {
                                if (storageManager.directoriesList[child].available &&
                                    storageManager.directoriesList[child].enabled &&
                                    storageManager.directoriesList[child].directoryContent !== StorageUtils.ContentAudio)
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
                                if (comboBoxDestination.currentIndex === (cbDestinations.count-1)) {
                                    folderInput.folder = previousDestination
                                } else {
                                    folderInput.folder = selectedDestination
                                }

                                if (comboBoxDestination.currentIndex === cbDestinations.count) {
                                    //
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
            ButtonWireframeIcon {
                id: buttonOffload
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Offload")
                source: "qrc:/assets/icons_material/baseline-archive-24px.svg"
                fullColor: true
                primaryColor: Theme.colorPrimary

                onClicked: {
                    if (typeof mediaProvider === "undefined" || !mediaProvider) return

                    var settingsOffload = {}

                    // settings
                    settingsOffload["ignoreJunk"] = switchIgnoreJunk.checked
                    settingsOffload["ignoreAudio"] = switchIgnoreAudio.checked
                    settingsOffload["extractTelemetry"] = switchTelemetry.checked
                    settingsOffload["mergeChapters"] = switchMerge.checked
                    settingsOffload["autoDelete"] = switchDelete.checked

                    // destination
                    if (comboBoxDestination.currentIndex === (cbDestinations.count-1)) {
                        settingsOffload["folder"] = folderInput.folder
                    } else {
                        settingsOffload["mediaDirectory"] = comboBoxDestination.currentText
                    }

                    // dispatch job
                    if (currentShot) {
                        mediaProvider.offloadSelected(currentShot.uuid, settingsOffload)
                    } else if (shots_uuids.length > 0) {
                        mediaProvider.offloadSelection(shots_uuids, settingsOffload)
                    } else if (popupMode === 3) {
                        mediaProvider.offloadAll(settingsOffload)
                    }
                    popupOffload.close()
                }
            }
        }
    }
}
