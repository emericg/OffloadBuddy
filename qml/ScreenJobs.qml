import QtQuick 2.15
import QtQuick.Controls 2.15

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: screenJobs
    width: 1280
    height: 720

    // HEADER //////////////////////////////////////////////////////////////////

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
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("JOBS QUEUE")
            verticalAlignment: Text.AlignVCenter
            font.bold: true
            font.pixelSize: Theme.fontSizeHeader
            color: Theme.colorHeaderContent
        }

        ButtonWireframeIcon {
            id: buttonClear
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            fullColor: true
            text: qsTr("Clear finished jobs")
            source: "qrc:/assets/icons_material/baseline-backspace-24px.svg"
            layoutDirection: Qt.RightToLeft

            visible: jobManager.trackedJobCount
            onClicked: jobManager.clearFinishedJobs()
        }

        ////////

        CsdWindows { }

        CsdLinux { }

        ////////

        Rectangle { // separator
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: 2
            opacity: 0.1
            color: Theme.colorHeaderContent
        }
        Rectangle { // shadow
            anchors.top: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            height: 8
            opacity: 0.5

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Theme.colorHeaderHighlight; }
                GradientStop { position: 1.0; color: Theme.colorBackground; }
            }
        }
    }

    // CONTENT /////////////////////////////////////////////////////////////////

    Item {
        id: rectangleContent

        anchors.top: rectangleHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        ListView {
            id: jobsView
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            interactive: false
            model: jobManager.jobsList
            delegate: ItemJob { job: modelData; width: jobsView.width; }
        }
    }
}
