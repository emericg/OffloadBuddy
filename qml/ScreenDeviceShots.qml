import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Controls.Styles 1.3

import com.offloadbuddy.style 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: screenDeviceShots
    width: 1280
    height: 720
    anchors.fill: parent

    property var selectedItem : shotsview.currentItem
    property int selectedItemIndex : shotsview.currentIndex
    property string selectedItemName : shotsview.currentItem.shot.name

    property var selectionList : [] // TODO

    Connections {
        target: myDevice
        onStateUpdated: updateGridViewSettings()
    }

    function restoreState() {
        sliderZoom.value = deviceState.zoomLevel
        comboBox_orderby.currentIndex = deviceState.orderBy
        shotsview.currentIndex = deviceState.selectedIndex
    }

    function updateDeviceHeader() {
        deviceModelText.text = myDevice.brand + " " + myDevice.model;
        deviceSpaceText.text = StringUtils.bytesToString_short(myDevice.spaceUsed) + " used of " + StringUtils.bytesToString_short(myDevice.spaceTotal)
        deviceSpaceBar.value = myDevice.spaceUsedPercent

        if (myDevice.model.includes("HERO7") ||
            myDevice.model.includes("HERO6")) {
            deviceImage.source = "qrc:/cameras/H6.svg"
        } else if (myDevice.model.includes("HERO5")) {
            deviceImage.source = "qrc:/cameras/H5.svg"
        } else if (myDevice.model.includes("Session")) {
            deviceImage.source = "qrc:/cameras/session.svg"
        } else if (myDevice.model.includes("HERO4")) {
            deviceImage.source = "qrc:/cameras/H4.svg"
        } else if (myDevice.model.includes("HERO3") ||
                   myDevice.model.includes("Hero3")) {
            deviceImage.source = "qrc:/cameras/H3.svg"
        } else if (myDevice.model.includes("FUSION")) {
            deviceImage.source = "qrc:/cameras/fusion.svg"
        } else if (myDevice.model.includes("HD2")) {
            deviceImage.source = "qrc:/cameras/H2.svg"
        } else {
            if (myDevice.deviceType === 2)
                deviceImage.source = "qrc:/cameras/generic_smartphone.svg"
            else if (myDevice.deviceType === 3)
                deviceImage.source = "qrc:/cameras/generic_camera.svg"
            else
                deviceImage.source = "qrc:/cameras/generic_actioncam.svg"
        }

        rectangleDelete.stopTheBlink()
    }

    function initGridViewSettings() {
        actionMenu.visible = false

        if (myDevice && myDevice.deviceStorage === 0)
            if (myDevice.deviceType === 2)
                imageEmpty.source = "qrc:/icons/card.svg"
            else
                imageEmpty.source = "qrc:/icons/phone.svg"
        else
            imageEmpty.source = "qrc:/icons/usb.svg"
    }

    function updateGridViewSettings() {
        //console.log("updateGridViewSettings() [device "+ myDevice + "] (state " + myDevice.deviceState + ") (shotcount: " + shotsview.count + ")")

        // restore state
        shotsview.currentIndex = deviceState.selectedIndex

        if (shotsview.count == 0) {
            selectionList = []
            shotsview.currentIndex = -1
        }

        if (myDevice) {
            if (myDevice.deviceState === 1) {
                circleEmpty.visible = true
                loadingFader.start()
            } else if (myDevice.deviceState === 0) {
                loadingFader.stop()
                if (shotsview.count > 0)
                    circleEmpty.visible = false
            }
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

        Image {
            id: deviceImage
            width: 128
            antialiasing: true
            fillMode: Image.PreserveAspectFit
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 8
            source: "qrc:/cameras/generic_actioncam.svg"
        }

        Text {
            id: deviceModelText
            width: 256
            height: 30
            text: "Camera brand & model"
            anchors.top: parent.top
            anchors.topMargin: 28
            anchors.right: deviceImage.left
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            color: ThemeEngine.colorHeaderTitle
            font.bold: true
            font.pixelSize: ThemeEngine.fontSizeHeaderTitle - 2
        }

        Text {
            id: deviceSpaceText
            width: 256
            height: 15
            anchors.right: deviceModelText.right
            anchors.rightMargin: 0
            anchors.top: deviceModelText.bottom
            anchors.topMargin: 8

            text: "64GB available of 128GB"
            color: ThemeEngine.colorHeaderText
            font.pixelSize: ThemeEngine.fontSizeHeaderText
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }

        ProgressBar {
            id: deviceSpaceBar
            width: 256
            height: 16
            anchors.right: deviceModelText.right
            anchors.rightMargin: 0
            anchors.top: deviceSpaceText.bottom
            anchors.topMargin: 8
            value: 0.5
/*
            contentItem: Rectangle {
                    width: deviceSpaceBar.visualPosition * deviceSpaceBar.width
                    height: deviceSpaceBar.height
                    color: ThemeEngine.colorProgressbar
                }
*/
        }

        Rectangle {
            id: rectangleTransfer
            width: 256
            height: 40
            color: "#00000000"
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16

            Rectangle {
                id: rectangleTransferDecorated
                color: ThemeEngine.colorApproved
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
                    myDevice.offloadCopyAll();
                }
            }

            Text {
                id: textTransfer
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Offload content")
                color: ThemeEngine.colorButtonText
                font.bold: true
                font.pixelSize: 16
            }
        }

        Rectangle {
            id: rectangleDelete
            width: 256
            height: 40
            color: "#00000000"
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
                        myDevice.deleteAll();
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
                rectangleDeleteDecorated.color = ThemeEngine.colorDangerZone;
            }

            Rectangle {
                id: rectangleDeleteDecorated
                color: ThemeEngine.colorDangerZone
                width: parent.width
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on color {
                    id: blinkReset
                    running: false
                    loops: Animation.Infinite
                    ColorAnimation { from: ThemeEngine.colorDangerZone; to: "red"; duration: 1000 }
                    ColorAnimation { from: "red"; to: ThemeEngine.colorDangerZone; duration: 1000 }
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
                color: ThemeEngine.colorButtonText
                text: qsTr("Delete ALL content")
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 16
                font.bold: true
                anchors.fill: parent
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
                        myDevice.orderByDate()
                    else if (currentIndex == 1)
                        myDevice.orderByDuration()
                    else if (currentIndex == 2)
                        myDevice.orderByShotType()
                    else if (currentIndex == 3)
                        myDevice.orderByName()
                } else
                    cbinit = true;

                displayText = qsTr("Order by:") + " " + cbShotsOrderby.get(currentIndex).text

                // save state
                deviceState.orderBy = currentIndex
            }
        }

        Slider {
            id: sliderZoom
            y: 72
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
                    shotsview.cellSize = 160;
                } else  if (value == 2.0) {
                    shotsview.cellSize = 256;
                } else  if (value == 3.0) {
                    shotsview.cellSize = 400;
                }

                // save state
                deviceState.zoomLevel = value
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
        id: rectangleDeviceShots
        color: ThemeEngine.colorContentBackground

        anchors.top: rectangleHeader.bottom
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.bottom: parent.bottom

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
            onMenuSelected: rectangleDeviceShots.actionMenuTriggered(index)
            onVisibleChanged: shotsview.interactive = !shotsview.interactive
        }
        function actionMenuTriggered(index) {
            //console.log("actionMenuTriggered(" + index + ") selected shot: '" + shotsview.currentItem.shot.name + "'")

            if (index === 1)
                myDevice.offloadCopySelected(shotsview.currentItem.shot.name)
            if (index === 2)
                myDevice.offloadMergeSelected(shotsview.currentItem.shot.name)
            if (index === 3)
                myDevice.reencodeSelected(shotsview.currentItem.shot.name)
            if (index === 4)
                myDevice.deleteSelected(shotsview.currentItem.shot.name)

            actionMenu.visible = false
        }

        ScrollView {
            id: scrollView
            anchors.fill: parent

            GridView {
                id: shotsview

                //Component.onCompleted: initGridViewStuff()
                onCountChanged: updateGridViewSettings()
                onCurrentIndexChanged: {
                    // save state
                    if (shotsview.currentIndex != 0)
                        deviceState.selectedIndex = shotsview.currentIndex
                }

                flickableChildren: MouseArea {
                    id: mouseAreaInsideView
                    anchors.fill: parent

                    acceptedButtons: Qt.AllButtons
                    onClicked: {
                        screenDeviceShots.selectionList = []
                        shotsview.currentIndex = -1
                        actionMenu.visible = false
                    }
                }

                property int cellSize: 256
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

                model: myDevice.shotFilter
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
