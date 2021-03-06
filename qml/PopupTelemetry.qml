import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsPath.js" as UtilsPath

Popup {
    id: popupTelemetry
    x: (appWindow.width / 2) - (width / 2) - (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 720
    padding: 0

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    signal confirmed()

    ////////

    property int popupMode: 0
    property bool recapEnabled: true
    property bool recapOpened: false

    property var uuids: []
    property var shots: []
    property var files: []

    property var mediaProvider: null
    property var currentShot: null

    ////////

    function open() { return; }

    function openSingle(provider, shot) {
        popupMode = 1
        recapEnabled = false
        recapOpened = false
        uuids = []
        shots = []
        files = []
        mediaProvider = provider
        currentShot = shot
        itemDestination.resetDestination()

        visible = true
    }

    function openSelection(provider) {
        if (uuids.length === 0 || shots.length === 0) return

        popupMode = 2
        recapEnabled = true
        recapOpened = false
        files = []
        mediaProvider = provider
        currentShot = null
        itemDestination.resetDestination()

        visible = true
    }

    ////////////////////////////////////////////////////////////////////////////

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.5; to: 1.0; duration: 133; } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 233; } }

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: recapOpened ? Theme.colorForeground : Theme.colorBackground
        radius: Theme.componentRadius
        border.width: Theme.componentBorderWidth
        border.color: Theme.colorForeground
    }

    ////////////////////////////////////////////////////////////////////////////

    contentItem: Column {

        Rectangle {
            id: titleArea
            anchors.left: parent.left
            anchors.right: parent.right

            height: 64
            color: Theme.colorPrimary
            radius: Theme.componentRadius

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 1
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Extract telemetry")
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: "white"
            }
        }

        ////////////////

        Rectangle {
            id: filesArea
            anchors.left: parent.left
            anchors.leftMargin: 1
            anchors.right: parent.right
            anchors.rightMargin: 0

            z: 1
            height: 48
            visible: shots.length
            color: Theme.colorForeground

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 48+16+16
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("%n shot(s) selected", "", shots.length)
                color: Theme.colorText
                font.pixelSize: Theme.fontSizeContent
            }

            ItemImageButton {
                width: 48
                height: 48
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter

                source: "qrc:/assets/icons_material/baseline-navigate_next-24px.svg"
                rotation: recapOpened ? -90 : 90
                onClicked: recapOpened = !recapOpened
            }
        }

        ////////////////

        Item {
            id: contentArea
            height: columnTelemetry.height
            anchors.left: parent.left
            anchors.right: parent.right

            ////////

            ListView {
                id: listArea
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24

                visible: recapOpened

                model: shots
                delegate: Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: modelData
                    font.pixelSize: 14
                    elide: Text.ElideLeft
                    color: Theme.colorSubText
                }
            }

            ////////

            Column {
                id: columnTelemetry
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.right: parent.right
                anchors.rightMargin: 24
                topPadding: 16
                bottomPadding: 16

                visible: !recapOpened

                Item {
                    id: elementGPS
                    height: 48
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Text {
                        id: titleGPS
                        width: 128
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("GPS trace")
                        font.pixelSize: 16
                        color: Theme.colorSubText
                    }

                    Row {
                        anchors.left: titleGPS.right
                        anchors.leftMargin: 16
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16

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
                    height: 48
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Text {
                        id: titleTelemetry
                        width: 128
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Telemetry")
                        font.pixelSize: 16
                        color: Theme.colorSubText
                    }

                    Row {
                        anchors.left: titleTelemetry.right
                        anchors.leftMargin: 16
                        anchors.right: parent.right
                        anchors.rightMargin: 0
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16

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

                Item {
                    id: elementAltitude
                    height: 48
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Text {
                        id: titleAltitude
                        width: 128
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Altitude")
                        font.pixelSize: 16
                        color: Theme.colorSubText
                    }

                    SwitchThemedDesktop {
                        id: switchEGM96
                        anchors.left: titleAltitude.right
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter

                        checked: true
                        enabled: false
                        text: qsTr("EGM96 correction")
                    }
                }

                ////////

                Item { // delimiter
                    anchors.left: parent.left
                    anchors.leftMargin: -23
                    anchors.right: parent.right
                    anchors.rightMargin: -23
                    height: 32

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: Theme.componentBorderWidth
                        color: Theme.colorForeground
                    }
                }

                ////////

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
                        font.pixelSize: 16
                    }
                }

                Item {
                    id: itemDestination
                    height: 48
                    anchors.left: parent.left
                    anchors.right: parent.right

                    property string gpsExtension: "gpx"
                    property string telemetryExtension: "json"
                    property string lastExtension: "json"

                    function resetDestination() {
                        if (typeof currentShot === "undefined" || !currentShot) return

                        fileInput.folder = currentShot.folder
                        fileInput.file = currentShot.name
                        rectangleFileWarning.visible = jobManager.fileExists(fileInput.path)
                    }

                    ComboBoxThemed {
                        id: comboBoxDestination
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 36

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

                    //visible: (comboBoxDestination.currentIndex === (cbDestinations.count-1))
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
                            rectangleFileWarning.visible = jobManager.fileExists(fileInput.path)
                        }
                    }
                }

                Row {
                    id: rectangleFileWarning
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48
                    spacing: 16

                    visible: false

                    ImageSvg {
                        width: 28
                        height: 28
                        anchors.verticalCenter: parent.verticalCenter

                        color: Theme.colorWarning
                        source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Warning, this file exists already and will be overwritten...")
                        color: Theme.colorText
                        font.bold: false
                        font.pixelSize: Theme.fontSizeContent
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        ////////////////

        Row {
            id: rowButtons
            height: Theme.componentHeight*2 + parent.spacing
            anchors.right: parent.right
            anchors.rightMargin: 24
            spacing: 16

            ButtonWireframe {
                id: buttonClose
                width: 96
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Close")
                fullColor: true
                primaryColor: Theme.colorGrey
                onClicked: popupTelemetry.close()
            }
            ButtonWireframeImage {
                id: buttonExtractTelemetry
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Extract telemetry")
                source: "qrc:/assets/icons_material/baseline-insert_chart-24px.svg"
                fullColor: true
                primaryColor: Theme.colorSecondary

                enabled: fileInput.isValid

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
                    settingsTelemetry["path"] = fileInput.text

                    // destination
                    settingsTelemetry["folder"] = fileInput.folder
                    settingsTelemetry["file"] = fileInput.file
                    settingsTelemetry["extension"] = fileInput.extension

                    // dispatch job
                    if (currentShot) {
                        currentShot.exportTelemetry(fileInput.text, 0, 30, 2, switchEGM96.checked)
                    } else if (uuids.length > 0) {
                        mediaProvider.extractTelemetrySelected(uuids, settingsTelemetry)
                    }
                }
            }
            ButtonWireframeImage {
                id: buttonExtractGps
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Extract GPS")
                source: "qrc:/assets/icons_material/baseline-map-24px.svg"
                fullColor: true
                primaryColor: Theme.colorPrimary

                enabled: fileInput.isValid

                onClicked: {
                    if (typeof currentShot === "undefined" || !currentShot) return
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
                    settingsTelemetry["folder"] = fileInput.folder
                    settingsTelemetry["file"] = fileInput.file
                    settingsTelemetry["extension"] = fileInput.extension

                    // dispatch job
                    if (currentShot) {
                        currentShot.exportGps(fileInput.text, 0, 2, switchEGM96.checked)
                        //mediaProvider.extractTelemetrySelected(uuids, settingsTelemetry)
                    } else if (uuids.length > 0) {
                        mediaProvider.extractTelemetrySelection(uuids, settingsTelemetry)
                    }
                }
            }
        }
    }
}
