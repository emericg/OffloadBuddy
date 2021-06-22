import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0
import com.offloadbuddy.shared 1.0
import "qrc:/js/UtilsString.js" as UtilsString
import "qrc:/js/UtilsDeviceCamera.js" as UtilsDevice

Item {
    id: mediaGrid
    width: 1280
    height: 720
    anchors.fill: parent

    property var selectedItem : shotsView.currentItem
    property int selectedItemIndex : shotsView.currentIndex
    property string selectedItemUuid: shotsView.currentItem ? shotsView.currentItem.shot.uuid : ""

    ////////////////////////////////////////////////////////////////////////////

    property bool selectionMode: false
    property var selectionList: []
    property int selectionCount: 0

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
            if (currentDevice && currentDevice.getShotByProxyIndex(i))
                currentDevice.getShotByProxyIndex(i).selected = false;
        }

        // save state
        if (deviceSavedState) {
            deviceSavedState.selectionMode = selectionMode
            deviceSavedState.selectionList = selectionList
            deviceSavedState.selectionCount = selectionCount
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Connections {
        target: currentDevice
        onStateUpdated: updateGridState()
        onStorageUpdated: updateStorage()
        onBatteryUpdated: updateBattery()
    }

    function restoreState() {
        if (typeof currentDevice === "undefined" || !currentDevice) return
        //console.log("ScreenDeviceGrid.restoreState()")

        // Grid filters and settings
        comboBox_orderby.currentIndex = deviceSavedState.orderBy
        comboBox_filterby.currentIndex = deviceSavedState.filterBy
        shotsView.setThumbFormat()

        // Banner // TODO reopen ONLY if needed
        if (currentDevice.deviceStorage === 1) { // VFS
            bannerMessage.openMessage(qsTr("Previews are not available (yet) with MTP devices..."))
        } else if (currentDevice.deviceStorage === 2) { // MTP
            bannerMessage.openMessage(qsTr("Metadata are not available from MTP devices. Offload media first, or plug SD cards directly."))
        } else {
            bannerMessage.close()
        }

        // Grid index
        if (deviceSavedState.selectedIndex >= 0 && deviceSavedState.selectedIndex < shotsView.count)
            shotsView.currentIndex = deviceSavedState.selectedIndex
        else
            shotsView.currentIndex = -1

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

        // Header picture
        deviceImage.source = UtilsDevice.getDevicePicture(currentDevice)

        // Storage and battery infos
        updateStorage()
        updateBattery()
    }

    function updateBattery() {
        if (typeof currentDevice === "undefined" || !currentDevice) return
        //console.log("ScreenDeviceGrid.updateBattery() batteryLevel: " + currentDevice.batteryLevel)
    }

    function updateStorage() {
        if (typeof currentDevice === "undefined" || !currentDevice) return
        //console.log("ScreenDeviceGrid.updateStorage() storageLevel: " + currentDevice.storageLevel)

        if (currentDevice.spaceTotal > 0) {
            if (currentDevice.getStorageCount() === 1) {
                deviceSpaceBar0.value = currentDevice.storageLevel
                deviceSpaceBar0.vsu = currentDevice.spaceUsed
                deviceSpaceBar0.vst = currentDevice.spaceTotal

            } else if (currentDevice.getStorageCount() > 1) {
                deviceSpaceBar0.value = currentDevice.getStorageLevel(2)
                deviceSpaceBar1.value = currentDevice.getStorageLevel(1)
            }
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
            if (shotsView.count <= 0) {
                rectangleTransfer.visible = false
                rectangleDelete.visible = false
            } else {
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
        } else {
            // Restore grid index
            if (deviceSavedState)
                if (deviceSavedState.selectedIndex >= 0 && deviceSavedState.selectedIndex < shotsView.count)
                    shotsView.currentIndex = deviceSavedState.selectedIndex
                else
                    shotsView.currentIndex = -1
        }
    }

    // POPUPS //////////////////////////////////////////////////////////////////

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

    PopupOffload {
        id: popupOffload

        onConfirmed: {
            //currentDevice.offloadAll(popupOffload.selectedPath)
        }
    }

    PopupDelete {
        id: popupDelete

        onConfirmed: {
/*
            // all
            currentDevice.deleteAll()

            // multi
            var indexes = mediaGrid.selectionList
            currentDevice.deleteSelection(indexes)

            // selected shot
            currentDevice.deleteSelected(selectedItemUuid)
            shotsView.currentIndex = -1
            mediaGrid.exitSelectionMode()
*/
        }
    }

    // HEADER //////////////////////////////////////////////////////////////////

    Rectangle {
        id: rectangleHeader
        height: 128
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        z: 1
        color: Theme.colorHeader

        DragHandler {
            // Drag on the sidebar to drag the whole window // Qt 5.15+
            // Also, prevent clicks below this area
            acceptedButtons: Qt.AllButtons
            onActiveChanged: if (active) appWindow.startSystemMove()
            target: null
        }

        ////////////////

        ImageSvg {
            id: deviceImage
            z: 5
            width: 128
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8

            fillMode: Image.PreserveAspectCrop
            color: Theme.colorHeaderContent

            Row {
                id: lilIcons
                height: 28
                anchors.right: parent.right
                anchors.rightMargin: -16
                anchors.bottom: parent.bottom
                layoutDirection: Qt.RightToLeft
/*
                ItemImageButton {
                    id: deviceSettings
                    height: 28
                    btnSize: 28
                    imgSize: 24
                    background: true
                    source: "qrc:/assets/icons_material/baseline-memory-24px.svg"
                }
*/
                ItemImageButtonTooltip {
                    id: deviceRO
                    height: 28
                    btnSize: 28
                    imgSize: 24
                    background: true
                    source: "qrc:/assets/icons_material/outline-https-24px.svg"
                    iconColor: Theme.colorWarning
                    tooltipText: "Read Only storage"
                    tooltipPosition: "left"

                    visible: currentDevice.readOnly
                }
            }
        }

        ////////////////

        Column {
            anchors.right: deviceImage.left
            anchors.rightMargin: 8
            anchors.verticalCenter: deviceImage.verticalCenter
            width: 256
            spacing: 4

            Text {
                id: deviceModel
                anchors.right: parent.right

                text: currentDevice.brand + " " + currentDevice.model
                color: Theme.colorHeaderContent
                font.bold: true
                font.pixelSize: Theme.fontSizeHeader
            }

            Text {
                id: deviceFirmware
                anchors.right: parent.right
                visible: currentDevice.deviceType > 3

                text: qsTr("firmware") + " " + currentDevice.firmware
                color: Theme.colorHeaderContent
                font.pixelSize: Theme.fontSizeContentSmall
            }
/*
            Text {
                anchors.right: parent.right
                visible: currentDevice.deviceType > 3

                text: qsTr("serial") + " " + currentDevice.serial
                color: Theme.colorHeaderContent
                font.pixelSize: Theme.fontSizeContentSmall
            }
*/
            DataBarSpace {
                id: deviceSpaceBar0
                width: 256
                height: 12

                visible: currentDevice.getStorageCount() > 0
                value: currentDevice.storageLevel
                valueMin: 0
                valueMax: 100
            }
            DataBarSpace {
                id: deviceSpaceBar1
                width: 256
                height: 12

                visible: currentDevice.getStorageCount() > 1
                value: currentDevice.storageLevel
                valueMin: 0
                valueMax: 100
            }

            DataBarPower {
                id: deviceBatteryBar0
                width: 256
                height: 12

                visible: currentDevice.batteryLevel > 0
                value: currentDevice.batteryLevel
                valueMin: 0
                valueMax: 100
            }
        }

        ////////////////

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
                            currentDevice.orderByDate()
                        else if (currentIndex == 1)
                            currentDevice.orderByDuration()
                        else if (currentIndex == 2)
                            currentDevice.orderByShotType()
                        else if (currentIndex == 3)
                            currentDevice.orderByName()
                        else if (currentIndex == 4)
                            currentDevice.orderByPath()
                    } else {
                        cbinit = true
                    }

                    displayText = qsTr("Order by:") + " " + cbShotsOrderby.get(currentIndex).text

                    // save state
                    if (deviceSavedState) deviceSavedState.orderBy = currentIndex
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
                            currentDevice.orderByDesc()
                        } else {
                            ascDesc = true
                            currentDevice.orderByAsc()
                        }
                    }
                }
            }

            ComboBoxThemed {
                id: comboBox_filterby
                width: 240

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

                        currentDevice.filterByType(cbMediaFilters.get(currentIndex).text)

                        if (currentIndex === 0)
                            displayText = cbMediaFilters.get(currentIndex).text // "No filter"
                        else
                            displayText = qsTr("Filter by:") + " " + cbMediaFilters.get(currentIndex).text
                    } else {
                        cbinit = true;
                    }

                    // save state
                    if (deviceSavedState) deviceSavedState.filterBy = currentIndex
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
                            deviceSavedState.thumbFormat = 1
                            shotsView.setThumbFormat()
                        }
                    }
                    ItemLilMenuButton {
                        text: "4:3"
                        selected: (shotsView.cellFormat === 4/3)
                        onClicked: {
                            deviceSavedState.thumbFormat = 2
                            shotsView.setThumbFormat()
                        }
                    }
                    ItemLilMenuButton {
                        text: "16:9"
                        selected: (shotsView.cellFormat === 16/9)
                        onClicked: {
                            deviceSavedState.thumbFormat = 3
                            shotsView.setThumbFormat()
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
                            deviceSavedState.thumbSize = 1
                            shotsView.setThumbFormat()
                        }
                    }
                    ItemLilMenuButton {
                        source: "qrc:/assets/icons_material/baseline-photo-24px.svg"
                        sourceSize: 22
                        selected: (shotsView.cellSizeTarget === 279)
                        onClicked: {
                            deviceSavedState.thumbSize = 2
                            shotsView.setThumbFormat()
                        }
                    }
                    ItemLilMenuButton {
                        source: "qrc:/assets/icons_material/baseline-photo-24px.svg"
                        sourceSize: 26
                        selected: (shotsView.cellSizeTarget === 376)
                        onClicked: {
                            deviceSavedState.thumbSize = 3
                            shotsView.setThumbFormat()
                        }
                    }
                    ItemLilMenuButton {
                        source: "qrc:/assets/icons_material/baseline-photo-24px.svg"
                        sourceSize: 30
                        selected: (shotsView.cellSizeTarget === 512)
                        onClicked: {
                            deviceSavedState.thumbSize = 4
                            shotsView.setThumbFormat()
                        }
                    }
                }
            }
        }

        ////////

        ButtonWireframe {
            id: rectangleTransfer
            width: 240
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16

            fullColor: true
            primaryColor: Theme.colorPrimary

            text: qsTr("Offload content")
            onClicked: popupOffload.openAll()
        }

        ButtonWireframe {
            id: rectangleDelete
            width: 240
            anchors.left: rectangleTransfer.right
            anchors.leftMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16

            fullColor: true
            primaryColor: Theme.colorError
            text: qsTr("Delete ALL content!")
            onClicked: popupDelete.openAll()
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

        ItemBannerMessage {
            id: bannerMessage
        }
    }

    // CONTENT /////////////////////////////////////////////////////////////////

    Item {
        id: rectangleDeviceGrid

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
                radius: (Theme.componentRadius > 4) ? Theme.componentRadius-2 : 2
                border.width: (Theme.componentRadius > 4) ? 6 : 4
                border.color: Theme.colorPrimary
            }
        }

        ////////

        ActionMenu {
            id: actionMenu
            z: 7
            onMenuSelected: rectangleDeviceGrid.actionMenuTriggered(index)
        }
        function actionMenuTriggered(index) {
            //console.log("actionMenuTriggered(" + index + ") selected shot: '" + shotsView.currentItem.shot.name + "'")

            var indexes = []
            if (mediaGrid.selectionMode) {
                indexes = selectionList
            } else {
                indexes.push(shotsView.currentIndex)
            }

            if (index === 1) {
                popupOffload.shots = currentDevice.getSelectedShotsNames(indexes)
                popupOffload.files = currentDevice.getSelectedFilesPaths(indexes)
                popupOffload.openSelection()
            }
            if (index === 3) {
                popupEncoding.updateEncodePanel(selectedItem.shot)
                popupEncoding.openSingle(selectedItem.shot)
            }
            if (index === 12) {
                shotsView.currentItem.shot.openFile()
            }
            if (index === 13) {
                shotsView.currentItem.shot.openFolder()
            }
            if (index === 16) {
                popupDelete.shots = currentDevice.getSelectedShotsNames(indexes)
                popupDelete.files = currentDevice.getSelectedFilesPaths(indexes)
                popupDelete.openSelection()
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
            focus: (appContent.state === "device" && screenLibrary.state === "stateMediaGrid")

            onCountChanged: updateGridViewSettings()
            onWidthChanged: computeCellSize()

            Component.onCompleted: {
                mediaGrid.exitSelectionMode()
                shotsView.currentIndex = -1
                actionMenu.visible = false
            }

            Connections {
                target: settingsManager
                onThumbFormatChanged: {
                    if (deviceSavedState) {
                        deviceSavedState.thumbFormat = settingsManager.thumbFormat
                        shotsView.computeCellSize()
                    }
                }
                onThumbSizeChanged: {
                    if (deviceSavedState) {
                        deviceSavedState.thumbSize = settingsManager.thumbSize
                        shotsView.computeCellSize()
                    }
                }
            }

            ////////

            property real cellFormat
            property int cellSizeTarget
            property int cellSize: cellSizeTarget
            property int cellMarginTarget: 12
            property int cellMargin: 12

            //property int cellMargin: (parent.width%cellSize) / Math.floor(parent.width/cellSize);
            cellWidth: cellSize + cellMargin
            cellHeight: Math.round(cellSize / cellFormat) + cellMargin

            function setThumbFormat() {
                if (deviceSavedState.thumbFormat === 1)
                    shotsView.cellFormat = 1.0
                else if (deviceSavedState.thumbFormat === 2)
                    shotsView.cellFormat = 4/3
                else if (deviceSavedState.thumbFormat === 3)
                    shotsView.cellFormat = 16/9

                if (deviceSavedState.thumbSize === 1)
                    shotsView.cellSizeTarget = 221
                else if (deviceSavedState.thumbSize === 2)
                    shotsView.cellSizeTarget = 279
                else if (deviceSavedState.thumbSize === 3)
                    shotsView.cellSizeTarget = 376
                else if (deviceSavedState.thumbSize === 4)
                    shotsView.cellSizeTarget = 512

                shotsView.computeCellSize()
            }

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

            onCurrentIndexChanged: {
                //console.log("onCurrentIndexChanged() selected index: " + shotsView.currentIndex)
                //console.log("onCurrentIndexChanged() selected item: " + shotsView.currentItem)
                //console.log("onCurrentIndexChanged() selected row/column: " + shotsView.childAt())
                //console.log("onCurrentIndexChanged() selected shot: " + selectedItem)
                //console.log("onCurrentIndexChanged() selected shots [ " + selectionList + "]")

                // save state
                if (deviceSavedState)
                    if (shotsView.currentIndex >= 0 && shotsView.currentItem != null)
                        deviceSavedState.selectedIndex = shotsView.currentIndex
            }
            onCurrentItemChanged: {
                //console.log("onCurrentItemChanged() index: " + shotsView.currentIndex)
                //console.log("onCurrentItemChanged() item: " + shotsView.currentItem)
                //console.log("onCurrentItemChanged() item: " + shotsView.currentItem.shot.name)
            }

            ////////

            model: currentDevice ? currentDevice.shotFilter : null
            delegate: ItemShot { width: shotsView.cellSize; cellFormat: shotsView.cellFormat; }

            ScrollBar.vertical: ScrollBar { z: 1 }

            highlight: itemHighlight
            highlightMoveDuration: 0

            flickableChildren: MouseArea {
                id: mouseAreaInsideView
                anchors.fill: parent

                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: {
                    mediaGrid.exitSelectionMode()
                    shotsView.currentIndex = -1
                    deviceSavedState.selectedIndex = -1
                    actionMenu.visible = false
                }
            }

            Keys.onPressed: {
                actionMenu.visible = false

                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    screenMedia.loadShot(currentDevice.getShotByUuid(screenDeviceGrid.selectedItemUuid))
                } else if (event.key === Qt.Key_PageUp) {
                    shotsView.currentIndex = 0
                } else if (event.key === Qt.Key_PageDown) {
                    shotsView.currentIndex = shotsView.count - 1
                } else if ((event.key === Qt.Key_A) && (event.modifiers & Qt.ControlModifier)) {
                    mediaGrid.selectAll()
                } else if (event.key === Qt.Key_Clear) {
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
                    popupDelete.shots = currentDevice.getSelectedShotsNames(indexes)
                    popupDelete.files = currentDevice.getSelectedFilesPaths(indexes)
                    popupDelete.openSelection()
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
