import QtQuick
import QtQuick.Controls

import QtCharts
import QtLocation
import QtPositioning
import Qt.labs.animation

import ThemeEngine

import "qrc:/utils/UtilsString.js" as UtilsString

Item {
    id: contentTelemetry
    width: 1500
    height: 700
    anchors.fill: parent

    property string mapmode: ""

    ////////////////////////////////////////////////////////////////////////////

    Connections {
        target: settingsManager
        function onAppUnitsChanged() { updateUnits() }
    }

    function updateUnits() {
        speedTitle.text = qsTr("Speed") + " (" + UtilsString.speedUnit(settingsManager.appUnits) + ")"
        altiTitle.text = qsTr("Altitude") + " (" + UtilsString.altitudeUnit(settingsManager.appUnits) + ")"

        updateMetadata()
    }

    function updateMap() { // "image" mode
        mapmode = "image"
        mapArea.fullscreen = true

        // Map
        if (!mapLoader.sourceComponent) {
            mapLoader.sourceComponent = mapComponent
        } else {
            mapLoader.item.updateMap()
        }

        // Reverse geo coding
        shot.getLocation()
    }

    function updateMetadata() { // "video" mode
        mapmode = "video"
        mapArea.fullscreen = false

        // Map
        if (!mapLoader.sourceComponent) {
            mapLoader.sourceComponent = mapComponent
        } else {
            mapLoader.item.updateMetadata()
        }

        // Reverse geo coding
        shot.getLocation()

        if (shot) {
            // Graphs data
            shot.updateSpeedsSerie(speedsSeries, settingsManager.appUnits)
            shot.updateAltiSerie(altiSeries, settingsManager.appUnits)
            shot.updateAcclSeries(acclX, acclY, acclZ)
            shot.updateGyroSeries(gyroX, gyroY, gyroZ)

            // Text data (V2)
            speedMetrics.text = qsTr("average") + " " +
                    UtilsString.speedToString(shot.avgSpeed, 0, settingsManager.appUnits) + " / ↘ " +
                    UtilsString.speedToString(shot.minSpeed, 0, settingsManager.appUnits) + " / ↗ " +
                    UtilsString.speedToString(shot.maxSpeed, 0, settingsManager.appUnits)
            altiMetrics.text = qsTr("average") + " " +
                    UtilsString.altitudeToString(shot.avgAlti, 0, settingsManager.appUnits) + " / ↘ " +
                    UtilsString.altitudeToString(shot.minAlti, 0, settingsManager.appUnits) + " / ↗ " +
                    UtilsString.altitudeToString(shot.maxAlti, 0, settingsManager.appUnits)
            acclMetrics.text = qsTr("max G force") + " " + (shot.maxG / 9.80665).toFixed(1) + " G's"

            // Text data (V1)
            trackDuration.text = UtilsString.durationToString_long(shot.duration)
            trackDistance.text = UtilsString.distanceToString_km(shot.distanceKm, 1, settingsManager.appUnits)

            // Graphs axis
            axisSpeedY0.min = shot.minSpeed * 0.9
            axisSpeedY0.max = shot.maxSpeed * 1.1
            axisAltiY0.min = shot.minAlti * 0.9
            axisAltiY0.max = shot.maxAlti * 1.1
            axisAcclY0.min = -12
            axisAcclY0.max = 12
            axisGyroY0.min = -8
            axisGyroY0.max = 8
            //axisGyroY0.applyNiceNumbers()

            axisSpeedX0.min = 0
            axisSpeedX0.max = speedsSeries.count
            axisAltiX0.min = 0
            axisAltiX0.max = altiSeries.count
            axisAcclX0.min = 0
            axisAcclX0.max = acclX.count
            axisGyroX0.min = 0
            axisGyroX0.max = gyroX.count
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        id: mapArea
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        property bool fullscreen: false

        width: fullscreen ? parent.width : parent.width * 0.40
        Behavior on width { NumberAnimation { duration: 233 } }

        radius: Theme.componentRadius
        color: Theme.colorForeground

        IconSvg {
            width: 64; height: 64;
            anchors.centerIn: parent

            color: Theme.colorIcon
            source: "qrc:/assets/icons/material-icons/outlined/hourglass_empty.svg"
        }

        Loader {
            id: mapLoader
            anchors.fill: parent

            asynchronous: true
            onLoaded: {
                // initial loading
                if (mapmode === "image")
                    mapLoader.item.updateMap()
                else
                    mapLoader.item.updateMetadata()
            }
        }
    }

    Component {
        id: mapComponent

        Map {
            id: map

            ////////////////

            plugin: Plugin {
                preferred: ["maplibre", "osm"]
                PluginParameter { name: "maplibre.map.styles"; value: "https://tiles.versatiles.org/styles/colorful.json" }
                PluginParameter { name: "osm.mapping.highdpi_tiles"; value: true }
            }
            //activeMapType: supportedMapTypes[0]
            copyrightsVisible: false

            ////////////////

            property bool fullscreen: false
            property bool moove: false

            //bearing: 0.0
            //tilt: 0.0
            //zoomLevel: 12
            //fieldOfView: 0
            //center: QtPositioning.coordinate(45.5, 6)

            property real zoomLevel_minimum: 12
            property real zoomLevel_maximum: 18

            property real tiltLevel_minimum: 0
            property real tiltLevel_maximum: 66

            property real fovLevel_minimum: 20
            property real fovLevel_maximum: 120

            BoundaryRule on zoomLevel { // zoom locks
                minimum: zoomLevel_minimum
                maximum: zoomLevel_maximum
            }

            ////////////////

            function updateMap() { // "image" mode
                button_map_fullscreen.visible = false

                if (shot.latitude !== 0.0) {
                    // center view
                    map.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
                    map.zoomLevel = 12

                    // clean GPS points
                    while (mapTrace.pathLength() > 0) {
                        mapTrace.removeCoordinate(mapTrace.coordinateAt(0))
                    }

                    // map marker
                    mapTrace.visible = false
                    mapMarker.visible = true
                    mapMarker.compass_bearing = shot.direction
                    mapMarker.coordinate = QtPositioning.coordinate(shot.latitude, shot.longitude)

                    // scale indicator
                    map.computeScale()
                }
            }

            function updateMetadata() { // "video" mode
                button_map_fullscreen.visible = true

                // GPS trace
                if (shot.latitude !== 0.0) {
                    // center view
                    map.center = QtPositioning.coordinate(shot.latitude, shot.longitude)

                    // clean GPS points
                    while (mapTrace.pathLength() > 0)
                        mapTrace.removeCoordinate(mapTrace.coordinateAt(0))
                    // add new GPS points // one per seconde (was 18Hz)
                    for (var i = 0; i < shot.getGpsPointCount(); i += 18)
                        mapTrace.addCoordinate(shot.getGpsCoordinates(i))

                    // map marker
                    mapMarker.visible = false
                    mapMarker.coordinate = QtPositioning.coordinate(shot.latitude, shot.longitude)

                    // choose a default zoom level
                    if (shot.distanceKm < 0.5)
                        map.zoomLevel = 18
                    else if (shot.distanceKm < 2)
                        map.zoomLevel = 15
                    else if (shot.distanceKm < 10)
                        map.zoomLevel = 12
                    else if (shot.distanceKm < 50)
                        map.zoomLevel = 10
                    else if (shot.distanceKm < 100)
                        map.zoomLevel = 8

                    // scale indicator
                    map.computeScale()
                }
            }

            property variant scaleLengths: [5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000, 1000000, 2000000]

            function computeScale() {
                //console.log("computeScale(zoom: " + map.zoomLevel + ")")

                mapScale.computeScale()

                if (mapTrace.pathLength() > 1) {
                    if ((shot.distanceKm < 1 && map.zoomLevel < 15) ||
                        (shot.distanceKm < 10 && map.zoomLevel < 10) ||
                        (shot.distanceKm < 50 && map.zoomLevel < 8) ||
                        (shot.distanceKm < 100 && map.zoomLevel < 7)) {
                        mapTrace.visible = false
                        mapMarker.visible = true
                    } else {
                        mapTrace.visible = true
                        mapMarker.visible = false
                    }
                } else {
                    mapTrace.visible = false
                    mapMarker.visible = true
                }
            }

            function zoomIn() {
                if (map.zoomLevel < Math.round(map.maximumZoomLevel)) {
                    map.zoomLevel = Math.round(map.zoomLevel + 1)
                    if (!map.moove) map.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
                    map.computeScale()
                }
            }

            function zoomOut() {
                if (map.zoomLevel > Math.round(map.minimumZoomLevel)) {
                    map.zoomLevel = Math.round(map.zoomLevel - 1)
                    if (!map.moove) map.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
                    map.computeScale()
                }
            }

            ////////////////

            MouseArea {
                anchors.fill: parent
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y < 0) zoomOut()
                    else if (wheel.angleDelta.y > 0) zoomIn()
                }
            }

            ////////

            MapMarker {
                id: mapMarker
            }

            MapPolyline {
                id: mapTrace
                visible: false
                line.width: 4
                line.color: Theme.colorSecondary
            }

            ////////

            Row {
                anchors.top: parent.top
                anchors.topMargin: Theme.componentMargin
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentMargin
                spacing: Theme.componentMargin

                MapButton {
                    id: button_map_fullscreen
                    width: mapArea.fullscreen ? 48 : 40
                    height: mapArea.fullscreen ? 48 : 40

                    source: mapArea.fullscreen ? "qrc:/assets/icons/material-symbols/fullscreen_exit.svg"
                                               : "qrc:/assets/icons/material-symbols/fullscreen.svg"
                    onClicked: mapArea.fullscreen = !mapArea.fullscreen
                }

                MapButton {
                    id: button_map_moove
                    width: mapArea.fullscreen ? 48 : 40
                    height: mapArea.fullscreen ? 48 : 40

                    source: "qrc:/assets/icons/material-symbols/open_with.svg"
                    highlighted: map.moove
                    onClicked: map.moove = !map.moove
                }
            }

            ////////

            Column {
                anchors.top: parent.top
                anchors.topMargin: Theme.componentMargin
                anchors.right: parent.right
                anchors.rightMargin: Theme.componentMargin
                spacing: Theme.componentMargin

                MapButtonCompass { // compass
                    width: 48
                    height: 48

                    onClicked: map.bearing = 0
                    sourceRotation: -map.bearing
                }

                MapButtonZoom { // zoom buttons
                    width: 48
                    height: 96

                    zoomLevel: map.zoomLevel
                    zoomLevel_minimum: map.zoomLevel_minimum
                    zoomLevel_maximum: map.zoomLevel_maximum

                    onMapZoomIn: {
                        map.zoomLevel = Math.round(map.zoomLevel + 1)
                        map.computeScale()
                    }
                    onMapZoomOut: {
                        map.zoomLevel = Math.round(map.zoomLevel - 1)
                        map.computeScale()
                    }
                }
            }

            ////////

            MapScale {
                id: mapScale
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentMargin
                anchors.bottom: parent.bottom
                anchors.bottomMargin: (mapmode === "image") ? 64 : Theme.componentMargin
                map: map
            }

            ////////

            MapFrameArea {
                anchors.right: parent.right
                anchors.rightMargin: Theme.componentMargin
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.componentMargin

                height: mapArea.fullscreen ? 44 : 40

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.componentMargin

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("GPS coordinates:")
                        font.pixelSize: Theme.fontSizeContent
                        font.bold: true
                        color: Theme.colorHeaderContent
                    }
                    TextEdit {
                        anchors.verticalCenter: parent.verticalCenter

                        readOnly: true
                        selectByMouse: true
                        selectionColor: Theme.colorPrimary
                        selectedTextColor: "white"

                        text: shot.latitudeString + " / " + shot.longitudeString
                        font.pixelSize: Theme.fontSizeContent
                        color: Theme.colorHeaderContent
                    }

                    Item { width: 1; height: 1; visible: shot.altitude; } // spacer

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: shot.altitude

                        text: qsTr("Altitude:")
                        font.pixelSize: Theme.fontSizeContent
                        font.bold: true
                        color: Theme.colorHeaderContent
                    }
                    TextEdit {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: shot.altitude

                        readOnly: true
                        selectByMouse: true
                        selectionColor: Theme.colorPrimary
                        selectedTextColor: "white"

                        text: UtilsString.altitudeToString(shot.altitude - shot.altitudeOffset, 0, settingsManager.appUnits)
                        font.pixelSize: Theme.fontSizeContent
                        color: Theme.colorHeaderContent
                    }

                    Item { width: 1; height: 1; visible: shot.speed; } // spacer

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: shot.speed

                        text: qsTr("Speed:")
                        font.pixelSize: Theme.fontSizeContent
                        font.bold: true
                        color: Theme.colorHeaderContent
                    }
                    TextEdit {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: shot.speed

                        readOnly: true
                        selectByMouse: true
                        selectionColor: Theme.colorPrimary
                        selectedTextColor: "white"

                        text: UtilsString.speedToString_km(shot.speed, 1, settingsManager.appUnits)
                        font.pixelSize: Theme.fontSizeContent
                        color: Theme.colorHeaderContent
                    }
                }
            }

            ////////
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Item {
        id: graphArea

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom

        z: -1
        width: parent.width * 0.60 - 16
        //Behavior on width { NumberAnimation { duration: 233 } }

        enabled: !mapArea.fullscreen

        property int graphLineWidth: 1
        property string graphHead: Theme.colorForeground // Theme.colorPrimary
        property string graphTxt: Theme.colorText // "white"
        property string graphBg: {
            if (Theme.currentTheme === Theme.THEME_LIGHT_AND_WARM) return Theme.colorComponentBackground
            if (Theme.currentTheme === Theme.THEME_DARK_AND_SPOOKY) return Theme.colorComponentBackground
            if (Theme.currentTheme === Theme.THEME_PLAIN_AND_BORING) return Theme.colorBackground
            if (Theme.currentTheme === Theme.THEME_BLOOD_AND_TEARS) return Theme.colorForeground
            if (Theme.currentTheme === Theme.THEME_MIGHTY_KITTENS) return Theme.colorComponentBackground
            return Theme.colorComponentBackground
        }

        ////////////////

        Grid {
            id: grid

            anchors.top: parent.top
            anchors.topMargin: Theme.componentMargin
            anchors.left: parent.left
            anchors.leftMargin: Theme.componentMargin
            anchors.right: parent.right
            anchors.rightMargin: Theme.componentMargin
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 72

            columns: 2
            spacing: Theme.componentMargin

            property int graphWidth: (grid.width - Theme.componentMargin) / 2
            property int graphHeight: (grid.height - Theme.componentMargin) / 2

            Rectangle { // speed box
                width: grid.graphWidth
                height: grid.graphHeight
                radius: Theme.componentRadius
                color: graphArea.graphBg
                border.width: 2
                border.color: graphArea.graphHead

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 40
                    radius: Theme.componentRadius
                    color: graphArea.graphHead

                    Text {
                        id: speedTitle
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Speed") + " (" + UtilsString.speedUnit(settingsManager.appUnits) + ")"
                        color: graphArea.graphTxt
                        font.bold: true
                        font.pixelSize: Theme.fontSizeContent
                    }

                    Text {
                        id: speedMetrics
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter
                        color: graphArea.graphTxt
                        font.pixelSize: 14
                    }
                }

                Item {
                    anchors.fill: parent
                    anchors.topMargin: 48

                    ChartView {
                        id: speedsGraph
                        anchors.fill: parent
                        anchors.topMargin: -16
                        anchors.leftMargin: -16
                        anchors.rightMargin: -12
                        anchors.bottomMargin: -16

                        legend.visible: false
                        antialiasing: true
                        backgroundColor: "transparent"
                        backgroundRoundness: 0

                        LineSeries {
                            id: speedsSeries
                            color: Theme.colorPrimary; width: graphArea.graphLineWidth;
                            axisX: ValueAxis { id: axisSpeedX0; visible: false; gridVisible: false; }
                            axisY: ValueAxis { id: axisSpeedY0; visible: true; gridVisible: true;
                                               labelsFont.pixelSize: Theme.fontSizeContentVerySmall; labelsColor: Theme.colorSubText; labelFormat: "%0.1f";
                                               gridLineColor: Theme.colorSeparator; }
                        }
                    }
                }
            }

            Rectangle { // alti box
                width: grid.graphWidth
                height: grid.graphHeight
                radius: Theme.componentRadius
                color: graphArea.graphBg
                border.width: 2
                border.color: graphArea.graphHead

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 40
                    radius: Theme.componentRadius
                    color: graphArea.graphHead

                    Text {
                        id: altiTitle
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Altitude") + " (" + UtilsString.altitudeUnit(settingsManager.appUnits) + ")"
                        color: graphArea.graphTxt
                        font.bold: true
                        font.pixelSize: Theme.fontSizeContent
                    }

                    Text {
                        id: altiMetrics
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter
                        color: graphArea.graphTxt
                        font.pixelSize: 14
                    }
                }

                Item {
                    anchors.fill: parent
                    anchors.topMargin: 48

                    ChartView {
                        id: altiGraph
                        anchors.fill: parent
                        anchors.topMargin: -16
                        anchors.leftMargin: -16
                        anchors.rightMargin: -12
                        anchors.bottomMargin: -16

                        legend.visible: false
                        antialiasing: true
                        backgroundColor: "transparent"

                        LineSeries {
                            id: altiSeries
                            color: Theme.colorWarning; width: graphArea.graphLineWidth;
                            axisX: ValueAxis { id: axisAltiX0; visible: false; gridVisible: false; }
                            axisY: ValueAxis { id: axisAltiY0; visible: true; gridVisible: true;
                                               labelsFont.pixelSize: Theme.fontSizeContentVerySmall; labelsColor: Theme.colorSubText; labelFormat: "%i";
                                               gridLineColor: Theme.colorSeparator; }
                        }
                    }
                }
            }

            Rectangle { // accl box
                width: grid.graphWidth
                height: grid.graphHeight
                radius: Theme.componentRadius
                color: graphArea.graphBg
                border.width: 2
                border.color: graphArea.graphHead

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 40
                    radius: Theme.componentRadius
                    color: graphArea.graphHead

                    Text {
                        id: acclTitle
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Accelerometer")
                        color: graphArea.graphTxt
                        font.bold: true
                        font.pixelSize: Theme.fontSizeContent
                    }

                    Text {
                        id: acclMetrics
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter
                        color: graphArea.graphTxt
                        font.pixelSize: 14
                    }
                }

                Item {
                    anchors.fill: parent
                    anchors.topMargin: 48

                    ChartView {
                        id: acclGraph
                        anchors.fill: parent
                        anchors.topMargin: -16
                        anchors.leftMargin: -16
                        anchors.rightMargin: -12
                        anchors.bottomMargin: -16

                        legend.visible: false
                        backgroundColor: "transparent"
                        antialiasing: true

                        ValueAxis { id: axisAcclX0; visible: false; gridVisible: false; }
                        ValueAxis { id: axisAcclY0; visible: true; gridVisible: true;
                                    labelsFont.pixelSize: Theme.fontSizeContentVerySmall; labelsColor: Theme.colorSubText; labelFormat: "%i";
                                    gridLineColor: Theme.colorSeparator; }

                        LineSeries { id: acclX; width: graphArea.graphLineWidth; axisX: axisAcclX0; axisY: axisAcclY0; }
                        LineSeries { id: acclY; width: graphArea.graphLineWidth; axisX: axisAcclX0; axisY: axisAcclY0; }
                        LineSeries { id: acclZ; width: graphArea.graphLineWidth; axisX: axisAcclX0; axisY: axisAcclY0; }
                    }
                }
            }

            Rectangle { // gyro box
                width: grid.graphWidth
                height:grid. graphHeight
                radius: Theme.componentRadius
                color: graphArea.graphBg
                border.width: 2
                border.color: graphArea.graphHead

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 40
                    radius: Theme.componentRadius
                    color: graphArea.graphHead

                    Text {
                        id: gyroTitle
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.componentMargin
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Gyroscope")
                        color: graphArea.graphTxt
                        font.bold: true
                        font.pixelSize: Theme.fontSizeContent
                    }
                }

                Item {
                    anchors.fill: parent
                    anchors.topMargin: 48

                    ChartView {
                        id: gyroGraph
                        anchors.fill: parent
                        anchors.topMargin: -16
                        anchors.leftMargin: -16
                        anchors.rightMargin: -12
                        anchors.bottomMargin: -16

                        legend.visible: false
                        antialiasing: true
                        backgroundColor: "transparent"

                        ValueAxis { id: axisGyroX0; visible: false; gridVisible: false; }
                        ValueAxis { id: axisGyroY0; visible: true; gridVisible: true;
                                    labelsFont.pixelSize: Theme.fontSizeContentVerySmall; labelsColor: Theme.colorSubText; labelFormat: "%i";
                                    gridLineColor: Theme.colorSeparator; }

                        LineSeries { id: gyroX; width: graphArea.graphLineWidth; axisX: axisGyroX0; axisY: axisGyroY0; }
                        LineSeries { id: gyroY; width: graphArea.graphLineWidth; axisX: axisGyroX0; axisY: axisGyroY0; }
                        LineSeries { id: gyroZ; width: graphArea.graphLineWidth; axisX: axisGyroX0; axisY: axisGyroY0; }
                    }
                }
            }
        }

        ////////////////

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: Theme.componentMargin
            anchors.right: parent.right
            anchors.rightMargin: Theme.componentMargin
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.componentMargin

            height: 40
            radius: Theme.componentRadius
            color: graphArea.graphHead

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentMargin
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Text {
                    id: labelDuration
                    text: qsTr("Track duration:")
                    font.pixelSize: Theme.fontSizeContent
                    color: graphArea.graphTxt
                }
                Text {
                    id: trackDuration
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContent
                    color: graphArea.graphTxt
                }

                Item { width: 1; height: 1; } // spacer

                Text {
                    id: labelDistance
                    text: qsTr("Distance traveled:")
                    font.pixelSize: Theme.fontSizeContent
                    color: graphArea.graphTxt
                }
                Text {
                    id: trackDistance
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContent
                    color: graphArea.graphTxt
                }
            }
        }

        ////////////////
    }

    ////////////////////////////////////////////////////////////////////////////
}
