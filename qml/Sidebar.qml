import QtQuick
import QtQuick.Controls
import QtQuick.Window

import ThemeEngine
import "qrc:/js/UtilsDeviceCamera.js" as UtilsDevice

Rectangle {
    id: sideBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.bottom: parent.bottom

    z: 10
    width: isHdpi ? 72 : 80
    color: Theme.colorSidebar

    Rectangle { // right border
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 2
        color: Theme.colorSidebarHighlight
    }

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
        height: sideBar.width

        anchors.top: macosWindowButtons.visible ? macosWindowButtons.bottom : parent.top
        anchors.topMargin: Theme.componentMargin
        anchors.left: parent.left
        anchors.right: parent.right

        source: "qrc:/assets/icons/fontawesome/photo-video-duotone.svg"
        sourceSize: 56
        highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"

        indicatorVisible: mediaLibrary.libraryState
        indicatorAnimated: mediaLibrary.libraryState
        indicatorSource: "qrc:/assets/icons/material-symbols/autorenew.svg"

        highlighted: appContent.state === "library"
        onClicked: appContent.state = "library"
    }

    Column {
        id: menuDevices

        anchors.top: button_library.bottom
        anchors.left: parent.left
        anchors.bottom: menuGeneral.top
        anchors.right: parent.right

        topPadding: Theme.componentMargin
        bottomPadding: Theme.componentMargin
        spacing: Theme.componentMargin

        Repeater {
            model: deviceManager.devicesList
            delegate: DesktopSidebarItem {
                height: sideBar.width

                text: modelData.model
                source: UtilsDevice.getDevicePicture(modelData)
                sourceSize: 60

                highlighted: (appContent.state === "device" && modelData === screenDevice.currentDevice)
                highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"

                indicatorVisible: modelData.deviceState
                indicatorAnimated: modelData.deviceState
                indicatorSource: "qrc:/assets/icons/material-symbols/autorenew.svg"

                onClicked: {
                    if (!(appContent.state === "device" && screenDevice.currentDevice === modelData)) {
                        screenDevice.currentDevice = modelData
                        appContent.state = "device"
                    }
                }
            }
        }
    }

    // MENUS down

    Column {
        id: menuGeneral
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        bottomPadding: Theme.componentMargin
        spacing: 0

        DesktopSidebarItem { // button_jobs
            visible: jobManager.trackedJobCount

            source: "qrc:/assets/icons/material-icons/duotone/save_alt.svg"
            sourceSize: 40

            highlighted: (appContent.state === "jobs")
            highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"

            indicatorVisible: jobManager.workingJobCount
            indicatorAnimated: jobManager.workingJobCount
            indicatorSource: "qrc:/assets/icons/material-symbols/autorenew.svg"

            onClicked: screenJobs.loadScreen()
        }
        DesktopSidebarItem { // button_settings
            source: "qrc:/assets/icons/material-icons/duotone/tune.svg"
            sourceSize: 40

            highlighted: (appContent.state === "settings")
            highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"

            onClicked: screenSettings.loadScreen()
        }
        DesktopSidebarItem { // button_about
            source: "qrc:/assets/icons/material-icons/duotone/info.svg"
            sourceSize: 40

            highlighted: (appContent.state === "about")
            highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"

            onClicked: screenAbout.loadScreen()
        }
        DesktopSidebarItem { // button_exit
            source: "qrc:/assets/icons/material-icons/duotone/exit_to_app.svg"
            sourceSize: 40

            highlightMode: "circle"

            onClicked: appWindow.close()
        }
    }

    ////////////////////////////////////////////////////////////////////////////
}
