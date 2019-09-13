import QtQuick 2.9
import QtQuick.Controls 2.2

import QtCharts 2.2
import QtLocation 5.9
import QtPositioning 5.9

import com.offloadbuddy.theme 1.0
import com.offloadbuddy.shared 1.0
import "UtilsString.js" as UtilsString

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
        speedsGraph.title = "Speed (" + UtilsString.speedUnit(settingsManager.appunits) + ")"
        altiGraph.title = "Altitude (" + UtilsString.altitudeUnit(settingsManager.appunits) + ")"
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
            // Graphs datas
            speedsGraph.title = "Speed (" + UtilsString.speedUnit(settingsManager.appunits) + ")"
            shot.updateSpeedsSerie(speedsSeries, settingsManager.appunits)
            altiGraph.title = "Altitude (" + UtilsString.altitudeUnit(settingsManager.appunits) + ")"
            shot.updateAltiSerie(altiSeries, settingsManager.appunits);
            shot.updateAcclSeries(acclX, acclY, acclZ);
            shot.updateGyroSeries(gyroX, gyroY, gyroZ);

            // Text datas
            speedMIN.text = UtilsString.speedToString(shot.minSpeed, 2, settingsManager.appunits)
            speedAVG.text = UtilsString.speedToString(shot.avgSpeed, 2, settingsManager.appunits)
            speedMAX.text = UtilsString.speedToString(shot.maxSpeed, 2, settingsManager.appunits)

            altiMIN.text = UtilsString.altitudeToString(shot.minAlti, 0, settingsManager.appunits)
            altiAVG.text = UtilsString.altitudeToString(shot.avgAlti, 0, settingsManager.appunits)
            altiMAX.text = UtilsString.altitudeToString(shot.maxAlti, 0, settingsManager.appunits)

            trackDuration.text = UtilsString.durationToString(shot.duration)
            trackDistance.text = UtilsString.distanceToString(shot.distanceKm, 1, settingsManager.appunits)
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
            if (shot.latitude !== 0.0) {
                button_map_dezoom.enabled = true
                button_map_zoom.enabled = true

                // clean GPS points
                while (mapTrace.pathLength() > 0)
                    mapTrace.removeCoordinate(mapTrace.coordinateAt(0))

                // add new GPS points // one per seconde (at 18Hz)
                for (var i = 0; i < shot.getGpsPointCount(); i+=18)
                    mapTrace.addCoordinate(shot.getGpsCoordinates(i))

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

                mapTraceGPS.center = QtPositioning.coordinate(shot.latitude, shot.longitude)

                if (mapTrace.pathLength() > 1) {
                    mapTrace.visible = true
                    mapMarker.visible = false
                } else {
                    mapTrace.visible = false
                    mapMarker.visible = true
                    mapMarker.coordinate = QtPositioning.coordinate(shot.latitude, shot.longitude)
                }
            }
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

    Item {
        id: rectangleMap
        width: 500

        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        Map {
            id: mapTraceGPS
            anchors.fill: parent
            anchors.margins: 16
            z: parent.z + 1

            copyrightsVisible: false
            gesture.enabled: false
            plugin: Plugin { name: "mapboxgl" } // "osm", "mapboxgl", "esri"

            //zoomLevel: 2
            //center: QtPositioning.coordinate(45.5, 6)

            MouseArea {
                anchors.fill: parent
                onWheel: {
                    if (wheel.angleDelta.y < 0)
                        mapTraceGPS.zoomLevel--
                    else
                        mapTraceGPS.zoomLevel++

                    mapTraceGPS.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
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
                    width: 40
                    height: 40
                    iconColor: "#606060"
                    highlightColor: "#F0F0F0"

                    source: "qrc:/icons_material/baseline-zoom_out-24px.svg"
                    onClicked: {
                        mapTraceGPS.zoomLevel--
                        mapTraceGPS.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
                    }
                }

                ItemImageButton {
                    id: button_map_zoom
                    width: 40
                    height: 40
                    iconColor: "#606060"
                    highlightColor: "#F0F0F0"

                    source: "qrc:/icons_material/baseline-zoom_in-24px.svg"
                    onClicked: {
                        mapTraceGPS.zoomLevel++
                        mapTraceGPS.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
                    }
                }
            }

            MapQuickItem {
                id: mapMarker
                visible: false
                anchorPoint.x: mapMarkerImg.width/2
                anchorPoint.y: mapMarkerImg.height/2
                sourceItem: Image {
                    id: mapMarkerImg
                    source: "qrc:/others/gps_marker.svg"
                }
            }

            MapPolyline {
                id: mapTrace
                visible: true
                line.width: 3
                line.color: Theme.colorPrimary

                path: [
                    { latitude: 45.5, longitude: 6 },
                ]
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Item {
        id: rectangleGraphs

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.right: rectangleMap.left
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        Item {
            id: rectangleText
            height: 138

            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16

            Text {
                id: labelMaxSpeed
                text: qsTr("max:")
                anchors.left: speedMIN.right
                anchors.leftMargin: 32
                anchors.verticalCenter: labelAvgSpeed.verticalCenter
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: labelAvgSpeed
                text: qsTr("Average speed:")
                anchors.top: labelDistance.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 8
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: labelMaxAltitude
                y: 32
                text: qsTr("max:")
                anchors.left: altiMIN.right
                anchors.leftMargin: 32
                anchors.verticalCenter: labelAvgAltitude.verticalCenter
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: labelAvgAltitude
                text: qsTr("Average altitude:")
                anchors.top: labelAvgSpeed.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 8
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: labelMinSpeed
                text: qsTr("min:")
                anchors.left: speedAVG.right
                anchors.leftMargin: 32
                anchors.verticalCenter: labelAvgSpeed.verticalCenter
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: labelMinAltitude
                text: qsTr("min:")
                anchors.left: altiAVG.right
                anchors.leftMargin: 32
                anchors.verticalCenter: labelAvgAltitude.verticalCenter
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: labelGforce
                text: qsTr("Max G force:")
                anchors.top: labelAvgAltitude.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 8
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: speedAVG
                text: qsTr("AVG")
                font.bold: true
                anchors.verticalCenter: labelAvgSpeed.verticalCenter
                anchors.left: labelAvgSpeed.right
                anchors.leftMargin: 12
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: speedMAX
                text: qsTr("MAX")
                font.bold: true
                anchors.left: labelMaxSpeed.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelMaxSpeed.verticalCenter
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: speedMIN
                text: qsTr("MIN")
                font.bold: true
                anchors.left: labelMinSpeed.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelMinSpeed.verticalCenter
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: altiAVG
                text: qsTr("AVG")
                font.bold: true
                anchors.left: labelAvgAltitude.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelAvgAltitude.verticalCenter
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: altiMAX
                text: qsTr("MAX")
                font.bold: true
                anchors.left: labelMaxAltitude.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelMaxAltitude.verticalCenter
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: altiMIN
                text: qsTr("MIN")
                font.bold: true
                anchors.left: labelMinAltitude.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelMinAltitude.verticalCenter
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: acclMAX
                text: qsTr("MAX")
                font.bold: true
                anchors.left: labelGforce.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelGforce.verticalCenter
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: labelDuration
                text: qsTr("Track duration:")
                anchors.top: parent.top
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 8
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: trackDuration
                text: "text"
                font.bold: true
                anchors.left: labelDuration.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelDuration.verticalCenter
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: labelDistance
                text: qsTr("Distance traveled:")
                anchors.verticalCenter: labelDuration.verticalCenter
                anchors.left: trackDuration.right
                anchors.leftMargin: 32
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
            }

            Text {
                id: trackDistance
                text: "text"
                font.bold: true
                anchors.left: labelDistance.right
                anchors.leftMargin: 12
                anchors.verticalCenter: labelDistance.verticalCenter
                font.pixelSize: Theme.fontSizeContentText
                color: Theme.colorText
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
                width: 480
                height: 240

                title: "Speed (" + UtilsString.speedUnit(settingsManager.appunits) + ")"
                titleColor: Theme.colorText
                titleFont.pixelSize: 14
                titleFont.bold: true

                antialiasing: true
                //legend.visible: false // Needs Qt 5.10+ / Qt Charts 2.3
                //backgroundRoundness: 0
                backgroundColor: "transparent"

                LineSeries {
                    id: speedsSeries
                    axisX: ValueAxis { id: axisSpeedX0; visible: false; gridVisible: false; }
                    axisY: ValueAxis { id: axisSpeedY0; visible: true; gridVisible: true;
                                       labelsFont.pixelSize: 10; labelsColor: Theme.colorText; labelFormat: "%0.1f";
                                       /*gridLineColor: Theme.colorSeparator;*/ }
                }
            }

            ChartView {
                id: altiGraph
                width: 480
                height: 240

                title: "Altitude (" + UtilsString.altitudeUnit(settingsManager.appunits) + ")"
                titleColor: Theme.colorText
                titleFont.pixelSize: 14
                titleFont.bold: true
                backgroundColor: "transparent"
                antialiasing: true

                LineSeries {
                    id: altiSeries
                    axisX: ValueAxis { id: axisAltiX0; visible: false; gridVisible: false; }
                    axisY: ValueAxis { id: axisAltiY0; visible: true; gridVisible: true;
                                       labelsFont.pixelSize: 10; labelsColor: Theme.colorText; labelFormat: "%i";
                                       /*gridLineColor: Theme.colorSeparator;*/ }
                }
            }

            ChartView {
                id: acclGraph
                width: 480
                height: 240

                title: "Acceleration"
                titleColor: Theme.colorText
                titleFont.pixelSize: 14
                titleFont.bold: true
                backgroundColor: "transparent"
                antialiasing: true

                ValueAxis { id: axisAcclX0; visible: false; gridVisible: false; }
                ValueAxis { id: axisAcclY0; visible: true; gridVisible: true;
                            labelsFont.pixelSize: 10; labelsColor: Theme.colorText; labelFormat: "%i";
                            /*gridLineColor: Theme.colorSeparator;*/ }

                LineSeries { id: acclX; axisX: axisAcclX0; axisY: axisAcclY0; }
                LineSeries { id: acclY; axisX: axisAcclX0; axisY: axisAcclY0; }
                LineSeries { id: acclZ; axisX: axisAcclX0; axisY: axisAcclY0; }
            }

            ChartView {
                id: gyroGraph
                width: 480
                height: 240

                title: "Gyroscope"
                titleColor: Theme.colorText
                titleFont.pixelSize: 14
                titleFont.bold: true
                backgroundColor: "transparent"
                antialiasing: true

                ValueAxis { id: axisGyroX0; visible: false; gridVisible: false; }
                ValueAxis { id: axisGyroY0; visible: true; gridVisible: true;
                            labelsFont.pixelSize: 10; labelsColor: Theme.colorText; labelFormat: "%i";
                            /*gridLineColor: Theme.colorSeparator;*/ }

                LineSeries { id: gyroX; axisX: axisGyroX0; axisY: axisGyroY0; }
                LineSeries { id: gyroY; axisX: axisGyroX0; axisY: axisGyroY0; }
                LineSeries { id: gyroZ; axisX: axisGyroX0; axisY: axisGyroY0; }
            }
        }
    }
}
