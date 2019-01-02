import QtQuick 2.9
import QtQuick.Controls 2.2

import QtCharts 2.2
import QtLocation 5.9
import QtPositioning 5.9

import com.offloadbuddy.style 1.0
import com.offloadbuddy.shared 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: contentTelemetry
    width: 1500
    height: 700
    anchors.fill: parent
    color: "#00000000"

    Connections {
        target: settingsManager
        onAppUnitsChanged: updateUnits()
    }

    function updateUnits() {
        speedsGraph.title = "Speed (" + StringUtils.speedUnit(settingsManager.appunits) + ")"
        altiGraph.title = "Altitude (" + StringUtils.altitudeUnit(settingsManager.appunits) + ")"
        updateMetadatas()
    }

    function updateMetadatas() {

        // Graphs sizes
        altiGraph.legend.visible = false
        speedsGraph.legend.visible = false
        acclGraph.legend.visible = false
        gyroGraph.legend.visible = false
        onWidthChanged()
        onHeightChanged()

        if (shot) {
            if (shot.latitude !== 0.0) {
                mapTraceGPS.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
                mapTraceGPS.zoomLevel = 12
                mapMarker.visible = false
                mapMarker.coordinate = QtPositioning.coordinate(shot.latitude, shot.longitude)
                button_map_dezoom.enabled = true
                button_map_zoom.enabled = true
            }

            // Graphs datas
            speedsGraph.title = "Speed (" + StringUtils.speedUnit(settingsManager.appunits) + ")"
            shot.updateSpeedsSerie(speedsSeries, settingsManager.appunits)
            altiGraph.title = "Altitude (" + StringUtils.altitudeUnit(settingsManager.appunits) + ")"
            shot.updateAltiSerie(altiSeries, settingsManager.appunits);
            shot.updateAcclSeries(acclX, acclY, acclZ);
            shot.updateGyroSeries(gyroX, gyroY, gyroZ);

            // Text datas
            speedMIN.text = StringUtils.speedToString(shot.minSpeed, 2, settingsManager.appunits)
            speedAVG.text = StringUtils.speedToString(shot.avgSpeed, 2, settingsManager.appunits)
            speedMAX.text = StringUtils.speedToString(shot.maxSpeed, 2, settingsManager.appunits)

            altiMIN.text = StringUtils.altitudeToString(shot.minAlti, 0, settingsManager.appunits)
            altiAVG.text = StringUtils.altitudeToString(shot.avgAlti, 0, settingsManager.appunits)
            altiMAX.text = StringUtils.altitudeToString(shot.maxAlti, 0, settingsManager.appunits)

            trackDuration.text = StringUtils.durationToString(shot.duration)
            trackDistance.text = StringUtils.distanceToString(shot.distanceKm, 1, settingsManager.appunits)
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
            axisSpeedX0.max = speedsSeries.count;
            axisAltiX0.min = 0;
            axisAltiX0.max = altiSeries.count;
            axisAcclX0.min = 0;
            axisAcclX0.max = acclX.count
            axisGyroX0.min = 0;
            axisGyroX0.max = gyroX.count

            // GPS trace
            mapTrace.visible = true

            if (shot.distanceKm < 0.5)
                mapTraceGPS.zoomLevel = 18
            else if (shot.distanceKm < 2)
                mapTraceGPS.zoomLevel = 15
            else if (shot.distanceKm < 10)
                mapTraceGPS.zoomLevel = 12
            else if (shot.distanceKm < 50)
                mapTraceGPS.zoomLevel = 10
            else if (shot.distanceKm < 100)
                mapTraceGPS.zoomLevel = 8

            // clean GPS points
            while (mapTrace.pathLength() > 0)
                mapTrace.removeCoordinate(mapTrace.coordinateAt(0))

            // add new GPS points // FIXME
            for (var i = 0; i < 18000; i+=18)
                mapTrace.addCoordinate(shot.getGpsCoordinates(i))
        }
    }

    onWidthChanged: {
        rectangleMap.width = width * 0.40;
        altiGraph.width = grid.width / 2
        speedsGraph.width = grid.width / 2
        acclGraph.width = grid.width / 2
        gyroGraph.width = grid.width / 2
    }
    onHeightChanged: {
        altiGraph.height = grid.height / 2
        speedsGraph.height = grid.height / 2
        acclGraph.height = grid.height / 2
        gyroGraph.height = grid.height / 2
    }

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        id: rectangleMap
        width: 500
        color: ThemeEngine.colorContentBackground

        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        Map {
            id: mapTraceGPS
            anchors.leftMargin: 0
            anchors.fill: parent
            copyrightsVisible: false
            anchors.margins: 16

            gesture.enabled: false
            z: parent.z + 1
            plugin: Plugin { name: "mapboxgl" } // "osm", "mapboxgl", "esri"
            center: QtPositioning.coordinate(45.5, 6)
            zoomLevel: 2

            MouseArea {
                anchors.fill: parent
                onWheel: {
                    if (wheel.angleDelta.y < 0)
                        onClicked: parent.zoomLevel--
                    else
                        onClicked: parent.zoomLevel++
                }
            }

            Row {
                id: row
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 16
                spacing: 16

                ButtonThemed {
                    id: button_map_dezoom
                    width: 40
                    height: 40
                    text: "-"
                    font.bold: true
                    font.pointSize: 16
                    opacity: 0.8

                    onClicked: parent.parent.zoomLevel--
                }

                ButtonThemed {
                    id: button_map_zoom
                    width: 40
                    height: 40
                    text: "+"
                    font.bold: true
                    font.pointSize: 16
                    opacity: 0.8

                    onClicked: parent.parent.zoomLevel++
                }
            }

            MapQuickItem {
                id: mapMarker
                visible: false
                anchorPoint.x: mapMarkerImg.width/2
                anchorPoint.y: mapMarkerImg.height/2
                sourceItem: Image {
                    id: mapMarkerImg
                    source: "qrc:/resources/other/gps_marker.svg"
                }
            }

            MapPolyline {
                id: mapTrace
                visible: true
                line.width: 3
                line.color: ThemeEngine.colorApproved

                path: [
                    { latitude: 45.5, longitude: 6 },
                ]
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        id: rectangleGraphs
        color: ThemeEngine.colorContentBackground

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.right: rectangleMap.left
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        Rectangle {
            id: rectangleText
            height: 138
            color: ThemeEngine.colorContentSubBox
            clip: true
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16

            Text {
                id: labelMaxSpeed
                text: qsTr("Max speed:")
                anchors.left: speedAVG.right
                anchors.leftMargin: 32
                anchors.verticalCenter: labelAvgSpeed.verticalCenter
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: labelAvgSpeed
                text: qsTr("Average speed:")
                anchors.top: labelDistance.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 8
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: labelMaxAltitude
                y: 32
                text: qsTr("Max altitude:")
                anchors.left: altiAVG.right
                anchors.leftMargin: 32
                anchors.verticalCenter: labelAvgAltitude.verticalCenter
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: labelAvgAltitude
                text: qsTr("Average altitude:")
                anchors.top: labelAvgSpeed.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 8
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: labelMinSpeed
                text: qsTr("Min speed:")
                anchors.left: speedMAX.right
                anchors.leftMargin: 32
                anchors.verticalCenter: labelAvgSpeed.verticalCenter
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: labelMinAltitude
                text: qsTr("Min altitude:")
                anchors.left: altiMAX.right
                anchors.leftMargin: 32
                anchors.verticalCenter: labelAvgAltitude.verticalCenter
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: labelGforce
                text: qsTr("Max G force:")
                anchors.top: labelAvgAltitude.bottom
                anchors.topMargin: 8
                font.bold: true
                anchors.left: parent.left
                anchors.leftMargin: 8
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: speedAVG
                text: qsTr("AVG")
                anchors.verticalCenter: labelAvgSpeed.verticalCenter
                anchors.left: labelAvgSpeed.right
                anchors.leftMargin: 12
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: speedMAX
                text: qsTr("MAX")
                anchors.left: labelMaxSpeed.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelMaxSpeed.verticalCenter
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: speedMIN
                text: qsTr("MIN")
                anchors.left: labelMinSpeed.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelMinSpeed.verticalCenter
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: altiAVG
                text: qsTr("AVG")
                anchors.left: labelAvgAltitude.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelAvgAltitude.verticalCenter
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: altiMAX
                text: qsTr("MAX")
                anchors.left: labelMaxAltitude.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelMaxAltitude.verticalCenter
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: altiMIN
                text: qsTr("MIN")
                anchors.left: labelMinAltitude.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelMinAltitude.verticalCenter
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: acclMAX
                text: qsTr("MAX")
                anchors.left: labelGforce.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelGforce.verticalCenter
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: labelDuration
                text: qsTr("Duration:")
                anchors.top: parent.top
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 8
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: trackDuration
                text: "text"
                anchors.left: labelDuration.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelDuration.verticalCenter
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: labelDistance
                text: qsTr("Distance traveled:")
                anchors.top: labelDuration.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 8
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: trackDistance
                text: "text"
                anchors.left: labelDistance.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelDistance.verticalCenter
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }
        }

        Grid {
            id: grid
            columns: 2
            anchors.top: rectangleText.bottom
            anchors.topMargin: 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0

            ChartView {
                id: speedsGraph
                width: 302
                height: 173
                title: "Speed (" + StringUtils.speedUnit(settingsManager.appunits) + ")"

                antialiasing: true
                //legend.visible: false // Needs Qt 5.10+ / Qt Charts 2.3
                //backgroundRoundness: 0
                //backgroundColor: "#00000000"

                LineSeries {
                    id: speedsSeries
                    axisX: ValueAxis { id: axisSpeedX0; visible: false; gridVisible: false; }
                    axisY: ValueAxis { id: axisSpeedY0; visible: true; gridVisible: true;
                                       labelsFont.pixelSize: 12; labelFormat: "%0.1f"; }
                }
            }

            ChartView {
                id: altiGraph
                width: 304
                height: 173
                title: "Altitude (" + StringUtils.altitudeUnit(settingsManager.appunits) + ")"

                antialiasing: true
                //legend.visible: false // Needs Qt 5.10+ / Qt Charts 2.3
                //backgroundRoundness: 0
                //backgroundColor: "#00000000"

                LineSeries {
                    id: altiSeries
                    color: "green"
                    axisX: ValueAxis { id: axisAltiX0; visible: false; gridVisible: false; }
                    axisY: ValueAxis { id: axisAltiY0; visible: true; gridVisible: true;
                                       labelsFont.pixelSize: 12; labelFormat: "%i"; }
                }
            }

            ChartView {
                id: acclGraph
                width: 302
                height: 173
                title: "Acceleration"
                antialiasing: true

                ValueAxis { id: axisAcclX0; visible: false; gridVisible: false; }
                ValueAxis { id: axisAcclY0; visible: true; gridVisible: true;
                            labelsFont.pixelSize: 12; labelFormat: "%i"; }

                SplineSeries { id: acclX; axisX: axisAcclX0; axisY: axisAcclY0; }
                SplineSeries { id: acclY; axisX: axisAcclX0; axisY: axisAcclY0; }
                SplineSeries { id: acclZ; axisX: axisAcclX0; axisY: axisAcclY0; }
            }

            ChartView {
                id: gyroGraph
                width: 302
                height: 173
                plotAreaColor: "#00000000"
                title: "Gyroscope"
                antialiasing: true

                ValueAxis { id: axisGyroX0; visible: false; gridVisible: false; }
                ValueAxis { id: axisGyroY0; visible: true; gridVisible: true;
                            labelsFont.pixelSize: 12; labelFormat: "%i"; }

                LineSeries { id: gyroX; axisX: axisGyroX0; axisY: axisGyroY0; color: "red"; }
                LineSeries { id: gyroY; axisX: axisGyroX0; axisY: axisGyroY0; color: "green"; }
                LineSeries { id: gyroZ; axisX: axisGyroX0; axisY: axisGyroY0; color: "blue"; }
            }
        }
    }
}
