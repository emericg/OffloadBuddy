import QtQuick
import QtQuick.Effects
import QtQuick.Controls

import ThemeEngine
import StorageUtils

import "qrc:/utils/UtilsString.js" as UtilsString
import "qrc:/utils/UtilsPath.js" as UtilsPath

Popup {
    id: popupOffload

    x: (appWindow.width / 2) - (width / 2) - (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 720
    padding: 0

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    ////////////////////////////////////////////////////////////////////////////

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

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.333; to: 1.0; duration: 133; } }

    Overlay.modal: Rectangle {
        color: "#000"
        opacity: ThemeEngine.isLight ? 0.333 : 0.666
    }

    background: Rectangle {
        radius: Theme.componentRadius
        color: Theme.colorBackground

        Item {
            anchors.fill: parent

            Column {
                anchors.left: parent.left
                anchors.right: parent.right

                Rectangle { // title area
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 64
                    color: Theme.colorPrimary
                }

                Rectangle { // subtitle area
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48
                    color: Theme.colorForeground
                    visible: (recapEnabled && shots_files.length)
                }
            }

            Rectangle { // border
                anchors.fill: parent
                radius: Theme.componentRadius
                color: "transparent"
                border.color: Theme.colorSeparator
                border.width: Theme.componentBorderWidth
                opacity: 0.4
            }

            layer.enabled: true
            layer.effect: MultiEffect { // clip
                maskEnabled: true
                maskInverted: false
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                maskSpreadAtMax: 0.0
                maskSource: ShaderEffectSource {
                    sourceItem: Rectangle {
                        x: background.x
                        y: background.y
                        width: background.width
                        height: background.height
                        radius: background.radius
                    }
                }
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect { // shadow
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowColor: ThemeEngine.isLight ? "#aa000000" : "#aaffffff"
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    contentItem: Column {

        ////////////////

        Item { // titleArea
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentMarginXL
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Offloading")
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: "white"
            }
        }

        ////////////////

        Item { // filesArea
            anchors.left: parent.left
            anchors.leftMargin: Theme.componentBorderWidth
            anchors.right: parent.right
            anchors.rightMargin: Theme.componentBorderWidth

            height: 48
            visible: (recapEnabled && shots_files.length)

            MouseArea {
                anchors.fill: parent
                onClicked: recapOpened = !recapOpened
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentBorderWidth
                anchors.right: parent.right
                anchors.rightMargin: 48+Theme.componentMargin*2
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("%n shot(s) selected", "", shots_names.length)
                color: Theme.colorText
                font.pixelSize: Theme.fontSizeContent
            }

            RoundButtonIcon {
                width: 48
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: Theme.componentMargin
                anchors.verticalCenter: parent.verticalCenter

                source: "qrc:/assets/icons/material-symbols/chevron_right.svg"
                rotation: recapOpened ? -90 : 90
                onClicked: recapOpened = !recapOpened
            }
        }

        ////////////////

        Column { // contentArea
            anchors.left: parent.left
            anchors.leftMargin: Theme.componentMarginXL
            anchors.right: parent.right
            anchors.rightMargin: Theme.componentMarginXL

            topPadding: Theme.componentMarginXL
            bottomPadding: Theme.componentMarginXL
            spacing: Theme.componentMarginXL

            ////////

            ListView {
                id: listArea
                anchors.fill: parent

                visible: recapOpened

                model: shots_names
                delegate: Text {
                    width: listArea.width
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
                anchors.right: parent.right

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

            ////////////

            Row {
                anchors.right: parent.right

                topPadding: Theme.componentMargin
                spacing: Theme.componentMargin

                ButtonFlat {
                    anchors.bottom: parent.bottom

                    color: Theme.colorGrey
                    text: qsTr("Cancel")
                    onClicked: popupOffload.close()
                }

                ButtonSolid {
                    anchors.bottom: parent.bottom

                    text: qsTr("Offload")
                    source: "qrc:/assets/icons/material-symbols/archive.svg"

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

            ////////////
        }

        ////////////////
    }

    ////////////////////////////////////////////////////////////////////////////
}
