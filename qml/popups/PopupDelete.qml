import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import ThemeEngine

Popup {
    id: popupDelete

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

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.5; to: 1.0; duration: 133; } }

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
        spacing: 0

        Rectangle { // titleArea
            anchors.left: parent.left
            anchors.right: parent.right

            height: 64
            radius: Theme.componentRadius
            color: Theme.colorPrimary

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

                text: qsTr("Confirmation")
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: "white"
            }
        }

        ////////////////

        Rectangle { // filesArea
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

                text: qsTr("%n shot(s) selected", "", shots_names.length) + " / " + qsTr("%n file(s) selected", "", shots_files.length)
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
            height: (shots_files.length > 0) ? 160 : 96
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24

            ////////

            Text {
                id: textArea
                height: Theme.componentHeight
                anchors.left: parent.left
                anchors.right: parent.right
                topPadding: 16

                visible: !recapOpened

                font.pixelSize: Theme.fontSizeContent
                color: Theme.colorText
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
            }

            ListView {
                id: listArea
                anchors.top: parent.top
                anchors.topMargin: recapOpened ? 0 : textArea.height + 16
                anchors.left: parent.left
                anchors.right: parent.right

                anchors.bottom: parent.bottom
                height: Math.min(64, listArea.count*16)

                visible: recapOpened || (shots_files.length > 0 && shots_files.length <= 4)
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
        }

        ////////////////

        Row {
            height: Theme.componentHeight*2 + parent.spacing
            anchors.right: parent.right
            anchors.rightMargin: 24
            spacing: 24

            ButtonWireframe {
                width: 96
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Cancel")
                fullColor: true
                primaryColor: Theme.colorGrey
                onClicked: popupDelete.close()
            }
            ButtonWireframeIcon {
                width: 128
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Delete")
                source: "qrc:/assets/icons_material/baseline-delete-24px.svg"
                fullColor: true
                primaryColor: Theme.colorError
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
    }
}
