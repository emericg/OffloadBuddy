import QtQuick
import QtQuick.Effects
import QtQuick.Controls

import ThemeEngine

Popup {
    id: popupDelete

    x: (appWindow.width / 2) - (width / 2) + (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 720
    padding: 0

    dim: true
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    parent: Overlay.overlay

    signal confirmed()

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

        if (currentShot.fileCount > 1)
            textArea.text = qsTr("Are you sure you want to delete the current shot and its files?")
        else
            textArea.text = qsTr("Are you sure you want to delete the current shot?")

        if (shots_files.length === 0) {
            recapEnabled = true
            shots_uuids.push(currentShot.uuid)
            shots_names.push(currentShot.name)
            shots_files = currentShot.filesList
        }

        visible = true
    }

    function openSelection(provider) {
        if (shots_uuids.length === 0 || shots_names.length === 0 || shots_files.length === 0) return

        popupMode = 2
        recapEnabled = true
        mediaProvider = provider
        textArea.text = qsTr("Are you sure you want to delete selected shot(s)?", "", shots_names.length)

        visible = true
    }

    function openAll(provider) {
        popupMode = 3
        mediaProvider = provider
        textArea.text = qsTr("Are you sure you want to delete ALL of the files from this device?")

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

                text: qsTr("Confirmation")
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

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentMarginXL
                anchors.right: parent.right
                anchors.rightMargin: 48+16+16
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("%n shot(s) selected", "", shots_names.length) + " / " + qsTr("%n file(s) selected", "", shots_files.length)
                color: Theme.colorText
                font.pixelSize: Theme.fontSizeContent
            }

            RoundButtonSunken {
                anchors.right: parent.right
                anchors.rightMargin: Theme.componentMargin
                anchors.verticalCenter: parent.verticalCenter

                rotation: recapOpened ? -90 : 90
                colorBackground: Theme.colorForeground
                source: "qrc:/assets/icons/material-symbols/chevron_right.svg"

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

            Text {
                id: textArea
                anchors.left: parent.left
                anchors.right: parent.right

                visible: !recapOpened

                font.pixelSize: Theme.fontSizeContent
                color: Theme.colorText
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
            }

            ////////

            ListView { // filesArea
                id: listArea
                anchors.left: parent.left
                anchors.right: parent.right

                visible: recapOpened || (shots_files.length > 0 && shots_files.length <= 8)
                height: Math.min(128, contentHeight)
                interactive: (contentHeight > 128)

                model: shots_files
                delegate: Text {
                    width: listArea.width
                    text: modelData
                    font.pixelSize: Theme.fontSizeContentSmall
                    elide: Text.ElideLeft
                    color: Theme.colorSubText
                }
            }

            ////////

            Row {
                anchors.right: parent.right

                topPadding: Theme.componentMargin
                spacing: Theme.componentMargin

                ButtonSolid {
                    anchors.bottom: parent.bottom

                    text: qsTr("Cancel")
                    color: Theme.colorGrey
                    onClicked: popupDelete.close()
                }

                ButtonSolid {
                    anchors.bottom: parent.bottom

                    text: qsTr("Delete")
                    source: "qrc:/assets/icons/material-symbols/delete.svg"
                    color: Theme.colorError
                    onClicked: {
                        var settingsDeletion = {}
                        settingsDeletion["moveToTrash"] = settingsManager.moveToTrash

                        if (currentShot) {
                            mediaProvider.deleteSelected(currentShot.uuid, settingsDeletion)
                            //mediaProvider.deleteSelected(shots_uuids[0], settingsDeletion)
                        } else if (shots_uuids.length > 0) {
                            mediaProvider.deleteSelection(shots_uuids, settingsDeletion)
                        } else if (popupMode === 3) {
                            mediaProvider.deleteAll(settingsDeletion)
                        }

                        // If deletion happen from media detail screen, go back
                        if (appContent.state === "library" && screenLibrary.state === "stateMediaDetails") screenLibrary.state = "stateMediaGrid"
                        else if (appContent.state === "device" && screenDevice.state === "stateMediaDetails") screenDevice.state = "stateMediaGrid"

                        popupDelete.close()
                    }
                }
            }

            ////////
        }

        ////////////////
    }

    ////////////////////////////////////////////////////////////////////////////
}
