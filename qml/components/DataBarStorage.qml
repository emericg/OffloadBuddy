import QtQuick
import QtQuick.Effects

import ThemeEngine
import "qrc:/utils/UtilsNumber.js" as UtilsNumber
import "qrc:/utils/UtilsString.js" as UtilsString

Item {
    id: dataBarStorage
    width: 256
    height: 40

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

    Item {
        id: item_title
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 16

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.directoryPath
            color: Theme.colorText
            font.pixelSize: Theme.fontSizeContent
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            TagDesktop {
                height: 20
                text: qsTr("Read Only")
                visible: modelData.readOnly
            }
            TagDesktop {
                height: 20
                text: qsTr("LFS")
                visible: modelData.largeFileSupport
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        id: item_bg
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        height: 16
        color: dataBarStorage.colorBackground

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskInverted: false
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            maskSpreadAtMax: 0.0
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: item_bg.width
                    height: item_bg.height
                    radius: item_bg.height
                }
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1

            text: UtilsString.bytesToString_short(vst)
            color: dataBarStorage.colorText
            font.bold: false
            font.pixelSize: 10
        }

        Rectangle {
            id: item_data
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom

            radius: item_bg.height/2
            color: {
                if (valueP > 90) return Theme.colorError
                else if (valueP > 75) return Theme.colorWarning
                else return dataBarStorage.colorForeground
            }

            width: {
                var res = valueP * item_bg.width
                if (res > item_bg.width) res = item_bg.width
                return res
            }
            Behavior on width { NumberAnimation { duration: animated ? 333 : 0 } }

            Text {
                anchors.horizontalCenter: parent.right
                anchors.horizontalCenterOffset: (contentWidth+12 < item_data.width) ? (-contentWidth/1.75) : (contentWidth/1.75)
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1

                text: UtilsString.bytesToString_short(vsu)
                color: (contentWidth+12 < item_data.width) ? "white" : dataBarStorage.colorText
                font.bold: false
                font.pixelSize: 10
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////
}
