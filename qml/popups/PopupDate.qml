import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import ThemeEngine

import "qrc:/js/UtilsNumber.js" as UtilsNumber

Popup {
    id: popupDate

    x: (appWindow.width / 2) - (width / 2) - (appSidebar.width / 2)
    y: (appWindow.height / 2) - (height / 2)
    width: 720
    padding: 0

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    signal confirmed()

    ////////

    property var qdateFirst: new Date(2001, 1, 1, 0, 0, 0)
    property var qdateToday: new Date()

    property var qdateFile
    property var qdateMetadata
    property var qdateGps
    property var qdateUser

    property var qdate

    function loadDates() {
        qdateToday = new Date();
        qdateFile = shot.dateFile
        qdateMetadata = shot.dateMetadata
        qdateGps = shot.dateGPS
        qdateUser = shot.dateUser

        dateFile.text = Qt.formatDateTime(shot.dateFile, Qt.SystemLocaleDate)
        dateMetadata.text = Qt.formatDateTime(shot.dateMetadata, Qt.SystemLocaleDate)
        dateGps.text = Qt.formatDateTime(shot.dateGPS, Qt.SystemLocaleDate)
        dateUser.text = Qt.formatDateTime(shot.dateUser, Qt.SystemLocaleDate)

        loadDate(shot.date, false)
    }

    function loadDate(dateToLoad, clicked) {
        qdate = dateToLoad
        if (clicked) {
            shot.dateUser = dateToLoad
            qdateUser = shot.dateUser
        }
        // date
        spinBoxYear.value = Qt.formatDateTime(dateToLoad, "yyyy");
        spinBoxMonth.value = Qt.formatDateTime(dateToLoad, "MM");
        spinBoxDay.value = Qt.formatDateTime(dateToLoad, "dd");
        // time
        spinBoxHours.value = Qt.formatDateTime(dateToLoad, "hh")
        spinBoxMinutes.value = Qt.formatDateTime(dateToLoad, "mm")
    }

    ////////////////////////////////////////////////////////////////////////////

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.5; to: 1.0; duration: 133; } }

    background: Item {
        Rectangle {
            id: bgrect
            anchors.fill: parent

            radius: Theme.componentRadius
            color: Theme.colorBackground
            border.color: Theme.colorSeparator
            border.width: Theme.componentBorderWidth
        }
        DropShadow {
            anchors.fill: parent
            source: bgrect
            color: "#60000000"
            radius: 24
            samples: radius*2+1
            cached: true
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    contentItem: Column {
        spacing: 16

        Rectangle { // titleArea
            anchors.left: parent.left
            anchors.right: parent.right

            height: 64
            color: Theme.colorPrimary
            radius: Theme.componentRadius

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 1
                anchors.right: parent.right
                anchors.rightMargin: 1
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
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24

            Text {
                height: 32
                anchors.left: parent.left
                anchors.right: parent.right

                text: qsTr("File date")
                color: Theme.colorSubText
                font.pixelSize: Theme.fontSizeContent
                verticalAlignment: Text.AlignVCenter

                Text {
                    id: dateFile
                    anchors.left: parent.left
                    anchors.leftMargin: 140
                    anchors.verticalCenter: parent.verticalCenter

                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                    verticalAlignment: Text.AlignVCenter
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    Item {
                        width: 36
                        height: 36

                        IconSvg {
                            id: dateFileValidator
                            width: 24
                            height: 24
                            anchors.centerIn: parent

                            visible: (qdateFile < qdateFirst || qdateFile > qdateToday)
                            source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
                            color: Theme.colorWarning
                            fillMode: Image.PreserveAspectFit
                        }
                        RoundButtonIcon {
                            id: dateFileSelector
                            width: 36
                            height: 36
                            anchors.verticalCenter: parent.verticalCenter

                            highlightMode: "color"
                            source: "qrc:/assets/icons_material/baseline-done-24px.svg"

                            visible: (qdateFile > qdateFirst && qdateFile < qdateToday)
                            enabled: visible
                            highlighted: (qdate && Qt.formatDateTime(qdate) === Qt.formatDateTime(qdateFile))
                            backgroundVisible: highlighted
                            onClicked: loadDate(qdateFile, true)
                        }
                    }
                }
            }

            Text {
                height: 32
                anchors.left: parent.left
                anchors.right: parent.right

                visible: dateMetadata.text

                text: qsTr("Metadata date")
                color: Theme.colorSubText
                font.pixelSize: Theme.fontSizeContent
                verticalAlignment: Text.AlignVCenter

                Text {
                    id: dateMetadata
                    anchors.left: parent.left
                    anchors.leftMargin: 140
                    anchors.verticalCenter: parent.verticalCenter

                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                    verticalAlignment: Text.AlignVCenter
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    Item {
                        width: 36
                        height: 36
                        IconSvg {
                            id: dateMetadataValidator
                            width: 24
                            height: 24
                            anchors.centerIn: parent

                            visible: (qdateMetadata < qdateFirst || qdateMetadata > qdateToday)
                            source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
                            color: Theme.colorWarning
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                    RoundButtonIcon {
                        id: dateMetadataSelector
                        width: 36
                        height: 36
                        anchors.verticalCenter: parent.verticalCenter

                        highlightMode: "color"
                        source: "qrc:/assets/icons_material/baseline-done-24px.svg"

                        visible: (qdateMetadata > qdateFirst && qdateMetadata < qdateToday)
                        enabled: visible
                        highlighted: (qdate && Qt.formatDateTime(qdate) === Qt.formatDateTime(qdateMetadata))
                        backgroundVisible: highlighted
                        onClicked: loadDate(qdateMetadata, true)
                    }
                }
            }

            Text {
                height: 32
                anchors.left: parent.left
                anchors.right: parent.right

                visible: dateGps.text

                text: qsTr("GPS date")
                color: Theme.colorSubText
                font.pixelSize: Theme.fontSizeContent
                verticalAlignment: Text.AlignVCenter

                Text {
                    id: dateGps
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 140
                    anchors.left: parent.left

                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                    verticalAlignment: Text.AlignVCenter
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    Item {
                        width: 36
                        height: 36
                        IconSvg {
                            id: dateGpsValidator
                            width: 24
                            height: 24
                            anchors.centerIn: parent

                            visible: (qdateGps < qdateFirst || qdateGps > qdateToday)
                            source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
                            color: Theme.colorWarning
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                    RoundButtonIcon {
                        id: dateGpsSelector
                        width: 36
                        height: 36
                        anchors.verticalCenter: parent.verticalCenter

                        highlightMode: "color"
                        source: "qrc:/assets/icons_material/baseline-done-24px.svg"

                        visible: (qdateGps > qdateFirst && qdateGps < qdateToday)
                        enabled: visible
                        highlighted: (qdate && Qt.formatDateTime(qdate) === Qt.formatDateTime(qdateGps))
                        backgroundVisible: highlighted
                        onClicked: loadDate(qdateGps, true)
                    }
                }
            }

            Text {
                height: 32
                anchors.left: parent.left
                anchors.right: parent.right

                visible: dateUser.text

                text: qsTr("User date")
                color: Theme.colorSubText
                font.pixelSize: Theme.fontSizeContent
                verticalAlignment: Text.AlignVCenter

                Text {
                    id: dateUser
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 140
                    anchors.left: parent.left

                    color: Theme.colorText
                    font.pixelSize: Theme.fontSizeContent
                    verticalAlignment: Text.AlignVCenter
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    Item {
                        width: 36
                        height: 36
                        IconSvg {
                            id: dateUserValidator
                            width: 24
                            height: 24
                            anchors.centerIn: parent

                            visible: (qdateUser < qdateFirst || qdateUser > qdateToday)
                            source: "qrc:/assets/icons_material/baseline-warning-24px.svg"
                            color: Theme.colorWarning
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                    RoundButtonIcon {
                        id: dateUserSelector
                        width: 36
                        height: 36
                        anchors.verticalCenter: parent.verticalCenter

                        highlightMode: "color"
                        source: "qrc:/assets/icons_material/baseline-done-24px.svg"

                        visible: (qdateUser > qdateFirst && qdateUser < qdateToday)
                        enabled: visible
                        highlighted: (qdate &&
                                   (Qt.formatDateTime(qdate) === Qt.formatDateTime(qdateUser) &&
                                    Qt.formatDateTime(qdate) !== Qt.formatDateTime(qdateFile) &&
                                    Qt.formatDateTime(qdate) !== Qt.formatDateTime(qdateMetadata) &&
                                    Qt.formatDateTime(qdate) !== Qt.formatDateTime(qdateGps)))
                        backgroundVisible: highlighted
                        onClicked: loadDate(qdateUser, true)
                    }
                }
            }
        }

        ////////////////

        Rectangle { // separator
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: Theme.colorSeparator
        }

        ////////////////

        Row {
            id: rowDate
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24
            spacing: 24

            function setUserDate() {
                var ds = spinBoxYear.value + "-" +
                         UtilsNumber.padNumber(spinBoxMonth.value) + "-" +
                         UtilsNumber.padNumber(spinBoxDay.value) + " " +
                         UtilsNumber.padNumber(spinBoxHours.value) + ":" +
                         UtilsNumber.padNumber(spinBoxMinutes.value)

                qdate = Date.fromLocaleString(Qt.locale(), ds, "yyyy-MM-dd hh:mm")
                qdateUser = Date.fromLocaleString(Qt.locale(), ds, "yyyy-MM-dd hh:mm")

                shot.dateUser = Date.fromLocaleString(Qt.locale(), ds, "yyyy-MM-dd hh:mm")
                dateUser.text = Qt.formatDateTime(shot.dateUser, Qt.SystemLocaleDate)
            }

            Column {
                id: columnYear
                spacing: 8

                Text {
                    id: elementYear
                    text: qsTr("Year")
                    font.pixelSize: Theme.fontSizeContent
                    color: Theme.colorSubText
                }

                SpinBoxThemedDesktop {
                    id: spinBoxYear

                    locale: Qt.locale('C')
                    from: 2000
                    to: 2100

                    value: 2022
                    onValueModified: rowDate.setUserDate()
                }
            }

            Column {
                id: columnMonth
                spacing: 8

                Text {
                    id: elementMonth
                    text: qsTr("Month")
                    font.pixelSize: Theme.fontSizeContent
                    color: Theme.colorSubText
                }

                SpinBoxThemedDesktop {
                    id: spinBoxMonth

                    from: 1
                    to: 12

                    value: 1
                    onValueModified: rowDate.setUserDate()
                }
            }

            Column {
                id: columnDay
                spacing: 8

                Text {
                    id: elementDay
                    text: qsTr("Day")
                    font.pixelSize: Theme.fontSizeContent
                    color: Theme.colorSubText
                }

                SpinBoxThemedDesktop {
                    id: spinBoxDay

                    from: 1
                    to: 31

                    value: 3
                    onValueModified: rowDate.setUserDate()
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
                    font.pixelSize: Theme.fontSizeContent
                    color: Theme.colorSubText
                }

                SpinBoxThemedDesktop {
                    id: spinBoxHours

                    from: 0
                    to: 23

                    value: 0
                    onValueModified: rowDate.setUserDate()
                }
            }

            Column {
                id: columnMinutes
                spacing: 8

                Text {
                    id: elementMinutes
                    text: qsTr("Minutes")
                    font.pixelSize: Theme.fontSizeContent
                    color: Theme.colorSubText
                }

                SpinBoxThemedDesktop {
                    id: spinBoxMinutes
                    from: 0
                    to: 59

                    value: 0
                    onValueModified: rowDate.setUserDate()
                }
            }
        }

        ////////////////

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 24
            spacing: 16

            ButtonSolid {
                text: qsTr("Cancel")
                color: Theme.colorGrey
                onClicked: popupDate.close()
            }
            ButtonSolid {
                text: qsTr("Change")
                source: "qrc:/assets/icons_material/duotone-schedule-24px.svg"
                color: Theme.colorPrimary
                onClicked: {
                    //popupDate.confirmed()
                    //popupDate.close()
                }
            }
        }
    }
}
