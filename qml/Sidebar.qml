import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

import ThemeEngine 1.0
import "qrc:/js/UtilsDeviceCamera.js" as UtilsDevice

Rectangle {
    id: sideBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.bottom: parent.bottom

    z: 10
    width: isHdpi ? 80 : 92
    color: Theme.colorSidebar

    ////////////////////////////////////////////////////////////////////////////

    DragHandler {
        // Drag on the sidebar to drag the whole window // Qt 5.15+
        // Also, prevent clicks below this area
        onActiveChanged: if (active) appWindow.startSystemMove();
        target: null
    }

    CsdMac {
        id: macosWindowButtons
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
    }

    ////////////////////////////////////////////////////////////////////////////

    // MENUS up

    DesktopSidebarItem {
        id: button_library
        height: 80

        anchors.top: macosWindowButtons.visible ? macosWindowButtons.bottom : parent.top
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        source: "qrc:/menus/media.svg"
        sourceSize: 64
        highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"
        indicatorAnimated: mediaLibrary.libraryState

        selected: appContent.state === "library"
        onClicked: appContent.state = "library"
    }

    ListView {
        id: menuDevices
        anchors.top: button_library.bottom
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.bottom: column.top
        anchors.bottomMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 0

        interactive: false
        spacing: 16

        model: deviceManager.devicesList
        delegate: DesktopSidebarItem {
            height: 80

            text: modelData.model
            source: UtilsDevice.getDevicePicture(modelData)
            sourceSize: 64
            highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"
            indicatorAnimated: modelData.deviceState

            selected: (appContent.state === "device" && modelData === screenDevice.currentDevice)
            onClicked: {
                if (!(appContent.state === "device" && screenDevice.currentDevice === modelData)) {
                    screenDevice.currentDevice = modelData
                    appContent.state = "device"
                }
            }
        }
    }

    // MENUS down

    Column {
        id: column
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        spacing: 0

        DesktopSidebarItem {
            id: button_jobs
            width: sideBar.width

            source: "qrc:/menus/jobs.svg"
            sourceSize: 48
            highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"

            visible: jobManager.trackedJobCount
            indicatorAnimated: jobManager.workingJobCount

            selected: appContent.state === "jobs"
            onClicked: appContent.state = "jobs"
        }
        DesktopSidebarItem {
            id: button_settings
            width: sideBar.width

            source: "qrc:/menus/settings.svg"
            sourceSize: 48
            highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"

            selected: appContent.state === "settings"
            onClicked: appContent.state = "settings"
        }
        DesktopSidebarItem {
            id: button_about

            source: "qrc:/menus/about.svg"
            sourceSize: 48
            highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"

            selected: appContent.state === "about"
            onClicked: appContent.state = "about"
        }
        DesktopSidebarItem {
            id: button_exit

            source: "qrc:/menus/exit.svg"
            sourceSize: 48
            highlightMode: "circle"

            onClicked: appWindow.close()
        }
    }
}
