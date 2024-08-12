import QtQuick
import QtQuick.Controls

import ThemeEngine
import "qrc:/utils/UtilsString.js" as UtilsString

Rectangle {
    id: bannerJob
    anchors.left: parent.left
    anchors.right: parent.right

    height: 0
    Behavior on height { NumberAnimation { duration: 133 } }

    clip: true
    visible: (height > 0)
    color: Theme.colorActionbar

    // prevent clicks below this area
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; }

    ////////////////

    function open() {
        bannerJob.height = 48
    }
    function close() {
        bannerJob.height = 0
    }

    property int jobrunning: -1

    function checkRunning() {
        bannerJob.jobrunning = 0
        for (var i = 0; i < currentDevice.jobsCount; i++) {
            if (rp.itemAt(i).visible) bannerJob.jobrunning++
        }
    }

    ////////////////

    Column {
        id: jobColumn
        anchors.left: parent.left
        anchors.leftMargin: Theme.componentMargin
        anchors.right: rectangleClose.left
        anchors.rightMargin: Theme.componentMargin
        anchors.verticalCenter: parent.verticalCenter

        Text {
            visible: (bannerJob.jobrunning === 0)
            text: qsTr("%1 job(s) queued...").arg(currentDevice.jobsCount)
            textFormat: Text.PlainText
            color: Theme.colorActionbarContent
            font.pixelSize: Theme.fontSizeContentBig
        }

        Repeater {
            id: rp
            model: currentDevice.jobsList
            Row {
                height: 16
                spacing: 16

                visible: modelData.running
                onVisibleChanged: bannerJob.checkRunning()

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: modelData.typeStr
                    textFormat: Text.PlainText
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContent
                    color: Theme.colorActionbarContent
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: modelData.name
                    textFormat: Text.PlainText
                    font.pixelSize: Theme.fontSizeContent
                    color: Theme.colorActionbarContent
                }

                ProgressBarThemed {
                    width: 512
                    height: 8
                    anchors.verticalCenter: parent.verticalCenter

                    colorBackground: Theme.colorBackground
                    colorForeground: Theme.colorActionbarHighlight

                    from: 0
                    to: 1
                    value: modelData.progress
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    visible: currentDevice.jobsCount > 1
                    text: "(" + (currentDevice.jobsCount-1) + " in queue)"
                    textFormat: Text.PlainText
                    font.pixelSize: Theme.fontSizeContent
                    color: Theme.colorActionbarContent
                }
            }
        }
    }

    ////////////////

    RoundButtonSunken {
        id: rectangleClose
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        source: "qrc:/assets/icons/material-symbols/close.svg"
        colorIcon: "white"
        colorBackground: Theme.colorActionbar
        onClicked: bannerJob.close()
    }

    ////////////////
}
