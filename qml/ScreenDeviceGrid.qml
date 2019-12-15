import QtQuick 2.9
import QtQuick.Controls 2.2

import ThemeEngine 1.0
import com.offloadbuddy.shared 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsDevice.js" as UtilsDevice

Item {
    id: mediaGrid
    width: 1280
    height: 720
    anchors.fill: parent

    property var selectedItem : shotsView.currentItem
    property int selectedItemIndex : shotsView.currentIndex
    property string selectedItemUuid: shotsView.currentItem ? shotsView.currentItem.shot.uuid : ""

    ////////

    property var selectionMode: false
    property var selectionList: []
    property var selectionCount: 0

    function selectFile(index) {
        // make sure it's not already selected
        if (currentDevice.getShotByProxyIndex(index).selected) return;

        // then add
        selectionMode = true;
        selectionList.push(index);
        selectionCount++;

        currentDevice.getShotByProxyIndex(index).selected = true;

        // save state
        if (deviceSavedState) {
            deviceSavedState.selectionMode = selectionMode
            deviceSavedState.selectionList = selectionList
            deviceSavedState.selectionCount = selectionCount
        }
    }
    function deselectFile(index) {
        var i = selectionList.indexOf(index);
        if (i > -1) { selectionList.splice(i, 1); selectionCount--; }
        if (selectionList.length <= 0 || selectionCount <= 0) { exitSelectionMode() }

        currentDevice.getShotByProxyIndex(index).selected = false;

        // save state
        if (deviceSavedState) {
            deviceSavedState.selectionMode = selectionMode
            deviceSavedState.selectionList = selectionList
            deviceSavedState.selectionCount = selectionCount
        }
    }

    function selectAll() {
        exitSelectionMode()

        selectionMode = true;
        for (var i = 0; i < shotsView.count; i++) {
            selectionList.push(i);
            selectionCount++;

            currentDevice.getShotByProxyIndex(i).selected = true;
        }

        // save state
        if (deviceSavedState) {
            deviceSavedState.selectionMode = selectionMode
            deviceSavedState.selectionList = selectionList
            deviceSavedState.selectionCount = selectionCount
        }
    }

    function exitSelectionMode() {
        selectionMode = false;
        selectionList = [];
        selectionCount = 0;

        for (var i = 0; i < shotsView.count; i++) {
            if (currentDevice) currentDevice.getShotByProxyIndex(i).selected = false;
        }

        // save state
        if (deviceSavedState) {
            deviceSavedState.selectionMode = selectionMode
            deviceSavedState.selectionList = selectionList
            deviceSavedState.selectionCount = selectionCount
        }
    }

    ////////

    Connections {
        target: currentDevice
        onStateUpdated: updateGridState()
        onStorageUpdated: updateStorage()
        onBatteryUpdated: updateBattery()
    }

    function restoreState() {
        //console.log("ScreenDeviceGrid.restoreState()")

        // Grid filters and settings
        comboBox_orderby.currentIndex = deviceSavedState.orderBy
        comboBox_filterby.currentIndex = deviceSavedState.filterBy

        // Banner // TODO reopen ONLY if needed
        bannerMessage.close()
        if (currentDevice.deviceStorage === 1) { // VFS
            bannerMessage.openMessage(qsTr("Previews are not available (yet) with MTP devices..."))
        }
        if (currentDevice.deviceStorage === 2) { // MTP
            bannerMessage.openMessage(qsTr("Metadatas are not available from MTP devices. Offload medias first, or plug SD cards directly."))
        }

        // Grid index
        shotsView.currentIndex = deviceSavedState.selectedIndex

        // Grid selection
        selectionMode = deviceSavedState.selectionMode
        selectionList = deviceSavedState.selectionList
        selectionCount = deviceSavedState.selectionCount

        // Grid menu
        actionMenu.visible = false
    }

    function initDeviceHeader() {
        if (typeof currentDevice === "undefined" || !currentDevice) return

        //console.log("ScreenDeviceGrid.initDeviceHeader()")

        // Header text and picture
        if (currentDevice.batteryLevel > 0.0 && currentDevice.storageLevel > 0.0)
            deviceModelText.anchors.topMargin = 12
        else if (currentDevice.batteryLevel <= 0.0 && currentDevice.storageLevel <= 0.0)
            deviceModelText.anchors.topMargin = 38
        else
            deviceModelText.anchors.topMargin = 26

        deviceModelText.text = currentDevice.brand + " " + currentDevice.model;
        deviceImage.source = UtilsDevice.getDevicePicture(currentDevice)

        // Storage and battery infos
        updateStorage()
        updateBattery()
    }

    function updateBattery() {
        if (typeof currentDevice === "undefined" || !currentDevice) return

        //console.log("ScreenDeviceGrid.updateBattery() currentDevice.batteryLevel" + currentDevice.batteryLevel)

        if (currentDevice.batteryLevel > 0.0) {
            deviceBatteryIcon.visible = true
            deviceBatteryBar.visible = true
            deviceBatteryBar.value = currentDevice.batteryLevel
        } else {
            deviceBatteryIcon.visible = false
            deviceBatteryBar.visible = false
        }
    }

    function updateStorage() {
        if (typeof currentDevice === "undefined" || !currentDevice) return

        //console.log("ScreenDeviceGrid.updateStorage() currentDevice.storageLevel" + currentDevice.storageLevel)

        if (currentDevice.spaceTotal > 0) {
            deviceSpaceText.text = UtilsString.bytesToString_short(currentDevice.spaceUsed)
                    + qsTr(" used of ") + UtilsString.bytesToString_short(currentDevice.spaceTotal)
        } else {
            deviceSpaceText.text = qsTr("Unknown storage")
        }

        if (currentDevice.readOnly === true) {
            deviceSpaceText.anchors.rightMargin = 32
            deviceLockedImage.visible = true
        } else {
            deviceSpaceText.anchors.rightMargin = 8
            deviceLockedImage.visible = false
        }

        if (currentDevice.spaceTotal > 0) {
            deviceStorageImage.visible = true
            if (currentDevice.getStorageCount() > 1) {
                deviceSpaceBar1.visible = true
                deviceSpaceBar1.value = currentDevice.getStorageLevel(2)
                deviceSpaceBar2.visible = true
                deviceSpaceBar2.value = currentDevice.getStorageLevel(1)
            } else {
                deviceSpaceBar1.visible = false
                deviceSpaceBar2.visible = true
                deviceSpaceBar2.value = currentDevice.storageLevel
            }
        } else {
            deviceStorageImage.visible = false
            deviceSpaceBar1.visible = false
            deviceSpaceBar2.visible = false
        }
    }

    function initGridViewSettings() {
        if (typeof currentDevice === "undefined" || !currentDevice) return

        //console.log("ScreenDeviceGrid.initGridViewSettings() [device "+ currentDevice + "]
        //    (state " + currentDevice.deviceState + ") (shotcount: " + shotsView.count + ")")

        if (currentDevice && currentDevice.deviceStorage === 0)
            if (currentDevice.deviceType === 2)
                imageEmpty.source = "qrc:/devices/card.svg"
            else
                imageEmpty.source = "qrc:/devices/camera.svg"
        else
            imageEmpty.source = "qrc:/devices/usb.svg"
    }

    function updateGridState() {
        if (typeof currentDevice === "undefined" || !currentDevice) return

        if (currentDevice.deviceState === 0) { // idle
            loadingFader.stop()

            if (shotsView.count <= 0) {
                circleEmpty.visible = true

                rectangleTransfer.visible = false
                rectangleDelete.visible = false
            } else {
                circleEmpty.visible = false
                rectangleTransfer.visible = true

                if (currentDevice.readOnly === true)
                    rectangleDelete.visible = false
                else
                    rectangleDelete.visible = true
            }
        } else { // scanning
            rectangleTransfer.visible = false
            rectangleDelete.visible = false
        }
    }

    function updateGridViewSettings() {
        if (typeof currentDevice === "undefined" || !currentDevice) return

        //console.log("ScreenDeviceGrid.updateGridViewSettings() [device "+ currentDevice + "]
        //    (state " + currentDevice.deviceState + ") (shotcount: " + shotsView.count + ")")

        // Grid State
        updateGridState()

        //
        if (shotsView.count <= 0) {
            shotsView.currentIndex = -1
            mediaGrid.exitSelectionMode()
            circleEmpty.visible = true
        } else {
            // Restore grid index
            if (deviceSavedState && deviceSavedState.selectedIndex <= shotsView.count)
                shotsView.currentIndex = deviceSavedState.selectedIndex
        }
    }

    // POPUPS //////////////////////////////////////////////////////////////////

    PopupEncodeVideo {
        id: popupEncodeVideo
        x: (applicationWindow.width / 2) - (popupEncodeVideo.width / 2) - (applicationSidebar.width / 2)
        y: (applicationWindow.height / 2) - (popupEncodeVideo.height / 2)
    }

    PopupOffload {
        id: popupOffloadAll
        x: (applicationWindow.width / 2) - (popupOffloadAll.width / 2) - (applicationSidebar.width / 2)
        y: (applicationWindow.height / 2) - (popupOffloadAll.height / 2)

        onConfirmed: {
            currentDevice.offloadAll(popupOffloadAll.selectedPath)
        }
    }

    PopupDelete {
        id: confirmDeleteAll
        x: (applicationWindow.width / 2) - (confirmDeleteAll.width / 2) - (applicationSidebar.width / 2)
        y: (applicationWindow.height / 2) - (confirmDeleteAll.height / 2)

        message: qsTr("Are you sure you want to delete ALL of the files from this device?")
        onConfirmed: {
            currentDevice.deleteAll()
        }
    }

    PopupDelete {
        id: confirmDeleteMultipleFilesPopup
        x: (applicationWindow.width / 2) - (confirmDeleteMultipleFilesPopup.width / 2) - (applicationSidebar.width / 2)
        y: (applicationWindow.height / 2) - (confirmDeleteMultipleFilesPopup.height / 2)

        message: qsTr("Are you sure you want to delete selected files?")
        onConfirmed: {
            var indexes = mediaGrid.selectionList
            mediaGrid.exitSelectionMode()

            //var uuid_list = currentDevice.getSelectedUuids(indexes)
            //var path_list = currentDevice.getSelectedPaths(indexes)
            //console.log("paths; " + path_list)

            // actual deletion
            currentDevice.deleteSelection(indexes)
        }
    }

    PopupDelete {
        id: confirmDeleteSingleFilePopup
        x: (applicationWindow.width / 2) - (confirmDeleteSingleFilePopup.width / 2) - (applicationSidebar.width / 2)
        y: (applicationWindow.height / 2) - (confirmDeleteSingleFilePopup.height / 2)

        message: qsTr("Are you sure you want to delete selected shot?")
        onConfirmed: {
            currentDevice.deleteSelected(selectedItemUuid)

            shotsView.currentIndex = -1
            mediaGrid.exitSelectionMode()
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

        ImageSvg {
            id: deviceImage
            width: 128
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 8

            fillMode: Image.PreserveAspectCrop
            color: Theme.colorHeaderContent
        }

        Text {
            id: deviceModelText
            width: 256
            height: 30
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.right: deviceImage.left
            anchors.rightMargin: 8

            text: "Camera brand & model"
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            color: Theme.colorHeaderContent
            font.bold: true
            font.pixelSize: Theme.fontSizeHeaderTitle - 2
        }

        ImageSvg {
            id: deviceLockedImage
            width: 24
            height: 24
            anchors.top: deviceModelText.bottom
            anchors.topMargin: 0
            anchors.right: deviceModelText.right
            anchors.rightMargin: -3

            source: "qrc:/icons_material/outline-https-24px.svg"
            color: Theme.colorHeaderContent
        }
        ImageSvg {
            id: deviceStorageImage
            width: 24
            height: 24
            anchors.top: deviceLockedImage.bottom
            anchors.topMargin: 0
            anchors.right: deviceModelText.right
            anchors.rightMargin: -3

            source: "qrc:/icons_material/outline-sd_card-24px.svg"
            color: Theme.colorHeaderContent
        }
        ImageSvg {
            id: deviceBatteryIcon
            width: 24
            height: 24
            anchors.top: deviceStorageImage.bottom
            anchors.topMargin: 0
            anchors.right: deviceModelText.right
            anchors.rightMargin: -3

            source: "qrc:/icons_material/outline-power-24px.svg"
            color: Theme.colorHeaderContent
        }

        Text {
            id: deviceSpaceText
            width: 232
            height: 24
            anchors.right: deviceImage.left
            anchors.rightMargin: 32
            anchors.top: deviceModelText.bottom
            anchors.topMargin: 0

            text: "64GB available of 128GB"
            color: Theme.colorHeaderContent
            font.pixelSize: Theme.fontSizeHeaderText
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignBottom
        }

        ProgressBarThemed {
            id: deviceSpaceBar1
            width: 256
            height: 6
            anchors.verticalCenterOffset: -4
            anchors.verticalCenter: deviceStorageImage.verticalCenter
            anchors.rightMargin: 2
            anchors.right: deviceStorageImage.left
            value: 0.5
        }
        ProgressBarThemed {
            id: deviceSpaceBar2
            width: 256
            height: 6
            anchors.verticalCenterOffset: 4
            anchors.verticalCenter: deviceStorageImage.verticalCenter
            anchors.right: deviceStorageImage.left
            anchors.rightMargin: 2
            value: 0.5
        }

        ProgressBarThemed {
            id: deviceBatteryBar
            width: 256
            height: 6
            anchors.verticalCenterOffset: 0
            anchors.verticalCenter: deviceBatteryIcon.verticalCenter
            anchors.right: deviceBatteryIcon.left
            anchors.rightMargin: 2
            value: 0.5
        }

        ////////


        ComboBoxThemed {
            id: comboBox_orderby
            width: 220
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
                    mediaGrid.exitSelectionMode()
                    shotsView.currentIndex = -1

                    if (currentIndex == 0)
                        currentDevice.orderByDate()
                    else if (currentIndex == 1)
                        currentDevice.orderByDuration()
                    else if (currentIndex == 2)
                        currentDevice.orderByShotType()
                    else if (currentIndex == 3)
                        currentDevice.orderByName()
                } else {
                    cbinit = true;
                }

                displayText = qsTr("Order by:") + " " + cbShotsOrderby.get(currentIndex).text

                // save state
                if (deviceSavedState) deviceSavedState.orderBy = currentIndex
            }
        }

        ComboBoxThemed {
            id: comboBox_filterby
            width: 240
            height: 40
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.left: comboBox_orderby.right
            anchors.leftMargin: 16
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

                    currentDevice.filterByType(cbMediaFilters.get(currentIndex).text)

                    if (currentIndex == 0)
                        displayText = cbMediaFilters.get(currentIndex).text
                    else
                        displayText = qsTr("Filter by:") + " " + cbMediaFilters.get(currentIndex).text
                } else {
                    cbinit = true;
                }

                // save state
                if (deviceSavedState) deviceSavedState.filterBy = currentIndex
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
            anchors.left: comboBox_filterby.right
            anchors.leftMargin: 16
            anchors.verticalCenter: comboBox_filterby.verticalCenter

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

        ////////

        ButtonWireframe {
            id: rectangleTransfer
            width: 220
            height: 40
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16

            text: qsTr("Offload content")
            fullColor: true
            onClicked: popupOffloadAll.open()
        }

        ButtonWireframe {
            id: rectangleDelete
            width: 240
            height: 40
            anchors.left: rectangleTransfer.right
            anchors.leftMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16

            text: qsTr("Delete ALL content!")
            fullColor: true
            primaryColor: Theme.colorError
            onClicked: confirmDeleteAll.open()
        }
    }

    // MENUS ///////////////////////////////////////////////////////////////////

    Column {
        id: menusArea
        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        z: 1

        ItemBannerActions {
            id: bannerSelection
            visible: (mediaGrid.selectionCount)
        }

        ItemBannerMessage {
            id: bannerMessage
        }
    }

    // CONTENT /////////////////////////////////////////////////////////////////

    Item {
        id: rectangleDeviceShots

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
                sourceSize.width: width
                sourceSize.height: height
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
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
            onMenuSelected: rectangleDeviceShots.actionMenuTriggered(index)
            onVisibleChanged: shotsView.interactive = !shotsView.interactive
        }
        function actionMenuTriggered(index) {
            //console.log("actionMenuTriggered(" + index + ") selected shot: '" + shotsView.currentItem.shot.name + "'")

            if (index === 0) {
                shotsView.currentItem.shot.openFolder()
            }
            if (index === 1) {
                currentDevice.offloadCopySelected(selectedItemUuid)
            }
            if (index === 2) {
                currentDevice.offloadMergeSelected(selectedItemUuid)
            }
            if (index === 3) {
                popupEncodeVideo.updateEncodePanel(selectedItem.shot)
                popupEncodeVideo.open()
            }
            if (index === 16) {
                var indexes = []
                indexes.push(shotsView.currentIndex)
                confirmDeleteSingleFilePopup.files = currentDevice.getSelectedPaths(indexes);
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
            focus: (applicationContent.state === "device" && screenLibrary.state === "stateMediaGrid")

            onCountChanged: updateGridViewSettings()
            onWidthChanged: computeCellSize()

            Component.onCompleted: {
                currentIndex = -1;
                mediaGrid.exitSelectionMode();
            }

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

            onCurrentIndexChanged: {
                //console.log("onCurrentIndexChanged() selected index: " + shotsview.currentIndex)
                //console.log("onCurrentIndexChanged() selected row/column: " + shotsview.childAt())

                //console.log("onCurrentIndexChanged() selected shot: " + shotsview.currentIndex)
                //console.log("onCurrentIndexChanged() selected shots [ " + selectionList + "]")

                //console.log("highlight: " + rectangleDeviceShots.highlight.x + "/" + rectangleDeviceShots.highlight.y)

                // save state
                if (deviceSavedState && shotsView.currentIndex != 0)
                    deviceSavedState.selectedIndex = shotsView.currentIndex
            }
            onCurrentItemChanged: {
                //console.log("onCurrentItemChanged() item: " + shotsview.currentItem)
                //shotsview.currentItem.visible = false;
                //console.log("onCurrentItemChanged() item: " + shotsview.currentItem.shot.name)

                //screenDeviceShots.selectionList.push(shotsview.currentItem.shot.name)
            }

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

            model: currentDevice ? currentDevice.shotFilter : null
            delegate: ItemShot { width: shotsView.cellSize; cellFormat: shotsView.cellFormat }

            ScrollBar.vertical: ScrollBar { z: 1 }

            flickableChildren: MouseArea {
                id: mouseAreaInsideView
                anchors.fill: parent

                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: {
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
                    screenDevice.state = "stateMediaDetails"
                } else if (event.key === Qt.Key_PageUp) {
                    shotsView.currentIndex = 0
                } else if (event.key === Qt.Key_PageDown) {
                    shotsView.currentIndex = shotsView.count - 1
                } else if ((event.key === Qt.Key_A) && (event.modifiers & Qt.ControlModifier)) {
                    mediaGrid.selectAll()
                } else if (event.key === Qt.Key_Clear) {
                    mediaGrid.exitSelectionMode()
                } else if (event.key === Qt.Key_Menu) {
                    //console.log("shotsview::Key_Menu")
                } else if (event.key === Qt.Key_Delete) {
                    if (selectionMode) {
                        confirmDeleteSingleFilePopup.files = currentDevice.getSelectedPaths(selectionList)
                        confirmDeleteSingleFilePopup.open()
                    } else {
                        var indexes = []
                        indexes.push(shotsView.currentIndex)
                        confirmDeleteSingleFilePopup.files = currentDevice.getSelectedPaths(indexes)
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
