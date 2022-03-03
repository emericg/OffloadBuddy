import QtQuick 2.15
import QtQuick.Controls.impl 2.15
import QtQuick.Templates 2.15 as T

import QtQuick.Dialogs 1.3 // Qt5
import QtGraphicalEffects 1.15 // Qt5

//import QtQuick.Dialogs // Qt6
//import Qt5Compat.GraphicalEffects // Qt6

import ThemeEngine 1.0
import "qrc:/js/UtilsPath.js" as UtilsPath

T.TextField {
    id: control

    implicitWidth: implicitBackgroundWidth + leftInset + rightInset
                   || Math.max(contentWidth, placeholder.implicitWidth) + leftPadding + rightPadding
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding,
                             placeholder.implicitHeight + topPadding + bottomPadding)

    clip: false
    padding: 12
    leftPadding: padding + 4

    text: ""
    color: colorText
    font.pixelSize: Theme.fontSizeComponent

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
    property int buttonWidth: (buttonChange.visible ? buttonChange.width : 0)

    // colors
    property string colorText: Theme.colorComponentText
    property string colorPlaceholderText: Theme.colorSubText
    property string colorBorder: Theme.colorComponentBorder
    property string colorBackground: Theme.colorComponentBackground
    property string colorSelectedText: Theme.colorHighContrast
    property string colorSelection: Theme.colorPrimary

    ////////////////////////////////////////////////////////////////////////////

    Loader {
        id: fileDialogLoader

        active: false
        asynchronous: false
        sourceComponent: FileDialog {
            title: qsTr("Please choose a directory!")
            sidebarVisible: true
            selectExisting: false
            selectMultiple: false
            selectFolder: true

            onAccepted: {
                //console.log("fileDialog URL: " + fileUrl)

                var f = UtilsPath.cleanUrl(fileUrl)
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

    background: Rectangle {
        implicitWidth: 256
        implicitHeight: Theme.componentHeight

        radius: Theme.componentRadius
        color: control.colorBackground

        ButtonThemed {
            id: buttonChange
            anchors.right: parent.right

            height: control.height
            visible: control.enabled
            text: qsTr("change")

            onClicked: {
                fileDialogLoader.active = true
                fileDialogLoader.item.open()
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
