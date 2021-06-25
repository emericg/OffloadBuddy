import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3

import ThemeEngine 1.0
import "qrc:/js/UtilsPath.js" as UtilsPath

TextField {
    id: folderArea
    implicitWidth: 128
    implicitHeight: Theme.componentHeight

    property alias folder: folderArea.text
    property alias file: fileArea.text
    property alias extension: extensionArea.text

    signal pathChanged(var path)

    property string colorText: Theme.colorComponentContent
    property string colorPlaceholderText: Theme.colorSubText
    property string colorBorder: Theme.colorComponentBorder
    property string colorBackground: Theme.colorComponentBackground

    placeholderText: ""
    placeholderTextColor: colorPlaceholderText

    color: colorText
    font.pixelSize: Theme.fontSizeComponent

    onEditingFinished: {
        pathChanged(folderArea.text + fileArea.text + "." + extensionArea.text)
        focus = false
    }

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        border.width: 2
        border.color: (folderArea.activeFocus || fileArea.activeFocus) ? Theme.colorPrimary : colorBorder
        color: colorBackground
        radius: Theme.componentRadius
    }

    TextInput {
        id: fileArea
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: folderArea.contentWidth + 12
        width: folderArea.width - x

        color: Theme.colorSubText
        verticalAlignment: "AlignVCenter"

        onEditingFinished: {
            pathChanged(folderArea.text + fileArea.text + "." + extensionArea.text)
            focus = false
        }
    }

    Text {
        id: dot
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: folderArea.contentWidth + 12 + fileArea.contentWidth + 1

        text: "."
        color: Theme.colorSubText
        verticalAlignment: "AlignVCenter"
    }
    Text {
        id: extensionArea
        anchors.top: parent.top
        anchors.left: dot.right
        anchors.leftMargin: 1
        anchors.bottom: parent.bottom
        color: Theme.colorSubText
        verticalAlignment: "AlignVCenter"
    }

    ////////////////////////////////////////////////////////////////////////////

    ButtonThemed {
        id: button_change
        width: 72
        height: 36
        anchors.right: parent.right
        anchors.rightMargin: 2
        anchors.verticalCenter: parent.verticalCenter

        embedded: true
        text: qsTr("change")
        onClicked: {
            fileDialogChange.folder =  "file:///" + textField_path.text
            fileDialogChange.open()
        }
    }

    FileDialog {
        id: fileDialogChange
        title: qsTr("Please choose a destination!")
        sidebarVisible: true
        selectExisting: true
        selectMultiple: false
        selectFolder: true

        onAccepted: {
            var f = UtilsPath.cleanUrl(fileDialogChange.fileUrl)
            if (f.slice(0, -1) !== "/") f += "/"
            textField_path.text = f

            pathChanged(folderArea.text + fileArea.text + "." + extensionArea.text)
        }
    }
}
