import QtQuick 2.10
import QtQuick.Controls 2.3

import com.offloadbuddy.style 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: screenLibrary
    width: 1280
    height: 720

    property var librarySavedState

    Component.onCompleted: {
        librarySavedState = ({ orderBy: 0,
                               zoomLevel: 2.0,
                               mainState: "stateMediaGrid",
                               selectedIndex: 0,
                               detail_shot: null,
                               detail_state: "overview" })
    }

    onStateChanged: {
/*
         // save state
         librarySavedState.mainState = state

        // restore state
        state = librarySavedState.mainState

        screenLibraryGrid.restoreState()
        screenLibraryGrid.updateDeviceHeader()
        screenLibraryGrid.initGridViewSettings()
        screenLibraryGrid.updateGridViewSettings()

        screenMedia.restoreState()
*/
    }

    // CONTENT /////////////////////////////////////////////////////////////////

    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        acceptedButtons: Qt.BackButton | Qt.ForwardButton

        onClicked: {
            if (mouse.button === Qt.BackButton) {
                if (screenLibrary.state === "stateMediaDetails")
                    screenLibrary.state = "stateMediaGrid"
            } else if (mouse.button === Qt.ForwardButton) {
                if (screenLibrary.state === "stateMediaGrid")
                    if (screenLibraryGrid.selectedItemIndex >= 0)
                        screenLibrary.state = "stateMediaDetails"
            }
        }
    }
    Shortcut {
        sequence: StandardKey.Back
        onActivated: {
            if (screenLibrary.state === "stateMediaDetails")
                screenLibrary.state = "stateMediaGrid"
        }
    }
    Shortcut {
        sequence: StandardKey.Forward
        onActivated: {
            if (screenLibrary.state === "stateMediaGrid")
                if (screenLibraryGrid.selectedItemIndex >= 0)
                    screenLibrary.state = "stateMediaDetails"
        }
    }

    ScreenLibraryGrid {
        anchors.fill: parent
        id: screenLibraryGrid
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
                target: screenLibraryGrid
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
