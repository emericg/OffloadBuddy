import QtQuick
import QtQuick.Effects
import QtQuick.Controls

import ThemeEngine
import ShotUtils 1.0
import "qrc:/utils/UtilsString.js" as UtilsString

Item {
    id: dataBarStorageStats
    implicitHeight: 32

    function load() {
        if (typeof currentDevice === "undefined" || !currentDevice) return
        //console.log("StorageStats.load(" + currentDevice.model + ")")

        currentDevice.shotModel.computeStats()
        dataBarStorageStats.visible = currentDevice.shotModel.shotCount
    }

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        id: rectangleTracks
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        height: 16
        radius: 10
        color: Theme.colorForeground

        Row {
            Repeater {
                model: currentDevice.shotModel.statsTracks
                delegate: Rectangle {
                    height: rectangleTracks.height
                    width: {
                        var www = Math.round(modelData.spacePercent * rectangleTracks.width)
                        return ((www > 1) ? www : 1)
                    }
                    color: {
                        if (modelData.trackType === ShotUtils.FILE_AUDIO) return Theme.colorMaterialOrange
                        else if (modelData.trackType === ShotUtils.FILE_VIDEO) return Theme.colorMaterialBlue
                        else if (modelData.trackType === ShotUtils.FILE_PICTURE) return Theme.colorMaterialLightGreen
                        else if (modelData.trackType === ShotUtils.FILE_METADATA) return Theme.colorMaterialDeepPurple
                        else return Theme.colorSubText
                    }
                }
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskInverted: false
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            maskSpreadAtMax: 0.0
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    x: rectangleTracks.x
                    y: rectangleTracks.y
                    width: rectangleTracks.width
                    height: rectangleTracks.height
                    radius: rectangleTracks.radius
                }
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Row {
        id: rowTrackSize
        anchors.top: rectangleTracks.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter

        height: 16
        spacing: 24

        Row {
            spacing: 16

            Repeater {
                model: currentDevice.shotModel.statsTracks
                delegate: Row {
                    spacing: 8
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14; radius: 14;
                        color: {
                            if (modelData.trackType === ShotUtils.FILE_AUDIO) return Theme.colorMaterialOrange
                            else if (modelData.trackType === ShotUtils.FILE_VIDEO) return Theme.colorMaterialBlue
                            else if (modelData.trackType === ShotUtils.FILE_PICTURE) return Theme.colorMaterialLightGreen
                            else if (modelData.trackType === ShotUtils.FILE_METADATA) return Theme.colorMaterialDeepPurple
                            else return Theme.colorSubText
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (modelData.trackType === ShotUtils.FILE_AUDIO) return qsTr("audio")
                            else if (modelData.trackType === ShotUtils.FILE_VIDEO) return qsTr("video")
                            else if (modelData.trackType === ShotUtils.FILE_PICTURE) return qsTr("picture")
                            else if (modelData.trackType === ShotUtils.FILE_METADATA) return qsTr("telemetry")
                            else return qsTr("other")
                        }
                        textFormat: Text.PlainText
                        color: Theme.colorSubText
                        font.pixelSize: Theme.fontSizeContentSmall
                        font.bold: false
                    }
                }
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////
}
