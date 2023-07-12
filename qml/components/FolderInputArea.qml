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

    implicitWidth: implicitBackgroundWidth + leftInset + rightInset
                   || Math.max(contentWidth, placeholder.implicitWidth) + leftPadding + rightPadding
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding,
                             placeholder.implicitHeight + topPadding + bottomPadding)

    padding: 12
    leftPadding: padding + 4

    clip: false
    color: colorText
    opacity: control.enabled ? 1 : 0.66

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
    property string path: control.text
    property bool isValid: (control.text.length > 0)

    // settings
    property int buttonWidth: (buttonChange.visible ? buttonChange.width + 2 : 2)

    // colors
    property string colorText: Theme.colorComponentText
    property string colorPlaceholderText: Theme.colorSubText
    property string colorBorder: Theme.colorComponentBorder
    property string colorBackground: Theme.colorComponentBackground
    property string colorSelection: Theme.colorPrimary
    property string colorSelectedText: Theme.colorHighContrast

    ////////////////////////////////////////////////////////////////////////////

    Loader {
        id: folderDialogLoader

        active: false
        asynchronous: false
        sourceComponent: FolderDialog {
            title: qsTr("Please choose a directory!")
            currentFolder: UtilsPath.makeUrl(control.text)

            onAccepted: {
                //console.log("fileDialog URL: " + selectedFolder)

                var f = UtilsPath.cleanUrl(selectedFolder)
                if (f.slice(0, -1) !== "/") f += "/"

                control.text = f
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    PlaceholderText {
        id: placeholder
        x: control.leftPadding
        y: control.topPadding
        width: control.width - (control.leftPadding + control.rightPadding)
        height: control.height - (control.topPadding + control.bottomPadding)

        text: control.placeholderText
        font: control.font
        color: control.placeholderTextColor
        verticalAlignment: control.verticalAlignment
        visible: !control.length && !control.preeditText && (!control.activeFocus || control.horizontalAlignment !== Qt.AlignHCenter)
        elide: Text.ElideRight
        renderType: control.renderType
    }

    ////////////////////////////////////////////////////////////////////////////

    ButtonThemed {
        id: buttonChange
        anchors.top: parent.top
        anchors.topMargin: 2
        anchors.right: parent.right
        anchors.rightMargin: 2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2

        visible: control.enabled
        text: qsTr("change")

        onClicked: {
            folderDialogLoader.active = true
            folderDialogLoader.item.open()
        }
    }

    background: Rectangle {
        implicitWidth: 256
        implicitHeight: Theme.componentHeight

        radius: Theme.componentRadius
        color: control.colorBackground

        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: buttonWidth
            color: Theme.colorComponent
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: Theme.componentRadius
            border.width: 2
            border.color: control.activeFocus ? Theme.colorPrimary : colorBorder
        }

        layer.enabled: true
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
