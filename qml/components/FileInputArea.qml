import QtQuick 2.15
import QtQuick.Controls.impl 2.15
import QtQuick.Templates 2.15 as T

//import QtQuick.Dialogs 1.3 // Qt5
//import QtGraphicalEffects 1.15 // Qt5

import QtQuick.Dialogs // Qt6
import Qt5Compat.GraphicalEffects // Qt6

import ThemeEngine 1.0
import "qrc:/js/UtilsPath.js" as UtilsPath

T.TextField {
    id: control

    implicitWidth: implicitBackgroundWidth + leftInset + rightInset ||
                   Math.max(contentWidth, placeholder.implicitWidth) + leftPadding + rightPadding
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding,
                             placeholder.implicitHeight + topPadding + bottomPadding)

    leftPadding: 12
    rightPadding: 12

    clip: true
    color: colorText
    //opacity: control.enabled ? 1 : 0.66

    text: ""
    font.pixelSize: Theme.componentFontSize
    verticalAlignment: TextInput.AlignVCenter

    placeholderText: ""
    placeholderTextColor: colorPlaceholderText

    selectByMouse: true
    selectionColor: colorSelection
    selectedTextColor: colorSelectedText

    onEditingFinished: focus = false

    property alias folder: control.text
    property alias file: fileArea.text
    property alias extension: extensionArea.text
    property string path: folder + file + "." + extension
    property bool isValid: (control.text.length > 0 && fileArea.text.length > 0 && extensionArea.text.length > 0)

    // settings
    property string buttonText: qsTr("change")
    property int buttonWidth: (buttonChange.visible ? buttonChange.width : 0)

    // colors
    property string colorText: Theme.colorComponentText
    property string colorPlaceholderText: Theme.colorSubText
    property string colorBorder: Theme.colorComponentBorder
    property string colorBackground: Theme.colorComponentBackground
    property string colorSelection: Theme.colorPrimary
    property string colorSelectedText: "white"

    ////////////////////////////////////////////////////////////////////////////

    Loader {
        id: fileDialogLoader

        active: false
        asynchronous: false
        sourceComponent: FileDialog {
            title: qsTr("Please choose a file!")
            currentFolder: UtilsPath.makeUrl(control.text)
            fileMode: FileDialog.SaveFile

            //fileMode: FileDialog.OpenFile / FileDialog.OpenFiles / FileDialog.SaveFile
            //flags: FileDialog.HideNameFilterDetails

            onAccepted: {
                //console.log("fileDialog URL: " + selectedFile)

                var f = UtilsPath.cleanUrl(selectedFile)
                if (f.slice(0, -1) !== "/") f += "/"

                control.text = f
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    PlaceholderText {
        id: placeholder
        anchors.top: control.top
        anchors.bottom: control.bottom

        x: control.leftPadding
        width: control.width - (control.leftPadding + control.rightPadding)

        text: control.placeholderText
        font: control.font
        color: control.placeholderTextColor
        verticalAlignment: control.verticalAlignment
        visible: !control.length && !control.preeditText && (!control.activeFocus || control.horizontalAlignment !== Qt.AlignHCenter)
        elide: Text.ElideRight
        renderType: control.renderType
    }

    ////////////////

    Row {
        id: contentRow
        anchors.left: parent.left
        anchors.leftMargin: control.leftPadding + control.contentWidth
        anchors.verticalCenter: parent.verticalCenter

        TextInput { // fileArea
            id: fileArea
            anchors.verticalCenter: parent.verticalCenter

            width: contentWidth
            autoScroll: false
            color: Theme.colorSubText

            selectByMouse: true
            selectionColor: control.colorSelection
            selectedTextColor: control.colorSelectedText

            onTextChanged: control.textChanged()
            onEditingFinished: focus = false
        }
        Text { // dot
            anchors.verticalCenter: parent.verticalCenter
            text: "."
            color: Theme.colorSubText
            verticalAlignment: Text.AlignVCenter
        }
        Text { // extension
            id: extensionArea
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.colorSubText
            verticalAlignment: Text.AlignVCenter
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        implicitWidth: 256
        implicitHeight: Theme.componentHeight

        radius: Theme.componentRadius
        color: control.colorBackground

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

    ////////////////

    ButtonThemed {
        id: buttonChange
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        text: control.buttonText

        onClicked: {
            fileDialogLoader.active = true
            fileDialogLoader.item.open()
        }
    }

    Rectangle {
        anchors.fill: background
        radius: Theme.componentRadius
        color: "transparent"

        border.width: 2
        border.color: (control.activeFocus || fileArea.activeFocus) ? control.colorSelection : control.colorBorder
    }

    ////////////////
}
