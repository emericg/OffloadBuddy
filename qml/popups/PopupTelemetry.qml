import QtQuick
import QtQuick.Effects
import QtQuick.Controls

import ThemeEngine

import "qrc:/utils/UtilsString.js" as UtilsString
import "qrc:/utils/UtilsPath.js" as UtilsPath

Popup {
    id: popupTelemetry

    x: (appWindow.width / 2) - (width / 2) + (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 720
    padding: 0

    dim: true
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    parent: Overlay.overlay

    ////////

    property int popupMode: 0
    property bool recapEnabled: false
    property bool recapOpened: false

    property var shots_uuids: []
    property var shots_names: []
    property var shots_files: []
    //property var shots: [] // TODO actual shot pointers

    property var mediaProvider: null
    property var currentShot: null

    ////////////////////////////////////////////////////////////////////////////

    function open() { return; }

    function openSingle(provider, shot) {
        popupMode = 1
        mediaProvider = provider
        currentShot = shot

        visible = true
    }

    function openSelection(provider) {
        if (shots_uuids.length === 0 || shots_names.length === 0) return

        popupMode = 2
        recapEnabled = true
        mediaProvider = provider

        visible = true
    }

    onClosed: {
        recapEnabled = false
        recapOpened = false
        shots_uuids = []
        shots_names = []
        shots_files = []
        mediaProvider = null
        currentShot = null
        itemDestination.resetDestination()
    }

    ////////////////////////////////////////////////////////////////////////////

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.333; to: 1.0; duration: 133; } }

    Overlay.modal: Rectangle {
        color: "#000"
        opacity: ThemeEngine.isLight ? 0.333 : 0.666
    }

    background: Rectangle {
        radius: Theme.componentRadius
        color: Theme.colorBackground

        Item {
            anchors.fill: parent

            Column {
                anchors.left: parent.left
                anchors.right: parent.right

                Rectangle { // title area
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 64
                    color: Theme.colorPrimary
                }

                Rectangle { // subtitle area
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48
                    color: Theme.colorForeground
                    visible: (recapEnabled && shots_uuids.length)
                }
            }

            Rectangle { // border
                anchors.fill: parent
                radius: Theme.componentRadius
                color: "transparent"
                border.color: Theme.colorSeparator
                border.width: Theme.componentBorderWidth
                opacity: 0.4
            }

            layer.enabled: true
            layer.effect: MultiEffect { // clip
                maskEnabled: true
                maskInverted: false
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                maskSpreadAtMax: 0.0
                maskSource: ShaderEffectSource {
                    sourceItem: Rectangle {
                        x: background.x
                        y: background.y
                        width: background.width
                        height: background.height
                        radius: background.radius
                    }
                }
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect { // shadow
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowColor: ThemeEngine.isLight ? "#aa000000" : "#aaffffff"
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    contentItem: Column {

        ////////////////

        Item { // titleArea
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentMarginXL
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Extract telemetry")
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: "white"
            }
        }

        ////////////////

        Item { // filesArea
            anchors.left: parent.left
            anchors.leftMargin: Theme.componentBorderWidth
            anchors.right: parent.right
            anchors.rightMargin: Theme.componentBorderWidth

            height: 48
            visible: (recapEnabled && shots_uuids.length)

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentMarginXL
                anchors.right: parent.right
                anchors.rightMargin: 48+16+16
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("%n shot(s) selected", "", shots_names.length)
                color: Theme.colorText
                font.pixelSize: Theme.fontSizeContent
            }

            RoundButtonSunken {
                anchors.right: parent.right
                anchors.rightMargin: Theme.componentMargin
                anchors.verticalCenter: parent.verticalCenter

                rotation: recapOpened ? -90 : 90
                colorBackground: Theme.colorForeground
                source: "qrc:/assets/icons/material-symbols/chevron_right.svg"

                onClicked: recapOpened = !recapOpened
            }
        }

        ////////////////

        Column { // contentArea
            anchors.left: parent.left
            anchors.leftMargin: Theme.componentMarginXL
            anchors.right: parent.right
            anchors.rightMargin: Theme.componentMarginXL

            topPadding: Theme.componentMarginXL
            bottomPadding: Theme.componentMarginXL
            spacing: Theme.componentMarginXL

            ////////

            ListView {
                id: listArea
                anchors.left: parent.left
                anchors.right: parent.right

                visible: recapOpened

                model: shots_names
                delegate: Text {
                    width: listArea.width
                    text: modelData
                    font.pixelSize: Theme.fontSizeContentSmall
                    elide: Text.ElideLeft
                    color: Theme.colorSubText
                }
            }

            ////////

            Column {
                id: columnTelemetry
                anchors.left: parent.left
                anchors.right: parent.right

                visible: !recapOpened

                Item {
                    id: elementGPS
                    height: 44
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Text {
                        id: titleGPS
                        width: 128
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("GPS trace")
                        font.pixelSize: Theme.fontSizeContent
                        color: Theme.colorSubText
                    }

                    Row {
                        anchors.left: titleGPS.right
                        anchors.leftMargin: Theme.componentMargin
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.componentMargin

                        RadioButtonThemed {
                            id: rbGPX
                            text: "GPX"
                            checked: true
                            onClicked: itemDestination.lastExtension = itemDestination.gpsExtension = "gpx"
                        }
                        RadioButtonThemed {
                            id: rbIGC
                            text: "IGC"
                            enabled: false
                            onClicked: itemDestination.lastExtension = itemDestination.gpsExtension = "igc"
                        }
                        RadioButtonThemed {
                            id: rbKML
                            text: "KML"
                            enabled: false
                            onClicked: itemDestination.lastExtension = itemDestination.gpsExtension = "kml"
                        }
                    }
                }

                ////////

                Item {
                    id: elementTelemetry
                    height: 44
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Text {
                        id: titleTelemetry
                        width: 128
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Telemetry")
                        font.pixelSize: Theme.fontSizeContent
                        color: Theme.colorSubText
                    }

                    Row {
                        anchors.left: titleTelemetry.right
                        anchors.leftMargin: Theme.componentMargin
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.componentMargin

                        RadioButtonThemed {
                            id: rbJSON
                            text: "JSON"
                            checked: true
                            onClicked: itemDestination.lastExtension = itemDestination.telemetryExtension = "json"
                        }
                        RadioButtonThemed {
                            id: rbCSV
                            text: "CSV"
                            enabled: false
                            onClicked: itemDestination.lastExtension = itemDestination.telemetryExtension = "csv"
                        }
                    }
                }

                ////////

                Item { // elementAltitude
                    height: 44
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Text {
                        id: titleAltitude
                        width: 128
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Altitude")
                        font.pixelSize: Theme.fontSizeContent
                        color: Theme.colorSubText
                    }

                    SwitchThemedDesktop { // switchEGM96
                        anchors.left: titleAltitude.right
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter

                        checked: true
                        text: qsTr("EGM96 correction")
                    }
                }

                ////////

                Item { // delimiter
                    anchors.left: parent.left
                    anchors.leftMargin: -Theme.componentMarginXL + Theme.componentBorderWidth
                    anchors.right: parent.right
                    anchors.rightMargin: -Theme.componentMarginXL + Theme.componentBorderWidth
                    height: 32

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: Theme.componentBorderWidth
                        color: Theme.colorForeground
                    }
                }

                ////////

                Column {
                    id: columnDestination
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Item {
                        height: 24
                        anchors.left: parent.left
                        anchors.right: parent.right

                        Text {
                            id: textDestinationTitle
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            //anchors.verticalCenter: parent.verticalCenter

                            text: qsTr("Destination")
                            color: Theme.colorSubText
                            font.pixelSize: Theme.fontSizeContent
                        }
                    }

                    Item {
                        id: itemDestination
                        height: 44
                        anchors.left: parent.left
                        anchors.right: parent.right

                        property string gpsExtension: "gpx"
                        property string telemetryExtension: "json"
                        property string lastExtension: "json"

                        function resetDestination() {
                            if (typeof currentShot === "undefined" || !currentShot) {
                                folderInput.folder = utilsApp.getStandardPath_string("")
                            } else {
                                fileInput.folder = currentShot.folder
                                fileInput.file = currentShot.name
                            }
                        }

                        ComboBoxThemed {
                            id: comboBoxDestination
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            ListModel {
                                id: cbDestinations
                                ListElement { text: qsTr("Next to the video file"); }
                                ListElement { text: qsTr("Select path manually"); }
                            }
                            model: cbDestinations

                            property bool cbinit: false
                            onCurrentIndexChanged: {
                                if (currentIndex === 0) itemDestination.resetDestination()
                            }
                        }
                    }

                    Item {
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: (popupMode === 2) && (comboBoxDestination.currentIndex === (cbDestinations.count-1))

                        FolderInputArea {
                            id: folderInput
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            folder: currentShot.folder

                            onPathChanged: {
                                //
                            }
                        }
                    }

                    Item {
                        height: 48
                        anchors.left: parent.left
                        anchors.right: parent.right

                        visible: (popupMode === 1)
                        enabled: (comboBoxDestination.currentIndex === (cbDestinations.count-1))

                        FileInputArea {
                            id: fileInput
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            folder: currentShot.folder
                            file: currentShot.name
                            extension: itemDestination.lastExtension

                            onPathChanged: {
                                if (currentShot && currentShot.containSourceFile(fileInput.path)) {
                                    fileWarning.setError()
                                } else if (jobManager.fileExists(fileInput.path)) {
                                    fileWarning.setWarning()
                                } else {
                                    fileWarning.setOK()
                                }
                            }
                        }
                    }

                    FileWarning {
                        id: fileWarning
                    }
                }
            }

            ////////////

            Row {
                anchors.right: parent.right

                topPadding: 0
                spacing: Theme.componentMargin

                ButtonSolid {
                    anchors.bottom: parent.bottom

                    color: Theme.colorGrey
                    text: qsTr("Close")

                    onClicked: popupTelemetry.close()
                }

                ButtonSolid {
                    anchors.bottom: parent.bottom

                    enabled: (popupMode === 1 && fileInput.isValid) || (popupMode === 2 && folderInput.isValid)
                    color: Theme.colorSecondary

                    text: qsTr("Extract telemetry")
                    source: "qrc:/assets/icons/material-symbols/insert_chart.svg"

                    onClicked: {
                        if (typeof currentShot === "undefined" || !currentShot) return
                        if (typeof mediaProvider === "undefined" || !mediaProvider) return

                        var settingsTelemetry = {}

                        // settings
                        if (rbJSON.checked)
                            settingsTelemetry["telemetry_format"] = "JSON";
                        else if (rbCSV.checked)
                            settingsTelemetry["telemetry_format"] = "CSV";

                        settingsTelemetry["telemetry_frequency"] = 30
                        settingsTelemetry["gps_frequency"] = 2
                        settingsTelemetry["egm96_correction"] = switchEGM96.checked

                        // destination
                        if (popupMode === 1) {
                            settingsTelemetry["folder"] = fileInput.folder
                            settingsTelemetry["file"] = fileInput.file
                            settingsTelemetry["extension"] = fileInput.extension
                        } else if (popupMode === 2) {
                            settingsTelemetry["folder"] = folderInput.folder
                        }

                        // dispatch job
                        if (currentShot) {
                            currentShot.exportTelemetry(fileInput.text, 0, 30, 2, switchEGM96.checked)
                        } else if (shots_uuids.length > 0) {
                            mediaProvider.extractTelemetrySelected(shots_uuids, settingsTelemetry)
                        }
                    }
                }

                ButtonSolid {
                    anchors.bottom: parent.bottom

                    text: qsTr("Extract GPS")
                    source: "qrc:/assets/icons/material-symbols/location/map-fill.svg"

                    enabled: (popupMode === 1 && fileInput.isValid) || (popupMode === 2 && folderInput.isValid)

                    onClicked: {
                        if (typeof mediaProvider === "undefined" || !mediaProvider) return

                        var settingsTelemetry = {}

                        // settings
                        if (rbGPX.checked)
                            settingsTelemetry["gps_format"] = "GPX";
                        else if (rbIGC.checked)
                            settingsTelemetry["gps_format"] = "IGC";
                        else if (rbKML.checked)
                            settingsTelemetry["gps_format"] = "KML";

                        settingsTelemetry["gps_frequency"] = 2
                        settingsTelemetry["egm96_correction"] = switchEGM96.checked

                        // destination
                        if (popupMode === 1) {
                            settingsTelemetry["folder"] = fileInput.folder
                            settingsTelemetry["file"] = fileInput.file
                            settingsTelemetry["extension"] = fileInput.extension
                        } else if (popupMode === 2) {
                            settingsTelemetry["folder"] = folderInput.folder
                        }

                        // dispatch job
                        if (currentShot) {
                            currentShot.exportGps(fileInput.text, 0, 2, switchEGM96.checked)
                            //mediaProvider.extractTelemetrySelected(shots_uuids, settingsTelemetry)
                        } else if (shots_uuids.length > 0) {
                            mediaProvider.extractTelemetrySelection(shots_uuids, settingsTelemetry)
                        }
                    }
                }
            }

            ////////////
        }

        ////////////////
    }

    ////////////////////////////////////////////////////////////////////////////
}
