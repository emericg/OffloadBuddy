import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2

import com.offloadbuddy.theme 1.0
import "UtilsString.js" as UtilsString

Rectangle {
    width: 1280
    height: 720

    property var myJobs

    Rectangle {
        id: rectangleHeader
        height: 64
        color: Theme.colorHeaderBackground
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        Text {
            id: textHeader
            height: 40
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("RUNNING JOBS")
            verticalAlignment: Text.AlignVCenter
            font.bold: true
            font.pixelSize: Theme.fontSizeHeaderTitle
            color: Theme.colorHeaderTitle
        }

        ButtonThemed {
            id: buttonClear
            width: 256
            text: qsTr("Clear finished jobs")
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            onClicked: myJobs.clearFinishedJobs()
        }
    }

    Rectangle {
        id: rectangleContent
        color: Theme.colorContentBackground

        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        Rectangle {
            id: rectangleJobs
            color: Theme.colorContentBox

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16

            ListView {
                id: jobsView
                width: parent.width
                interactive: false
                model: jobManager.jobsList
                delegate: ItemJob { job: modelData }

                spacing: 16
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 16
            }
        }
    }
}
