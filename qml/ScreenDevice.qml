import QtQuick 2.10
import QtQuick.Controls 2.3

import com.offloadbuddy.style 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: screenDevice
    width: 1280
    height: 720

    property var deviceStateList: []
    property var deviceState

    property var myDevice

    onMyDeviceChanged: {
        if (!deviceStateList[myDevice.uniqueId]) {
            deviceStateList[myDevice.uniqueId] = ({ orderBy: 0,
                                                    zoomLevel: 2.0,
                                                    mainState: "stateMediaGrid",
                                                    selectedIndex: 0,
                                                    detail_shot: null,
                                                    detail_state: "overview" })
        }

        //console.log("Device is now " + myDevice.uniqueId)

        // restore state
        deviceState = deviceStateList[myDevice.uniqueId]
        state = deviceState.mainState

        screenDeviceGrid.restoreState()
        screenDeviceGrid.updateDeviceHeader()
        screenDeviceGrid.initstateMediaGridSettings()
        screenDeviceGrid.updatestateMediaGridSettings()

        screenMedia.restoreState()
    }

    ScreenDeviceGrid {
        anchors.fill: parent
        id: screenDeviceGrid
    }
    ScreenMedia {
        anchors.fill: parent
        id: screenMedia
    }

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        acceptedButtons: Qt.BackButton | Qt.ForwardButton

        onClicked: {
            if (mouse.button === Qt.BackButton) {
                if (screenDevice.state === "stateMediaDetails")
                    screenDevice.state = "stateMediaGrid"
            } else if (mouse.button === Qt.ForwardButton) {
                if (screenDevice.state === "stateMediaGrid")
                    if (screenDeviceGrid.selectedItemIndex >= 0)
                        screenDevice.state = "stateMediaDetails"
            }
        }
    }
    Shortcut {
        sequence: StandardKey.Back
        onActivated: {
            if (screenDevice.state === "stateMediaDetails")
                screenDevice.state = "stateMediaGrid"
        }
    }
    Shortcut {
        sequence: StandardKey.Forward
        onActivated: {
            if (screenDevice.state === "stateMediaGrid")
                if (screenDeviceGrid.selectedItemIndex >= 0)
                    screenDevice.state = "stateMediaDetails"
        }
    }

    onStateChanged: {
        console.log("screendevice onStateChanged")
         // save state
         deviceState.mainState = state
    }
    state: "stateMediaGrid"
    states: [
        State {
            name: "stateMediaGrid"

            PropertyChanges {
                target: screenDeviceGrid
                visible: true
            }
            PropertyChanges {
                target: screenMedia
                visible: false
            }
        },
        State {
            name: "stateMediaDetails"

            PropertyChanges {
                target: screenDeviceGrid
                visible: false
            }
            PropertyChanges {
                target: screenMedia
                visible: true
                shot: myDevice.getShot(screenDeviceGrid.selectedItemName)
            }
        }
    ]
}
