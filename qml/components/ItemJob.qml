import QtQuick
import QtQuick.Controls

import ThemeEngine
import JobUtils 1.0
import "qrc:/utils/UtilsString.js" as UtilsString

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
            id: rowStatus
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                clip: true

                IconSvg {
                    id: imageJob
                    width: 32
                    height: 32

                    source: {
                        if (job.type === JobUtils.JOB_ENCODE || job.type === JobUtils.JOB_CLIP)
                            return "qrc:/assets/icons/material-symbols/memory.svg"
                        else if (job.type === JobUtils.JOB_OFFLOAD || job.type === JobUtils.JOB_MOVE)
                            return "qrc:/assets/icons/material-icons/duotone/save_alt.svg"
                        else if (job.type === JobUtils.JOB_MERGE)
                            return "qrc:/assets/icons/material-symbols/merge_type.svg"
                        else if (job.type === JobUtils.JOB_DELETE || job.type === JobUtils.JOB_FORMAT)
                            return "qrc:/assets/icons/material-symbols/delete.svg"
                        else if (job.type === JobUtils.JOB_TELEMETRY)
                            return "qrc:/assets/icons/material-symbols/insert_chart.svg"
                        else if (job.type === JobUtils.JOB_FIRMWARE_UPDATE)
                            return "qrc:/assets/icons/material-symbols/settings_applications.svg"
                        else
                            return "qrc:/assets/icons/material-symbols/autorenew.svg"
                    }
                    color: Theme.colorIcon

                    SequentialAnimation on opacity {
                        running: (job.state === JobUtils.JOB_STATE_WORKING &&
                                  job.type === JobUtils.JOB_ENCODE)
                        loops: Animation.Infinite
                        alwaysRunToEnd: true

                        PropertyAnimation { to: 0.5; duration: 666; }
                        PropertyAnimation { to: 1; duration: 666; }
                    }
                    SequentialAnimation {
                        running: (job.state === JobUtils.JOB_STATE_WORKING &&
                                  job.type === JobUtils.JOB_OFFLOAD)
                        loops: Animation.Infinite
                        alwaysRunToEnd: false

                        onStopped: imageJob.y = 0
                        NumberAnimation { target: imageJob; property: "y"; duration: 666; to: 32; }
                        NumberAnimation { target: imageJob; property: "y"; duration: 666; to: -32; }
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
                font.pixelSize: Theme.fontSizeContentSmall
            }

            Text {
                id: jobName
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                text: job.name
                font.pixelSize: Theme.fontSizeContentSmall
                color: Theme.colorText
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: jobElements
                width: 32
                anchors.verticalCenter: parent.verticalCenter

                visible: (job.elementsCount > 1)
                text: (job.elementsIndex+1) + "/" + job.elementsCount
                font.pixelSize: Theme.fontSizeContentSmall
                color: Theme.colorSubText
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                id: jobDuration
                width: 32
                anchors.verticalCenter: parent.verticalCenter

                visible: (job.elapsed > 0)
                font.pixelSize: Theme.fontSizeContentSmall
                color: Theme.colorSubText
                horizontalAlignment: Text.AlignHCenter

                Timer {
                    running: (job.running && job.elapsed > 0)
                    interval: 666
                    onTriggered: parent.text = job.elapsed + qsTr("s", "short for second")
                }
            }
        }

        ////////////////

        ProgressBarThemed {
            id: progressBar
            anchors.left: rowStatus.right
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

            RoundButtonIcon {
                id: rectangleOpenFolder
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                visible: (job.destinationFolder.length && job.state >= JobUtils.JOB_STATE_WORKING)
                highlightMode: "color"
                source: "qrc:/assets/icons/material-symbols/folder_open.svg"
                onClicked: job.openDestinationFolder()
            }

            RoundButtonIcon {
                id: rectangleOpenFile
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                visible: (job.destinationFile.length && job.state === JobUtils.JOB_STATE_DONE)
                highlightMode: "color"
                source: "qrc:/assets/icons/material-icons/duotone/launch.svg"
                onClicked: job.openDestinationFile()
            }

            RoundButtonIcon {
                id: rectanglePlayPause
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                visible: ((Qt.platform.os === "linux" || Qt.platform.os === "osx") &&
                          (job.type === JobUtils.JOB_ENCODE) &&
                          (job.state === JobUtils.JOB_STATE_WORKING || job.state === JobUtils.JOB_STATE_PAUSED)) // running

                highlightMode: "color"
                source: job.state === JobUtils.JOB_STATE_WORKING ? "qrc:/assets/icons_material/outline-pause_circle.svg"
                                                                 : "qrc:/assets/icons_material/outline-play_circle.svg"
                onClicked: jobManager.playPauseJob(job.id)
            }

            RoundButtonIcon {
                id: rectangleStop
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                visible: ((Qt.platform.os === "linux" || Qt.platform.os === "osx") &&
                          (job.type === JobUtils.JOB_ENCODE || job.type === JobUtils.JOB_FIRMWARE_UPDATE) &&
                          (job.state === JobUtils.JOB_STATE_WORKING || job.state === JobUtils.JOB_STATE_PAUSED)) // running

                highlightMode: "color"
                source: "qrc:/assets/icons_material/outline-stop_circle.svg"
                onClicked: jobManager.stopJob(job.id)
            }

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

            Item { // separator
                width: 8; height: 8;
                visible: (rectangleOpenFile.visible || rectangleOpenFolder.visible ||
                          rectanglePlayPause.visible || rectangleStop.visible ||
                          jobETA.visible)
            }

            IconSvg {
                id: imageStatus
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                color: Theme.colorIcon
                source: {
                    if (job.state === JobUtils.JOB_STATE_QUEUED) {
                        return "qrc:/assets/icons/material-icons/duotone/schedule.svg"
                    } else if (job.state === JobUtils.JOB_STATE_WORKING) {
                        return "qrc:/assets/icons/material-symbols/autorenew.svg"
                    } else if (job.state === JobUtils.JOB_STATE_PAUSED) {
                        return "qrc:/assets/icons/material-symbols/pause-fill.svg"
                    } else if (job.state === JobUtils.JOB_STATE_DONE) {
                        return "qrc:/assets/icons_material/outline-check_circle.svg"
                    } else if (job.state === JobUtils.JOB_STATE_ERRORED) {
                        return "qrc:/assets/icons/material-symbols/report.svg"
                    } else if (job.state === JobUtils.JOB_STATE_ABORTED) {
                        return "qrc:/assets/icons/material-symbols/cancel.svg"
                    }
                }

                NumberAnimation on rotation {
                    loops: Animation.Infinite
                    alwaysRunToEnd: false

                    running: (job.state === JobUtils.JOB_STATE_WORKING)
                    from: 0
                    to: 360
                    duration: 2000
                    onStopped: imageStatus.rotation = 0
                }
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
                visible: job.destinationFolder || job.destinationFile

                Text {
                    text: qsTr("Destination:")
                    color: Theme.colorText
                }
                Text {
                    text: job.destinationFolder
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
