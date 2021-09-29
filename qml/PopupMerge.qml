import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import StorageUtils 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Popup {
    id: popupMerge
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

    Connections {
        // keep default settings up to date
        target: settingsManager
        onAutoDeleteChanged: switchDelete.checked = settingsManager.autoDelete
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

                text: qsTr("Merge chaptered files")
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
            height: columnMerge.height
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
                    font.pixelSize: Theme.fontSizeContentSmall
                    elide: Text.ElideLeft
                    color: Theme.colorSubText
                }
            }

            ////////

            Column {
                id: columnMerge
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 24
                topPadding: 16
                bottomPadding: 16

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

                    visible: !recapEnabled && currentShot.fileCount
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

                    visible: !recapEnabled && currentShot.fileCount

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

                        function updateDestinations() {
                            cbDestinations.clear()

                            if (currentShot)
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
                                if (comboBoxDestination.currentIndex === 0) {
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
                        rectangleFileWarning.visible = jobManager.fileExists(fileInput.path)
                    }
                }

                Row {
                    id: rectangleFileWarning
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48
                    spacing: 16

                    visible: false

                    ImageSvg {
                        width: 28
                        height: 28
                        anchors.verticalCenter: parent.verticalCenter

                        color: Theme.colorWarning
                        source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Warning, this file exists already and will be overwritten...")
                        color: Theme.colorText
                        font.bold: false
                        font.pixelSize: Theme.fontSizeContent
                        wrapMode: Text.WordWrap
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
                onClicked: popupMerge.close()
            }
            ButtonWireframeImage {
                id: buttonMerge
                anchors.verticalCenter: parent.verticalCenter

                enabled: (shots_files.length > 1)

                text: qsTr("Merge")
                source: "qrc:/assets/icons_material/baseline-merge_type-24px.svg"
                fullColor: true
                primaryColor: Theme.colorPrimary

                onClicked: {
                    if (typeof mediaProvider === "undefined" || !mediaProvider) return

                    var settingsMerge = {}

                    // destination
                    if (popupMode === 1) {
                        if (comboBoxDestination.currentIndex === 0) {
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
    }
}
