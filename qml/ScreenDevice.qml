import QtQuick 2.10
import QtQuick.Controls 2.4

import com.offloadbuddy.style 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: screenDevice
    width: 1280
    height: 720

    property var mySettings
    property var myDevice

    onMyDeviceChanged: {
        screenDeviceShots.updateDeviceHeader();
        state = "shotsview"
    }

    ScreenDeviceShots {
        anchors.fill: parent
        id: screenDeviceShots
    }
    ScreenDeviceShotDetails {
        anchors.fill: parent
        id: screenDeviceShotDetails
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
                shot: myDevice.getShot(screenDeviceShots.selectedItem)
            }
        }
    ]
}
