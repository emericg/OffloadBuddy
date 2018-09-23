import QtQuick 2.10
import QtQuick.Controls 2.3

import com.offloadbuddy.style 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: screenDevice
    width: 1280
    height: 720

    property var myDevice

    property var deviceStateList: []
    property var deviceState

    onMyDeviceChanged: {
        if (!deviceStateList[myDevice.uniqueId]) {
            deviceStateList[myDevice.uniqueId] = ({ orderBy: 0,
                                                    zoomLevel: 2.0,
                                                    mainState: "shotsview",
                                                    selectedIndex: 0,
                                                    detail_shot: null,
                                                    detail_state: "overview" })
        }

        //console.log("Device is now " + myDevice.uniqueId)

        // restore state
        deviceState = deviceStateList[myDevice.uniqueId]
        state = deviceState.mainState

        screenDeviceShots.restoreState()
        screenDeviceShots.updateDeviceHeader()
        screenDeviceShots.initGridViewSettings()
        screenDeviceShots.updateGridViewSettings()

        screenDeviceShotDetails.restoreState()
    }

    ScreenDeviceShots {
        anchors.fill: parent
        id: screenDeviceShots
    }
    ScreenDeviceShotDetails {
        anchors.fill: parent
        id: screenDeviceShotDetails
    }

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        acceptedButtons: Qt.BackButton | Qt.ForwardButton

        onClicked: {
            if (mouse.button === Qt.BackButton) {
                if (screenDevice.state === "shotdetails")
                    screenDevice.state = "shotsview"
            } else if (mouse.button === Qt.ForwardButton) {
                if (screenDevice.state === "shotsview")
                    if (screenDeviceShots.selectedItemIndex >= 0)
                        screenDevice.state = "shotdetails"
            }
        }
    }
    Shortcut {
        sequence: StandardKey.Back
        onActivated: {
            if (screenDevice.state === "shotdetails")
                screenDevice.state = "shotsview"
        }
    }
    Shortcut {
        sequence: StandardKey.Forward
        onActivated: {
            if (screenDevice.state === "shotsview")
                if (screenDeviceShots.selectedItemIndex >= 0)
                    screenDevice.state = "shotdetails"
        }
    }

    onStateChanged: {
         // save state
         deviceState.mainState = state
    }
    state: "shotsview"
    states: [
        State {
            name: "shotsview"

            PropertyChanges {
                target: screenDeviceShots
                visible: true
            }
            PropertyChanges {
                target: screenDeviceShotDetails
                visible: false
            }
        },
        State {
            name: "shotdetails"

            PropertyChanges {
                target: screenDeviceShots
                visible: false
            }
            PropertyChanges {
                target: screenDeviceShotDetails
                visible: true
                shot: myDevice.getShot(screenDeviceShots.selectedItemName)
            }
        }
    ]
}
