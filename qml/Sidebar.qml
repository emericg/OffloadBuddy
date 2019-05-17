import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Window 2.2

import com.offloadbuddy.theme 1.0

Rectangle {
    id: sideBar
    width: 96
    color: Theme.colorSidebar

    anchors.left: parent.left
    anchors.leftMargin: 0
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 0
    anchors.top: parent.top
    anchors.topMargin: 0
    transformOrigin: Item.Center

    Connections {
        target: applicationContent
        onStateChanged: {
            if (applicationContent.state === "library") {
                selectorArrow.anchors.verticalCenter = button_library.verticalCenter
                selectorBar.anchors.verticalCenter = button_library.verticalCenter
                selectorBar.height = 68
            } else if (applicationContent.state === "device") {
                selectorArrow.anchors.verticalCenter = undefined
                selectorBar.anchors.verticalCenter = undefined
                selectorBar.height = 68
            } else if (applicationContent.state === "jobs") {
                selectorArrow.anchors.verticalCenter = button_jobs.verticalCenter
                selectorBar.anchors.verticalCenter = button_jobs.verticalCenter
                selectorBar.height = 54
            } else if (applicationContent.state === "settings") {
                selectorArrow.anchors.verticalCenter = button_settings.verticalCenter
                selectorBar.anchors.verticalCenter = button_settings.verticalCenter
                selectorBar.height = 54
            } else if (applicationContent.state === "about") {
                selectorArrow.anchors.verticalCenter = button_about.verticalCenter
                selectorBar.anchors.verticalCenter = button_about.verticalCenter
                selectorBar.height = 54
            }
        }
    }

    signal myDeviceClicked(var devicePtr)
    onMyDeviceClicked: {
        if (typeof devicePtr !== "undefined") {
            //console.log(devicePtr + ' component was triggered')
            applicationContent.state = "device"
            screenDevice.currentDevice = devicePtr
            currentDevicePtr = devicePtr // save current device
        }
    }

    Connections {
        target: deviceManager
        signal deviceRemoved(var devicePtr)
        onDeviceRemoved: {
            //console.log("deviceRemoved(" + devicePtr + ") and currentDevice(" + currentDevicePtr + ")")
            if (typeof devicePtr !== "undefined")
                if (devicePtr === currentDevicePtr)
                    applicationContent.state = "library"
        }
    }

    Connections {
        target: jobManager
        onTrackedJobsUpdated: {
            if (button_jobs.visible === false && jobManager.trackedJobCount > 0) {
                button_jobs.visible = true
                button_jobs_fadein.start()
            }

            if (jobManager.workingJobCount > 0) {
                button_jobs_working.start()
            } else {
                button_jobs_working.stop()
                button_jobs_fadein.start()
            }
        }
    }

    // SELECTORS

    ImageSvg {
        id: selectorArrow
        width: 12
        height: 12
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.verticalCenter: button_library.verticalCenter

        visible: (Theme.selector === "arrow")
        source: "qrc:/menus/selector_arrow.svg"
        color: Theme.colorSidebarContent
    }

    Rectangle {
        id: selectorBar
        width: parent.width
        height: 64
        anchors.verticalCenter: button_library.verticalCenter

        visible: (Theme.selector === "bar")
        color: "black"

        Rectangle {
            width: 4
            height: parent.height
            color: Theme.colorPrimary
        }
    }

    // MENUS

    Item {
        id: button_library
        width: 64
        height: 64
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 24

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: applicationContent.state = "library"
        }

        ImageSvg {
            anchors.fill: parent
            source: "qrc:/menus/media.svg"
            color: Theme.colorSidebarContent
        }
    }

    Item {
        id: menuDevice
        anchors.bottom: button_settings.top
        anchors.bottomMargin: 16
        anchors.top: button_library.bottom
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        ListView {
            id: devicesview
            interactive: false
            spacing: 16
            anchors.fill: parent

            model: deviceManager.devicesList
            delegate: ItemDeviceMenu {
                myDevice: modelData
                Component.onCompleted: {
                    myDeviceClicked.connect(sideBar.myDeviceClicked)
                }
            }
        }
    }

    Item {
        id: button_jobs
        width: 50
        height: 50
        anchors.bottom: button_settings.top
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter

        visible: false

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: applicationContent.state = "jobs"
        }
        ImageSvg {
            id: button_jobs_image
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: "qrc:/menus/jobs.svg"
            opacity: 0
            color: Theme.colorSidebarContent

            NumberAnimation on opacity {
                id: button_jobs_fadein
                from: button_jobs_image.opacity
                to: 1
                duration: 1000
            }

            SequentialAnimation on opacity {
                id: button_jobs_working
                running: false
                loops: Animation.Infinite
                OpacityAnimator { from: 0; to: 1; duration: 1000 }
                OpacityAnimator { from: 1; to: 0; duration: 1000 }
            }
        }
    }

    Item {
        id: button_settings
        width: 50
        height: 50
        anchors.bottom: button_about.top
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: applicationContent.state = "settings"
        }
        ImageSvg {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: "qrc:/menus/settings.svg"
            color: Theme.colorSidebarContent
        }
    }

    Item {
        id: button_about
        width: 50
        height: 50
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: button_exit.top
        anchors.bottomMargin: 8

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: applicationContent.state = "about"
        }
        ImageSvg {
            anchors.fill: parent
            source: "qrc:/menus/about.svg"
            color: Theme.colorSidebarContent
        }
    }

    Item {
        id: button_exit
        width: 50
        height: 50
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }
        ImageSvg {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: "qrc:/menus/exit.svg"
            color: Theme.colorSidebarContent
        }
    }
}
