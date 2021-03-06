import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Rectangle {
    id: itemJob
    implicitWidth: 640
    implicitHeight: 48

    radius: Theme.componentRadius
    color: Theme.colorForeground

    property var job: null
    property bool expended: false

    signal pauseClicked()
    signal stopClicked()

    ////////////////////////////////////////////////////////////////////////////

    Component.onCompleted: updateJobStatus()

    Connections {
        target: job
        onJobUpdated: updateJobStatus()
    }

    function updateJobStatus() {
        if (job.state === 0) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-done-24px.svg"
        } else if (job.state === 1) {
            if (job.typeStr === qsTr("ENCODING"))
                imageStatus.source = "qrc:/assets/icons_material/baseline-memory-24px.svg"
            else if (job.typeStr === qsTr("OFFLOADING") || job.typeStr === qsTr("MOVE"))
                imageStatus.source = "qrc:/assets/icons_material/baseline-save_alt-24px.svg"
            else
                imageStatus.source = "qrc:/assets/icons_material/baseline-autorenew-24px.svg"
        } else if (job.state === 2) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-pause-24px.svg"
        } else if (job.state === 8) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-done-24px.svg"
        } else if (job.state === 9) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-error-24px.svg"
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Item {
        height: 48
        anchors.left: parent.left
        anchors.right: parent.right

        ImageSvg {
            id: imageStatus
            width: 32
            height: 32
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter

            source: "qrc:/assets/icons_material/baseline-schedule-24px.svg"
            color: Theme.colorIcon

            NumberAnimation on rotation {
                id: encodeAnimation
                running: (job.state === 1 && job.typeStr === qsTr("ENCODING"))
                alwaysRunToEnd: true
                loops: Animation.Infinite

                duration: 2000
                from: 0
                to: 360
            }

            SequentialAnimation {
                id: offloadAnimation
                running: (job.state === 1 && job.typeStr === qsTr("OFFLOADING"))
                alwaysRunToEnd: true
                loops: Animation.Infinite

                onStopped: imageStatus.y = 0
                NumberAnimation { target: imageStatus; property: "y"; from: -40; to: 40; duration: 1000; }
            }
        }

        Text {
            id: jobType
            height: 40
            anchors.left: imageStatus.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter

            text: job.typeStr
            color: Theme.colorText
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 14
        }

        Text {
            id: jobName
            height: 40
            anchors.left: jobType.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            text: job.name
            font.pixelSize: 14
            color: Theme.colorText
            verticalAlignment: Text.AlignVCenter
        }

        ProgressBarThemed {
            id: progressBar
            height: 12
            anchors.right: rowButtons.left
            anchors.rightMargin: 8
            anchors.left: jobName.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            value: job.progress
        }

        Row {
            id: rowButtons
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 12
/*
            ItemImageButton {
                id: rectanglePlayPause
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                visible: (job.state === 1 || job.state === 2) // running
                highlightMode: "color"
                source: "qrc:/assets/icons_material/baseline-pause_circle_outline-24px.svg"
                onClicked: job.setPlayPause()
            }

            ItemImageButton {
                id: rectangleStop
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                visible: (job.state === 1 || job.state === 2) // running
                highlightMode: "color"
                source: "qrc:/assets/icons_material/baseline-cancel-24px.svg"
                onClicked: jobManager.stopJob(job.name)
            }
*/
            ItemImageButton {
                id: rectangleOpen
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                visible: job.destination.length
                highlightMode: "color"
                source: "qrc:/assets/icons_material/baseline-folder_open-24px.svg"
                onClicked: job.openDestination()
            }
        }
    }
}
