import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.1

import com.offloadbuddy.style 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: itemJob
    height: 48
    width: parent.width
    color: ThemeEngine.colorContentSubBox

    property var job

    signal pauseClicked()
    signal stopClicked()

    Image {
        id: imageStatus
        width: 40
        height: 40
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        source: "qrc:/resources/minicons/dark_queued.svg"
    }

    Connections {
        target: job
        onJobUpdated: {
            if (job.state >= 8) {
                imageStatus.source = "qrc:/resources/minicons/dark_done.svg"
            } else if (job.state >= 1) {
                imageStatus.source = "qrc:/resources/minicons/dark_working.svg"
            }
        }
    }

    Component.onCompleted: {
        if (job.state >= 8) {
            imageStatus.source = "qrc:/resources/minicons/dark_done.svg"
        } else if (job.state >= 1) {
            imageStatus.source = "qrc:/resources/minicons/dark_working.svg"
        }
    }

    Text {
        id: jobType
        width: 96
        height: 40
        text: job.type
        font.bold: true
        verticalAlignment: Text.AlignVCenter
        anchors.left: imageStatus.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 12
    }

    Text {
        id: jobName
        y: 25
        width: 96
        height: 40
        text: job.name
        verticalAlignment: Text.AlignVCenter
        anchors.left: jobType.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 12
    }

    ProgressBar {
        id: progressBar
        y: 20
        height: 20
        anchors.right: rectanglePlayPause.left
        anchors.rightMargin: 8
        anchors.left: jobName.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        value: job.progress
    }

    Rectangle {
        id: rectangleDelete
        width: 40
        height: 40
        color: ThemeEngine.colorDangerZone
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            id: mouseAreaDelete
            anchors.fill: parent
            //onClicked:

            onPressed: {
                rectangleDelete.anchors.bottomMargin = rectangleDelete.anchors.bottomMargin + 2
                rectangleDelete.anchors.leftMargin = rectangleDelete.anchors.leftMargin + 2
                rectangleDelete.anchors.rightMargin = rectangleDelete.anchors.rightMargin + 2
                rectangleDelete.width = rectangleDelete.width - 4
                rectangleDelete.height = rectangleDelete.height - 4
            }
            onReleased: {
                rectangleDelete.anchors.bottomMargin = rectangleDelete.anchors.bottomMargin - 2
                rectangleDelete.anchors.leftMargin = rectangleDelete.anchors.leftMargin - 2
                rectangleDelete.anchors.rightMargin = rectangleDelete.anchors.rightMargin - 2
                rectangleDelete.width = rectangleDelete.width + 4
                rectangleDelete.height = rectangleDelete.height + 4
            }
        }

        Text {
            id: textDelete
            color: ThemeEngine.colorButtonText
            text: qsTr("X")
            font.pixelSize: 24
            font.bold: true

            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Rectangle {
        id: rectanglePlayPause
        width: 40
        height: 40
        color: ThemeEngine.colorApproved
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: rectangleDelete.left

        MouseArea {
            id: mouseAreaPlayPause
            anchors.fill: parent
        }

        Text {
            id: textPlayPause
            color: ThemeEngine.colorButtonText
            text: qsTr("▶")
            verticalAlignment: Text.AlignVCenter
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            anchors.fill: parent
            font.pixelSize: 24
        }
    }
}
