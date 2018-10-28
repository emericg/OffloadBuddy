import QtQuick 2.10
import QtQuick.Controls 2.3

import QtLocation 5.10
import QtPositioning 5.10
import QtMultimedia 5.10

import com.offloadbuddy.style 1.0
import com.offloadbuddy.shared 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: contentMap
    anchors.fill: parent
    color: "#00000000"

    function updateMap() {
        if (shot.latitude !== 0.0) {
            mapGPS.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
            mapGPS.zoomLevel = 12
            mapGPS.anchors.topMargin = 48
            mapMarker.visible = true
            mapMarker.coordinate = QtPositioning.coordinate(shot.latitude, shot.longitude)
            button_map_dezoom.enabled = true
            button_map_zoom.enabled = true
            button_gps_export.visible = false
            button_gps_export.enabled = false

            rectangleCoordinates.visible = true
            coordinates.text = shot.latitudeString + "    " + shot.longitudeString
            altitude.text = shot.altitudeString
        } else {
            mapGPS.center = QtPositioning.coordinate(45.5, 6)
            mapGPS.zoomLevel = 2
            mapGPS.anchors.topMargin = 16
            mapMarker.visible = false
            rectangleCoordinates.visible = false
            button_map_dezoom.enabled = false
            button_map_zoom.enabled = false
            button_gps_export.visible = false
        }
    }

    Map {
        id: mapGPS
        copyrightsVisible: false
        anchors.topMargin: 48
        anchors.fill: parent
        anchors.margins: 16

        gesture.enabled: false
        z: parent.z + 1
        plugin: Plugin { name: "mapboxgl" } // "osm", "mapboxgl", "esri"
        center: QtPositioning.coordinate(45.5, 6)
        zoomLevel: 2

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

            Button {
                id: button_map_dezoom
                width: 40
                height: 40
                text: "-"
                font.bold: true
                font.pointSize: 16
                opacity: 1

                onClicked: parent.parent.zoomLevel--
            }

            Button {
                id: button_map_zoom
                width: 40
                height: 40
                text: "+"
                font.bold: true
                font.pointSize: 14
                opacity: 1

                onClicked: parent.parent.zoomLevel++
            }
        }
        /*
                MapPolyline {
                    id: mapTrace
                    visible: false
                    line.width: 3
                    line.color: 'green'

                    path: [
                        { latitude: -27, longitude: 153.0 },
                        { latitude: -27, longitude: 154.1 },
                        { latitude: -28, longitude: 153.5 },
                        { latitude: -29, longitude: 153.5 }
                    ]
*/
    }

    Rectangle {
        id: rectangleCoordinates
        height: 32
        color: ThemeEngine.colorContentSubBox
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.top: parent.top
        anchors.topMargin: 8

        Text {
            id: labelCoodrinates
            text: qsTr("GPS coordinates:")
            verticalAlignment: Text.AlignVCenter
            font.bold: true
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 16
        }

        Text {
            id: labelAltitude
            text: qsTr("Altitude:")
            anchors.verticalCenterOffset: 0
            anchors.left: coordinates.right
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 16
            anchors.leftMargin: 64
            verticalAlignment: Text.AlignVCenter
            font.bold: true
        }

        Text {
            id: coordinates
            text: qsTr("Text")
            anchors.left: labelCoodrinates.right
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
        }

        Text {
            id: altitude
            text: qsTr("Text")
            anchors.left: labelAltitude.right
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 16
        }

        Button {
            id: button_gps_export
            text: qsTr("Export GPS trace")
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
