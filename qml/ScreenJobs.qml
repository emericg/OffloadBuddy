import QtQuick
import QtQuick.Controls

import ThemeEngine
import "qrc:/utils/UtilsString.js" as UtilsString

Loader {
    id: screenJobs
    anchors.fill: parent

    function loadScreen() {
        // load screen
        screenJobs.active = true

        // change screen
        appContent.state = "jobs"
    }

    function backAction() {
        if (screenJobs.status === Loader.Ready)
            screenJobs.item.backAction()
    }

    active: false
    asynchronous: false

    sourceComponent: Item {
        anchors.fill: parent

        // HEADER //////////////////////////////////////////////////////////////

        Rectangle {
            id: rectangleHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            z: 5
            height: 64
            color: Theme.colorHeader

            DragHandler {
                // Drag on the sidebar to drag the whole window // Qt 5.15+
                // Also, prevent clicks below this area
                onActiveChanged: if (active) appWindow.startSystemMove();
                target: null
            }

            Text {
                id: textHeader
                height: 40
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentMarginXL
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("JOBS QUEUE")
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: Theme.fontSizeHeader
                color: Theme.colorHeaderContent
            }

            ButtonSolid {
                id: buttonClear
                anchors.right: parent.right
                anchors.rightMargin: Theme.componentMarginXL
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Clear finished jobs")
                source: "qrc:/assets/icons/material-symbols/backspace-fill.svg"
                layoutDirection: Qt.RightToLeft

                visible: jobManager.trackedJobCount
                onClicked: jobManager.clearFinishedJobs()
            }

            ////////

            CsdWindows { }

            CsdLinux { }

            ////////

            HeaderSeparator { }
        }

        HeaderShadow {anchors.top: rectangleHeader.bottom; }

        // CONTENT /////////////////////////////////////////////////////////////

        Item {
            id: rectangleContent

            anchors.top: rectangleHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            ListView {
                id: jobsView
                anchors.fill: parent
                anchors.margins: Theme.componentMarginXL
                spacing: Theme.componentMarginXL

                interactive: false
                model: jobManager.jobsList
                delegate: ItemJob { job: modelData; width: jobsView.width; }
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////
}
