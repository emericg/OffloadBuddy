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

    property int buttonWidth: (buttonChange.visible ? buttonChange.width : 0)

    ////////////////////////////////////////////////////////////////////////////

    property alias folder: control.text
    property string path: control.text
    property bool isValid: (control.text.length > 0)

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
        title: qsTr("Please choose a directory!")
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

            visible: control.enabled
            focusPolicy: Qt.NoFocus
            font.pixelSize: Theme.fontSizeComponent

            onClicked: {
                //fileDialog.folder =  "file:///" + control.text
                fileDialog.folder = control.text
                fileDialog.open()
            }

            background: Rectangle {
                radius: Theme.componentRadius
                //opacity: enabled ? 1 : 0.33
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

                //opacity: enabled ? 1.0 : 0.33
                color: buttonChange.down ? Theme.colorComponentContent : Theme.colorComponentContent
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: Theme.componentRadius
            border.width: 2
            border.color: control.activeFocus ? Theme.colorPrimary : colorBorder
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
}
