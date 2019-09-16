import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Rectangle {
    id: itemJob
    color: Theme.colorForeground
    implicitWidth: 640
    implicitHeight: 48

    property var job: null

    signal pauseClicked()
    signal stopClicked()

    ImageSvg {
        id: imageStatus
        width: 40
        height: 40
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        source: "qrc:/icons_material/baseline-schedule-24px.svg"
        color: Theme.colorIcon

        NumberAnimation on rotation {
            id: encodeAnimation
            running: false

            onStarted: imageStatus.source = "qrc:/icons_material/baseline-memory-24px.svg"
            onStopped: imageStatus.rotation = 0
            duration: 2000;
            from: 0;
            to: 360;
            loops: Animation.Infinite
        }

        SequentialAnimation {
            id: offloadAnimation
            running: false

            onStarted: imageStatus.source = "qrc:/icons_material/baseline-save_alt-24px.svg"
            onStopped: imageStatus.y = 0
            NumberAnimation { target: imageStatus; property: "y"; from: -40; to: 40; duration: 1000; }
            loops: Animation.Infinite
        }
    }

    Connections {
        target: job
        onJobUpdated: updateJobStatus()
    }

    Component.onCompleted: updateJobStatus()

    function updateJobStatus() {
        if (job.state === 8) {
            imageStatus.source = "qrc:/icons_material/baseline-done-24px.svg"
            offloadAnimation.stop()
            encodeAnimation.stop()
        } else if (job.state === 9) {
            imageStatus.source = "qrc:/icons_material/baseline-error-24px.svg"
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
        color: Theme.colorText
        font.bold: true
        verticalAlignment: Text.AlignVCenter
        anchors.left: imageStatus.right
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 14
    }

    Text {
        id: jobName
        y: 25
        height: 40
        text: job.name
        color: Theme.colorText
        verticalAlignment: Text.AlignVCenter
        anchors.left: jobType.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 14
    }

    ProgressBarThemed {
        id: progressBar
        height: 12
        anchors.right: rectangleOpen.left
        anchors.rightMargin: 8
        anchors.left: jobName.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        value: job.progress
    }

    Item {
        id: rectangleOpen
        width: 40
        height: 40
        anchors.right: rectanglePlayPause.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        visible: job.type !== 3 // not a deletion

        ImageSvg {
            id: imageOpen
            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            source: "qrc:/icons_material/outline-folder-24px.svg"
            color: Theme.colorIcon
        }

        MouseArea {
            id: mouseAreaOpen
            anchors.fill: parent
            onClicked: job.openDestination()

            onPressed: {
                imageOpen.width = imageOpen.width - 4
                imageOpen.height = imageOpen.height - 4
            }
            onReleased: {
                imageOpen.width = imageOpen.width + 4
                imageOpen.height = imageOpen.height + 4
            }
        }
    }

    Item {
        id: rectangleDelete
        width: 40
        height: 40
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        ImageSvg {
            id: imageDelete
            width: 40
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            source: "qrc:/icons_material/baseline-cancel-24px.svg"
            color: Theme.colorIcon
        }
        MouseArea {
            id: mouseAreaDelete
            anchors.fill: parent
            //onClicked:

            onPressed: {
                imageDelete.width = imageDelete.width - 4
                imageDelete.height = imageDelete.height - 4
            }
            onReleased: {
                imageDelete.width = imageDelete.width + 4
                imageDelete.height = imageDelete.height + 4
            }
        }
    }

    Item {
        id: rectanglePlayPause
        width: 40
        height: 40
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: rectangleDelete.left

        ImageSvg {
            id: imagePlayPause
            width: 40
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            source: "qrc:/icons_material/baseline-pause_circle_outline-24px.svg"
            color: Theme.colorIcon
        }

        MouseArea {
            id: mouseAreaPlayPause
            anchors.fill: parent

            onPressed: {
                imagePlayPause.width = imagePlayPause.width - 4
                imagePlayPause.height = imagePlayPause.height - 4
            }
            onReleased: {
                imagePlayPause.width = imagePlayPause.width + 4
                imagePlayPause.height = imagePlayPause.height + 4
            }
        }
    }
}
