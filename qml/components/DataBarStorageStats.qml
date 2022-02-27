import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15

import ThemeEngine 1.0
import ShotUtils 1.0
import "qrc:/js/UtilsString.js" as UtilsString

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
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                x: rectangleTracks.x
                y: rectangleTracks.y
                width: rectangleTracks.width
                height: rectangleTracks.height
                radius: rectangleTracks.radius
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
                        color: Theme.colorSubText
                        font.pixelSize: Theme.fontSizeContentSmall
                        font.bold: false
                    }
                }
            }
        }
    }
}
