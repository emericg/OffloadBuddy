import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3 // Qt5
import QtGraphicalEffects 1.12 // Qt5
//import Qt5Compat.GraphicalEffects // Qt6

import ThemeEngine 1.0
import "qrc:/js/UtilsPath.js" as UtilsPath

TextField {
    id: control
    implicitWidth: 128
    implicitHeight: Theme.componentHeight

    property string colorText: Theme.colorComponentText
    property string colorPlaceholderText: Theme.colorSubText
    property string colorBorder: Theme.colorComponentBorder
    property string colorBackground: Theme.colorComponentBackground

    property alias buttonWidth: buttonChange.width

    ////////////////////////////////////////////////////////////////////////////

    property alias folder: control.text
    property alias file: fileArea.text
    property alias extension: extensionArea.text

    property string path: folder + file + "." + extension
    property bool isValid: (control.text.length > 0 && fileArea.text.length > 0 && extensionArea.text.length > 0)

    placeholderText: ""
    placeholderTextColor: colorPlaceholderText

    color: enabled ? colorText : colorPlaceholderText
    font.pixelSize: Theme.fontSizeComponent

    onTextChanged: {
        //
    }
    onEditingFinished: {
        focus = false
    }

    ////////////////////////////////////////////////////////////////////////////

    FileDialog {
        id: fileDialog
        title: qsTr("Please choose a file!")
        sidebarVisible: true
        selectExisting: true
        selectMultiple: false
        selectFolder: true

        onAccepted: {
            //console.log("fileDialog URL: " + fileUrl)

            var f = UtilsPath.cleanUrl(fileUrl)
            if (f.slice(0, -1) !== "/") f += "/"

            control.text = f
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: colorBackground
        radius: Theme.componentRadius

        Button {
            id: buttonChange
            anchors.right: parent.right
            width: contentText.contentWidth + (contentText.contentWidth / 2)
            height: Theme.componentHeight

            font.pixelSize: Theme.fontSizeComponent
            focusPolicy: Qt.NoFocus

            onClicked: {
                //fileDialog.folder =  "file:///" + control.text
                fileDialog.folder = control.text
                fileDialog.open()
            }

            background: Rectangle {
                radius: Theme.componentRadius
                opacity: enabled ? 1 : 0.33
                color: buttonChange.down ? Theme.colorComponentDown : Theme.colorComponent
            }

            contentItem: Text {
                id: contentText
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter

                text: qsTr("change")
                textFormat: Text.PlainText
                font: buttonChange.font
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                opacity: enabled ? 1.0 : 0.33
                color: buttonChange.down ? Theme.colorComponentContent : Theme.colorComponentContent
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: Theme.componentRadius
            border.width: 2
            border.color: (control.activeFocus || fileArea.activeFocus) ? Theme.colorPrimary : colorBorder
        }

        layer.enabled: false
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                x: background.x
                y: background.y
                width: background.width
                height: background.height
                radius: background.radius
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    TextInput {
        id: fileArea
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: control.contentWidth + 10
        width: control.width - buttonChange.width - x

        color: Theme.colorSubText
        verticalAlignment: Text.AlignVCenter

        onTextChanged: {
            parent.textChanged()
        }
        onEditingFinished: {
            focus = false
        }
    }

    Text {
        id: dot
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: control.contentWidth + 10 + fileArea.contentWidth

        text: "."
        color: Theme.colorSubText
        verticalAlignment: Text.AlignVCenter
    }
    Text {
        id: extensionArea
        anchors.top: parent.top
        anchors.left: dot.right
        anchors.leftMargin: 1
        anchors.bottom: parent.bottom

        color: Theme.colorSubText
        verticalAlignment: Text.AlignVCenter
    }
}
