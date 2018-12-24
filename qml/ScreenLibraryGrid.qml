import QtQuick 2.10
import QtQuick.Controls 2.3

import com.offloadbuddy.style 1.0

Rectangle {
    width: 1280
    height: 720

    property var selectedItem : shotsview.currentItem
    property int selectedItemIndex : shotsview.currentIndex
    property string selectedItemName : shotsview.currentItem.shot.name

    property var selectionList : [] // TODO

    function initGridViewSettings() {
        actionMenu.visible = false
    }

    function updateGridViewSettings() {

        if (shotsview.count == 0) {
            selectionList = []
            shotsview.currentIndex = -1
        }

        if (mediaLibrary) {
            if (mediaLibrary.libraryState === 1) { // scanning
                circleEmpty.visible = true
                loadingFader.start()
            } else if (mediaLibrary.libraryState === 0) { // idle
                loadingFader.stop()
                if (shotsview.count > 0) {
                    circleEmpty.visible = false
                }
            }
        }
    }

    // POPUPS //////////////////////////////////////////////////////////////////

    Popup {
        id: popupEncode
        modal: true
        focus: true
        x: (parent.width - panelEncode.width) / 2
        y: (parent.height - panelEncode.height) / 2
        closePolicy: Popup.CloseOnEscape /*| Popup.CloseOnPressOutsideParent*/

        PanelEncode {
            id: panelEncode
        }
    }

    // HEADER //////////////////////////////////////////////////////////////////

    Rectangle {
        id: rectangleHeader
        height: 128
        color: ThemeEngine.colorHeaderBackground
        z: 1
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        MouseArea {
            id: mouseArea
            anchors.fill: parent
        }

        Text {
            id: textHeader
            width: 200
            height: 40
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16

            color: ThemeEngine.colorHeaderTitle
            text: qsTr("MEDIA LIBRARY")
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            font.bold: true
            font.pixelSize: ThemeEngine.fontSizeHeaderTitle
        }

        ComboBox {
            id: comboBox_directories
            y: 16
            width: 300
            height: 40
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            displayText: qsTr("Show ALL media directories")

            model: ListModel {
                id: cbMediaDirectories
                ListElement { text: qsTr("ALL media directories"); }
            }
        }

        ComboBox {
            id: comboBox_orderby
            width: 256
            height: 40
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16
            displayText: qsTr("Order by: Date")

            model: ListModel {
                id: cbShotsOrderby
                ListElement { text: qsTr("Date"); }
                ListElement { text: qsTr("Duration"); }
                ListElement { text: qsTr("Shot type"); }
                //ListElement { text: qsTr("GPS location"); }
                ListElement { text: qsTr("Name"); }
            }

            property bool cbinit: false
            onCurrentIndexChanged: {
                if (cbinit) {
                    if (currentIndex == 0)
                        mediaLibrary.orderByDate()
                    else if (currentIndex == 1)
                        mediaLibrary.orderByDuration()
                    else if (currentIndex == 2)
                        mediaLibrary.orderByShotType()
                    else if (currentIndex == 3)
                        mediaLibrary.orderByName()
                } else
                    cbinit = true;

                displayText = qsTr("Order by:") + " " + cbShotsOrderby.get(currentIndex).text
            }
        }

        ComboBox {
            id: comboBox_filterby
            width: 256
            height: 40
            anchors.top: comboBox_orderby.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16
            displayText: qsTr("Filter by: No filter")

            model: ListModel {
                id: cbMediaFilters
                ListElement { text: qsTr("No filters"); }
                ListElement { text: qsTr("Shot types"); }
                ListElement { text: qsTr("Camera models"); }
            }
            /*
            property bool cbinit: false
            onCurrentIndexChanged: {
                if (cbinit) {
                    if (currentIndex == 0)
                        mediaLibrary.orderByDate()
                    else if (currentIndex == 1)
                        mediaLibrary.orderByDuration()
                    else if (currentIndex == 2)
                        mediaLibrary.orderByShotType()
                    else if (currentIndex == 3)
                        mediaLibrary.orderByName()
                } else
                    cbinit = true;

                displayText = qsTr("Order by:") + " " + cbShotsOrderby.get(currentIndex).text
            }*/
        }

        Slider {
            id: sliderZoom
            width: 200
            height: 40
            anchors.verticalCenter: comboBox_orderby.verticalCenter
            anchors.left: textZoom.right
            anchors.leftMargin: 16
            stepSize: 1
            to: 3
            from: 1
            value: 2

            onValueChanged: {
                if (value == 1.0) {
                    shotsview.cellSize = 200;
                } else  if (value == 2.0) {
                    shotsview.cellSize = 272;
                } else  if (value == 3.0) {
                    shotsview.cellSize = 400;
                }
            }
        }

        Text {
            id: textZoom
            height: 40
            anchors.verticalCenter: comboBox_orderby.verticalCenter
            anchors.left: comboBox_orderby.right
            anchors.leftMargin: 16

            text: qsTr("Zoom:")
            font.pixelSize: ThemeEngine.fontSizeHeaderText
            color: ThemeEngine.colorHeaderText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // CONTENT /////////////////////////////////////////////////////////////////

    Rectangle {
        id: rectangleLibraryGrid
        color: ThemeEngine.colorContentBackground

        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        Rectangle {
            id: circleEmpty
            width: 350
            height: 350
            radius: width*0.5
            color: ThemeEngine.colorHeaderBackground
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                id: imageEmpty
                width: 256
                height: 256
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                source: "qrc:/icons/disk.svg"
            }

            NumberAnimation on opacity {
                id: loadingFader;
                from: 1;
                to: 0;
                duration: 2000;
                loops: Animation.Infinite;
                onStopped: imageEmpty.opacity = 1;
            }
        }

        Component {
            id: highlight
            Rectangle {
                width: shotsview.cellSize;
                height: shotsview.cellSize
                color: "#00000000"
                border.width : 4
                border.color: ThemeEngine.colorApproved
                x: {
                    if (shotsview.currentItem.x) {
                        x = shotsview.currentItem.x
                    } else {
                        x = 0
                    }
                }
                y: {
                    if (shotsview.currentItem.y) {
                        y = shotsview.currentItem.y
                    } else {
                        y = 0
                    }
                }
                z: 6
            }
        }

        ActionMenu {
            id: actionMenu
            z: 7
        }
        Connections {
            target: actionMenu
            onMenuSelected: rectangleLibraryGrid.actionMenuTriggered(index)
            onVisibleChanged: shotsview.interactive = !shotsview.interactive
        }
        function actionMenuTriggered(index) {
            //console.log("actionMenuTriggered(" + index + ") selected shot: '" + selectedItemName + "'")
/*
            if (index === 2)
                myDevice.offloadMergeSelected(selectedItemName)
            if (index === 3) {
                panelEncode.updateEncodePanel(selectedItem.shot)
                popupEncode.open()
            }
            if (index === 16)
                myDevice.deleteSelected(selectedItemName)
*/
            actionMenu.visible = false
        }

        ScrollView {
            id: scrollView
            anchors.fill: parent

            GridView {
                id: shotsview

                //Component.onCompleted: initGridViewStuff()
                onCountChanged: updateGridViewSettings()

                flickableChildren: MouseArea {
                    id: mouseAreaInsideView
                    anchors.fill: parent

                    acceptedButtons: Qt.AllButtons
                    onClicked: {
                        screenLibraryGrid.selectionList = []
                        shotsview.currentIndex = -1
                        actionMenu.visible = false
                    }
                }

                property int cellSize: 272
                property int cellMargin: 16
                //property int cellMargin: (parent.width%cellSize) / Math.floor(parent.width/cellSize);
                cellWidth: cellSize + cellMargin
                cellHeight: cellSize + 16

                anchors.rightMargin: 16
                anchors.leftMargin: 16
                anchors.bottomMargin: 16
                anchors.topMargin: 16
                anchors.fill: parent

                interactive: true
                //snapMode: GridView.SnapToRow
                //clip: true
                //keyNavigationEnabled: true

                model: mediaLibrary.shotFilter
                delegate: ItemShot { width: shotsview.cellSize }

                highlight: highlight
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 0
                focus: true
            }
        }

        MouseArea {
            id: mouseAreaOutsideView
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            propagateComposedEvents: true
        }
    }
}