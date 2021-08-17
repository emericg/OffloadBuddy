import QtQuick 2.12
import QtQuick.Controls 2.12

import QtCharts 2.3
import QtLocation 5.12
import QtPositioning 5.12

import ThemeEngine 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: contentTelemetry
    width: 1500
    height: 700
    anchors.fill: parent

    Connections {
        target: settingsManager
        onAppUnitsChanged: updateUnits()
    }
    function updateUnits() {
        speedsGraph.title = "Speed (" + UtilsString.speedUnit(settingsManager.appUnits) + ")"
        altiGraph.title = "Altitude (" + UtilsString.altitudeUnit(settingsManager.appUnits) + ")"
        updateMetadata()
    }

    function updateMap() { // "image" mode
        mapArea.fullscreen = true
        if (!mapLoader.sourceComponent) {
            mapLoader.sourceComponent = mapComponent
        }
        mapLoader.item.updateMap()
    }

    function updateMetadata() { // "video" mode
        // Map
        mapArea.fullscreen = false
        if (!mapLoader.sourceComponent) {
            mapLoader.sourceComponent = mapComponent
        }
        mapLoader.item.updateMetadata()

        // Graphs sizes
        altiGraph.legend.visible = false
        speedsGraph.legend.visible = false
        acclGraph.legend.visible = false
        gyroGraph.legend.visible = false

        if (shot) {
            // Graphs data
            speedsGraph.title = "Speed (" + UtilsString.speedUnit(settingsManager.appUnits) + ")"
            shot.updateSpeedsSerie(speedsSeries, settingsManager.appUnits)
            altiGraph.title = "Altitude (" + UtilsString.altitudeUnit(settingsManager.appUnits) + ")"
            shot.updateAltiSerie(altiSeries, settingsManager.appUnits);
            shot.updateAcclSeries(acclX, acclY, acclZ);
            shot.updateGyroSeries(gyroX, gyroY, gyroZ);

            // Text data
            speedMIN.text = UtilsString.speedToString(shot.minSpeed, 2, settingsManager.appUnits)
            speedAVG.text = UtilsString.speedToString(shot.avgSpeed, 2, settingsManager.appUnits)
            speedMAX.text = UtilsString.speedToString(shot.maxSpeed, 2, settingsManager.appUnits)

            altiMIN.text = UtilsString.altitudeToString(shot.minAlti, 0, settingsManager.appUnits)
            altiAVG.text = UtilsString.altitudeToString(shot.avgAlti, 0, settingsManager.appUnits)
            altiMAX.text = UtilsString.altitudeToString(shot.maxAlti, 0, settingsManager.appUnits)

            trackDuration.text = UtilsString.durationToString_long(shot.duration)
            trackDistance.text = UtilsString.distanceToString_km(shot.distanceKm, 1, settingsManager.appUnits)

            trackDuration2.text = UtilsString.durationToString_short(shot.duration)
            trackDistance2.text = trackDistance.text
            trackSpeed2.text = speedAVG.text

            acclMAX.text = (shot.maxG / 9.80665).toFixed(1) + " G's"

            // Graphs axis
            axisSpeedY0.min = shot.minSpeed * 0.9;
            axisSpeedY0.max = shot.maxSpeed * 1.1;
            axisAltiY0.min = shot.minAlti * 0.9;
            axisAltiY0.max = shot.maxAlti * 1.1;
            axisAcclY0.min = -12;
            axisAcclY0.max = 12;
            axisGyroY0.min = -8;
            axisGyroY0.max = 8;
            //axisGyroY0.applyNiceNumbers()

            axisSpeedX0.min = 0;
            axisSpeedX0.max = speedsSeries.count
            axisAltiX0.min = 0;
            axisAltiX0.max = altiSeries.count
            axisAcclX0.min = 0;
            axisAcclX0.max = acclX.count
            axisGyroX0.min = 0;
            axisGyroX0.max = gyroX.count
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        id: mapArea
        anchors.top: parent.top
        anchors.topMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16

        property bool fullscreen: false
        width: fullscreen ? parent.width - 32 : parent.width * 0.40
        Behavior on width { NumberAnimation { duration: 333 } }

        color: Theme.colorForeground

        ImageSvg {
            width: 64; height: 64;
            anchors.centerIn: parent

            color: Theme.colorIcon
            source: "qrc:/assets/icons_material/baseline-hourglass_empty-24px.svg"
        }

        Loader {
            id: mapLoader
            anchors.fill: parent

            //sourceComponent: mapComponent
            //asynchronous: true
        }
    }

    Component {
        id: mapComponent

        Map {
            id: map

            gesture.enabled: moove
            plugin: Plugin {
                //name: "mapboxgl"
                preferred: ["mapboxgl", "osm", "esri"]
                //PluginParameter { name: "osm.mapping.highdpi_tiles"; value: "true"; }
            }
            copyrightsVisible: false

            property bool fullscreen: false
            property bool moove: false

            //zoomLevel: 2
            //center: QtPositioning.coordinate(45.5, 6)

            ////////

            function updateMap() { // "image" mode
                button_map_fullscreen.visible = false

                if (shot.latitude !== 0.0) {
                    map.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
                    map.zoomLevel = 12
                    mapTrace.visible = false
                    mapMarker.visible = true
                    mapMarker.coordinate = QtPositioning.coordinate(shot.latitude, shot.longitude)
                    button_map_dezoom.enabled = true
                    button_map_zoom.enabled = true
                    calculateScale()
                }
            }

            function updateMetadata() { // "video" mode
                mapMarker.visible = false
                button_map_fullscreen.visible = true

                // GPS trace
                if (shot.latitude !== 0.0) {
                    button_map_dezoom.enabled = true
                    button_map_zoom.enabled = true

                    // clean GPS points
                    while (mapTrace.pathLength() > 0)
                        mapTrace.removeCoordinate(mapTrace.coordinateAt(0))

                    // add new GPS points // one per seconde (was 18Hz)
                    for (var i = 0; i < shot.getGpsPointCount(); i += 18)
                        mapTrace.addCoordinate(shot.getGpsCoordinates(i))

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

                    // center view
                    map.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
                    mapMarker.coordinate = QtPositioning.coordinate(shot.latitude, shot.longitude)

                    // scale indicator
                    calculateScale()

                    if (mapTrace.pathLength() > 1) {
                        mapTrace.visible = true
                        mapMarker.visible = false
                    } else {
                        mapTrace.visible = false
                        mapMarker.visible = true
                    }
                }
            }

            property variant scaleLengths: [5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000, 1000000, 2000000]

            function calculateScale() {
                //console.log("calculateScale(zoom: " + map.zoomLevel + ")")

                var coord1, coord2, dist, f
                f = 0
                coord1 = map.toCoordinate(Qt.point(0, mapScale.y))
                coord2 = map.toCoordinate(Qt.point(100, mapScale.y))
                dist = Math.round(coord1.distanceTo(coord2))

                if (dist === 0) {
                    // not visible
                } else {
                    for (var i = 0; i < scaleLengths.length-1; i++) {
                        if (dist < (scaleLengths[i] + scaleLengths[i+1]) / 2 ) {
                            f = scaleLengths[i] / dist
                            dist = scaleLengths[i]
                            break;
                        }
                    }
                    if (f === 0) {
                        f = dist / scaleLengths[i]
                        dist = scaleLengths[i]
                    }
                }

                mapScale.width = 100 * f
                mapScaleText.text = UtilsString.distanceToString(dist, 0, settingsManager.appUnits)
            }

            function zoomIn() {
                if (map.zoomLevel < Math.round(map.maximumZoomLevel)) {
                    map.zoomLevel = Math.round(map.zoomLevel + 1)
                    if (!map.moove) map.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
                    calculateScale()
                }
            }

            function zoomOut() {
                if (map.zoomLevel > Math.round(map.minimumZoomLevel)) {
                    map.zoomLevel = Math.round(map.zoomLevel - 1)
                    if (!map.moove) map.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
                    calculateScale()
                }
            }

            ////////

            MouseArea {
                anchors.fill: parent
                onWheel: {
                    if (wheel.angleDelta.y < 0) zoomOut()
                    else if (wheel.angleDelta.y > 0) zoomIn()
                }
            }

            ////////

            MapQuickItem {
                id: mapMarker
                visible: false
                anchorPoint.x: mapMarkerImg.width/2
                anchorPoint.y: mapMarkerImg.height/2
                sourceItem: Image {
                    id: mapMarkerImg
                    width: 64
                    height: 64
                    source: "qrc:/assets/others/gps_marker.svg"
                }
            }

            MapPolyline {
                id: mapTrace
                visible: false
                line.width: 3
                line.color: Theme.colorSecondary
            }

            ////////

            Row {
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 16
                spacing: 16

                ItemImageButton {
                    id: button_map_fullscreen
                    width: mapArea.fullscreen ? 48 : 40
                    height: mapArea.fullscreen ? 48 : 40

                    background: true
                    backgroundColor: Theme.colorHeader
                    iconColor: Theme.colorHeaderContent
                    highlightMode: "color"
                    highlightColor: Theme.colorBackground

                    source: mapArea.fullscreen ? "qrc:/assets/icons_material/baseline-fullscreen_exit-24px.svg"
                                           : "qrc:/assets/icons_material/baseline-fullscreen-24px.svg"
                    onClicked: mapArea.fullscreen = !mapArea.fullscreen
                }

                ItemImageButton {
                    id: button_map_moove
                    width: mapArea.fullscreen ? 48 : 40
                    height: mapArea.fullscreen ? 48 : 40

                    background: true
                    backgroundColor: Theme.colorHeader
                    iconColor: Theme.colorHeaderContent
                    highlightMode: "color"
                    highlightColor: Theme.colorBackground

                    selected: map.moove
                    onClicked: map.moove = !map.moove
                    source: "qrc:/assets/icons_material/baseline-open_with-24px.svg"
                }
            }

            Row {
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 16
                spacing: 16

                ItemImageButton {
                    id: button_map_dezoom
                    width: mapArea.fullscreen ? 48 : 40
                    height: mapArea.fullscreen ? 48 : 40

                    background: true
                    backgroundColor: Theme.colorHeader
                    iconColor: Theme.colorHeaderContent
                    highlightMode: "color"
                    highlightColor: Theme.colorBackground

                    source: "qrc:/assets/icons_material/baseline-zoom_out-24px.svg"
                    onClicked: zoomOut()
                }

                ItemImageButton {
                    id: button_map_zoom
                    width: mapArea.fullscreen ? 48 : 40
                    height: mapArea.fullscreen ? 48 : 40

                    background: true
                    backgroundColor: Theme.colorHeader
                    iconColor: Theme.colorHeaderContent
                    highlightMode: "color"
                    highlightColor: Theme.colorBackground

                    source: "qrc:/assets/icons_material/baseline-zoom_in-24px.svg"
                    onClicked: zoomIn()
                }
            }

            ////////

            Item {
                id: mapScale
                width: 100
                height: 16
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: mapMarker.visible ? 64 : 16

                Text {
                    id: mapScaleText
                    anchors.centerIn: parent
                    text: "100m"
                    color: "#555"
                    font.pixelSize: Theme.fontSizeContentVerySmall
                }

                Rectangle {
                    width: 2; height: 6;
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    color: "#555"
                }
                Rectangle {
                    width: parent.width; height: 2;
                    anchors.bottom: parent.bottom
                    color: "#555"
                }
                Rectangle {
                    width: 2; height: 6;
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    color:"#555"
                }
            }

            ////////

            Rectangle {
                height: mapArea.fullscreen ? 48 : 40
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                color: Theme.colorHeader
                opacity: 0.8
                visible: mapMarker.visible

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 16

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("GPS coordinates:")
                        font.pixelSize: Theme.fontSizeContent
                        font.bold: true
                        color: Theme.colorHeaderContent
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: shot.latitudeString + "    " + shot.longitudeString
                        font.pixelSize: Theme.fontSizeContent
                        color: Theme.colorHeaderContent
                    }

                    Item { width: 1; height: 1; } // spacer

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: qsTr("Altitude:")
                        font.pixelSize: Theme.fontSizeContent
                        font.bold: true
                        color: Theme.colorHeaderContent
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter

                        text: UtilsString.altitudeToString(shot.altitude - shot.altitudeOffset, 0, settingsManager.appUnits)
                        font.pixelSize: Theme.fontSizeContent
                        color: Theme.colorHeaderContent
                    }
                }
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Item {
        id: rectangleGraphs

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom

        width: parent.width * 0.6
        z: -1

        Column {
            id: rectangleText

            anchors.top: parent.top
            anchors.topMargin: 24
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24
            spacing: 12

            Row {
                spacing: 24

                Row {
                    height: 28

                    Rectangle {
                        width: parent.height
                        height: parent.height
                        color: Theme.colorMaterialLightGreen
                        ImageSvg {
                            width: 20
                            height: 20
                            anchors.centerIn: parent
                            source: "qrc:/assets/icons_material/baseline-timer-24px.svg"
                            color: "white"
                        }
                    }
                    Rectangle {
                        width: 24 + trackDuration2.contentWidth
                        height: parent.height
                        color: Theme.colorForeground
                        Text {
                            id: trackDuration2
                            anchors.centerIn: parent
                            text: "01:24.254"
                            color: Theme.colorText
                            font.bold: true
                            font.pixelSize: Theme.fontSizeContentSmall
                        }
                    }
                }

                Row {
                    height: 28

                    Rectangle {
                        width: parent.height
                        height: parent.height
                        color: Theme.colorMaterialLightGreen
                        ImageSvg {
                            width: 20
                            height: 20
                            anchors.centerIn: parent
                            source: "qrc:/assets/icons_material/baseline-straighten-24px.svg"
                            color: "white"
                        }
                    }
                    Rectangle {
                        width: 24 + trackDistance2.contentWidth
                        height: parent.height
                        color: Theme.colorForeground
                        Text {
                            id: trackDistance2
                            height: parent.height
                            anchors.centerIn: parent
                            text: "0.0 km"
                            color: Theme.colorText
                            font.bold: true
                            font.pixelSize: Theme.fontSizeContentSmall
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Row {
                    height: 28

                    Rectangle {
                        width: parent.height
                        height: parent.height
                        color: Theme.colorMaterialLightGreen
                        ImageSvg {
                            width: 20
                            height: 20
                            anchors.centerIn: parent
                            source: "qrc:/assets/icons_material/outline-speed-24px.svg"
                            color: "white"
                        }
                    }
                    Rectangle {
                        width: 24 + trackSpeed2.contentWidth
                        height: parent.height
                        color: Theme.colorForeground
                        Text {
                            id: trackSpeed2
                            height: parent.height
                            anchors.centerIn: parent
                            text: "0.0 km/h"
                            color: Theme.colorText
                            font.bold: true
                            font.pixelSize: Theme.fontSizeContentSmall
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            ////////

            Row {
                spacing: 12

                Text {
                    id: labelDuration
                    text: qsTr("Track duration:")
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }
                Text {
                    id: trackDuration
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }

                Item { width: 1; height: 1; } // spacer

                Text {
                    id: labelDistance
                    text: qsTr("Distance traveled:")
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }
                Text {
                    id: trackDistance
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }
            }

            Row {
                spacing: 8

                Text {
                    id: labelAvgSpeed
                    text: qsTr("Average speed:")
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    id: speedAVG
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }

                Item { width: 1; height: 1; } // spacer

                Text {
                    id: labelMinSpeed
                    text: qsTr("(min:")
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }
                Text {
                    id: speedMIN
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }

                Text {
                    id: labelMaxSpeed
                    text: qsTr("/ max:")
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    id: speedMAX
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }
                Text {
                    text: qsTr(")")
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }
            }

            Row {
                spacing: 8

                Text {
                    id: labelAvgAltitude
                    text: qsTr("Average altitude:")
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }
                Text {
                    id: altiAVG
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }

                Item { width: 1; height: 1; } // spacer

                Text {
                    id: labelMinAltitude
                    text: qsTr("(min:")
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }
                Text {
                    id: altiMIN
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }

                Text {
                    id: labelMaxAltitude
                    text: qsTr("/ max:")
                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContentSmall
                }
                Text {
                    id: altiMAX
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }
                Text {
                    text: qsTr(")")
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }
            }

            Row {
                spacing: 8

                Text {
                    id: labelGforce
                    text: qsTr("Max G force:")
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }
                Text {
                    id: acclMAX
                    font.bold: true
                    font.pixelSize: Theme.fontSizeContentSmall
                    color: Theme.colorText
                }
            }
        }

        ////////////////

        Grid {
            id: grid
            columns: 2

            anchors.top: rectangleText.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            ChartView {
                id: speedsGraph
                width: grid.width / 2
                height: grid.height / 2
                anchors.margins: -24

                title: "Speed (" + UtilsString.speedUnit(settingsManager.appUnits) + ")"
                titleColor: Theme.colorText
                titleFont.pixelSize: Theme.fontSizeContentSmall
                titleFont.bold: true

                antialiasing: true
                backgroundColor: "transparent"
                backgroundRoundness: 0
                legend.visible: false

                LineSeries {
                    id: speedsSeries
                    color: Theme.colorPrimary;  width: 1;
                    axisX: ValueAxis { id: axisSpeedX0; visible: false; gridVisible: false; }
                    axisY: ValueAxis { id: axisSpeedY0; visible: true; gridVisible: true;
                                       labelsFont.pixelSize: Theme.fontSizeContentVerySmall; labelsColor: Theme.colorSubText; labelFormat: "%0.1f";
                                       gridLineColor: Theme.colorSeparator; }
                }
            }

            ChartView {
                id: altiGraph
                width: grid.width / 2
                height: grid.height / 2
                anchors.margins: -24

                title: "Altitude (" + UtilsString.altitudeUnit(settingsManager.appUnits) + ")"
                titleColor: Theme.colorText
                titleFont.pixelSize: Theme.fontSizeContentSmall
                titleFont.bold: true

                backgroundColor: "transparent"
                antialiasing: true

                LineSeries {
                    id: altiSeries
                    color: Theme.colorWarning;  width: 1;
                    axisX: ValueAxis { id: axisAltiX0; visible: false; gridVisible: false; }
                    axisY: ValueAxis { id: axisAltiY0; visible: true; gridVisible: true;
                                       labelsFont.pixelSize: Theme.fontSizeContentVerySmall; labelsColor: Theme.colorSubText; labelFormat: "%i";
                                       gridLineColor: Theme.colorSeparator; }
                }
            }

            ChartView {
                id: acclGraph
                width: grid.width / 2
                height: grid.height / 2
                anchors.margins: -24

                title: "Acceleration"
                titleColor: Theme.colorText
                titleFont.pixelSize: Theme.fontSizeContentSmall
                titleFont.bold: true
                backgroundColor: "transparent"
                antialiasing: true

                ValueAxis { id: axisAcclX0; visible: false; gridVisible: false; }
                ValueAxis { id: axisAcclY0; visible: true; gridVisible: true;
                            labelsFont.pixelSize: Theme.fontSizeContentVerySmall; labelsColor: Theme.colorSubText; labelFormat: "%i";
                            gridLineColor: Theme.colorSeparator; }

                LineSeries { id: acclX; axisX: axisAcclX0; axisY: axisAcclY0; }
                LineSeries { id: acclY; axisX: axisAcclX0; axisY: axisAcclY0; }
                LineSeries { id: acclZ; axisX: axisAcclX0; axisY: axisAcclY0; }
            }

            ChartView {
                id: gyroGraph
                width: grid.width / 2
                height: grid.height / 2
                anchors.margins: -24

                title: "Gyroscope"
                titleColor: Theme.colorText
                titleFont.pixelSize: Theme.fontSizeContentSmall
                titleFont.bold: true
                backgroundColor: "transparent"
                antialiasing: true

                ValueAxis { id: axisGyroX0; visible: false; gridVisible: false; }
                ValueAxis { id: axisGyroY0; visible: true; gridVisible: true;
                            labelsFont.pixelSize: Theme.fontSizeContentVerySmall; labelsColor: Theme.colorSubText; labelFormat: "%i";
                            gridLineColor: Theme.colorSeparator; }

                LineSeries { id: gyroX; axisX: axisGyroX0; axisY: axisGyroY0; }
                LineSeries { id: gyroY; axisX: axisGyroX0; axisY: axisGyroY0; }
                LineSeries { id: gyroZ; axisX: axisGyroX0; axisY: axisGyroY0; }
            }
        }
    }
}
