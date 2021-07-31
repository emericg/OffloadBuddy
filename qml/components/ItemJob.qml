import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import JobUtils 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Rectangle {
    id: itemJob
    implicitWidth: 640
    implicitHeight: 48

    height: 48 + (expanded ? jobline2.height : 0)
    Behavior on height { NumberAnimation { duration: 133 } }

    radius: Theme.componentRadius
    color: Theme.colorForeground
    clip: true

    property var job: null
    property bool expanded: false

    signal pauseClicked()
    signal stopClicked()

    ////////////////////////////////////////////////////////////////////////////

    Component.onCompleted: updateJobStatus()
    Connections {
        target: job
        onJobUpdated: updateJobStatus()
    }

    function updateJobStatus() {

        // status
        //if (encodeAnimation.running || offloadAnimation.running) return

        if (job.state === JobUtils.JOB_STATE_QUEUED) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-schedule-24px.svg"
        } else if (job.state === JobUtils.JOB_STATE_WORKING) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-autorenew-24px.svg"
        } else if (job.state === JobUtils.JOB_STATE_PAUSED) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-pause-24px.svg"
        } else if (job.state === JobUtils.JOB_STATE_DONE) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-done-24px.svg"
        } else if (job.state === JobUtils.JOB_STATE_ERRORED) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-error-24px.svg"
        } else if (job.state === JobUtils.JOB_STATE_ABORTED) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-cancel-24px.svg"
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    MouseArea {
        anchors.fill: parent
        onClicked: expanded = !expanded
    }

    Item {
        id: jobline1
        height: 48
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12

        Row {
            id: rowTexts
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            ImageSvg {
                id: imageStatus
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                source: "qrc:/assets/icons_material/baseline-schedule-24px.svg"
                color: Theme.colorIcon

                NumberAnimation on rotation {
                    id: encodeAnimation
                    running: (job.state === JobUtils.JOB_STATE_WORKING &&
                              job.type === JobUtils.JOB_ENCODE)
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    onFinished: updateJobStatus()

                    duration: 2000
                    from: 0
                    to: 360
                }

                SequentialAnimation {
                    id: offloadAnimation
                    running: (job.state === JobUtils.JOB_STATE_WORKING &&
                              job.type === JobUtils.JOB_OFFLOAD)
                    loops: Animation.Infinite
                    alwaysRunToEnd: true

                    onFinished: updateJobStatus()
                    onStopped: imageStatus.y = 0

                    NumberAnimation {
                        target: imageStatus
                        property: "y"
                        from: -40
                        to: 40
                        duration: 1000
                    }
                }
            }

            ImageSvg {
                id: imageJob
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                source: {
                    if (job.type === JobUtils.JOB_ENCODE)
                        return "qrc:/assets/icons_material/baseline-memory-24px.svg"
                    else if (job.type === JobUtils.JOB_OFFLOAD || job.type === JobUtils.JOB_MOVE)
                        return "qrc:/assets/icons_material/baseline-save_alt-24px.svg"
                    else
                        return "qrc:/assets/icons_material/baseline-autorenew-24px.svg"
                }
                color: Theme.colorIcon

                SequentialAnimation on opacity {
                    running: (job.state === JobUtils.JOB_STATE_WORKING &&
                              job.type === JobUtils.JOB_ENCODE)
                    loops: Animation.Infinite
                    alwaysRunToEnd: true

                    PropertyAnimation { to: 0.5; duration: 750; }
                    PropertyAnimation { to: 1; duration: 750; }
                }
                SequentialAnimation {
                    running: (job.state === JobUtils.JOB_STATE_WORKING &&
                              job.type === JobUtils.JOB_OFFLOAD)
                    loops: Animation.Infinite
                    //alwaysRunToEnd: true
                    onStopped: imageJob.y = 0

                    NumberAnimation {
                        target: imageJob
                        property: "y"
                        from: -40
                        to: 40
                        duration: 1000
                    }
                }
            }

            Text {
                id: jobType
                height: 40
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
                anchors.verticalCenter: parent.verticalCenter

                text: job.name
                font.pixelSize: 14
                color: Theme.colorText
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: jobDuration
                width: 32
                anchors.verticalCenter: parent.verticalCenter

                visible: job.elapsed > 0
                font.pixelSize: 14
                color: Theme.colorSubText
                horizontalAlignment: Text.AlignHCenter

                Timer {
                    running: job.running && job.elapsed > 0
                    interval: 666
                    onTriggered: parent.text = job.elapsed + qsTr("s", "short for second")
                }
            }
        }

        ////////////////

        ProgressBarThemed {
            id: progressBar
            anchors.left: rowTexts.right
            anchors.leftMargin: 12
            anchors.right: rowButtons.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter

            height: 10
            value: job.progress
            colorBackground: Theme.colorBackground
        }

        ////////////////

        Row {
            id: rowButtons
            height: 40
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: jobETA
                width: 32
                anchors.verticalCenter: parent.verticalCenter

                color: Theme.colorSubText
                visible: job.eta > 0
                horizontalAlignment: Text.AlignHCenter

                Timer {
                    running: job.running && job.eta > 0
                    interval: 666
                    onTriggered: parent.text = job.eta + qsTr("s", "short for second")
                }
            }

            ItemImageButton {
                id: rectanglePlayPause
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                visible: ((Qt.platform.os === "linux" || Qt.platform.os === "osx") &&
                          (job.state === JobUtils.JOB_STATE_WORKING || job.state === JobUtils.JOB_STATE_PAUSED)) // running

                highlightMode: "color"
                source: job.state === JobUtils.JOB_STATE_WORKING ? "qrc:/assets/icons_material/outline-pause_circle-24px.svg"
                                                                 : "qrc:/assets/icons_material/outline-play_circle-24px.svg"
                onClicked: jobManager.playPauseJob(job.id)
            }

            ItemImageButton {
                id: rectangleStop
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                visible: ((Qt.platform.os === "linux" || Qt.platform.os === "osx") &&
                          (job.state === JobUtils.JOB_STATE_WORKING || job.state === JobUtils.JOB_STATE_PAUSED)) // running

                highlightMode: "color"
                source: "qrc:/assets/icons_material/outline-stop_circle-24px.svg"
                onClicked: jobManager.stopJob(job.id)
            }
/*
            ItemImageButton {
                id: rectangleOpenFile
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                visible: job.destination.length
                highlightMode: "color"
                source: "qrc:/assets/icons_material/baseline-folder-24px.svg"
                onClicked: job.openDestinationFile()
            }
*/
            ItemImageButton {
                id: rectangleOpenFolder
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                visible: job.destination.length
                highlightMode: "color"
                source: "qrc:/assets/icons_material/baseline-folder_open-24px.svg"
                onClicked: job.openDestinationFolder()
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Item {
        id: jobline2
        anchors.top: jobline1.bottom
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12

        height: Math.min(320, joblinecolumn.height)
        visible: expanded

        Column {
            id: joblinecolumn
            anchors.left: parent.left
            anchors.right: parent.right

            spacing: 8
            bottomPadding: 8

            Row {
                spacing: 24

                Row {
                    spacing: 8

                    Text {
                        text: qsTr("Status:")
                        color: Theme.colorText
                    }
                    Text {
                        text: job.stateStr
                        color: Theme.colorSubText
                    }
                }

                Row {
                    visible: job.state >= JobUtils.JOB_STATE_WORKING
                    spacing: 8

                    Text {
                        text: qsTr("Started:")
                        color: Theme.colorText
                    }
                    Text {
                        text: job.startDate.toLocaleTimeString("hh:ss")
                        color: Theme.colorSubText
                    }
                }

                Row {
                    visible: job.state >= JobUtils.JOB_STATE_DONE
                    spacing: 8

                    Text {
                        text: qsTr("Stopped:")
                        color: Theme.colorText
                    }
                    Text {
                        text: job.stopDate.toLocaleTimeString("hh:ss")
                        color: Theme.colorSubText
                    }
                }
            }

            Row {
                spacing: 8
                visible: job.destination

                Text {
                    text: qsTr("Destination:")
                    color: Theme.colorText
                }
                Text {
                    text: job.destination
                    color: Theme.colorSubText
                }
            }

            Row {
                spacing: 8

                Text {
                    text: qsTr("Source(s):")
                    color: Theme.colorText
                }
                Repeater {
                    model: job.files
                    Text {
                        text: modelData
                        color: Theme.colorSubText
                    }
                }
            }
        }
    }
}
