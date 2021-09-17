import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import "qrc:/js/UtilsNumber.js" as UtilsNumber

Slider {
    id: control
    implicitWidth: 200
    implicitHeight: Theme.componentHeight
    padding: 4

    value: 0.5
    snapMode: RangeSlider.SnapAlways

    property int hhh: 16
    property string unit: ""
    property bool kshort: false

    // colors
    property string colorBg: Theme.colorForeground
    property string colorFg: Theme.colorPrimary
    property string colorTxt: "white"

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight / 2) - (height / 2)
        width: control.availableWidth

        height: hhh
        radius: hhh
        color: colorBg
        opacity: 1

        Rectangle {
            visible: h2.x > 4
            width: (h2.x + (h2.width / 3))
            height: parent.height
            color: colorFg
            radius: hhh
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    handle: Rectangle {
        id: h2
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight / 2) - (height / 2)
        implicitWidth: hhh
        implicitHeight: hhh
        width: t2.width + 16

        radius: hhh
        color: colorFg
        border.color: colorFg
        opacity: control.pressed ? 1 : 1

        Text {
            id: t2
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            anchors.horizontalCenter: parent.horizontalCenter

            text: {
                var vvalue = control.value
                if (unit === "°" && settingsManager.tempUnit === "F") vvalue = UtilsNumber.tempCelsiusToFahrenheit(vvalue)
                vvalue = vvalue.toFixed(0)
                return ((kshort && control.value > 999) ? (vvalue / 1000) : vvalue) + unit
            }
            textFormat: Text.PlainText
            font.pixelSize: 10
            font.bold: true
            color: colorTxt
        }
    }
}
