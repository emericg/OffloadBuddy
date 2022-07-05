import QtQuick 2.15
import QtQuick.Controls.impl 2.15
import QtQuick.Templates 2.15 as T

//import QtGraphicalEffects 1.15 // Qt5
import Qt5Compat.GraphicalEffects // Qt6

import ThemeEngine 1.0
import "qrc:/js/UtilsNumber.js" as UtilsNumber

T.SpinBox {
    id: control
    implicitWidth: 128
    implicitHeight: Theme.componentHeight

    value: 50
    editable: true
    font.pixelSize: Theme.fontSizeComponent

    property string legend

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        implicitWidth: 128
        implicitHeight: Theme.componentHeight

        radius: Theme.componentRadius
        color: Theme.colorComponentBackground
        opacity: enabled ? 1 : 0.33

        Rectangle {
            width: control.height
            height: control.height
            anchors.verticalCenter: parent.verticalCenter
            x: control.mirrored ? 0 : control.width - width
            color: control.up.pressed ? Theme.colorComponentDown : Theme.colorComponent
        }
        Rectangle {
            width: control.height
            height: control.height
            anchors.verticalCenter: parent.verticalCenter
            x: control.mirrored ? control.width - width : 0
            color: control.down.pressed ? Theme.colorComponentDown : Theme.colorComponent
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.componentRadius
            color: "transparent"
            border.width: Theme.componentBorderWidth
            border.color: control.focus ? Theme.colorPrimary : Theme.colorComponentBorder
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                x: control.x
                y: control.y
                width: control.width
                height: control.height
                radius: Theme.componentRadius
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    contentItem: Item {
        Row {
            anchors.centerIn: parent
            spacing: -2

            TextInput {
                height: control.height
                anchors.verticalCenter: parent.verticalCenter

                color: Theme.colorComponentText
                opacity: enabled ? 1.0 : 0.33
                selectionColor: Theme.colorText
                selectedTextColor: "white"

                text: control.textFromValue(control.value, control.locale)
                font: control.font
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter

                readOnly: !control.editable
                validator: control.validator
                inputMethodHints: Qt.ImhFormattedNumbersOnly

                onEditingFinished: {
                    control.value = control.valueFromText(text, control.locale)
                    control.focus = false
                }
            }

            Text {
                height: control.height
                anchors.verticalCenter: parent.verticalCenter

                visible: control.legend
                color: Theme.colorComponentText
                opacity: 0.8

                text: control.legend
                textFormat: Text.PlainText
                font: control.font
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    up.indicator: Item {
        implicitWidth: Theme.componentHeight
        implicitHeight: Theme.componentHeight

        width: control.height
        height: control.height
        anchors.verticalCenter: control.verticalCenter
        x: control.mirrored ? 0 : control.width - width
        opacity: enabled ? 1.0 : 0.33

        Rectangle {
            anchors.centerIn: parent
            width: UtilsNumber.round2(parent.height * 0.4)
            height: 2
            color: enabled ? Theme.colorComponentContent : Theme.colorSubText
        }
        Rectangle {
            anchors.centerIn: parent
            width: 2
            height: UtilsNumber.round2(parent.height * 0.4)
            color: Theme.colorComponentContent
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    down.indicator: Item {
        implicitWidth: Theme.componentHeight
        implicitHeight: Theme.componentHeight

        width: control.height
        height: control.height
        anchors.verticalCenter: control.verticalCenter
        x: control.mirrored ? control.width - width : 0
        opacity: enabled ? 1.0 : 0.33

        Rectangle {
            anchors.centerIn: parent
            width: UtilsNumber.round2(parent.height * 0.4)
            height: 2
            color: Theme.colorComponentContent
        }
    }

    ////////////////////////////////////////////////////////////////////////////
}
