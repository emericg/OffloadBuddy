import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Popup {
    id: popupDate
    x: (appWindow.width / 2) - (width / 2) - (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 640
    padding: 0

    signal confirmed()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    ////////////////////////////////////////////////////////////////////////////

    property var qdateFirst: new Date(2001, 1, 1, 0, 0, 0)
    property var qdateToday: new Date();

    property var qdateFile
    property var qdateMetadata
    property var qdateGps

    property var qdate
    onQdateChanged: qqdateChanged()

    function qqdateChanged() {
        dateFileSelector.color = (Qt.formatDateTime(qdate) == Qt.formatDateTime(qdateFile)) ? Theme.colorPrimary : Theme.colorIcon
        dateMetadataSelector.color = (Qt.formatDateTime(qdate) == Qt.formatDateTime(qdateMetadata)) ? Theme.colorPrimary : Theme.colorIcon
        dateGpsSelector.color = (Qt.formatDateTime(qdate) == Qt.formatDateTime(qdateGps)) ? Theme.colorPrimary : Theme.colorIcon
    }

    function loadDates() {
        qdateToday = new Date();
        qdateFile = shot.dateFile
        qdateMetadata = shot.dateMetadata
        qdateGps = shot.dateGPS

        dateFile.text = Qt.formatDateTime(shot.dateFile, Qt.SystemLocaleDate)
        dateMetadata.text = Qt.formatDateTime(shot.dateMetadata, Qt.SystemLocaleDate)
        dateGps.text = Qt.formatDateTime(shot.dateGPS, Qt.SystemLocaleDate)

        loadDate(shot.date)
    }

    function loadDate(dateToLoad) {
        qdate = dateToLoad
        // date
        spinBoxYear.value = Qt.formatDateTime(dateToLoad, "yyyy");
        spinBoxMonth.value = Qt.formatDateTime(dateToLoad, "MM");
        spinBoxDay.value = Qt.formatDateTime(dateToLoad, "dd");
        // time
        spinBoxHours.value = Qt.formatDateTime(dateToLoad, "hh")
        spinBoxMinutes.value = Qt.formatDateTime(dateToLoad, "mm")
    }

    ////////////////////////////////////////////////////////////////////////////

    background: Rectangle {
        color: Theme.colorBackground
        radius: Theme.componentRadius
    }

    contentItem: Column {
        spacing: 16

        Rectangle {
            id: titleArea
            height: 64
            anchors.left: parent.left
            anchors.right: parent.right
            radius: Theme.componentRadius
            color: ThemeEngine.colorPrimary

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Change date and time")
                font.pixelSize: Theme.fontSizeTitle
                font.bold: true
                color: "white"
            }
        }

        ////////////////

        Column {
            id: columnCurrent
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24

            Text {
                id: dateFileL
                height: 32
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                text: qsTr("File date")
                font.pixelSize: 16
                verticalAlignment: Text.AlignVCenter
                color: Theme.colorSubText

                Text {
                    id: dateFile
                    anchors.left: parent.left
                    anchors.leftMargin: 140
                    anchors.verticalCenter: parent.verticalCenter

                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 16
                    color: Theme.colorText
                }

                ImageSvg {
                    id: dateFileValidator
                    width: 24
                    height: 24
                    anchors.right: parent.right
                    anchors.rightMargin: 40
                    anchors.verticalCenter: parent.verticalCenter

                    visible: (qdateFile < qdateFirst || qdateFile > qdateToday)
                    source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
                    color: Theme.colorWarning
                    fillMode: Image.PreserveAspectFit
                }
                ImageSvg {
                    id: dateFileSelector
                    width: 24
                    height: 24
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    fillMode: Image.PreserveAspectFit
                    source: "qrc:/assets/icons_material/baseline-done-24px.svg"

                    MouseArea {
                        anchors.fill: parent
                        enabled: (qdateFile > qdateFirst && qdateFile < qdateToday)
                        hoverEnabled: enabled

                        onEntered: parent.color = Theme.colorPrimary
                        onExited: parent.color = (qdate === qdateFile) ? Theme.colorPrimary : Theme.colorIcon
                        onClicked: loadDate(qdateFile)
                    }
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
                font.pixelSize: 16
                verticalAlignment: Text.AlignVCenter
                color: Theme.colorSubText

                Text {
                    id: dateMetadata
                    anchors.leftMargin: 140
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    color: Theme.colorText
                }

                ImageSvg {
                    id: dateMetadataValidator
                    width: 24
                    height: 24
                    anchors.right: parent.right
                    anchors.rightMargin: 40
                    anchors.verticalCenter: parent.verticalCenter

                    visible: (qdateMetadata < qdateFirst || qdateMetadata > qdateToday)
                    source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
                    color: Theme.colorWarning
                    fillMode: Image.PreserveAspectFit
                }
                ImageSvg {
                    id: dateMetadataSelector
                    width: 24
                    height: 24
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    fillMode: Image.PreserveAspectFit
                    source: "qrc:/assets/icons_material/baseline-done-24px.svg"

                    MouseArea {
                        anchors.fill: parent
                        enabled: (qdateMetadata > qdateFirst && qdateMetadata < qdateToday)
                        hoverEnabled: enabled

                        onEntered: parent.color = Theme.colorPrimary
                        onExited: parent.color = (qdate === qdateMetadata) ? Theme.colorPrimary : Theme.colorIcon
                        onClicked: loadDate(qdateMetadata)
                    }
                }
            }

            Text {
                id: dateGpsL
                height: 32
                anchors.right: parent.right
                anchors.left: parent.left

                visible: dateGps.text

                text: qsTr("GPS date")
                font.pixelSize: 16
                verticalAlignment: Text.AlignVCenter
                color: Theme.colorSubText

                Text {
                    id: dateGps
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 140
                    anchors.left: parent.left

                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    color: Theme.colorText
                }

                ImageSvg {
                    id: dateGpsValidator
                    width: 24
                    height: 24
                    anchors.right: parent.right
                    anchors.rightMargin: 40
                    anchors.verticalCenter: parent.verticalCenter

                    visible: (qdateGps < qdateFirst || qdateGps > qdateToday)
                    source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
                    color: Theme.colorWarning
                    fillMode: Image.PreserveAspectFit
                }
                ImageSvg {
                    id: dateGpsSelector
                    width: 24
                    height: 24
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    fillMode: Image.PreserveAspectFit
                    source: "qrc:/assets/icons_material/baseline-done-24px.svg"

                    MouseArea {
                        anchors.fill: parent
                        enabled: (qdateGps > qdateFirst && qdateGps < qdateToday)
                        hoverEnabled: enabled

                        onEntered: parent.color = Theme.colorPrimary
                        onExited: parent.color = (qdate === qdateGps) ? Theme.colorPrimary : Theme.colorIcon
                        onClicked: loadDate(qdateGps)
                    }
                }
            }
        }

        ////////////////

        Row {
            id: rowDate
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24
            spacing: 24

            Column {
                id: columnYear
                spacing: 8

                Text {
                    id: elementYear
                    text: qsTr("Year")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                SpinBoxThemed {
                    id: spinBoxYear

                    locale: Qt.locale('C')
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
                    color: Theme.colorSubText
                }

                SpinBoxThemed {
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
                    color: Theme.colorSubText
                }

                SpinBoxThemed {
                    id: spinBoxDay
                    value: 3
                    from: 1
                    to: 31
                }
            }
        }

        Row {
            id: rowTime
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24
            spacing: 24

            Column {
                id: columnHours
                spacing: 8

                Text {
                    id: elementHours
                    text: qsTr("Hours")
                    font.pixelSize: 16
                    color: Theme.colorSubText
                }

                SpinBoxThemed {
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
                    color: Theme.colorSubText
                }

                SpinBoxThemed {
                    id: spinBoxMinutes
                    value: 0
                    from: 0
                    to: 59
                }
            }
        }

        ////////////////

        Row {
            id: rowButtons
            height: Theme.componentHeight*2 + parent.spacing
            anchors.right: parent.right
            anchors.rightMargin: 24
            spacing: 24

            ButtonWireframe {
                id: buttonCancel
                width: 96
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Cancel")
                fullColor: true
                primaryColor: Theme.colorMaterialDarkGrey
                onClicked: popupDate.close()
            }
            ButtonWireframeImage {
                id: buttonExit
                width: 128
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Change")
                source: "qrc:/assets/icons_material/baseline-schedule-24px.svg"
                fullColor: true
                primaryColor: Theme.colorPrimary
                onClicked: {
                    popupDate.confirmed()
                    popupDate.close()
                }
            }
        }
    }
}
