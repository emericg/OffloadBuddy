import QtQuick 2.15
import QtQuick.Controls 2.15

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: screenLibrary
    width: 1280
    height: 720

    function updateFocus() {
        screenMedia.updateFocus()
    }

    // KEYS HANDLING ///////////////////////////////////////////////////////////

    Shortcut {
        sequences: [StandardKey.Back]
        onActivated: {
            if (screenLibrary.state === "stateMediaDetails")
                screenMedia.back()
        }
    }
    Shortcut {
        sequences: [StandardKey.Forward]
        onActivated: {
            if (screenLibrary.state === "stateMediaGrid")
                screenMedia.restoreShot(true)
        }
    }
/*
    focus: true
    Keys.onPressed: (event) => {
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

        onClicked: (mouse) => {
            if (mouse.button === Qt.BackButton) {
                if (screenLibrary.state === "stateMediaDetails")
                    screenMedia.back()
            } else if (mouse.button === Qt.ForwardButton) {
                if (screenLibrary.state === "stateMediaGrid")
                    screenMedia.restoreShot(true)
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
            }
        }
    ]
}
