import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.Templates as T

import ThemeEngine

T.ComboBox {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    leftPadding: 16
    rightPadding: 16

    font.pixelSize: Theme.componentFontSize

    property string folders

    ////////////////

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: Theme.componentHeight

        radius: Theme.componentRadius
        opacity: control.enabled ? 1 : 0.66
        color: control.down ? Theme.colorComponentDown : Theme.colorComponent
        border.width: 2
        border.color: Theme.colorComponentBorder
    }

    ////////////////

    contentItem: Text {
        text: control.displayText
        textFormat: Text.PlainText

        font: control.font
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter

        opacity: control.enabled ? 1 : 0.66
        color: Theme.colorComponentContent

        Text {
            x: parent.leftPadding + parent.contentWidth
            anchors.verticalCenter: parent.verticalCenter

            text: control.folders
            textFormat: Text.PlainText
            font: control.font
            color: Theme.colorComponentContent
            opacity: 0.6
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    ////////////////

    indicator: Canvas {
        x: control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 12
        height: 8

        Connections {
            target: ThemeEngine
            function onCurrentThemeChanged() { indicator.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset()
            ctx.moveTo(0, 0)
            ctx.lineTo(width, 0)
            ctx.lineTo(width / 2, height)
            ctx.closePath()
            ctx.fillStyle = Theme.colorComponentContent
            ctx.fill()
        }
    }

    ////////////////

    delegate: T.ItemDelegate {
        width: control.width - 2
        height: control.height
        highlighted: (control.highlightedIndex === index)

        background: Rectangle {
            implicitWidth: 200
            implicitHeight: Theme.componentHeight

            radius: Theme.componentRadius
            opacity: enabled ? 1 : 0.3
            color: highlighted ? "#F6F6F6" : "transparent"
        }

        contentItem: Text {
            leftPadding: control.leftPadding
            text: control.textRole
                ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole])
                : modelData
            textFormat: Text.PlainText
            color: highlighted ? "black" : Theme.colorSubText
            font.pixelSize: Theme.componentFontSize
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }    

    ////////////////

    popup: Popup {
        y: control.height - 1
        width: control.width
        implicitHeight: (contentItem.implicitHeight) ? contentItem.implicitHeight + 2 : 0
        padding: 1

        contentItem: ListView {
            implicitHeight: contentHeight
            clip: true
            currentIndex: control.highlightedIndex
            model: control.popup.visible ? control.delegateModel : null
        }

        background: Rectangle {
            radius: Theme.componentRadius
            color: "white"
            border.color: Theme.colorComponentBorder
            border.width: control.visualFocus ? 0 : 1
        }
    }

    ////////////////
}
