import QtQuick
import QtQuick.Effects
import QtQuick.Controls

import ThemeEngine
import StorageUtils

import "qrc:/utils/UtilsString.js" as UtilsString
import "qrc:/utils/UtilsPath.js" as UtilsPath

Popup {
    id: popupMove

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

                text: qsTr("Move")
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
            spacing: Theme.componentMarginXL

            ////////////

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

            ////////////

            Column {
                anchors.left: parent.left
                anchors.right: parent.right

                visible: !recapOpened

                Item {
                    anchors.right: parent.right
                    anchors.left: parent.left

                    visible: !recapEnabled && currentShot && currentShot.fileCount
                    height: 32

                    Text {
                        id: textSourceTitle
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("File(s)", "", currentShot.fileCount)
                        textFormat: Text.PlainText
                        color: Theme.colorSubText
                        font.pixelSize: Theme.fontSizeContent
                    }
                }

                ListView { // filesArea
                    anchors.left: parent.left
                    anchors.right: parent.right

                    clip: true
                    visible: !recapEnabled && currentShot && currentShot.fileCount
                    height: Math.min(64, currentShot && currentShot.fileCount*16)

                    model: currentShot.filesList
                    delegate: Text {
                        width: ListView.view.width
                        text: modelData
                        textFormat: Text.PlainText
                        font.pixelSize: Theme.fontSizeContentSmall
                        elide: Text.ElideLeft
                        color: Theme.colorText
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
                            textFormat: Text.PlainText
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

                                for (var child in storageManager.directoriesList) {
                                    if (storageManager.directoriesList[child].available &&
                                        storageManager.directoriesList[child].enabled &&
                                        storageManager.directoriesList[child].directoryContent !== StorageUtils.ContentAudio)
                                    {
                                        if (currentShot && storageManager.directoriesList[child].directoryPath.includes(currentShot.folder)) {
                                            // ignore this one
                                        } else {
                                            cbDestinations.append( { "text": storageManager.directoriesList[child].directoryPath } )
                                        }
                                    }
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

            ////////////

            Row {
                anchors.right: parent.right

                topPadding: 0
                spacing: Theme.componentMargin

                ButtonSolid {
                    anchors.bottom: parent.bottom

                    text: qsTr("Cancel")
                    color: Theme.colorGrey

                    onClicked: popupMove.close()
                }

                ButtonSolid {
                    anchors.bottom: parent.bottom

                    text: qsTr("Move")
                    source: "qrc:/assets/icons/material-symbols/archive.svg"

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

            ////////////
        }

        ////////////////
    }

    ////////////////////////////////////////////////////////////////////////////
}
