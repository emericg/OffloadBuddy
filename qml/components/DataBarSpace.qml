import QtQuick 2.12
import QtGraphicalEffects 1.12 // Qt5
//import Qt5Compat.GraphicalEffects // Qt6

import ThemeEngine 1.0
import "qrc:/js/UtilsNumber.js" as UtilsNumber
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: dataBarSpace
    width: 256
    height: 16

    property bool animated: true

    property string colorText: Theme.colorText
    property string colorForeground: Theme.colorPrimary
    property string colorBackground: Theme.colorForeground

    property real value: 0
    property real valueMin: 0
    property real valueMax: 100
    property real vsu: 0
    property real vst: 0

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
            color: "white"
            font.bold: true
            font.pixelSize: 10 // Theme.fontSizeContentVerySmall
        }

        Rectangle {
            id: item_data
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom

            radius: dataBarSpace.height/2
            color: {
                if (value > 90) return Theme.colorError
                else if (value > 75) return Theme.colorWarning
                else return colorForeground
            }

            width: {
                var res = UtilsNumber.normalize(value, valueMin, valueMax) * item_bg.width
                if (res > item_bg.width) res = item_bg.width
                return res
            }
            Behavior on width { NumberAnimation { duration: animated ? 333 : 0 } }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1

                text: UtilsString.bytesToString_short(vsu)
                color: "white"
                font.bold: true
                font.pixelSize: 10 // Theme.fontSizeContentVerySmall

                onTextChanged: {
                    if (contentWidth > item_data.width) {
                        color = Theme.colorSubText
                        anchors.rightMargin = - contentWidth - 6
                    } else {
                        color = "white"
                        anchors.rightMargin = 6
                    }
                }
            }
        }
    }
}
