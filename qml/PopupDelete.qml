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

    property var shots: []
    property var files: []
    property bool fileRecapOpened: false
    property bool fileRecapEnabled: true

    property var mediaProvider: null
    property var currentShot: null

    function open() { return; }

    function openSingle(shot) {
        popupMode = 1
        shots = []
        files = []
        fileRecapEnabled = false
        fileRecapOpened = false
        mediaProvider = null
        currentShot = shot

        textArea.text = qsTr("Are you sure you want to delete current shot?")
        visible = true
    }

    function openSelection() {
        popupMode = 2
        if (shots.length === 0 || files.length === 0) return
        fileRecapEnabled = true
        fileRecapOpened = false
        mediaProvider = null
        currentShot = null

        if (shots.length > 1)
            textArea.text = qsTr("Are you sure you want to delete selected shots?")
        else
            textArea.text = qsTr("Are you sure you want to delete selected shot?")
        visible = true
    }

    function openAll() {
        popupMode = 3
        shots = []
        files = []
        fileRecapEnabled = false
        fileRecapOpened = false
        mediaProvider = null
        currentShot = null

        textArea.text = qsTr("Are you sure you want to delete ALL of the files from this device?")
        visible = true
    }

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: fileRecapOpened ? ThemeEngine.colorForeground : ThemeEngine.colorBackground
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
                rotation: fileRecapOpened ? -90 : 90
                onClicked: fileRecapOpened = !fileRecapOpened
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

                visible: fileRecapOpened

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

                visible: !fileRecapOpened
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

                visible: !fileRecapOpened

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
                    popupDelete.confirmed()
                    popupDelete.close()
                }
            }
        }
    }
}
