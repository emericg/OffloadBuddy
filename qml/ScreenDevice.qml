import QtQuick
import QtQuick.Controls

import ThemeEngine
import "qrc:/utils/UtilsString.js" as UtilsString

Item {
    id: screenDevice
    width: 1280
    height: 720

    property var deviceSavedStateList: []
    property var deviceSavedState: null
    property var currentDevice: null

    function updateFocus() {
        console.log("screenDevice.updateFocus()")
        screenMedia.updateFocus()
    }

    onCurrentDeviceChanged: {
        //console.log("onCurrentDeviceChanged() Device is now " + currentDevice.uuid)
        if (typeof currentDevice === "undefined" || !currentDevice) return

        // No saved state? Initialize it!
        if (!(deviceSavedStateList[currentDevice.uuid])) {
            deviceSavedStateList[currentDevice.uuid] = ({ mainState: "stateMediaGrid",
                                                          orderBy: settingsManager.deviceSortRole,
                                                          orderByAscDesc: settingsManager.deviceSortOrder,
                                                          filterBy: 0,
                                                          thumbSize: settingsManager.thumbSize,
                                                          thumbFormat: settingsManager.thumbFormat,
                                                          selectedIndex: -1,
                                                          selectionMode: false,
                                                          selectionList: [],
                                                          selectionCount: 0,
                                                          detail_shot: null,
                                                          detail_state: "overview" })
        }

        // Select saved state
        deviceSavedState = deviceSavedStateList[currentDevice.uuid]

        screenDevice.state = deviceSavedState.mainState
        screenDeviceGrid.updateGridState()
        screenDeviceGrid.initDeviceHeader()
        screenDeviceGrid.initGridViewSettings()
        screenDeviceGrid.restoreState()
        screenMedia.restoreShot(false)
    }

    // KEYS HANDLING ///////////////////////////////////////////////////////////

    Shortcut {
        sequences: [StandardKey.Back]
        onActivated: {
            if (screenDevice.state === "stateMediaDetails" || screenDevice.state === "stateDeviceInfos")
                screenMedia.back()
        }
    }
    Shortcut {
        sequences: [StandardKey.Forward]
        onActivated: {
            if (screenDevice.state === "stateMediaGrid")
                screenMedia.restoreShot(true)
        }
    }

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        acceptedButtons: Qt.BackButton | Qt.ForwardButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.BackButton) {
                if (screenDevice.state === "stateMediaDetails" || screenDevice.state === "stateDeviceInfos")
                    screenMedia.back()
            } else if (mouse.button === Qt.ForwardButton) {
                if (screenDevice.state === "stateMediaGrid")
                    screenMedia.restoreShot(true)
            }
        }
    }

    //focus: (appContent.state === "device")

    // CONTENT /////////////////////////////////////////////////////////////////

    ScreenDeviceGrid {
        anchors.fill: parent
        id: screenDeviceGrid
    }
    ScreenMedia {
        anchors.fill: parent
        id: screenMedia
        startedFrom: "device"
    }
    ScreenDeviceInfos {
        anchors.fill: parent
        id: screenDeviceInfos
    }

    // STATES //////////////////////////////////////////////////////////////////

    state: "stateMediaGrid"
    states: [
        State {
            name: "stateMediaGrid"
            PropertyChanges { target: screenDeviceGrid; visible: true; }
            PropertyChanges { target: screenDeviceInfos; visible: false; }
            PropertyChanges { target: screenMedia; visible: false; }
        },
        State {
            name: "stateDeviceInfos"
            PropertyChanges { target: screenDeviceGrid; visible: false; }
            PropertyChanges { target: screenDeviceInfos; visible: true; }
            PropertyChanges { target: screenMedia; visible: false; }
        },
        State {
            name: "stateMediaDetails"
            PropertyChanges { target: screenDeviceGrid; visible: false; }
            PropertyChanges { target: screenDeviceInfos; visible: false; }
            PropertyChanges { target: screenMedia; visible: true; }
        }
    ]
}
