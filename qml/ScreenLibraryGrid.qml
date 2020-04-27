import QtQuick 2.9
import QtQuick.Controls 2.2

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

    property var selectionMode: false
    property var selectionList: []
    property var selectionCount: 0

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
        // Grid menu
        actionMenu.visible = false
    }

    function updateGridViewSettings() {
        if (typeof mediaLibrary === "undefined" || !mediaLibrary) return

        // Grid State
        if (mediaLibrary.libraryState === 1) { // scanning
            circleEmpty.visible = true
            loadingFader.start()
        } else if (mediaLibrary.libraryState === 0) { // idle
            loadingFader.stop()
            if (shotsView.count > 0) {
                circleEmpty.visible = false
            }
        }

        if (shotsView.count <= 0) {
            shotsView.currentIndex = -1
            mediaGrid.exitSelectionMode()
            circleEmpty.visible = true
        }

        // Header texts
        textFilesCount.text = qsTr("%1 shots  /  %2 files".arg(mediaLibrary.shotModel.getShotCount()).arg(mediaLibrary.shotModel.getFileCount()))
        textFilesSize.text = qsTr("%1 of space used".arg(UtilsString.bytesToString_short(mediaLibrary.shotModel.getDiskSpace())))
    }

    // POPUPS //////////////////////////////////////////////////////////////////

    PopupEncodeVideo {
        id: popupEncodeVideo
    }

    PopupDelete {
        id: confirmDeleteMultipleFilesPopup

        message: qsTr("Are you sure you want to delete selected shots?")
        onConfirmed: {
            var indexes = mediaGrid.selectionList;
            mediaGrid.exitSelectionMode();

            //var uuid_list = mediaLibrary.getSelectedUuids(indexes);
            //var path_list = mediaLibrary.getSelectedPaths(indexes);
            //console.log("paths; " + path_list)

            // actual deletion
            mediaLibrary.deleteSelection(indexes)
        }
    }

    PopupDelete {
        id: confirmDeleteSingleFilePopup

        message: qsTr("Are you sure you want to delete selected shot?")
        onConfirmed: {
            mediaLibrary.deleteSelected(selectedItemUuid)

            shotsView.currentIndex = -1;
            mediaGrid.exitSelectionMode();
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

        Text {
            id: textFilesCount
            height: 24
            anchors.top: textHeader.bottom
            anchors.topMargin: 4
            anchors.right: parent.right
            anchors.rightMargin: 16

            text: "%42 shots  /  128 files"
            verticalAlignment: Text.AlignVCenter
            color: Theme.colorHeaderContent
            font.pixelSize: Theme.fontSizeHeaderText
        }

        Text {
            id: textFilesSize
            height: 24
            anchors.top: textFilesCount.bottom
            anchors.topMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 16

            text: "236 GB of space used"
            verticalAlignment: Text.AlignVCenter
            color: Theme.colorHeaderContent
            font.pixelSize: Theme.fontSizeHeaderText
        }

        ComboBoxThemed {
            id: comboBox_directories
            height: 40
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
                target: settingsManager
                function onDirectoriesUpdated() { comboBox_directories.updateDirectories() }
            }

            function updateDirectories() {
                cbMediaDirectories.clear()
                cbMediaDirectories.append( { text: qsTr("ALL media directories") } );

                for (var child in settingsManager.directoriesList) {
                    //if (settingsManager.directoriesList[child].available)
                    cbMediaDirectories.append( { "text": settingsManager.directoriesList[child].directoryPath } )
                }
            }

            property bool cbinit: false
            width: 476
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
            height: 40
            spacing: 16
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 16

            ComboBoxThemed {
                id: comboBox_orderby
                width: 220
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
                    } else {
                        cbinit = true;
                    }

                    displayText = qsTr("Order by:") + " " + cbShotsOrderby.get(currentIndex).text
                }
            }

            ComboBoxThemed {
                id: comboBox_filterby
                width: 240
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

        Rectangle {
            anchors.fill: rowLilMenuFormat
            color: Theme.colorComponent
            radius: Theme.componentRadius
        }
        Row {
            id: rowLilMenuFormat
            height: 36
            anchors.left: rowFilter.right
            anchors.leftMargin: 16
            anchors.verticalCenter: rowFilter.verticalCenter

            ItemLilMenuButton {
                height: parent.height
                text: "1:1"
                selected: (shotsView.cellFormat === 1.0)
                onClicked: {
                    shotsView.cellFormat = 1.0
                    shotsView.computeCellSize()
                }
            }
            ItemLilMenuButton {
                height: parent.height
                text: "4:3"
                selected: (shotsView.cellFormat === 4/3)
                onClicked:  {
                    shotsView.cellFormat = 4/3
                    shotsView.computeCellSize()
                }
            }
            ItemLilMenuButton {
                height: parent.height
                text: "16:9"
                selected: (shotsView.cellFormat === 16/9)
                onClicked:  {
                    shotsView.cellFormat = 16/9
                    shotsView.computeCellSize()
                }
            }
        }

        Rectangle {
            anchors.fill: rowLilMenuZoom
            color: Theme.colorComponent
            radius: Theme.componentRadius
        }
        Row {
            id: rowLilMenuZoom
            height: 36
            anchors.left: rowLilMenuFormat.right
            anchors.leftMargin: 16
            anchors.verticalCenter: rowLilMenuFormat.verticalCenter

            ItemLilMenuButton {
                height: parent.height
                source: "qrc:/icons_material/baseline-photo-24px.svg"
                sourceSize: 18
                selected: (shotsView.cellSizeTarget === 221)
                onClicked: {
                    shotsView.cellSizeTarget = 221;
                    shotsView.computeCellSize();
                }
            }
            ItemLilMenuButton {
                height: parent.height
                source: "qrc:/icons_material/baseline-photo-24px.svg"
                sourceSize: 22
                selected: (shotsView.cellSizeTarget === 279)
                onClicked: {
                    shotsView.cellSizeTarget = 279;
                    shotsView.computeCellSize();
                }
            }
            ItemLilMenuButton {
                height: parent.height
                source: "qrc:/icons_material/baseline-photo-24px.svg"
                sourceSize: 26
                selected: (shotsView.cellSizeTarget === 376)
                onClicked: {
                    shotsView.cellSizeTarget = 376;
                    shotsView.computeCellSize();
                }
            }
            ItemLilMenuButton {
                height: parent.height
                source: "qrc:/icons_material/baseline-photo-24px.svg"
                sourceSize: 30
                selected: (shotsView.cellSizeTarget === 512)
                onClicked: {
                    shotsView.cellSizeTarget = 512;
                    shotsView.computeCellSize();
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
            id: bannerSelection
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
                width: shotsView.cellSize;
                height: shotsView.cellSize
                visible: !mediaGrid.selectionMode
                color: "transparent"
                border.width : 4
                border.color: Theme.colorPrimary
                x: {
                    if (shotsView.currentItem.x) {
                        x = shotsView.currentItem.x
                    } else {
                        x = 0
                    }
                }
                y: {
                    if (shotsView.currentItem.y) {
                        y = shotsView.currentItem.y
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
            function onMenuSelected() { rectangleLibraryGrid.actionMenuTriggered(index) }
            function onVisibleChanged() { shotsView.interactive = !shotsView.interactive }
        }
        function actionMenuTriggered(index) {
            //console.log("actionMenuTriggered(" + index + ") selected shot: '" + shotsView.currentItem.shot.name + "'")

            if (index === 0) {
                selectedItem.shot.openFolder()
            }
            if (index === 3) {
                popupEncodeVideo.updateEncodePanel(selectedItem.shot)
                popupEncodeVideo.open()
            }
            if (index === 16) {
                var indexes = []
                indexes.push(shotsView.currentIndex)
                confirmDeleteSingleFilePopup.files = mediaLibrary.getSelectedPaths(indexes);
                confirmDeleteSingleFilePopup.open()
            }

            actionMenu.visible = false
        }

        GridView {
            id: shotsView
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.topMargin: 16

            //clip: true
            //snapMode: GridView.SnapToRow
            interactive: true
            keyNavigationEnabled: true
            focus: (applicationContent.state === "library" && screenLibrary.state === "stateMediaGrid")

            onCountChanged: updateGridViewSettings()
            onWidthChanged: computeCellSize()

            Component.onCompleted: {
                mediaGrid.exitSelectionMode()
                shotsView.currentIndex = -1
                actionMenu.visible = false
            }

            Connections {
                target: settingsManager
                function onThumbFormatChanged() {
                    if (settingsManager.thumbFormat === 1)
                        shotsView.cellFormat = 1.0
                    else if (settingsManager.thumbFormat === 2)
                        shotsView.cellFormat = 4/3
                    else if (settingsManager.thumbFormat === 3)
                        shotsView.cellFormat = 16/9

                    shotsView.computeCellSize()
                }
                function onThumbSizeChanged() {
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
                var availableWidth = shotsView.width - cellMarginTarget
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

            highlight: highlight
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 0

            Keys.onPressed: {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    actionMenu.visible = false
                    screenLibrary.state = "stateMediaDetails"
                }  else if (event.key === Qt.Key_PageUp) {
                    shotsView.currentIndex = 0;
                } else if (event.key === Qt.Key_PageDown) {
                    shotsView.currentIndex = shotsView.count - 1;
                } else if ((event.key === Qt.Key_A) && (event.modifiers & Qt.ControlModifier)) {
                    mediaGrid.selectAll()
                } else if (event.key === Qt.Key_Clear) {
                    mediaGrid.exitSelectionMode()
                } else if (event.key === Qt.Key_Menu) {
                    //console.log("shotsView::Key_Menu")
                } else if (event.key === Qt.Key_Delete) {
                    if (selectionMode) {
                        confirmDeleteSingleFilePopup.files = mediaLibrary.getSelectedPaths(selectionList);
                        confirmDeleteSingleFilePopup.open()
                    } else {
                        var indexes = []
                        indexes.push(shotsView.currentIndex)
                        confirmDeleteSingleFilePopup.files = mediaLibrary.getSelectedPaths(indexes);
                        confirmDeleteSingleFilePopup.open()
                    }
                }
            }
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
