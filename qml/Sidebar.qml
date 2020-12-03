import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

import ThemeEngine 1.0

Rectangle {
    id: sideBar
    width: isHdpi ? 80 : 92
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.bottom: parent.bottom

    color: Theme.colorSidebar

    signal myDeviceClicked(var devicePtr)
    onMyDeviceClicked: {
        if (typeof devicePtr !== "undefined") {
            //console.log(devicePtr + ' component was triggered')
            if (!(appContent.state === "device" && screenDevice.currentDevice === devicePtr)) {
                appContent.state = "device"
                screenDevice.currentDevice = devicePtr
                currentDevicePtr = devicePtr // save current device
            }
        }
    }

    Connections {
        target: deviceManager
        signal deviceRemoved(var devicePtr)
        onDeviceRemoved: {
            //console.log("deviceRemoved(" + devicePtr + ") and currentDevice(" + currentDevicePtr + ")")
            if (typeof devicePtr !== "undefined")
                if (devicePtr === currentDevicePtr)
                    appContent.state = "library"
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    DragHandler { // Drag on the sidebar to drag the whole window // Qt 5.15+
        // also, prevent clicks below this area
        onActiveChanged: if (active) appWindow.startSystemMove();
        target: null
    }

    CsdMac {
        id: macosWindowButtons
        height: 48
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
    }

    ////////////////////////////////////////////////////////////////////////////

    // MENUS up

    SidebarWidget {
        id: button_library
        height: 80

        anchors.top: macosWindowButtons.visible ? macosWindowButtons.bottom : parent.top
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        selected: appContent.state === "library"
        animated: mediaLibrary.libraryState
        onClicked: appContent.state = "library"
        source: "qrc:/menus/media.svg"
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
        delegate: SidebarWidget {
            height: 80
            myDevice: modelData
            selected: (appContent.state === "device" && modelData === currentDevicePtr)
            animated: currentDevicePtr.deviceState
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

        SidebarWidget {
            id: button_jobs
            width: sideBar.width
            imgSize: 48

            visible: jobManager.trackedJobCount
            animated: jobManager.workingJobCount

            selected: appContent.state === "jobs"
            onClicked: appContent.state = "jobs"
            source: "qrc:/menus/jobs.svg"
        }
        SidebarWidget {
            id: button_settings
            width: sideBar.width
            imgSize: 48

            selected: appContent.state === "settings"
            onClicked: appContent.state = "settings"
            source: "qrc:/menus/settings.svg"
        }
        SidebarWidget {
            id: button_about
            width: sideBar.width
            imgSize: 48

            selected: appContent.state === "about"
            onClicked: appContent.state = "about"
            source: "qrc:/menus/about.svg"
        }
        SidebarWidget {
            id: button_exit
            width: sideBar.width
            imgSize: 48

            source: "qrc:/menus/exit.svg"
            onClicked: appWindow.close()
        }
    }
}
