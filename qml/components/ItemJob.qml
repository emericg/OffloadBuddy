import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
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
        if (job.state === 0) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-schedule-24px.svg"
        } else if (job.state === 1) {
            if (job.typeStr === qsTr("ENCODING"))
                imageStatus.source = "qrc:/assets/icons_material/baseline-memory-24px.svg"
            else if (job.typeStr === qsTr("OFFLOADING") || job.typeStr === qsTr("MOVE"))
                imageStatus.source = "qrc:/assets/icons_material/baseline-save_alt-24px.svg"
            else
                imageStatus.source = "qrc:/assets/icons_material/baseline-autorenew-24px.svg"
        } else if (job.state === 2) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-pause-24px.svg"
        }

        if (encodeAnimation.running || offloadAnimation.running) return

        if (job.state === 8) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-done-24px.svg"
        } else if (job.state === 9) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-error-24px.svg"
        } else if (job.state === 10) {
            imageStatus.source = "qrc:/assets/icons_material/baseline-error-24px.svg"
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
                    running: (job.state === 1 && job.typeStr === qsTr("ENCODING"))
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    onFinished: updateJobStatus()

                    duration: 2000
                    from: 0
                    to: 360
                }

                SequentialAnimation {
                    id: offloadAnimation
                    running: (job.state === 1 && job.typeStr === qsTr("OFFLOADING"))
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

            height: 12
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
/*
            ItemImageButton {
                id: rectanglePlayPause
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                visible: ((Qt.platform.os === "linux" || Qt.platform.os === "osx") &&
                          (job.state === 1 || job.state === 2)) // running

                highlightMode: "color"
                source: job.state === 1 ? "qrc:/assets/icons_material/baseline-pause_circle_outline-24px.svg" :
                                          "qrc:/assets/icons_material/baseline-play_circle_outline-24px.svg"
                onClicked: jobManager.playPauseJob(job.id)
            }

            ItemImageButton {
                id: rectangleStop
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                visible: ((Qt.platform.os === "linux" || Qt.platform.os === "osx") &&
                          (job.state === 1 || job.state === 2)) // running

                highlightMode: "color"
                source: "qrc:/assets/icons_material/baseline-cancel-24px.svg"
                onClicked: jobManager.stopJob(job.id)
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
                    visible: false
                    spacing: 8

                    Text {
                        text: qsTr("Status:")
                        color: Theme.colorText
                    }
                    Text {
                        text: job.state
                        color: Theme.colorSubText
                    }
                }

                Row {
                    visible: job.state >= 1
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
                    visible: job.state >= 8
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
