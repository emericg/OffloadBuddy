import QtQuick
import QtQuick.Effects
import QtQuick.Controls

import ThemeEngine
import StorageUtils

import "qrc:/utils/UtilsString.js" as UtilsString
import "qrc:/utils/UtilsPath.js" as UtilsPath

Popup {
    id: popupMerge

    x: (appWindow.width / 2) - (width / 2) - (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 720
    padding: 0

    dim: true
    modal: true
    focus: visible
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    parent: Overlay.overlay

    ////////////////////////////////////////////////////////////////////////////

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

    Connections {
        // keep default settings up to date
        target: settingsManager
        function onAutoDeleteChanged() { switchDelete.checked = settingsManager.autoDelete }
    }

    ////////

    function open() { return; }

    function openSingle(provider, shot) {
        popupMode = 1
        mediaProvider = provider
        currentShot = shot
        comboBoxDestination.updateDestinations()

        visible = true
    }

    function openSelection(provider) {
        if (shots_uuids.length === 0 || shots_names.length === 0 || shots_files.length === 0) return

        popupMode = 2
        recapEnabled = true
        mediaProvider = provider
        comboBoxDestination.updateDestinations()

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

                text: qsTr("Merge chaptered files")
                textFormat: Text.PlainText
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
                anchors.leftMargin: Theme.componentMarginXL
                anchors.right: parent.right
                anchors.rightMargin: 48+Theme.componentMargin*2
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("%n shot(s) selected", "", shots_names.length) + " / " + qsTr("%n file(s) selected", "", shots_files.length)
                textFormat: Text.PlainText
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
            spacing: Theme.componentMargin

            ////////

            ListView { // filesArea
                anchors.left: parent.left
                anchors.right: parent.right

                visible: recapOpened || (shots_files.length > 0 && shots_files.length <= 8)
                height: Math.min(128, contentHeight)
                interactive: (contentHeight > 128)

                model: shots_files
                delegate: Text {
                    width: ListView.view.width
                    text: modelData
                    textFormat: Text.PlainText
                    font.pixelSize: Theme.fontSizeContentSmall
                    elide: Text.ElideLeft
                    color: Theme.colorSubText
                }
            }

            ////////

            Column {
                id: columnMerge
                anchors.left: parent.left
                anchors.right: parent.right

                visible: !recapOpened

                Item {
                    height: 48
                    anchors.left: parent.left
                    anchors.right: parent.right

                    SwitchThemedDesktop {
                        id: switchDelete
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        checked: settingsManager.autoDelete
                        text: qsTr("Delete original chapters after merge")
                    }
                }
                Item {
                    anchors.right: parent.right
                    anchors.left: parent.left

                    visible: !recapEnabled && currentShot && currentShot.fileCount
                    height: 32

                    Text {
                        id: textSourceTitle
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Chapters", "", currentShot.fileCount)
                        color: Theme.colorSubText
                        font.pixelSize: Theme.fontSizeContent
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    visible: !recapEnabled && currentShot && currentShot.fileCount

                    Repeater {
                        model: currentShot.filesList
                        delegate: Text {
                            anchors.left: parent.left
                            anchors.right: parent.right

                            text: modelData
                            font.pixelSize: Theme.fontSizeContentSmall
                            elide: Text.ElideLeft
                            color: Theme.colorText
                        }
                    }
                }

                ////////

                Item { // delimiter
                    anchors.left: parent.left
                    anchors.leftMargin: -Theme.componentMarginXL + Theme.componentBorderWidth
                    anchors.right: parent.right
                    anchors.rightMargin: -Theme.componentMarginXL + Theme.componentBorderWidth
                    height: 32

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: Theme.componentBorderWidth
                        color: Theme.colorForeground
                    }
                }

                ////////

                Column {
                    id: columnDestination
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Item {
                        height: 24
                        anchors.right: parent.right
                        anchors.left: parent.left

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

                            ListModel { id: cbDestinations }
                            model: cbDestinations

                            function updateDestinations() {
                                cbDestinations.clear()

                                if (currentShot && appContent.state !== "device")
                                    cbDestinations.append( { "text": qsTr("Next to the video file") } )

                                for (var child in storageManager.directoriesList) {
                                    if (storageManager.directoriesList[child].available &&
                                        storageManager.directoriesList[child].enabled &&
                                        storageManager.directoriesList[child].directoryContent !== StorageUtils.ContentAudio) {
                                        cbDestinations.append( { "text": storageManager.directoriesList[child].directoryPath } )
                                    }
                                }
                                cbDestinations.append( { "text": qsTr("Select path manually") } )

                                // TODO save value instead of reset?
                                comboBoxDestination.currentIndex = 0
                            }

                            property bool cbinit: false
                            onCurrentIndexChanged: {
                                if (storageManager.directoriesCount <= 0) return

                                var selectedDestination = comboBoxDestination.textAt(comboBoxDestination.currentIndex)
                                var previousDestination = comboBoxDestination.currentText
                                if (previousDestination === qsTr("Next to the video file")) previousDestination = currentShot.folder

                                if (currentShot) {
                                    if (comboBoxDestination.currentIndex === 0 && appContent.state !== "device") {
                                        fileInput.folder = currentShot.folder + jobManager.getDestinationHierarchy(currentShot, selectedDestination)
                                    } else if (comboBoxDestination.currentIndex === (cbDestinations.count-1)) {
                                        fileInput.folder = previousDestination + jobManager.getDestinationHierarchy(currentShot, previousDestination)
                                    } else if (comboBoxDestination.currentIndex < cbDestinations.count) {
                                        fileInput.folder = selectedDestination + jobManager.getDestinationHierarchy(currentShot, selectedDestination)
                                    }
                                    fileInput.file = currentShot.name + "_merged"
                                } else {
                                    if (comboBoxDestination.currentIndex === (cbDestinations.count-1)) {
                                        folderInput.folder = previousDestination
                                    } else if (comboBoxDestination.currentIndex < cbDestinations.count) {
                                        folderInput.folder = selectedDestination
                                    }
                                }
                            }

                            folders: jobManager.getDestinationHierarchyDisplay(currentShot, currentText)
                        }
                    }

                    FolderInputArea {
                        id: folderInput
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: (popupMode === 2) && (comboBoxDestination.currentIndex === (cbDestinations.count-1))
                        enabled: (comboBoxDestination.currentIndex === (cbDestinations.count-1))
                    }

                    FileInputArea {
                        id: fileInput
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: (popupMode === 1)
                        enabled: (comboBoxDestination.currentIndex === (cbDestinations.count-1))

                        extension: "mp4"
                        onPathChanged: {
                            if (currentShot && currentShot.containSourceFile(fileInput.path)) {
                                fileWarning.setError()
                            } else if (jobManager.fileExists(fileInput.path)) {
                                fileWarning.setWarning()
                            } else {
                                fileWarning.setOK()
                            }
                        }
                    }

                    FileWarning {
                        id: fileWarning
                    }
                }
            }

            ////////////

            Row {
                anchors.right: parent.right

                topPadding: Theme.componentMargin
                spacing: Theme.componentMargin

                ButtonSolid {
                    anchors.bottom: parent.bottom

                    text: qsTr("Cancel")
                    color: Theme.colorGrey

                    onClicked: popupMerge.close()
                }

                ButtonSolid {
                    anchors.bottom: parent.bottom

                    enabled: (shots_files.length > 1)

                    text: qsTr("Merge")
                    source: "qrc:/assets/icons/material-symbols/merge_type.svg"

                    onClicked: {
                        if (typeof mediaProvider === "undefined" || !mediaProvider) return

                        var settingsMerge = {}

                        // destination
                        if (popupMode === 1) {
                            if (comboBoxDestination.currentIndex === 0 && appContent.state !== "device") {
                                settingsMerge["folder"] = currentShot.folder
                                settingsMerge["file"] = fileInput.file
                                settingsMerge["extension"] = fileInput.extension
                            } else if (comboBoxDestination.currentIndex === (cbDestinations.count-1)) {
                                settingsMerge["folder"] = fileInput.folder
                                settingsMerge["file"] = fileInput.file
                                settingsMerge["extension"] = fileInput.extension
                            } else {
                                settingsMerge["mediaDirectory"] = comboBoxDestination.currentText
                            }
                        } else if (popupMode === 2) {
                            if (comboBoxDestination.currentIndex === (cbDestinations.count-1)) {
                                settingsMerge["folder"] = folderInput.folder
                            } else {
                                settingsMerge["mediaDirectory"] = comboBoxDestination.currentText
                            }
                        }

                        // settings
                        settingsMerge["autoDelete"] = switchDelete.checked

                        // dispatch job
                        if (currentShot) {
                            mediaProvider.mergeSelected(currentShot.uuid, settingsMerge)
                        } else if (mediaProvider && shots_uuids.length > 0) {
                            mediaProvider.mergeSelection(shots_uuids, settingsMerge)
                        }
                        popupMerge.close()
                    }
                }
            }

            ////////////
        }

        //////////////////
    }

    ////////////////////////////////////////////////////////////////////////////
}
