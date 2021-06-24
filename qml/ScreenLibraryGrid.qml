import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import com.offloadbuddy.shared 1.0
import "qrc:/js/UtilsString.js" as UtilsString

Item {
    id: mediaGrid
    width: 1280
    height: 720

    property var selectedItem: shotsView.currentItem
    property int selectedItemIndex: shotsView.currentIndex
    property string selectedItemUuid: shotsView.currentItem ? shotsView.currentItem.shot.uuid : ""

    ////////

    property bool selectionMode: false
    property var selectionList: []
    property int selectionCount: 0

    function selectFile(index) {
        // make sure it's not already selected
        if (mediaLibrary.getShotByProxyIndex(index).selected) return;

        // then add
        selectionMode = true;
        selectionList.push(index);
        selectionCount++;

        mediaLibrary.getShotByProxyIndex(index).selected = true;
    }
    function deselectFile(index) {
        var i = selectionList.indexOf(index);
        if (i > -1) { selectionList.splice(i, 1); selectionCount--; }
        if (selectionList.length <= 0 || selectionCount <= 0) { exitSelectionMode() }

        mediaLibrary.getShotByProxyIndex(index).selected = false;
    }

    function selectAll() {
        exitSelectionMode()

        selectionMode = true;
        for (var i = 0; i < shotsView.count; i++) {
            selectionList.push(i);
            selectionCount++;

            mediaLibrary.getShotByProxyIndex(i).selected = true;
        }
    }

    function exitSelectionMode() {
        selectionMode = false;
        selectionList = [];
        selectionCount = 0;

        for (var i = 0; i < shotsView.count; i++) {
            mediaLibrary.getShotByProxyIndex(i).selected = false;
        }
    }

    ////////

    function initGridViewSettings() {
        actionMenu.visible = false
        shotsView.currentIndex = -1
        mediaGrid.exitSelectionMode()
    }

    function updateGridViewSettings() {
        actionMenu.visible = false
        shotsView.currentIndex = -1
        mediaGrid.exitSelectionMode()
    }

    // POPUPS //////////////////////////////////////////////////////////////////

    PopupMove {
        id: popupMove

        onConfirmed: {
            //
        }
    }

    PopupTelemetry {
        id: popupTelemetry

        onConfirmed: {
            //
        }
    }

    PopupEncoding {
        id: popupEncoding

        onConfirmed: {
            //
        }
    }

    PopupDelete {
        id: popupDelete

        onConfirmed: {
            //
        }
    }

    // HEADER //////////////////////////////////////////////////////////////////

    Rectangle {
        id: rectangleHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        z: 1
        height: 128
        color: Theme.colorHeader

        DragHandler {
            // Drag on the sidebar to drag the whole window // Qt 5.15+
            // Also, prevent clicks below this area
            acceptedButtons: Qt.AllButtons
            onActiveChanged: if (active) appWindow.startSystemMove()
            target: null
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
            font.pixelSize: Theme.fontSizeHeader
        }

        Text {
            id: textFilesCount
            height: 24
            anchors.top: textHeader.bottom
            anchors.topMargin: 4
            anchors.right: parent.right
            anchors.rightMargin: 16

            text: qsTr("%1 shots  /  %2 files").arg(mediaLibrary.shotModel.shotCount).arg(mediaLibrary.shotModel.fileCount)
            verticalAlignment: Text.AlignVCenter
            color: Theme.colorHeaderContent
            font.pixelSize: Theme.fontSizeContentBig
        }

        Text {
            id: textFilesSize
            height: 24
            anchors.top: textFilesCount.bottom
            anchors.topMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 16

            text: qsTr("%1 of space used").arg(UtilsString.bytesToString_short(mediaLibrary.shotModel.diskSpace))
            verticalAlignment: Text.AlignVCenter
            color: Theme.colorHeaderContent
            font.pixelSize: Theme.fontSizeContentBig
        }

        ComboBoxThemed {
            id: comboBox_directories
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16

            ListModel {
                id: cbMediaDirectories
                ListElement { text: qsTr("ALL media directories"); }
            }

            model: cbMediaDirectories
            displayText: qsTr("Show ALL media directories")
            visible: (cbMediaDirectories.count > 2)

            Component.onCompleted: comboBox_directories.updateDirectories()
            Connections {
                target: storageManager
                onDirectoriesUpdated: comboBox_directories.updateDirectories()
            }

            function updateDirectories() {
                cbMediaDirectories.clear()
                cbMediaDirectories.append( { text: qsTr("ALL media directories") } );

                for (var child in storageManager.directoriesList) {
                    if (storageManager.directoriesList[child].available)
                        cbMediaDirectories.append( { "text": storageManager.directoriesList[child].directoryPath } )
                }
            }

            property bool cbinit: false
            width: 240 + 16 + 240
            onCurrentIndexChanged: {
                if (cbinit) {
                    mediaGrid.exitSelectionMode()
                    shotsView.currentIndex = -1
                    actionMenu.visible = false

                    if (currentIndex < 0) {
                        //
                    } else if (currentIndex === 0) {
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

        Row {
            id: rowFilter
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16
            spacing: 16

            ComboBoxThemed {
                id: comboBox_orderby
                width: 240
                displayText: qsTr("Order by: Date")

                model: ListModel {
                    id: cbShotsOrderby
                    ListElement { text: qsTr("Date"); }
                    ListElement { text: qsTr("Duration"); }
                    ListElement { text: qsTr("Shot type"); }
                    //ListElement { text: qsTr("GPS location"); }
                    ListElement { text: qsTr("Name"); }
                    ListElement { text: qsTr("Folder"); }
                }

                property bool cbinit: false
                onCurrentIndexChanged: {
                    if (cbinit) {
                        mediaGrid.exitSelectionMode()
                        shotsView.currentIndex = -1
                        actionMenu.visible = false

                        if (currentIndex == 0)
                            mediaLibrary.orderByDate()
                        else if (currentIndex == 1)
                            mediaLibrary.orderByDuration()
                        else if (currentIndex == 2)
                            mediaLibrary.orderByShotType()
                        else if (currentIndex == 3)
                            mediaLibrary.orderByName()
                        else if (currentIndex == 4)
                            mediaLibrary.orderByPath()
                    } else {
                        cbinit = true
                    }

                    displayText = qsTr("Order by:") + " " + cbShotsOrderby.get(currentIndex).text
                }

                ItemImageButton {
                    anchors.right: parent.right
                    anchors.rightMargin: 32
                    width: parent.height
                    height: parent.height

                    rotation: ascDesc ? 180 : 0
                    iconColor: Theme.colorComponentContent
                    highlightMode: "color"
                    highlightColor: Theme.colorSubText
                    source: "qrc:/assets/icons_material/baseline-filter_list-24px.svg"

                    property bool ascDesc: false

                    onClicked: {
                        if (ascDesc) {
                            ascDesc = false
                            mediaLibrary.orderByDesc()
                        } else {
                            ascDesc = true
                            mediaLibrary.orderByAsc()
                        }
                    }
                }
            }

            ComboBoxThemed {
                id: comboBox_filterby
                width: 240

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
                        mediaGrid.exitSelectionMode()
                        shotsView.currentIndex = -1
                        actionMenu.visible = false

                        mediaLibrary.filterByType(cbMediaFilters.get(currentIndex).text)

                        if (currentIndex == 0)
                            displayText = cbMediaFilters.get(currentIndex).text // "No filter"
                        else
                            displayText = qsTr("Filter by:") + " " + cbMediaFilters.get(currentIndex).text
                    } else {
                        cbinit = true;
                    }
                }
            }
        }

        Row {
            anchors.left: rowFilter.right
            anchors.leftMargin: 16
            anchors.verticalCenter: rowFilter.verticalCenter
            spacing: 12

            visible: (rectangleHeader.width > 1280)

            ItemLilMenu {
                width: rowLilMenuFormat.width

                Row {
                    id: rowLilMenuFormat
                    height: parent.height

                    ItemLilMenuButton {
                        text: "1:1"
                        selected: (shotsView.cellFormat === 1.0)
                        onClicked: {
                            shotsView.cellFormat = 1.0
                            shotsView.computeCellSize()
                        }
                    }
                    ItemLilMenuButton {
                        text: "4:3"
                        selected: (shotsView.cellFormat === 4/3)
                        onClicked: {
                            shotsView.cellFormat = 4/3
                            shotsView.computeCellSize()
                        }
                    }
                    ItemLilMenuButton {
                        text: "16:9"
                        selected: (shotsView.cellFormat === 16/9)
                        onClicked: {
                            shotsView.cellFormat = 16/9
                            shotsView.computeCellSize()
                        }
                    }
                }
            }

            ItemLilMenu {
                width: rowLilMenuZoom.width

                Row {
                    id: rowLilMenuZoom
                    height: parent.height

                    ItemLilMenuButton {
                        source: "qrc:/assets/icons_material/baseline-photo-24px.svg"
                        sourceSize: 18
                        selected: (shotsView.cellSizeTarget === 221)
                        onClicked: {
                            shotsView.cellSizeTarget = 221;
                            shotsView.computeCellSize();
                        }
                    }
                    ItemLilMenuButton {
                        source: "qrc:/assets/icons_material/baseline-photo-24px.svg"
                        sourceSize: 22
                        selected: (shotsView.cellSizeTarget === 279)
                        onClicked: {
                            shotsView.cellSizeTarget = 279;
                            shotsView.computeCellSize();
                        }
                    }
                    ItemLilMenuButton {
                        source: "qrc:/assets/icons_material/baseline-photo-24px.svg"
                        sourceSize: 26
                        selected: (shotsView.cellSizeTarget === 376)
                        onClicked: {
                            shotsView.cellSizeTarget = 376;
                            shotsView.computeCellSize();
                        }
                    }
                    ItemLilMenuButton {
                        source: "qrc:/assets/icons_material/baseline-photo-24px.svg"
                        sourceSize: 30
                        selected: (shotsView.cellSizeTarget === 512)
                        onClicked: {
                            shotsView.cellSizeTarget = 512;
                            shotsView.computeCellSize();
                        }
                    }
                }
            }
        }

        ////////

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: 2
            opacity: 0.1
            color: Theme.colorHeaderHighlight
        }
        SimpleShadow {
            anchors.top: parent.bottom
            anchors.topMargin: -height
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
        }
    }

    // MENUS ///////////////////////////////////////////////////////////////////

    Column {
        id: menusArea
        anchors.top: rectangleHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        z: 1

        ItemBannerActions {
            id: bannerSelection
            height: (mediaGrid.selectionCount) ? 56 : 0
        }
    }

    // CONTENT /////////////////////////////////////////////////////////////////

    Item {
        id: rectangleLibraryGrid

        anchors.top: menusArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        ////////

        Rectangle {
            id: circleEmpty
            width: 350; height: 350; radius: 350;
            anchors.centerIn: parent
            visible: (shotsView.count <= 0)
            color: Theme.colorHeader

            Image {
                id: imageEmpty
                width: 256
                height: 256
                sourceSize.width: width
                sourceSize.height: height
                anchors.centerIn: parent
                source: "qrc:/devices/disk.svg"
            }
        }

        ////////

        Component {
            id: itemHighlight

            Rectangle {
                width: shotsView.cellSize
                height: shotsView.cellSize
                x: 0; y: 0; z: 2;

                visible: !mediaGrid.selectionMode

                color: "transparent"
                radius: (Theme.componentRadius > 6) ? Theme.componentRadius-2 : 3
                border.width: (Theme.componentRadius > 4) ? 6 : 4
                border.color: Theme.colorPrimary

                SimpleShadow {
                    anchors.fill: parent
                    color: Theme.colorPrimary
                    radius: parent.radius
                    filled: false
                }
            }
        }

        ////////

        ActionMenu {
            id: actionMenu
            z: 7

            onMenuSelected: { rectangleLibraryGrid.actionMenuTriggered(index) }
        }
        function actionMenuTriggered(index) {
            //console.log("actionMenuTriggered(" + index + ") selected shot: '" + shotsView.currentItem.shot.name + "'")

            var indexes = []
            if (mediaGrid.selectionMode) {
                indexes = selectionList
            } else {
                indexes.push(shotsView.currentIndex)
            }

            if (index === 2) {
                popupMove.uuids = mediaLibrary.getSelectedShotsUuids(indexes)
                popupMove.shots = mediaLibrary.getSelectedShotsNames(indexes)
                popupMove.files = mediaLibrary.getSelectedFilesPaths(indexes)
                popupMove.openSelection(mediaLibrary)
            }
            if (index === 3) {
                popupEncoding.uuids = mediaLibrary.getSelectedShotsUuids(indexes)
                popupEncoding.shots = mediaLibrary.getSelectedShotsNames(indexes)
                popupEncoding.files = mediaLibrary.getSelectedFilesPaths(indexes)
                popupEncoding.updateEncodePanel(selectedItem.shot)
                popupEncoding.openSingle(mediaLibrary, selectedItem.shot)
            }
            if (index === 12) {
                selectedItem.shot.openFile()
            }
            if (index === 13) {
                selectedItem.shot.openFolder()
            }
            if (index === 16) {
                popupDelete.uuids = mediaLibrary.getSelectedShotsUuids(indexes)
                popupDelete.shots = mediaLibrary.getSelectedShotsNames(indexes)
                popupDelete.files = mediaLibrary.getSelectedFilesPaths(indexes)
                popupDelete.openSelection(mediaLibrary)
            }

            actionMenu.visible = false
        }

        // GridView ////////////////////////////////////////////////////////////

        GridView {
            id: shotsView
            anchors.fill: parent

            topMargin: 16
            leftMargin: 16
            rightMargin: 4
            bottomMargin: 4

            interactive: !actionMenu.visible
            keyNavigationEnabled: true
            //snapMode: GridView.FlowTopToBottom
            focus: (appContent.state === "library" && screenLibrary.state === "stateMediaGrid")

            onCountChanged: updateGridViewSettings()
            onWidthChanged: computeCellSize()

            Component.onCompleted: initGridViewSettings()

            Connections {
                target: settingsManager
                onThumbFormatChanged: {
                    if (settingsManager.thumbFormat === 1)
                        shotsView.cellFormat = 1.0
                    else if (settingsManager.thumbFormat === 2)
                        shotsView.cellFormat = 4/3
                    else if (settingsManager.thumbFormat === 3)
                        shotsView.cellFormat = 16/9

                    shotsView.computeCellSize()
                }
                onThumbSizeChanged: {
                    if (settingsManager.thumbSize === 1)
                        shotsView.cellSizeTarget = 221
                    else if (settingsManager.thumbSize === 2)
                        shotsView.cellSizeTarget = 279
                    else if (settingsManager.thumbSize === 3)
                        shotsView.cellSizeTarget = 376
                    else if (settingsManager.thumbSize === 4)
                        shotsView.cellSizeTarget = 512

                    shotsView.computeCellSize()
                }
            }

            ////////

            property real cellFormat: {
                if (settingsManager.thumbFormat === 1)
                    return 1.0
                else if (settingsManager.thumbFormat === 2)
                    return 4/3
                else if (settingsManager.thumbFormat === 3)
                    return 16/9
            }
            property int cellSizeTarget: {
                if (settingsManager.thumbSize === 1)
                    return 221
                else if (settingsManager.thumbSize === 2)
                    return 279
                else if (settingsManager.thumbSize === 3)
                    return 376
                else if (settingsManager.thumbSize === 4)
                    return 512
            }
            property int cellSize: cellSizeTarget
            property int cellMarginTarget: 12
            property int cellMargin: 12

            //property int cellMargin: (parent.width%cellSize) / Math.floor(parent.width/cellSize);
            cellWidth: cellSize + cellMargin
            cellHeight: Math.round(cellSize / cellFormat) + cellMargin

            function computeCellSize() {
                var availableWidth = shotsView.width - shotsView.leftMargin - shotsView.rightMargin
                var cellColumnsTarget = Math.trunc(availableWidth / cellSizeTarget)
                // 1 // Adjust only cellSize
                cellSize = (availableWidth - cellMarginTarget * cellColumnsTarget) / cellColumnsTarget
                // Recompute
                cellWidth = cellSize + cellMargin
                cellHeight = Math.round(cellSize / cellFormat) + cellMarginTarget
            }

            ////////

            model: mediaLibrary.shotFilter
            delegate: ItemShot { width: shotsView.cellSize; cellFormat: shotsView.cellFormat; }

            ScrollBar.vertical: ScrollBar { z: 1 }

            highlight: itemHighlight
            highlightMoveDuration: 0

            flickableChildren: MouseArea {
                id: mouseAreaInsideView
                anchors.fill: parent

                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: {
                    //console.log("mouseAreaInsideView clicked")
                    mediaGrid.exitSelectionMode()
                    shotsView.currentIndex = -1
                    actionMenu.visible = false
                }
            }

            Keys.onPressed: {
                actionMenu.visible = false

                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    screenMedia.loadShot(mediaLibrary.getShotByUuid(screenLibraryGrid.selectedItemUuid))
                } else if (event.key === Qt.Key_PageUp) {
                    shotsView.currentIndex = 0
                } else if (event.key === Qt.Key_PageDown) {
                    shotsView.currentIndex = shotsView.count - 1
                } else if ((event.key === Qt.Key_A) && (event.modifiers & Qt.ControlModifier)) {
                    mediaGrid.selectAll()
                } else if (event.key === Qt.Key_Clear) {
                    mediaGrid.exitSelectionMode()
                } else if (event.key === Qt.Key_Escape) {
                    mediaGrid.exitSelectionMode()
                } else if (event.key === Qt.Key_Menu) {
                    //console.log("shotsView::Key_Menu")
                } else if (event.key === Qt.Key_Delete) {
                    var indexes = []
                    if (mediaGrid.selectionMode) {
                        indexes = selectionList
                    } else {
                        indexes.push(shotsView.currentIndex)
                    }
                    popupDelete.uuids = mediaLibrary.getSelectedShotsUuids(indexes)
                    popupDelete.shots = mediaLibrary.getSelectedShotsNames(indexes)
                    popupDelete.files = mediaLibrary.getSelectedFilesPaths(indexes)
                    popupDelete.openSelection(mediaLibrary)
                }
            }
        }

        ////////

        MouseArea {
            id: mouseAreaOutsideView
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            propagateComposedEvents: true
            //onClicked: console.log("mouseAreaOutsideView clicked")
        }
    }
}
