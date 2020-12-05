import QtQuick 2.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.12

import ThemeEngine 1.0

Item {
    id: resizeWidget
    implicitWidth: 720
    implicitHeight: 720
    anchors.fill: parent
/*
    onWidthChanged: {
        gismo.restoreCoord()
    }
    onHeightChanged: {
        gismo.restoreCoord()
    }
    Component.onCompleted: {
        gismo.restoreCoord()
    }
*/
    property bool editing: false
    property real projectAR: 16/9
    property bool projectARlock: true
    property string grid: "rulesofthree"

    visible: editing || gismo.fx > 0.0 || gismo.fy > 0.0 || gismo.fwidth < 1.0 || gismo.fheight < 1.0

    function reset() {
        gismo.fx = 0.0
        gismo.fy = 0.0
        gismo.fcx = 0.5
        gismo.fcy = 0.5
        gismo.fwidth = 1.0
        gismo.fheight = 1.0
        editing = false
    }

    function load() {
        editing = false
/*
        // Load values from project file
        gismo.fx = project.cropX
        gismo.fy = project.cropY
        gismo.fcx = project.cropX + (project.cropW / 2)
        gismo.fcy = project.cropY + (project.cropH / 2)
        gismo.fwidth = project.cropW
        gismo.fheight = project.cropH
*/
        //
        gismo.fx = mediaArea.cropX
        gismo.fy = mediaArea.cropY
        gismo.fcx = mediaArea.cropX + (mediaArea.cropW / 2)
        gismo.fcy = mediaArea.cropY + (mediaArea.cropH / 2)
        gismo.fwidth = mediaArea.cropW
        gismo.fheight = mediaArea.cropH

        // Restore on screen coordinates
        gismo.restoreCoord()
    }
    function save() {
        // Save on screen coordinates
        gismo.saveCoord()

        //
        mediaArea.cropX = gismo.fx
        mediaArea.cropY = gismo.fy
        mediaArea.cropW = gismo.fwidth
        mediaArea.cropH = gismo.fheight
/*
        // Save values to project file
        project.cropX = gismo.fx
        project.cropY = gismo.fy
        project.cropW = gismo.fwidth
        project.cropH = gismo.fheight
*/
    }

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: gismo.top
        color: "black"
        opacity: 0.4
    }
    Rectangle {
        anchors.top: gismo.top
        anchors.left: parent.left
        anchors.right: gismo.left
        anchors.bottom: gismo.bottom
        color: "black"
        opacity: 0.4
    }
    Rectangle {
        anchors.top: gismo.top
        anchors.left: gismo.right
        anchors.right: parent.right
        anchors.bottom: gismo.bottom
        color: "black"
        opacity: 0.4
    }
    Rectangle {
        anchors.top: gismo.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "black"
        opacity: 0.4
    }

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        id: gismo

        x: 0
        y: 0
        width: 0
        height: 0

        property real ar: resizeWidget.projectAR
        property bool arLock: resizeWidget.projectARlock
        property int minWidth: 128
        property int minHeight: 128

        ////////

        property real fx: 0.0
        property real fy: 0.0
        property real fcx: 0.5
        property real fcy: 0.5
        property real fwidth: 1.0
        property real fheight: 1.0

        function saveCoord() {
            fx = gismo.x / resizeWidget.width
            fy = gismo.y / resizeWidget.height
            fcx = (gismo.x / resizeWidget.width) + (gismo.width / 2)
            fcy = (gismo.y / resizeWidget.height) + (gismo.height / 2)
            fwidth =  gismo.width / resizeWidget.width
            fheight =  gismo.height / resizeWidget.height

            //console.log("> fx : " + fx.toFixed(2) + " > fy "+ fy.toFixed(2) +
            //            " > fwidth "+ fwidth.toFixed(2) + " > fheight "+ fheight.toFixed(2))
        }

        function restoreCoord() {
            restoreCoordFromFx() // DEPRECATED
            //restoreCoordFromCenter()
        }

        function restoreCoordFromFx() {
            if (fwidth <= 0 || fheight <= 0) return
            //console.log("restoreCoordFromFx()")

            gismo.x = fx * resizeWidget.width
            gismo.y = fy * resizeWidget.height
            gismo.width = fwidth * resizeWidget.width
            gismo.height = fheight * resizeWidget.height
        }
        function restoreCoordFromCenter() {
            if (fwidth <= 0 || fheight <= 0) return
            //console.log("restoreCoordFromCenter")

            if (resizeWidget.projectARlock) {
                var sar = resizeWidget.width/ resizeWidget.height
                if (sar > resizeWidget.projectAR) {
                    gismo.width = (fheight * resizeWidget.height) * resizeWidget.projectAR
                    gismo.height = (fheight * resizeWidget.height)
                } else {
                    gismo.width = (fwidth * resizeWidget.width)
                    gismo.height = (fwidth * resizeWidget.width) / resizeWidget.projectAR
                }
            } else {
                gismo.width = fwidth * resizeWidget.width
                gismo.height = fheight * resizeWidget.height
            }

            gismo.x = (fcx * resizeWidget.width) - (gismo.width / 2)
            gismo.y = (fcy * resizeWidget.height) - (gismo.height / 2)
        }

        ////////

        property var originalMouseOffset
        property int originalX: 0
        property int originalY: 0
        property int originalWidth: 0
        property int originalHeight: 0

        function initOriginals(mouseXX, mouseYY) {
            //gismo.originalMouseOffset = mapToItem(gismo, mouseXX, mouseYY)
            gismo.originalX = gismo.x
            gismo.originalY = gismo.y
            gismo.originalWidth = gismo.width
            gismo.originalHeight = gismo.height
        }

        ////////

        color: "transparent"
        border.color: "#99ffffff"
        border.width: editing ? 1 : 0

        MouseArea {
            id: mouseAreaDrag
            anchors.fill: parent

            enabled: editing
            acceptedButtons: Qt.AllButtons

            property bool isDragging: false
            property var globalMouseOffset

            onPressed: {
                //console.log("mouseAreaDrag::onPressed()")
/*
                var positionInArea = mapToItem(gismo, mouse.x, mouse.y)
                var positionInParent = mapToItem(resizeWidget, mouse.x, mouse.y)
                var positionInWindow = mapToItem(appWindow.contentItem, mouse.x, mouse.y)
                var globalPosition = mapToGlobal(mouse.x, mouse.y)

                console.log("> root: " + positionInArea)
                console.log("> root: " + positionInParent)
                console.log("> window: " + positionInWindow)
                console.log("> system: " + globalPosition)
*/
                mouseAreaDrag.isDragging = true
                globalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: {
                //console.log("mouseAreaDrag::onReleased()")
                if (mouseAreaDrag.isDragging) mouseAreaDrag.isDragging = false
            }
            onPositionChanged: {
                //console.log("mouseAreaDrag::onPositionChanged()")
                if (mouseAreaDrag.isDragging) {
                    var globalMouse = mapToItem(resizeWidget, mouse.x, mouse.y)
                    var newPosX = globalMouse.x - globalMouseOffset.x
                    var newPosY = globalMouse.y - globalMouseOffset.y

                    if (newPosX <= 0) gismo.x = 0
                    else if (newPosX + gismo.width > resizeWidget.width) gismo.x = resizeWidget.width - gismo.width
                    else gismo.x = newPosX

                    if (newPosY <= 0) gismo.y = 0
                    else if (newPosY + gismo.height > resizeWidget.height) gismo.y = resizeWidget.height - gismo.height
                    else gismo.y = newPosY

                    resizeWidget.save()
                }
            }
        }

        ////////////////////

        Item {
            id: grid_rulesofthree
            anchors.fill: parent
            visible: editing && grid === "rulesofthree"

            Repeater {
                model: 2
                Rectangle {
                    x: (index + 1) * (parent.width / 3);
                    y: -overlays.height
                    width: 1; height: overlays.height*2;
                    color: Theme.colorSeparator;
                    opacity: 0.33;
                }
            }
            Repeater {
                model: 2
                Rectangle {
                    x: -overlays.width
                    y: (index + 1) * (parent.height / 3);
                    width: overlays.width*2; height: 1;
                    color: Theme.colorSeparator;
                    opacity: 0.33;
                }
            }
        }
        Item {
            id: grid_phi
            anchors.fill: parent
            visible: editing && grid === "phi"

            Rectangle {
                x: parent.width * 0.618
                y: -overlays.height
                width: 1; height: overlays.height*2;
                color: Theme.colorSeparator;
                opacity: 0.33;
            }
            Rectangle {
                x: parent.width - (parent.width * 0.618);
                y: -overlays.height
                width: 1; height: overlays.height*2;
                color: Theme.colorSeparator;
                opacity: 0.33;
            }
            Rectangle {
                x: -overlays.width
                y: parent.height * 0.618
                width: overlays.width*2; height: 1;
                color: Theme.colorSeparator;
                opacity: 0.33;
            }
            Rectangle {
                x: -overlays.width
                y: parent.height - (parent.height * 0.618);
                width: overlays.width*2; height: 1;
                color: Theme.colorSeparator;
                opacity: 0.33;
            }
        }

        ////////////////////

        // controls
        Row {
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.right: buttonLock.left
            anchors.rightMargin: 8
            spacing: 8

            visible: resizeWidget.editing && resizeWidget.projectARlock

            ItemTextButton {
                id: button43
                width: 32; height: 32;

                background: true
                backgroundColor: "#222222"
                highlightMode: "color"
                textColor: (resizeWidget.projectAR == 4/3) ? Theme.colorPrimary : "white"

                text: "4:3"
                onClicked: {
                    resizeWidget.projectAR = 4/3
                }
            }
            ItemTextButton {
                id: button169
                width: 32; height: 32;

                background: true
                backgroundColor: "#222222"
                highlightMode: "color"
                textColor: (resizeWidget.projectAR == 16/9) ? Theme.colorPrimary : "white"

                text: "16:9"
                onClicked: {
                    resizeWidget.projectAR = 16/9
                }
            }
            ItemTextButton {
                id: button219
                width: 32; height: 32;

                background: true
                backgroundColor: "#222222"
                highlightMode: "color"
                textColor: (resizeWidget.projectAR == 21/9) ? Theme.colorPrimary : "white"

                text: "21:9"
                onClicked: {
                    resizeWidget.projectAR = 21/9
                }
            }
        }
        ItemImageButton {
            id: buttonLock
            width: 32; height: 32;
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 8

            visible: resizeWidget.editing
            background: true
            backgroundColor: "#222222"
            highlightMode: "color"
            iconColor: (resizeWidget.projectARlock) ? Theme.colorPrimary : "white"

            source: "qrc:/assets/icons_material/outline-https-24px.svg"
            onClicked: {
                resizeWidget.projectARlock = !resizeWidget.projectARlock
            }
        }
        Column {
            anchors.top: buttonLock.bottom
            anchors.topMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8
            spacing: 8

            visible: resizeWidget.editing && resizeWidget.projectARlock

            ItemTextButton {
                id: button34
                width: 32; height: 32;

                background: true
                backgroundColor: "#222222"
                highlightMode: "color"
                textColor: (resizeWidget.projectAR == 3/4) ? Theme.colorPrimary : "white"

                text: "3:4"
                onClicked: {
                    resizeWidget.projectAR = 3/4
                }
            }
            ItemTextButton {
                id: button916
                width: 32; height: 32;

                background: true
                backgroundColor: "#222222"
                highlightMode: "color"
                textColor: (resizeWidget.projectAR == 9/16) ? Theme.colorPrimary : "white"

                text: "9:16"
                onClicked: {
                    resizeWidget.projectAR = 9/16
                }
            }
            ItemTextButton {
                id: button921
                width: 32; height: 32;

                background: true
                backgroundColor: "#222222"
                highlightMode: "color"
                textColor: (resizeWidget.projectAR == 9/21) ? Theme.colorPrimary : "white"

                text: "9:21"
                onClicked: {
                    resizeWidget.projectAR = 9/21
                }
            }
        }

        ItemImageButton {
            id: buttonValidate
            width: 32; height: 32;
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8

            visible: resizeWidget.editing
            background: true
            backgroundColor: "#222222"
            highlightMode: "color"
            iconColor: highlighted ? Theme.colorPrimary : "white"

            source: "qrc:/assets/icons_material/baseline-done-24px.svg"
            onClicked: resizeWidget.editing = false
        }

        ////////////////////

        MouseArea { // top
            id: mouseAreaTOP
            width: 32
            height: 16
            anchors.top: parent.top
            anchors.topMargin: -8
            anchors.horizontalCenter: parent.horizontalCenter

            enabled: editing
            visible: editing

            hoverEnabled: true
            onEntered: isHovered = true
            onExited: isHovered = false

            property bool isHovered: false
            property bool isResizing: false

            onPressed: {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: {
                if (isResizing) {
                    var globalMouse = mapToItem(resizeWidget, mouse.x, mouse.y)
                    var changeY = globalMouse.y - gismo.originalY - gismo.originalMouseOffset.y

                    var modifier = (mouse.modifiers & Qt.ControlModifier)
                    gismo.resize(modifier, changeY, 0, 0, 0)
                }
            }

            Rectangle {
                width: 32; height: 5;
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 1

                color: "white"
                opacity: mouseAreaTOP.isHovered ? 1: 0.8
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
/*
            Rectangle {
                anchors.fill: parent
                color: "white"
                radius: 2
                opacity: mouseAreaTOP.isHovered ? 0.75: 0.33
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
*/
        }

        ////////////////

        MouseArea { // left
            id: mouseAreaLEFT
            width: 16
            height: 32
            anchors.left: parent.left
            anchors.leftMargin: -8
            anchors.verticalCenter: parent.verticalCenter

            enabled: editing
            visible: editing

            hoverEnabled: true
            onEntered: isHovered = true
            onExited: isHovered = false

            property bool isHovered: false
            property bool isResizing: false

            onPressed: {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: {
                if (isResizing) {
                    var globalMouse = mapToItem(resizeWidget, mouse.x, mouse.y)
                    var changeX = globalMouse.x - gismo.originalX - gismo.originalMouseOffset.x

                    var modifier = (mouse.modifiers & Qt.ControlModifier)
                    gismo.resize(modifier, 0, changeX, 0, 0)
                }
            }

            Rectangle {
                width: 5; height: 32;
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: 1

                color: "white"
                opacity: mouseAreaLEFT.isHovered ? 1: 0.8
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
/*
            Rectangle {
                anchors.fill: parent
                color: "white"
                radius: 2
                opacity: mouseAreaLEFT.isHovered ? 0.75: 0.33
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
*/
        }

        ////////

        MouseArea { // right
            id: mouseAreaRIGHT
            width: 16
            height: 32
            anchors.right: parent.right
            anchors.rightMargin: -8
            anchors.verticalCenter: parent.verticalCenter

            enabled: editing
            visible: editing

            hoverEnabled: true
            onEntered: isHovered = true
            onExited: isHovered = false

            property bool isHovered: false
            property bool isResizing: false

            onPressed: {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: {
                if (isResizing) {
                    var globalMouse = mapToItem(resizeWidget, mouse.x, mouse.y)
                    var changeX = globalMouse.x - gismo.originalX - gismo.originalMouseOffset.x

                    var modifier = (mouse.modifiers & Qt.ControlModifier)
                    gismo.resize(modifier, 0, 0, changeX, 0)
                }
            }

            Rectangle {
                width: 5; height: 32;
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: 0

                color: "white"
                opacity: mouseAreaLEFT.isHovered ? 1: 0.8
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
/*
            Rectangle {
                anchors.fill: parent
                color: "white"
                radius: 2
                opacity: mouseAreaLEFT.isHovered ? 0.75: 0.33
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
*/
        }

        ////////

        MouseArea { // bottom
            id: mouseAreaBOTTOM
            width: 32
            height: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -8
            anchors.horizontalCenter: parent.horizontalCenter

            enabled: editing
            visible: editing

            hoverEnabled: true
            onEntered: isHovered = true
            onExited: isHovered = false

            property bool isHovered: false
            property bool isResizing: false

            onPressed: {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: {
                if (isResizing) {
                    var globalMouse = mapToItem(resizeWidget, mouse.x, mouse.y)
                    var changeY = globalMouse.y - gismo.originalY - gismo.originalMouseOffset.y

                    var modifier = (mouse.modifiers & Qt.ControlModifier)
                    gismo.resize(modifier, 0, 0, 0, changeY)
                }
            }

            Rectangle {
                width: 32; height: 5;
                anchors.verticalCenter: parent.verticalCenter

                color: "white"
                opacity: mouseAreaBOTTOM.isHovered ? 1: 0.8
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
/*
            Rectangle {
                anchors.fill: parent
                color: "white"
                radius: 2
                opacity: mouseAreaBOTTOM.isHovered ? 0.75: 0.33
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
*/
        }

        ////////////////

        MouseArea { // top left corner
            id: areaCorner_TopLeft
            width: 28
            height: 28
            anchors.top: parent.top
            anchors.topMargin: -10
            anchors.left: parent.left
            anchors.leftMargin: -10

            enabled: editing
            visible: editing

            hoverEnabled: true
            onEntered: isHovered = true
            onExited: isHovered = false

            property bool isHovered: false
            property bool isResizing: false

            onPressed: {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: {
                if (isResizing) {
                    var globalMouse = mapToItem(resizeWidget, mouse.x, mouse.y)
                    var changeX = globalMouse.x - gismo.originalX - gismo.originalMouseOffset.x
                    var changeY = globalMouse.y - gismo.originalY - gismo.originalMouseOffset.y

                    var modifier = (mouse.modifiers & Qt.ControlModifier)
                    gismo.resize(modifier, changeY, changeX, 0, 0)
                }
            }
/*
            Rectangle {
                anchors.fill: parent
                color: "white"
                radius: 2
                opacity: areaCorner_TopLeft.isHovered ? 0.75: 0.33
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
*/
        }
        Item {
            width: 16; height: 16;
            anchors.top: gismo.top
            anchors.topMargin: -1
            anchors.left: gismo.left
            anchors.leftMargin: -1
            rotation: 0

            //visible: editing
            opacity: areaCorner_TopLeft.isHovered ? 1: 0.8
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Rectangle {
                width: 4; height: 16;
                color: "white"
            }
            Rectangle {
                width: 16; height: 4;
                color: "white"
            }
        }

        ////////

        MouseArea { // top right corner
            id: areaCorner_TopRight
            width: 28
            height: 28
            anchors.top: parent.top
            anchors.topMargin: -10
            anchors.right: parent.right
            anchors.rightMargin: -10

            enabled: editing
            visible: editing

            hoverEnabled: true
            onEntered: isHovered = true
            onExited: isHovered = false

            property bool isHovered: false
            property bool isResizing: false

            onPressed: {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: {
                if (isResizing) {
                    var globalMouse = mapToItem(resizeWidget, mouse.x, mouse.y)
                    var changeX = globalMouse.x - gismo.originalX - gismo.originalMouseOffset.x
                    var changeY = globalMouse.y - gismo.originalY - gismo.originalMouseOffset.y

                    var modifier = (mouse.modifiers & Qt.ControlModifier)
                    gismo.resize(modifier, changeY, 0, changeX, 0)
                }
            }
/*
            Rectangle {
                anchors.fill: parent
                color: "white"
                radius: 2
                opacity: areaCorner_TopRight.isHovered ? 0.75: 0.33
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
*/
        }
        Item {
            width: 16; height: 16;
            anchors.top: gismo.top
            anchors.topMargin: -1
            anchors.right: gismo.right
            anchors.rightMargin: -1
            rotation: 90

            //visible: editing
            opacity: areaCorner_TopRight.isHovered ? 1: 0.8
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Rectangle {
                width: 4; height: 16;
                color: "white"
            }
            Rectangle {
                width: 16; height: 4;
                color: "white"
            }
        }

        ////////

        MouseArea { // bottom right corner
            id: areaCorner_BottomRight
            width: 28
            height: 28
            anchors.right: parent.right
            anchors.rightMargin: -10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -10

            enabled: editing
            visible: editing

            hoverEnabled: true
            onEntered: isHovered = true
            onExited: isHovered = false

            property bool isHovered: false
            property bool isResizing: false

            onPressed: {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: {
                if (isResizing) {
                    var globalMouse = mapToItem(resizeWidget, mouse.x, mouse.y)
                    var changeX = globalMouse.x - gismo.originalX - gismo.originalMouseOffset.x
                    var changeY = globalMouse.y - gismo.originalY - gismo.originalMouseOffset.y

                    var modifier = (mouse.modifiers & Qt.ControlModifier)
                    gismo.resize(modifier, 0, 0, changeX, changeY)
                }
            }
/*
            Rectangle {
                anchors.fill: parent
                color: "white"
                radius: 2
                opacity: areaCorner_BottomRight.isHovered ? 0.75: 0.33
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
*/
        }
        Item {
            width: 16; height: 16;
            anchors.right: gismo.right
            anchors.rightMargin: -1
            anchors.bottom: gismo.bottom
            anchors.bottomMargin: -1
            rotation: 180

            //visible: editing
            opacity: areaCorner_BottomRight.isHovered ? 1: 0.8
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Rectangle {
                width: 4; height: 16;
                color: "white"
            }
            Rectangle {
                width: 16; height: 4;
                color: "white"
            }
        }

        ////////

        MouseArea { // bottom left corner
            id: areaCorner_BottomLeft
            width: 28
            height: 28
            anchors.left: parent.left
            anchors.leftMargin: -10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -10

            enabled: editing
            visible: editing

            hoverEnabled: true
            onEntered: isHovered = true
            onExited: isHovered = false

            property bool isHovered: false
            property bool isResizing: false

            onPressed: {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: {
                if (isResizing) {
                    var globalMouse = mapToItem(resizeWidget, mouse.x, mouse.y)
                    var changeX = globalMouse.x - gismo.originalX - gismo.originalMouseOffset.x
                    var changeY = globalMouse.y - gismo.originalY - gismo.originalMouseOffset.y

                    var modifier = (mouse.modifiers & Qt.ControlModifier)
                    gismo.resize(modifier, 0, changeX, 0,  changeY)
                }
            }
/*
            Rectangle {
                anchors.fill: parent
                color: "white"
                radius: 2
                opacity: areaCorner_BottomLeft.isHovered ? 0.75: 0.33
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
*/
        }
        Item {
            width: 16; height: 16;
            anchors.left: gismo.left
            anchors.leftMargin: -1
            anchors.bottom: gismo.bottom
            anchors.bottomMargin: -1
            rotation: 270

            //visible: editing
            opacity: areaCorner_BottomLeft.isHovered ? 1: 0.8
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Rectangle {
                width: 4; height: 16;
                color: "white"
            }
            Rectangle {
                width: 16; height: 4;
                color: "white"
            }
        }

        ////////////////

        function resize(modifier, up, left, right, down) {
            //console.log("> resize() > +
            //            "> up: " + up.toFixed(0) + " > left: "+ left.toFixed(0) +
            //            " > right: "+ right.toFixed(0) + " > down: "+ down.toFixed(0))

            // clamp values
            if (up && gismo.originalY + up < 0) up = -gismo.originalY
            if (left && gismo.originalX + left < 0) left = -gismo.originalX
            if (right && gismo.originalX + gismo.originalWidth + right > resizeWidget.width) right = resizeWidget.width - gismo.originalX - gismo.originalWidth
            if (down && gismo.originalY + gismo.originalHeight + down > resizeWidget.height) down = resizeWidget.height - gismo.originalY - gismo.originalHeight

            var changeUp = up
            var changeLeft = left
            var changeRight = right
            var changeDown = down

            if (up && modifier) changeDown = -up*2
            else if (up) changeDown = -up

            if (left && modifier) changeRight = -left*2
            else if (left) changeRight = -left

            if (right && modifier) { changeLeft = -right; changeRight += right;}
            if (down && modifier) { changeUp = -down; changeDown += down; }

            //console.log("> changeUp: " + changeUp.toFixed(0) + " > changeLeft: "+ changeLeft.toFixed(0) +
            //            " > changeRight: "+ changeRight.toFixed(0) + " > changeDown: "+ changeDown.toFixed(0))

            gismo.x = gismo.originalX + changeLeft
            gismo.y = gismo.originalY + changeUp
            gismo.width = gismo.originalWidth + changeRight
            gismo.height = gismo.originalHeight + changeDown

            if (gismo.arLock) {
                if (left || right || (up && right) || (down && left)) {
                    gismo.height = gismo.width / gismo.ar
                    if (up) gismo.y = gismo.originalY + gismo.originalHeight - gismo.height
                    if (left && !down) gismo.y = gismo.originalY + gismo.originalHeight - gismo.height
                    if (modifier) gismo.y = gismo.originalY + ((gismo.originalHeight - gismo.height) / 2)
                } else if (up || down) {
                    gismo.width = gismo.height * gismo.ar
                    if (up) gismo.x = gismo.originalX + gismo.originalWidth - gismo.width
                    if (modifier) gismo.x = gismo.originalX + ((gismo.originalWidth - gismo.width) / 2)
                }
            }

            resizeWidget.save()
        }
    }
}
