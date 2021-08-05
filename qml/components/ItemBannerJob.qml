import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString

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

    ////////////////////////////////////////////////////////////////////////////

    function open() {
        bannerJob.height = 48
    }
    function close() {
        bannerJob.height = 0
    }

    ////////////////////////////////////////////////////////////////////////////

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.right: rectangleClose.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
/*
        Text {
            text: qsTr("(%1 job(s) in queue)").arg(currentDevice.jobsCount)
            font.pixelSize: Theme.fontSizeContent
            color: Theme.colorActionbarContent
        }
*/
        Repeater {
            model: currentDevice.jobsList
            Row {
                height: 16
                spacing: 16

                visible: modelData.running

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: modelData.typeStr
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContent
                    color: Theme.colorActionbarContent
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    text: modelData.name
                    font.pixelSize: Theme.fontSizeContent
                    color: Theme.colorActionbarContent
                }

                ProgressBarThemed {
                    width: 512
                    height: 8
                    anchors.verticalCenter: parent.verticalCenter

                    colorBackground: Theme.colorBackground
                    colorForeground: Theme.colorActionbarContent

                    from: 0
                    to: 1
                    value: modelData.progress
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter

                    visible: currentDevice.jobsCount > 1
                    text: "(" + (currentDevice.jobsCount-1) + " in queue)"
                    font.pixelSize: Theme.fontSizeContent
                    color: Theme.colorActionbarContent
                }
            }
        }
    }

    ItemImageButton {
        id: rectangleClose
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        source: "qrc:/assets/icons_material/baseline-close-24px.svg"
        iconColor: "white"
        backgroundColor: Theme.colorActionbarHighlight
        onClicked: bannerJob.close()
    }
}
