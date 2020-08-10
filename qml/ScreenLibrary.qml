import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: screenLibrary
    width: 1280
    height: 720

    Connections {
        target: mediaLibrary
        function onStateUpdated() { screenLibraryGrid.updateGridViewSettings() }
    }

    function updateFocus() {
        screenMedia.updateFocus()
    }

    // KEYS HANDLING ///////////////////////////////////////////////////////////

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
/*
    focus: true
    Keys.onPressed: {
        if (event.key === Qt.Key_Enter) {
            event.accepted = true;
            console.log("Key_Enter in screenlibrary")
            //
        } else if (event.key === Qt.Key_Delete) {
            console.log("Key_Delete in screenlibrary")
            event.accepted = true;
            //
        }
    }
*/
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

    // CONTENT /////////////////////////////////////////////////////////////////

    ScreenLibraryGrid {
        anchors.fill: parent
        id: screenLibraryGrid
    }
    ScreenMedia {
        anchors.fill: parent
        id: screenMedia
        startedFrom: "library"
    }

    // STATES //////////////////////////////////////////////////////////////////

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
                shot: mediaLibrary.getShotByUuid(screenLibraryGrid.selectedItemUuid)
            }
        }
    ]
}
