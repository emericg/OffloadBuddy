import QtQuick 2.12
import QtQuick.Controls 2.12

import QtLocation 5.9
import QtPositioning 5.9

import ThemeEngine 1.0
import com.offloadbuddy.shared 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: contentMap
    anchors.fill: parent

    function updateMap() {
        if (shot.latitude !== 0.0) {
            mapPointGPS.center = QtPositioning.coordinate(shot.latitude, shot.longitude)
            mapPointGPS.zoomLevel = 12
            mapMarker.visible = true
            mapMarker.coordinate = QtPositioning.coordinate(shot.latitude, shot.longitude)
            button_map_dezoom.enabled = true
            button_map_zoom.enabled = true
            button_gps_export.visible = false
            button_gps_export.enabled = false

            rectangleCoordinates.visible = true
            coordinates.text = shot.latitudeString + "    " + shot.longitudeString
            altitude.text = UtilsString.altitudeToString(shot.altitude, 0, settingsManager.appUnits)
        }
    }

    Map {
        id: mapPointGPS
        anchors.topMargin: 48
        anchors.fill: parent
        anchors.margins: 16
        z: parent.z + 1

        copyrightsVisible: false
        gesture.enabled: false
        plugin: Plugin { name: "mapboxgl" } // "osm", "mapboxgl", "esri"

        //zoomLevel: 2
        //center: QtPositioning.coordinate(45.5, 6)

        MapQuickItem {
            id: mapMarker
            visible: false
            anchorPoint.x: mapMarkerImg.width/2
            anchorPoint.y: mapMarkerImg.height/2
            sourceItem: Image {
                id: mapMarkerImg
                source: "qrc:/assets/others/gps_marker.svg"
            }
        }

        MouseArea {
            anchors.fill: parent
            onWheel: {
                if (wheel.angleDelta.y < 0)
                    parent.zoomLevel--
                else
                    parent.zoomLevel++
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
                background: true

                source: "qrc:/assets/icons_material/baseline-zoom_out-24px.svg"
                onClicked: parent.parent.zoomLevel--
            }

            ItemImageButton {
                id: button_map_zoom
                width: 40
                height: 40
                background: true

                source: "qrc:/assets/icons_material/baseline-zoom_in-24px.svg"
                onClicked: parent.parent.zoomLevel++
            }
        }
    }

    Rectangle {
        id: rectangleCoordinates
        height: 32
        color: Theme.colorForeground
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
