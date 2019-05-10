import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0
import "UtilsString.js" as UtilsString

Rectangle {
    id: screenDeviceGrid
    width: 1280
    height: 720
    anchors.fill: parent

    property var selectedItem : shotsview.currentItem
    property int selectedItemIndex : shotsview.currentIndex
    property string selectedItemName : shotsview.currentItem ? shotsview.currentItem.shot.name : ""
    //property string selectedItemPath : shotsview.currentItem ? shotsview.currentItem.shot.path : ""

    property var selectionList : [] // TODO

    Connections {
        target: currentDevice
        onStateUpdated: screenDeviceGrid.updateGridViewSettings()
        onDeviceUpdated: screenDeviceGrid.updateDeviceHeader()
        onStorageUpdated: updateStorage()
        onBatteryUpdated: updateBattery()
    }

    function restoreState() {
        sliderZoom.value = deviceSavedState.zoomLevel
        comboBox_orderby.currentIndex = deviceSavedState.orderBy
        comboBox_filterby.currentIndex = deviceSavedState.filterBy
        shotsview.currentIndex = deviceSavedState.selectedIndex
    }

    function updateBattery() {
        //console.log("currentDevice.batteryLevel" + currentDevice.batteryLevel)
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
        //console.log("currentDevice.storageLevel" + currentDevice.storageLevel)
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

    function updateDeviceHeader() {
        // Header
        if (currentDevice.batteryLevel > 0.0 && currentDevice.storageLevel > 0.0)
            deviceModelText.anchors.topMargin = 12
        else if (currentDevice.batteryLevel <= 0.0 && currentDevice.storageLevel <= 0.0)
            deviceModelText.anchors.topMargin = 38
        else
            deviceModelText.anchors.topMargin = 26

        deviceModelText.text = currentDevice.brand + " " + currentDevice.model;

        if (currentDevice.model.includes("HERO7 White") ||
            currentDevice.model.includes("HERO7 Silver")) {
            deviceImage.source = "qrc:/cameras/H7w.svg"
        } else if (currentDevice.model.includes("HERO7") ||
            currentDevice.model.includes("HERO6")) {
            deviceImage.source = "qrc:/cameras/H6.svg"
        } else if (currentDevice.model.includes("HERO5")) {
            deviceImage.source = "qrc:/cameras/H5.svg"
        } else if (currentDevice.model.includes("Session")) {
            deviceImage.source = "qrc:/cameras/session.svg"
        } else if (currentDevice.model.includes("HERO4")) {
            deviceImage.source = "qrc:/cameras/H4.svg"
        } else if (currentDevice.model.includes("HERO3") ||
                   currentDevice.model.includes("Hero3")) {
            deviceImage.source = "qrc:/cameras/H3.svg"
        } else if (currentDevice.model.includes("FUSION") ||
                   currentDevice.model.includes("Fusion")) {
            deviceImage.source = "qrc:/cameras/fusion.svg"
        } else if (currentDevice.model.includes("HD2")) {
            deviceImage.source = "qrc:/cameras/H2.svg"
        } else {
            if (currentDevice.deviceType === 2)
                deviceImage.source = "qrc:/cameras/generic_smartphone.svg"
            else if (currentDevice.deviceType === 3)
                deviceImage.source = "qrc:/cameras/generic_camera.svg"
            else
                deviceImage.source = "qrc:/cameras/generic_actioncam.svg"
        }

        // Storage and battery infos
        updateStorage()
        updateBattery()

        // Banner
        banner.close()
        if (currentDevice.deviceStorage === 1) { // VFS
            banner.openMessage(qsTr("Previews are not available (yet) with MTP devices..."))
        }
        if (currentDevice.deviceStorage === 2) { // MTP
            banner.openMessage(qsTr("Metadatas are not available from MTP devices. Offload medias first, or plug SD cards directly."))
        }
    }

    function initGridViewSettings() {
        rectangleTransfer.visible = false
        rectangleDelete.stopTheBlink()
        rectangleDelete.visible = false
        actionMenu.visible = false

        if (currentDevice && currentDevice.deviceStorage === 0)
            if (currentDevice.deviceType === 2)
                imageEmpty.source = "qrc:/devices/card.svg"
            else
                imageEmpty.source = "qrc:/devices/phone.svg"
        else
            imageEmpty.source = "qrc:/devices/usb.svg"
    }

    function updateGridViewSettings() {
        //console.log("updateGridViewSettings() [device "+ currentDevice + "]
        //    (state " + currentDevice.deviceState + ") (shotcount: " + shotsview.count + ")")

        // restore state
        if (deviceSavedState)
            shotsview.currentIndex = deviceSavedState.selectedIndex

        if (shotsview.count == 0) {
            selectionList = []
            shotsview.currentIndex = -1
        }

        if (currentDevice) {
            if (currentDevice.deviceState === 1) { // scanning
                circleEmpty.visible = true
                loadingFader.start()
            } else if (currentDevice.deviceState === 0) { // idle
                loadingFader.stop()
                if (shotsview.count > 0) {
                    circleEmpty.visible = false
                    rectangleTransfer.visible = true

                    if (currentDevice.readOnly === true)
                        rectangleDelete.visible = false
                    else
                        rectangleDelete.visible = true
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
        background: Item {
            //
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

        Image {
            id: deviceImage
            opacity: 0.8
            width: 128
            antialiasing: true
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 8

            source: "qrc:/cameras/generic_actioncam.svg"
            sourceSize.width: deviceImage.width
            sourceSize.height: deviceImage.height
            fillMode: Image.PreserveAspectCrop
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

        Item {
            id: rectangleTransfer
            width: 240
            height: 40
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16

            Rectangle {
                id: rectangleTransferDecorated
                color: Theme.colorPrimary
                width: parent.width
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
            }

            MouseArea {
                anchors.fill: parent
                onPressed: {
                    rectangleTransferDecorated.width = rectangleTransferDecorated.width - 8
                    rectangleTransferDecorated.height = rectangleTransferDecorated.height - 8
                }
                onReleased: {
                    rectangleTransferDecorated.width = rectangleTransferDecorated.width + 8
                    rectangleTransferDecorated.height = rectangleTransferDecorated.height + 8
                }
                onClicked: {
                    currentDevice.offloadAll();
                }
            }

            Text {
                id: textTransfer
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Offload content")
                color: "white"
                font.bold: true
                font.pixelSize: 15
            }
        }

        Item {
            id: rectangleDelete
            width: 240
            height: 40
            anchors.left: rectangleTransfer.right
            anchors.leftMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16

            property bool weAreBlinking: false
            property double startTime: 0

            function startTheBlink() {
                if (weAreBlinking === true) {
                    if ((new Date().getTime() - startTime) > 500) {
                        stopTheBlink();
                        currentDevice.deleteAll();
                    }
                } else {
                    startTime = new Date().getTime()
                    weAreBlinking = true;
                    timerReset.start();
                    blinkReset.start();
                    textReset.text = qsTr("!!! CONFIRM !!!");
                }
            }
            function stopTheBlink() {
                weAreBlinking = false;
                timerReset.stop();
                blinkReset.stop();
                textReset.text = qsTr("Delete ALL content!");
                rectangleDeleteDecorated.color = Theme.colorWarning;
            }

            Rectangle {
                id: rectangleDeleteDecorated
                color: Theme.colorWarning
                width: parent.width
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on color {
                    id: blinkReset
                    running: false
                    loops: Animation.Infinite
                    ColorAnimation { from: Theme.colorWarning; to: "red"; duration: 1000 }
                    ColorAnimation { from: "red"; to: Theme.colorWarning; duration: 1000 }
                }
            }

            Timer {
                id: timerReset
                interval: 4000
                running: false
                repeat: false
                onTriggered: {
                    rectangleDelete.stopTheBlink()
                }
            }

            MouseArea {
                anchors.fill: parent

                onPressed: {
                    rectangleDeleteDecorated.width = rectangleDeleteDecorated.width - 8
                    rectangleDeleteDecorated.height = rectangleDeleteDecorated.height - 8
                }
                onReleased: {
                    rectangleDeleteDecorated.width = rectangleDeleteDecorated.width + 8
                    rectangleDeleteDecorated.height = rectangleDeleteDecorated.height + 8
                }
                onClicked: {
                    rectangleDelete.startTheBlink()
                }
            }

            Text {
                id: textReset
                color: "white"
                text: qsTr("Delete ALL content")
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 15
                font.bold: true
                anchors.fill: parent
            }
        }

        ComboBoxThemed {
            id: comboBox_orderby
            width: 200
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
                        currentDevice.orderByDate()
                    else if (currentIndex == 1)
                        currentDevice.orderByDuration()
                    else if (currentIndex == 2)
                        currentDevice.orderByShotType()
                    else if (currentIndex == 3)
                        currentDevice.orderByName()
                } else
                    cbinit = true;

                displayText = qsTr("Order by:") + " " + cbShotsOrderby.get(currentIndex).text

                // save state
                if (deviceSavedState)
                    deviceSavedState.orderBy = currentIndex
            }
        }

        ComboBoxThemed {
            id: comboBox_filterby
            width: 200
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
                    currentDevice.filterByType(cbMediaFilters.get(currentIndex).text)

                    if (currentIndex == 0)
                        displayText = cbMediaFilters.get(currentIndex).text
                    else
                        displayText = qsTr("Filter by:") + " " + cbMediaFilters.get(currentIndex).text
                } else
                    cbinit = true;

                // save state
                if (deviceSavedState)
                    deviceSavedState.filterBy = currentIndex
            }
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
                    shotsview.cellSizeTarget = 450;
                    shotsview.computeCellSize();
                }

                // save state
                if (deviceSavedState)
                    deviceSavedState.zoomLevel = value
            }
        }

        Text {
            id: textZoom
            height: 40
            anchors.verticalCenter: comboBox_filterby.verticalCenter
            anchors.left: comboBox_filterby.right
            anchors.leftMargin: 16

            text: qsTr("ZOOM")
            font.pixelSize: Theme.fontSizeHeaderText
            color: Theme.colorHeaderContent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // CONTENT /////////////////////////////////////////////////////////////////

    Item {
        id: rectangleDeviceShots

        anchors.top: rectangleHeader.bottom
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.bottom: parent.bottom

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
            onMenuSelected: rectangleDeviceShots.actionMenuTriggered(index)
            onVisibleChanged: shotsview.interactive = !shotsview.interactive
        }
        function actionMenuTriggered(index) {
            //console.log("actionMenuTriggered(" + index + ") selected shot: '" + selectedItemName + "'")

            if (index === 0)
                shotsview.currentItem.shot.openFolder()
            if (index === 1)
                currentDevice.offloadCopySelected(selectedItemName)
            if (index === 2)
                currentDevice.offloadMergeSelected(selectedItemName)
            if (index === 3) {
                panelEncode.updateEncodePanel(selectedItem.shot)
                popupEncode.open()
            }
            if (index === 16)
                currentDevice.deleteSelected(selectedItemName)

            actionMenu.visible = false
        }

        ItemBanner {
            id: banner
        }

        GridView {
            id: shotsview
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.topMargin: banner.height + 16

            interactive: true
            //snapMode: GridView.SnapToRow
            //clip: true
            //keyNavigationEnabled: true
            //focus: true

            onCountChanged: updateGridViewSettings()
            Component.onCompleted: { currentIndex = -1 }

            property real cellFormat: 4/3
            property int cellSizeTarget: 279
            property int cellSize: 279
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
                if (deviceSavedState && shotsview.currentIndex != 0)
                    deviceSavedState.selectedIndex = shotsview.currentIndex
            }
            onCurrentItemChanged: {
                //console.log("onCurrentItemChanged() item: " + shotsview.currentItem)
                //shotsview.currentItem.visible = false;
                //console.log("onCurrentItemChanged() item: " + shotsview.currentItem.shot.name)

                //screenDeviceShots.selectionList.push(shotsview.currentItem.shot.name)
            }
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

            model: currentDevice ? currentDevice.shotFilter : null
            delegate: ItemShot { width: shotsview.cellSize; cellFormat: shotsview.cellFormat }

            ScrollBar.vertical: ScrollBar { z: 1 }

            flickableChildren: MouseArea {
                id: mouseAreaInsideView
                anchors.fill: parent

                acceptedButtons: Qt.AllButtons
                onClicked: {
                    screenDeviceGrid.selectionList = []
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
        }
    }
}
