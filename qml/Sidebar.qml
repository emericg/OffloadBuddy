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
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        source: "qrc:/assets/icons_fontawesome/photo-video-duotone.svg"
        sourceSize: 60
        highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"
        indicatorAnimated: mediaLibrary.libraryState

        highlighted: appContent.state === "library"
        onClicked: appContent.state = "library"
    }

    ListView {
        id: menuDevices
        anchors.top: button_library.bottom
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.bottom: menuGeneral.top
        anchors.bottomMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 0

        interactive: false
        spacing: 16

        model: deviceManager.devicesList
        delegate: DesktopSidebarItem {
            height: sideBar.width

            text: modelData.model
            source: UtilsDevice.getDevicePicture(modelData)
            sourceSize: 60
            highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"
            indicatorAnimated: modelData.deviceState

            highlighted: (appContent.state === "device" && modelData === screenDevice.currentDevice)
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
        id: menuGeneral
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16

        spacing: 0

        DesktopSidebarItem {
            id: button_jobs

            source: "qrc:/assets/icons_material/duotone-save_alt-24px.svg"
            sourceSize: 40
            highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"

            visible: jobManager.trackedJobCount
            indicatorVisible: jobManager.workingJobCount
            indicatorAnimated: jobManager.workingJobCount
            indicatorSource: "qrc:/assets/icons_material/baseline-autorenew-24px.svg"

            highlighted: (appContent.state === "jobs")
            onClicked: screenJobs.loadScreen()
        }
        DesktopSidebarItem {
            id: button_settings

            source: "qrc:/assets/icons_material/duotone-tune-24px.svg"
            sourceSize: 40
            highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"

            highlighted: (appContent.state === "settings")
            onClicked: screenSettings.loadScreen()
        }
        DesktopSidebarItem {
            id: button_about

            source: "qrc:/assets/icons_material/duotone-info-24px.svg"
            sourceSize: 40
            highlightMode: (Theme.sidebarSelector) ? "indicator" : "background"

            highlighted: (appContent.state === "about")
            onClicked: screenAbout.loadScreen()
        }
        DesktopSidebarItem {
            id: button_exit

            source: "qrc:/assets/icons_material/duotone-exit_to_app-24px.svg"
            sourceSize: 40
            highlightMode: "circle"

            onClicked: appWindow.close()
        }
    }
}
