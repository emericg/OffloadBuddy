import QtQuick 2.9
import QtQuick.Controls 2.2

import QtLocation 5.9
import QtPositioning 5.9
import QtMultimedia 5.9

import com.offloadbuddy.theme 1.0
import com.offloadbuddy.shared 1.0
import "UtilsString.js" as UtilsString

Rectangle {
    id: contentMap
    anchors.fill: parent
    color: "#00000000"

    function updateMap() {
        if (shot.latitude !== 0.0) {
            mapPointGPS.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
            mapPointGPS.zoomLevel = 12
            mapPointGPS.anchors.topMargin = 48
            mapMarker.visible = true
            mapMarker.coordinate = QtPositioning.coordinate(shot.latitude, shot.longitude)
            button_map_dezoom.enabled = true
            button_map_zoom.enabled = true
            button_gps_export.visible = false
            button_gps_export.enabled = false

            rectangleCoordinates.visible = true
            coordinates.text = shot.latitudeString + "    " + shot.longitudeString
            altitude.text = UtilsString.altitudeToString(shot.altitude, 0, settingsManager.appunits)
        } else {
            mapPointGPS.center = QtPositioning.coordinate(45.5, 6)
            mapPointGPS.zoomLevel = 2
            mapPointGPS.anchors.topMargin = 16
            mapMarker.visible = false
            rectangleCoordinates.visible = false
            button_map_dezoom.enabled = false
            button_map_zoom.enabled = false
            button_gps_export.visible = false
        }
    }

    Map {
        id: mapPointGPS
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
                source: "qrc:/others/gps_marker.svg"
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
    }

    Rectangle {
        id: rectangleCoordinates
        height: 32
        color: Theme.colorContentSubBox
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.top: parent.top
        anchors.topMargin: 16

        Text {
            id: labelCoordinates
            height: parent.height
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("GPS coordinates:")
            font.pixelSize: 16
            font.bold: true
            color: Theme.colorText
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: labelAltitude
            height: parent.height
            anchors.verticalCenterOffset: 0
            anchors.left: coordinates.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 64

            text: qsTr("Altitude:")
            font.pixelSize: 16
            font.bold: true
            color: Theme.colorText
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: coordinates
            height: parent.height
            anchors.left: labelCoordinates.right
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            text: "text"
            font.pixelSize: 16
            color: Theme.colorText
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: altitude
            height: parent.height
            anchors.left: labelAltitude.right
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            text: "text"
            font.pixelSize: 16
            color: Theme.colorText
            verticalAlignment: Text.AlignVCenter
        }

        ButtonThemed {
            id: button_gps_export
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Export GPS trace")
        }
    }
}
