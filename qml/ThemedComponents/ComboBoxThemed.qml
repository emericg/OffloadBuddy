import QtQuick 2.10
import QtQuick.Controls 2.3

import com.offloadbuddy.style 1.0

ComboBox {
    id: control
/*
    delegate: ItemDelegate {
        width: control.width
        contentItem: Text {
            text: modelData
            color: "#21be2b"
            font: control.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        highlighted: control.highlightedIndex === index
    }

    indicator: Canvas {
        id: canvas
        x: control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 12
        height: 8
        contextType: "2d"

        Connections {
            target: control
            onPressedChanged: canvas.requestPaint()
        }

        onPaint: {
            context.reset();
            context.moveTo(0, 0);
            context.lineTo(width, 0);
            context.lineTo(width / 2, height);
            context.closePath();
            context.fillStyle = control.pressed ? "#17a81a" : "#21be2b";
            context.fill();
        }
    }
*/
    contentItem: Text {
        leftPadding: 8
        rightPadding: 8

        text: control.displayText
        font: control.font
        color: ThemeEngine.colorComboBoxText
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 120
        implicitHeight: 40
        color: ThemeEngine.colorComboBox
        //border.color: control.pressed ? "#17a81a" : "#21be2b"
        //border.width: control.visualFocus ? 2 : 1
    }

    popup: Popup {
        y: control.height
        width: control.width
        implicitHeight: contentItem.implicitHeight
        padding: 0

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex

            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            color: "white"
            //border.color: ThemeEngine.colorButton
        }
    }

}
