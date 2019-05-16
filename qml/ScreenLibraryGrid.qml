import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

import com.offloadbuddy.theme 1.0

Item {
    id: mediaGrid
    width: 1280
    height: 720

    property var selectedItem: shotsview.currentItem
    property int selectedItemIndex: shotsview.currentIndex
    property string selectedItemUuid: shotsview.currentItem ? shotsview.currentItem.shot.uuid : ""

    property var selectionMode: false
    property var selectionList: []
    property var selectionCount: 0

    function selectedFile(index) {
        selectionMode = true;
        selectionList.push(index);
        selectionCount++;
    }

    function isFileSelected(index) {
        if (selectionList.indexOf(index) > -1)
            return true
        return false
    }

    function deselectedFile(index) {
        var i = selectionList.indexOf(index);
        if (i > -1) { selectionList.splice(i, 1); selectionCount--; }
        if (selectionList.length === 0) selectionMode = false;
    }

    function listSelectedFile(index) {
        for (var child in selectionList) {
            console.log("listSelectedFile(" + index)
        }
    }

    function exitSelectionMode() {
        for (var child in shotsview.contentItem.children) {
            if (shotsview.contentItem.children[child].shotSelected) {
                shotsview.contentItem.children[child].shotSelected = false;
            }
        }

        selectionMode = false;
        selectionList = [];
        selectionCount = 0;
    }

    function initGridViewSettings() {
        actionMenu.visible = false
    }

    function updateGridViewSettings() {
        if (shotsview.count == 0) {
            shotsview.currentIndex = -1
            mediaGrid.exitSelectionMode()
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
        background: Item {/*
            ShaderEffectSource {
              id: effectSource
              anchors.fill: popupEncode
              sourceItem: mediaGrid
              sourceRect: Qt.rect(0,0,900,900)
            }
            FastBlur{
              id: blur
              anchors.fill: effectSource
              source: effectSource
              radius: 32
            }*/
        }
    }

    // HEADER //////////////////////////////////////////////////////////////////

    Rectangle {
        id: rectangleHeader
        height: 128
        color: Theme.colorHeader
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
            height: 40
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16

            text: qsTr("MEDIA LIBRARY")
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            color: Theme.colorHeaderContent
            font.bold: true
            font.pixelSize: Theme.fontSizeHeaderTitle
        }

        SliderThemed {
            id: sliderZoom
            width: 200
            height: 40
            anchors.verticalCenter: textZoom.verticalCenter
            anchors.left: textZoom.right
            anchors.leftMargin: 4
            stepSize: 1
            from: 1
            value: 2
            to: 4

            onValueChanged: {
                if (value == 1.0) {
                    shotsview.cellSizeTarget = 221;
                    shotsview.computeCellSize();
                } else if (value == 2.0) {
                    shotsview.cellSizeTarget = 279;
                    shotsview.computeCellSize();
                } else if (value == 3.0) {
                    shotsview.cellSizeTarget = 376;
                    shotsview.computeCellSize();
                } else if (value == 4.0) {
                    shotsview.cellSizeTarget = 512;
                    shotsview.computeCellSize();
                }
            }
        }

        Text {
            id: textZoom
            height: 40
            anchors.left: parent.left
            anchors.leftMargin: 16

            text: qsTr("ZOOM")
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            font.pixelSize: Theme.fontSizeHeaderText
            color: Theme.colorHeaderContent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Row {
            id: row
            height: 40
            spacing: 16
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16

            ComboBoxThemed {
                id: comboBox_directories
                width: 300
                height: 40
                anchors.verticalCenter: parent.verticalCenter

                ListModel {
                    id: cbMediaDirectories
                    ListElement { text: qsTr("ALL media directories"); }
                }

                model: cbMediaDirectories
                displayText: qsTr("Show ALL media directories")
                visible: (cbMediaDirectories.count > 2)

                Component.onCompleted: updateDirectories()
                Connections {
                    target: settingsManager
                    onDirectoriesUpdated: updateDirectories()
                }

                function updateDirectories() {
                    cbMediaDirectories.clear()
                    cbMediaDirectories.append( { text: qsTr("ALL media directories") } );

                    for (var child in settingsManager.directoriesList) {
                        if (settingsManager.directoriesList[child].available)
                            cbMediaDirectories.append( { "text": settingsManager.directoriesList[child].directoryPath } )
                    }
                }

                property bool cbinit: false
                onCurrentIndexChanged: {
                    if (cbinit) {
                        exitSelectionMode()

                        if (currentIndex == 0) {
                            mediaLibrary.filterByFolder("")
                            displayText = qsTr("Show") + " " + cbMediaDirectories.get(currentIndex).text
                        } else {
                            mediaLibrary.filterByFolder(cbMediaDirectories.get(currentIndex).text)
                            displayText = cbMediaDirectories.get(currentIndex).text
                        }
                    } else {
                        cbinit = true;
                    }
                }
            }

            ComboBoxThemed {
                id: comboBox_orderby
                width: 200
                height: 40
                anchors.verticalCenter: parent.verticalCenter
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
                        exitSelectionMode()

                        if (currentIndex == 0)
                            mediaLibrary.orderByDate()
                        else if (currentIndex == 1)
                            mediaLibrary.orderByDuration()
                        else if (currentIndex == 2)
                            mediaLibrary.orderByShotType()
                        else if (currentIndex == 3)
                            mediaLibrary.orderByName()
                    } else {
                        cbinit = true;
                    }

                    displayText = qsTr("Order by:") + " " + cbShotsOrderby.get(currentIndex).text
                }
            }

            ComboBoxThemed {
                id: comboBox_filterby
                width: 200
                height: 40
                anchors.verticalCenter: parent.verticalCenter
                displayText: qsTr("No filter")

                model: ListModel {
                    id: cbMediaFilters
                    ListElement { text: qsTr("No filter"); }
                    ListElement { text: qsTr("Videos"); }
                    ListElement { text: qsTr("Photos"); }
                    ListElement { text: qsTr("Timelapses"); }
                }

                property bool cbinit: false
                onCurrentIndexChanged: {
                    if (cbinit) {
                        exitSelectionMode()

                        mediaLibrary.filterByType(cbMediaFilters.get(currentIndex).text)

                        if (currentIndex == 0)
                            displayText = cbMediaFilters.get(currentIndex).text
                        else
                            displayText = qsTr("Filter by:") + " " + cbMediaFilters.get(currentIndex).text
                    } else {
                        cbinit = true;
                    }
                }
            }
        }
    }

    // MENUS ///////////////////////////////////////////////////////////////////

    Column {
        id: menusArea
        z: 1
        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        ItemBannerActions {
            id: menuSelection
            visible: (mediaGrid.selectionCount)
        }
    }

    // CONTENT /////////////////////////////////////////////////////////////////

    Item {
        id: rectangleLibraryGrid

        anchors.top: menusArea.bottom
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
            color: Theme.colorHeader
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                id: imageEmpty
                width: 256
                height: 256
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                source: "qrc:/devices/disk.svg"
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
                border.color: Theme.colorPrimary
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
            //console.log("actionMenuTriggered(" + index + ") selected shot: '" + shotsview.currentItem.shot.name + "'")

            if (index === 0)
                selectedItem.shot.openFolder()
            if (index === 3) {
                panelEncode.updateEncodePanel(selectedItem.shot)
                popupEncode.open()
            }
            if (index === 16)
                mediaLibrary.deleteSelected(selectedItemUuid)

            actionMenu.visible = false
        }

        GridView {
            id: shotsview
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.topMargin: 16

            interactive: true
            //snapMode: GridView.SnapToRow
            //clip: true
            //keyNavigationEnabled: true
            //focus: true

            onCountChanged: updateGridViewSettings()
            Component.onCompleted: {
                currentIndex = -1;
                mediaGrid.exitSelectionMode();
            }

            property real cellFormat: 4/3
            property int cellSizeTarget: 279
            property int cellSize: 279
            property int cellMarginTarget: 12
            property int cellMargin: 12

            //property int cellMargin: (parent.width%cellSize) / Math.floor(parent.width/cellSize);
            cellWidth: cellSize + cellMargin
            cellHeight: Math.round(cellSize / cellFormat) + cellMargin

            onWidthChanged: {/*
                if (shotsview.width < 1280) {
                    if (cellSizeTarget != 279) cellSizeTarget = 279
                } else if (shotsview.width < 1920) {
                    if (cellSizeTarget != 400) cellSizeTarget = 400
                } else {
                    if (cellSizeTarget != 600) cellSizeTarget = 600
                }*/

                computeCellSize()
            }
            function computeCellSize() {
                var availableWidth = shotsview.width - cellMarginTarget
                var cellColumnsTarget = Math.trunc(availableWidth / cellSizeTarget)
                // 1 // Adjust only cellSize
                cellSize = (availableWidth - cellMarginTarget * cellColumnsTarget) / cellColumnsTarget
                // Recompute
                cellWidth = cellSize + cellMargin
                cellHeight = Math.round(cellSize / cellFormat) + cellMarginTarget
            }

            ////////

            model: mediaLibrary.shotFilter
            delegate: ItemShot { width: shotsview.cellSize; cellFormat: shotsview.cellFormat; }

            ScrollBar.vertical: ScrollBar { z: 1 }

            flickableChildren: MouseArea {
                id: mouseAreaInsideView
                anchors.fill: parent

                acceptedButtons: Qt.AllButtons
                onClicked: {
                    //console.log("mouseAreaInsideView clicked")
                    mediaGrid.exitSelectionMode()
                    shotsview.currentIndex = -1
                    actionMenu.visible = false
                }
            }

            highlight: highlight
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 0
        }

        MouseArea {
            id: mouseAreaOutsideView
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            propagateComposedEvents: true
            //onClicked: console.log("mouseAreaOutsideView clicked")
        }
    }
}
