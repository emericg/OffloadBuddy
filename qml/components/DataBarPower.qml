import QtQuick 2.12
import QtGraphicalEffects 1.12 // Qt5
//import Qt5Compat.GraphicalEffects // Qt6

import ThemeEngine 1.0
import "qrc:/js/UtilsNumber.js" as UtilsNumber
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: dataBarPower
    width: 256
    height: 16

    property bool animated: true

    property string colorText: Theme.colorText
    property string colorForeground: Theme.colorSecondary
    property string colorBackground: Theme.colorForeground

    property real value: 0
    property real valueMin: 0
    property real valueMax: 100

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        id: item_bg
        anchors.fill: parent
        color: dataBarPower.colorBackground

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: item_bg.width
                height: dataBarPower.height
                radius: dataBarPower.height/2
            }
        }

        Rectangle {
            id: item_data
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom

            radius: dataBarPower.height/2
            color: {
                if (value < 10) return Theme.colorError
                else if (value < 25) return Theme.colorWarning
                else return colorForeground
            }

            width: UtilsNumber.normalize(value, valueMin, valueMax) * item_bg.width
            Behavior on width { NumberAnimation { duration: animated ? 333 : 0 } }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1

                text: value + "%"
                textFormat: Text.PlainText
                color: "white"
                font.bold: true
                font.pixelSize: 10 // Theme.fontSizeContentVerySmall
            }
        }
    }
}
