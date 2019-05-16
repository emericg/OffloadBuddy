import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0
import "UtilsString.js" as UtilsString

Item {
    id: screenDevice
    width: 1280
    height: 720

    property var deviceSavedStateList: []
    property var deviceSavedState: null
    property var currentDevice: null

    onCurrentDeviceChanged: {
        if (currentDevice) {
            //console.log("Device is now " + currentDevice.uniqueId)
            screenDeviceGrid.updateDeviceHeader()
            screenDeviceGrid.initGridViewSettings()
            screenDeviceGrid.updateGridViewSettings()
        }

        if (currentDevice && !deviceSavedStateList[currentDevice.uniqueId]) {
            deviceSavedStateList[currentDevice.uniqueId] = ({ orderBy: 0,
                                                              filterBy: 0,
                                                              zoomLevel: 2.0,
                                                              mainState: "stateMediaGrid",
                                                              selectedIndex: 0,
                                                              detail_shot: null,
                                                              detail_state: "overview" })
        }

        if (currentDevice && deviceSavedStateList[currentDevice.uniqueId]) {
            // restore state
            deviceSavedState = deviceSavedStateList[currentDevice.uniqueId]
            state = deviceSavedState.mainState
            screenDeviceGrid.restoreState()
            screenMedia.restoreState()
        }
    }

    onStateChanged: {
        // save state
        if (deviceSavedState)
             deviceSavedState.mainState = state
    }

    // CONTENT /////////////////////////////////////////////////////////////////

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

    ScreenDeviceGrid {
        anchors.fill: parent
        id: screenDeviceGrid
    }
    ScreenMedia {
        anchors.fill: parent
        id: screenMedia
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
                shot: currentDevice.getShotByUuid(screenDeviceGrid.selectedItemUuid)
            }
        }
    ]
}
