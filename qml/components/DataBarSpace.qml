import QtQuick
//import QtGraphicalEffects 1.15 // Qt5
import Qt5Compat.GraphicalEffects // Qt6

import ThemeEngine
import "qrc:/utils/UtilsNumber.js" as UtilsNumber
import "qrc:/utils/UtilsString.js" as UtilsString

Item {
    id: dataBarSpace
    width: 256
    height: 16

    property bool animated: true

    property string colorText: Theme.colorSubText
    property string colorForeground: Theme.colorPrimary
    property string colorBackground: Theme.colorForeground

    property real value: 0
    property real valueMin: 0
    property real valueMax: 100
    property real vsu: 0
    property real vst: 0

    property real valueP: UtilsNumber.normalize(value, valueMin, valueMax)

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        id: item_bg
        anchors.fill: parent
        color: dataBarSpace.colorBackground

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: item_bg.width
                height: dataBarSpace.height
                radius: dataBarSpace.height/2
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1

            text: UtilsString.bytesToString_short(vst)
            color: dataBarSpace.colorText
            font.bold: false
            font.pixelSize: 10
        }

        Rectangle {
            id: item_data
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom

            radius: dataBarSpace.height/2
            color: {
                if (valueP > 90) return Theme.colorError
                else if (valueP > 75) return Theme.colorWarning
                else return dataBarSpace.colorForeground
            }

            width: {
                var res = valueP * item_bg.width
                if (res > item_bg.width) res = item_bg.width
                return res
            }
            Behavior on width { NumberAnimation { duration: animated ? 333 : 0 } }

            Text {
                anchors.left: parent.right
                anchors.leftMargin: (contentWidth+12 < item_data.width) ? -contentWidth-6 : 6
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1

                text: UtilsString.bytesToString_short(vsu)
                color: (contentWidth+12 < item_data.width) ? "white" : dataBarSpace.colorText
                font.bold: false
                font.pixelSize: 10
            }
        }
    }
}
