import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

ComboBox {
    id: control
    implicitWidth: 200
    implicitHeight: Theme.componentHeight

    font.pixelSize: Theme.fontSizeComponent

    background: Rectangle {
        radius: Theme.componentRadius
        color: control.down ? Theme.colorComponentDown : Theme.colorComponent
        border.width: 1
        border.color: Theme.colorComponentBorder
    }

    contentItem: Text {
        leftPadding: 16
        rightPadding: 8

        text: control.displayText
        textFormat: Text.PlainText
        font: control.font
        color: Theme.colorComponentText
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    indicator: Canvas {
        id: canvas
        x: control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 12
        height: 8
        contextType: "2d"

        Connections {
            target: ThemeEngine
            onCurrentThemeChanged: canvas.requestPaint()
        }

        onPaint: {
            context.reset()
            context.moveTo(0, 0)
            context.lineTo(width, 0)
            context.lineTo(width / 2, height)
            context.closePath()
            context.fillStyle = Theme.colorComponentText
            context.fill()
        }
    }

    delegate: ItemDelegate {
        width: control.width - 2
        height: control.height
        highlighted: (control.highlightedIndex === index)

        background: Rectangle {
            implicitWidth: 200
            implicitHeight: Theme.componentHeight

            radius: Theme.componentRadius + 2
            opacity: enabled ? 1 : 0.3
            color: highlighted ? "#f6f6f6" : "white"
        }

        contentItem: Text {
            text: modelData
            color: highlighted ? "#000000" : "#555555"
            font.pixelSize: Theme.fontSizeComponent
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
    }

    popup: Popup {
        y: control.height - 1
        width: control.width
        implicitHeight: contentItem.implicitHeight
        padding: 1

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight

            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
        }

        background: Rectangle {
            radius: Theme.componentRadius
            color: "white"
            border.color: Theme.colorComponentBorder
            border.width: control.visualFocus ? 0 : 1
        }
    }
}
