import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

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
    property bool recapEnabled: true
    property bool recapOpened: false

    property var uuids: []
    property var shots: []
    property var files: []

    property var mediaProvider: null
    property var currentShot: null

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

        textArea.text = qsTr("Are you sure you want to delete current shot?")
        visible = true
    }

    function openSelection(provider) {
        if (uuids.length === 0 || shots.length === 0 || files.length === 0) return

        popupMode = 2
        recapEnabled = true
        recapOpened = false
        mediaProvider = provider
        currentShot = null

        if (shots.length > 1)
            textArea.text = qsTr("Are you sure you want to delete selected shots?")
        else
            textArea.text = qsTr("Are you sure you want to delete selected shot?")
        visible = true
    }

    function openAll(provider) {
        popupMode = 3
        recapEnabled = false
        recapOpened = false
        uuids = []
        shots = []
        files = []
        mediaProvider = provider
        currentShot = null

        textArea.text = qsTr("Are you sure you want to delete ALL of the files from this device?")
        visible = true
    }

    ////////////////////////////////////////////////////////////////////////////

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.5; to: 1.0; duration: 133; } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 233; } }

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

                text: qsTr("Confirmation")
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

            visible: files.length

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 48+16+16
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("%n shot(s) selected", "", shots.length) + " / " + qsTr("%n file(s) selected", "", files.length)
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
            height: (files.length > 0) ? 160 : 96
            anchors.left: parent.left
            anchors.right: parent.right

            ////////

            ListView {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24

                visible: recapOpened

                model: files
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

            Text {
                id: textArea
                height: Theme.componentHeight
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 24

                visible: !recapOpened
                font.pixelSize: Theme.fontSizeContent
                color: Theme.colorText
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
            }

            ListView {
                id: listArea
                anchors.top: textArea.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 24
                anchors.bottom: parent.bottom

                visible: !recapOpened

                model: files
                delegate: Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: modelData
                    font.pixelSize: 14
                    elide: Text.ElideLeft
                    color: Theme.colorSubText
                }
            }
        }

        ////////////////

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
                onClicked: popupDelete.close()
            }
            ButtonWireframeImage {
                id: buttonConfirm
                width: 128
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Delete")
                source: "qrc:/assets/icons_material/baseline-delete-24px.svg"
                fullColor: true
                primaryColor: Theme.colorError
                onClicked: {
                    var settingsDeletion = {}
                    settingsDeletion["trash"] = settingsManager.moveToTrash

                    if (currentShot) {
                        mediaProvider.deleteSelected(currentShot.uuid, settingsDeletion)
                        //mediaProvider.deleteSelected(uuids[0], settingsDeletion)
                    } else if (uuids.length > 0) {
                        mediaProvider.deleteSelection(uuids, settingsDeletion)
                    } else if (popupMode === 3) {
                        mediaProvider.deleteAll(settingsDeletion)
                    }

                    popupDelete.close()
                }
            }
        }
    }
}
