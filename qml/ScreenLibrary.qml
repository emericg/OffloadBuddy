import QtQuick 2.10
import QtQuick.Controls 2.3

import com.offloadbuddy.style 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: screenLibrary
    width: 1280
    height: 720

    property var libraryStateList: []
    property var libraryState
/*
    property var myDevice

    onMyDeviceChanged: {
        if (!libraryStateList[myDevice.uniqueId]) {
            libraryStateList[myDevice.uniqueId] = ({ orderBy: 0,
                                                    zoomLevel: 2.0,
                                                    mainState: "shotsview",
                                                    selectedIndex: 0,
                                                    detail_shot: null,
                                                    detail_state: "overview" })
        }

        //console.log("Device is now " + myDevice.uniqueId)

        // restore state
        libraryState = libraryStateList[myDevice.uniqueId]
        state = libraryState.mainState

        screenLibraryGrid.restoreState()
        screenLibraryGrid.updateDeviceHeader()
        screenLibraryGrid.initGridViewSettings()
        screenLibraryGrid.updateGridViewSettings()

        screenMedia.restoreState()
    }
*/
    ScreenLibraryGrid {
        anchors.fill: parent
        id: screenLibraryGrid
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
                if (screenLibrary.state === "shotdetails")
                    screenLibrary.state = "shotsview"
            } else if (mouse.button === Qt.ForwardButton) {
                if (screenLibrary.state === "shotsview")
                    if (screenLibraryGrid.selectedItemIndex >= 0)
                        screenLibrary.state = "shotdetails"
            }
        }
    }
    Shortcut {
        sequence: StandardKey.Back
        onActivated: {
            if (screenLibrary.state === "shotdetails")
                screenLibrary.state = "shotsview"
        }
    }
    Shortcut {
        sequence: StandardKey.Forward
        onActivated: {
            if (screenLibrary.state === "shotsview")
                if (screenLibraryGrid.selectedItemIndex >= 0)
                    screenLibrary.state = "shotdetails"
        }
    }

    onStateChanged: {
        console.log("onStateChanged")
         // save state
         libraryState.mainState = state
    }
    state: "shotsview"
    states: [
        State {
            name: "shotsview"

            PropertyChanges {
                target: screenLibraryGrid
                visible: true
            }
            PropertyChanges {
                target: screenMedia
                visible: false
            }
        },
        State {
            name: "shotdetails"

            PropertyChanges {
                target: screenLibraryGrid
                visible: false
            }
            PropertyChanges {
                target: screenMedia
                visible: true
                shot: mediaLibrary.getShot(screenLibraryGrid.selectedItemName)
            }
        }
    ]
}
