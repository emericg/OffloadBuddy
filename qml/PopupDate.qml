import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0

Popup {
    id: popupDate
    width: 540
    height: 480

    signal confirmed()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: Theme.colorBackground
        radius: 2
    }

    function loadDates() {
        dateFile.text = shot.dateFile
        dateMetadata.text = shot.dateMetadata
        dateGps.text = shot.dateGPS
    }

    Text {
        id: textArea
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.top: parent.top
        anchors.topMargin: 24

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        wrapMode: Text.WordWrap
        font.pixelSize: 22
        color: Theme.colorText
        text: qsTr("Change date and time")
    }

    Row {
        id: row
        height: 40
        spacing: 32
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter

        ButtonImageWireframe {
            id: buttonExit
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Change")
            source: "qrc:/icons_material/baseline-schedule-24px.svg"
            fullColor: true
            primaryColor: Theme.colorPrimary
            onClicked: {
                popupDate.confirmed();
                popupDate.close();
            }
        }

        ButtonWireframe {
            id: buttonCancel
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Cancel")
            primaryColor: Theme.colorPrimary
            onClicked: {
                popupDate.close();
            }
        }
    }

    Column {
        id: columnCurrent
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.top: textArea.bottom
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.leftMargin: 24

        Text {
            id: dateFileL
            height: 32
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0

            text: qsTr("File date")
            font.pixelSize: 15
            verticalAlignment: Text.AlignVCenter
            color: Theme.colorSubText

            Text {
                id: dateFile
                anchors.left: parent.left
                anchors.leftMargin: 140
                anchors.verticalCenter: parent.verticalCenter

                verticalAlignment: Text.AlignVCenter
                text: qsTr("Text")
                font.pixelSize: 15
                color: Theme.colorSubText
            }
        }

        Text {
            id: dateMetadataL
            height: 32
            anchors.right: parent.right
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            anchors.left: parent.left

            visible: dateMetadata.text

            text: qsTr("Metadata date")
            font.pixelSize: 15
            verticalAlignment: Text.AlignVCenter
            color: Theme.colorSubText

            Text {
                id: dateMetadata
                anchors.leftMargin: 140
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Text")
                font.pixelSize: 15
                verticalAlignment: Text.AlignVCenter
                color: Theme.colorSubText
            }
        }

        Text {
            id: dateGpsL
            height: 32
            anchors.right: parent.right
            anchors.left: parent.left

            visible: dateGps.text

            text: qsTr("GPS date")
            font.pixelSize: 15
            verticalAlignment: Text.AlignVCenter
            color: Theme.colorSubText

            Text {
                id: dateGps
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 140
                anchors.left: parent.left

                text: qsTr("Text")
                font.pixelSize: 15
                verticalAlignment: Text.AlignVCenter
                color: Theme.colorSubText
            }
        }
    }

    Row {
        id: rowDate
        spacing: 24
        anchors.top: columnCurrent.bottom
        anchors.topMargin: 24
        anchors.left: parent.left
        anchors.leftMargin: 24
        anchors.right: parent.right
        anchors.rightMargin: 24

        Column {
            id: columnYear
            spacing: 8

            Text {
                id: elementYear
                text: qsTr("Year")
                font.pixelSize: 16
                color: Theme.colorText
            }

            SpinBox {
                id: spinBoxYear
                from: 2000
                to: 2200
                value: 2019
            }
        }

        Column {
            id: columnMonth
            spacing: 8

            Text {
                id: elementMonth
                text: qsTr("Month")
                font.pixelSize: 16
                color: Theme.colorText
            }

            SpinBox {
                id: spinBoxMonth
                value: 1
                from: 1
                to: 12
            }
        }

        Column {
            id: columnDay
            spacing: 8

            Text {
                id: elementDay
                text: qsTr("Day")
                font.pixelSize: 16
                color: Theme.colorText
            }

            SpinBox {
                id: spinBoxDay
                value: 3
                from: 1
                to: 31
            }
        }
    }

    Row {
        id: rowTime
        spacing: 24
        anchors.top: rowDate.bottom
        anchors.topMargin: 24
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.left: parent.left
        anchors.leftMargin: 24

        Column {
            id: columnHours
            spacing: 8

            Text {
                id: elementHours
                text: qsTr("Hours")
                font.pixelSize: 16
                color: Theme.colorText
            }

            SpinBox {
                id: spinBoxHours
                value: 0
                from: 0
                to: 23
            }
        }

        Column {
            id: columnMinutes
            spacing: 8

            Text {
                id: elementMinutes
                text: qsTr("Minutes")
                font.pixelSize: 16
                color: Theme.colorText
            }

            SpinBox {
                id: spinBoxMinutes
                value: 0
                from: 0
                to: 59
            }
        }
    }
}
