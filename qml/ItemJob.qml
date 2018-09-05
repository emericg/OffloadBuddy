import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.1
import QtGraphicalEffects 1.0

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

    Rectangle {
        id: rectangleStatus
        width: 40
        height: 40
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        color: "#00000000"
        clip: true

        Image {
            id: imageStatus
            width: 40
            height: 40
            source: "qrc:/resources/minicons/job_queued.svg"

            NumberAnimation on rotation {
                id: encodeAnimation
                running: false

                onStarted: imageStatus.source = "qrc:/resources/minicons/job_encoding.svg"
                onStopped: imageStatus.rotation = 0
                duration: 2000;
                from: 0;
                to: 360;
                loops: Animation.Infinite
            }

            SequentialAnimation {
                id: offloadAnimation
                running: false

                onStarted: imageStatus.source = "qrc:/resources/minicons/job_offloading.svg"
                onStopped: imageStatus.y = 0
                NumberAnimation { target: imageStatus; property: "y"; from: -40; to: 40; duration: 1000; }
                loops: Animation.Infinite
            }
        }
    }

    Connections {
        target: job
        onJobUpdated: updateJobStatus()
    }

    Component.onCompleted: updateJobStatus()

    function updateJobStatus() {
        if (job.state === 8) {
            imageStatus.source = "qrc:/resources/minicons/job_done.svg"
            offloadAnimation.stop()
            encodeAnimation.stop()
        } else if (job.state === 9) {
            imageStatus.source = "qrc:/resources/minicons/job_errored.svg"
            offloadAnimation.stop()
            encodeAnimation.stop()
        } else if (job.state >= 1) {
            if (job.type === qsTr("ENCODING"))
                encodeAnimation.start()
            else
                offloadAnimation.start()
        }
    }

    Text {
        id: jobType
        height: 40
        text: job.type
        font.bold: true
        verticalAlignment: Text.AlignVCenter
        anchors.left: rectangleStatus.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 12
    }

    Text {
        id: jobName
        y: 25
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
            verticalAlignment: Text.AlignTop
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            anchors.fill: parent
            font.pixelSize: 24
        }
    }
}
