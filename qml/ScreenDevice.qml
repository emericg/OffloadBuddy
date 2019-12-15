import QtQuick 2.9
import QtQuick.Controls 2.2

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: screenDevice
    width: 1280
    height: 720

    property var deviceSavedStateList: []
    property var deviceSavedState: null
    property var currentDevice: null

    onCurrentDeviceChanged: {
        if (typeof currentDevice === "undefined" || !currentDevice) return

        //console.log("Device is now " + currentDevice.uuid)

        // No saved state? Initialize it!
        if (!(deviceSavedStateList[currentDevice.uuid])) {
            deviceSavedStateList[currentDevice.uuid] = ({ orderBy: 0,
                                                          filterBy: 0,
                                                          thumbSize: settingsManager.thumbSize,
                                                          thumbFormat: settingsManager.thumbFormat,
                                                          mainState: "stateMediaGrid",
                                                          selectedIndex: -1,
                                                          selectionMode: false,
                                                          selectionList: [],
                                                          selectionCount: 0,
                                                          detail_shot: null,
                                                          detail_state: "overview" })
        }

        // Restore state
        deviceSavedState = deviceSavedStateList[currentDevice.uuid]

        screenDeviceGrid.updateGridState()
        screenDeviceGrid.initDeviceHeader()
        screenDeviceGrid.initGridViewSettings()
        screenDeviceGrid.restoreState()
        screenMedia.restoreState()

        screenDevice.state = deviceSavedState.mainState
    }

    // KEYS HANDLING ///////////////////////////////////////////////////////////

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

    ScreenDeviceGrid {
        anchors.fill: parent
        id: screenDeviceGrid
    }
    ScreenMedia {
        anchors.fill: parent
        id: screenMedia
    }

    // STATES //////////////////////////////////////////////////////////////////

    onStateChanged: {
        // save state
        if (deviceSavedState) deviceSavedState.mainState = state
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
