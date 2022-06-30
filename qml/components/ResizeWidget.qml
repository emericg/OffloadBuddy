import QtQuick 2.15
import QtQuick.Controls 2.15
//import QtGraphicalEffects 1.15 // Qt5
import Qt5Compat.GraphicalEffects // Qt6

import ThemeEngine 1.0
import MediaUtils 1.0

Item {
    id: resizeWidget
    implicitWidth: 720
    implicitHeight: 720
    anchors.fill: parent

    property bool editing: false
    property string grid: "rulesofthree"

    visible: (resizeWidget.editing ||
              gismo.arEnum !== mediaUtils.arFromGeometry(shot.widthVisible, shot.heightVisible) ||
              gismo.fx > 0.0 || gismo.fy > 0.0 || gismo.fwidth < 1.0 || gismo.fheight < 1.0)

    function load() {
        editing = false

        // Load values from project
        gismo.fx = shot.cropX
        gismo.fy = shot.cropY
        gismo.fcx = shot.cropX + (shot.cropW / 2)
        gismo.fcy = shot.cropY + (shot.cropH / 2)
        gismo.fwidth = shot.cropW
        gismo.fheight = shot.cropH

        // Restore on screen coordinates
        gismo.restoreCoord()
    }
    function save() {
        // Save on screen coordinates
        gismo.saveCoord()

        // Save values to project
        shot.cropX = gismo.fx
        shot.cropY = gismo.fy
        shot.cropW = gismo.fwidth
        shot.cropH = gismo.fheight
    }
    function reset() {
        resizeWidget.editing = false
        gismo.resetCoord()
        shot.cropX = gismo.fx
        shot.cropY = gismo.fy
        shot.cropW = gismo.fwidth
        shot.cropH = gismo.fheight
    }

    ////////////////////////////////////////////////////////////////////////////
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
    Connections {
        target: shot
        function userSettingsUpdated() {
            //
        }
    }
*/
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

        ////////

        property bool arLock: shot.cropARlock
        property real arFloat: mediaUtils.arToFloat(shot.cropAR)
        property int arEnum: shot.cropAR

        property int minWidth: 256
        property int minHeight: 256

        ////////

        property real fx: 0.0
        property real fy: 0.0
        property real fcx: 0.5
        property real fcy: 0.5
        property real fwidth: 1.0
        property real fheight: 1.0

        function saveCoord() {
            fx = (gismo.x / resizeWidget.width)
            fy = (gismo.y / resizeWidget.height)
            fwidth =  (gismo.width / resizeWidget.width)
            fheight =  (gismo.height / resizeWidget.height)
            fcx = fx + fwidth/2
            fcy = fy + fheight/2

            //console.log("saveCoord() > fx : " + fx.toFixed(2) + " > fy "+ fy.toFixed(2) +
            //            " > fcx "+ fcx.toFixed(2) + " > fcy "+ fcy.toFixed(2) +
            //            " > fwidth "+ fwidth.toFixed(2) + " > fheight "+ fheight.toFixed(2))
        }

        function resetCoord() {
            fx = 0.0
            fy = 0.0
            fcx = 0.5
            fcy = 0.5
            fwidth = 1.0
            fheight = 1.0

            gismo.x = 0
            gismo.y = 0
            gismo.width = resizeWidget.width
            gismo.height = resizeWidget.height
        }

        function restoreCoord() {
            restoreCoordFromFx()        // for regular content
            //restoreCoordFromCenter()  // for 360 'sizeless' content
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
            //console.log("restoreCoordFromCenter()")

            if (gismo.arLock) {
                var sar = resizeWidget.width/ resizeWidget.height
                if (sar > gismo.arFloat) {
                    gismo.width = (fheight * resizeWidget.height) * gismo.arFloat
                    gismo.height = (fheight * resizeWidget.height)
                } else {
                    gismo.width = (fwidth * resizeWidget.width)
                    gismo.height = (fwidth * resizeWidget.width) / gismo.arFloat
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
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            property bool isDragging: false
            property var globalMouseOffset

            onPressed: (mouse) => {
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
            onPositionChanged: (mouse) => {
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

        ////////////////

        Item {
            id: grid_rulesofthree
            anchors.fill: parent

            visible: (editing && grid === "rulesofthree")
            clip: true

            Repeater {
                model: 2
                Rectangle {
                    x: (index + 1) * (parent.width / 3)
                    y: -overlays.height
                    width: 1; height: overlays.height*2;
                    color: Theme.colorSeparator
                    opacity: 0.33
                }
            }
            Repeater {
                model: 2
                Rectangle {
                    x: -overlays.width
                    y: (index + 1) * (parent.height / 3)
                    width: overlays.width*2; height: 1;
                    color: Theme.colorSeparator
                    opacity: 0.33
                }
            }
        }
        Item {
            id: grid_phi
            anchors.fill: parent

            visible: (editing && grid === "phi")
            clip: true

            Rectangle {
                x: parent.width * 0.618
                y: -overlays.height
                width: 1; height: overlays.height*2;
                color: Theme.colorSeparator
                opacity: 0.33
            }
            Rectangle {
                x: parent.width - (parent.width * 0.618)
                y: -overlays.height
                width: 1; height: overlays.height*2;
                color: Theme.colorSeparator
                opacity: 0.33
            }
            Rectangle {
                x: -overlays.width
                y: parent.height * 0.618
                width: overlays.width*2; height: 1;
                color: Theme.colorSeparator
                opacity: 0.33
            }
            Rectangle {
                x: -overlays.width
                y: parent.height - (parent.height * 0.618)
                width: overlays.width*2; height: 1;
                color: Theme.colorSeparator
                opacity: 0.33
            }
        }

        ////////////////

        // controls
        Row {
            anchors.right: buttonLock.left
            anchors.rightMargin: 8
            anchors.verticalCenter: buttonLock.verticalCenter
            spacing: 8

            visible: (resizeWidget.editing && gismo.arLock)

            RoundButtonText {
                id: button43
                width: 32; height: 32;

                background: true
                backgroundColor: "#222222"
                highlightMode: "color"
                textColor: (shot.cropAR === MediaUtils.AspectRatio_4_3) ? Theme.colorPrimary : "white"

                text: "4:3"
                onClicked: {
                    shot.cropAR = MediaUtils.AspectRatio_4_3
                    gismo.restoreCoordFromCenter()
                }
            }
            RoundButtonText {
                id: button169
                width: 32; height: 32;

                background: true
                backgroundColor: "#222222"
                highlightMode: "color"
                textColor: (shot.cropAR === MediaUtils.AspectRatio_16_9) ? Theme.colorPrimary : "white"

                text: "16:9"
                onClicked: {
                    shot.cropAR = MediaUtils.AspectRatio_16_9
                    gismo.restoreCoordFromCenter()
                }
            }
            RoundButtonText {
                id: button219
                width: 32; height: 32;

                background: true
                backgroundColor: "#222222"
                highlightMode: "color"
                textColor: (shot.cropAR === MediaUtils.AspectRatio_21_9) ? Theme.colorPrimary : "white"

                text: "21:9"
                onClicked: {
                    shot.cropAR = MediaUtils.AspectRatio_21_9
                    gismo.restoreCoordFromCenter()
                }
            }
        }
        RoundButtonIcon {
            id: buttonLock
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8

            background: true
            backgroundColor: "#222222"
            highlightMode: "color"
            iconColor: (shot.cropARlock) ? Theme.colorPrimary : "white"

            visible: resizeWidget.editing
            source: "qrc:/assets/icons_material/outline-https-24px.svg"
            onClicked: {
                shot.cropARlock = !shot.cropARlock
            }
        }
        Column {
            anchors.top: buttonLock.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: buttonLock.horizontalCenter
            spacing: 8

            visible: (resizeWidget.editing && gismo.arLock)

            RoundButtonText {
                id: button34
                width: 32; height: 32;

                background: true
                backgroundColor: "#222222"
                highlightMode: "color"
                textColor: (shot.cropAR === MediaUtils.AspectRatio_3_4) ? Theme.colorPrimary : "white"

                text: "3:4"
                onClicked: {
                    shot.cropAR = MediaUtils.AspectRatio_3_4
                    gismo.restoreCoordFromCenter()
                }
            }
            RoundButtonText {
                id: button916
                width: 32; height: 32;

                background: true
                backgroundColor: "#222222"
                highlightMode: "color"
                textColor: (shot.cropAR === MediaUtils.AspectRatio_9_16) ? Theme.colorPrimary : "white"

                text: "9:16"
                onClicked: {
                    shot.cropAR = MediaUtils.AspectRatio_9_16
                    gismo.restoreCoordFromCenter()
                }
            }
            RoundButtonText {
                id: button921
                width: 32; height: 32;

                background: true
                backgroundColor: "#222222"
                highlightMode: "color"
                textColor: (shot.cropAR === MediaUtils.AspectRatio_9_21) ? Theme.colorPrimary : "white"

                text: "9:21"
                onClicked: {
                    shot.cropAR = MediaUtils.AspectRatio_9_21
                    gismo.restoreCoordFromCenter()
                }
            }
        }


        Row {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            spacing: 8

            RoundButtonIcon {
                id: buttonReset
                iconColor: "white"
                background: true
                backgroundColor: "#222222"
                highlightMode: "color"

                visible: resizeWidget.editing
                source: "qrc:/assets/icons_material/baseline-close-24px.svg"
                onClicked: resizeWidget.reset()
            }
            RoundButtonIcon {
                id: buttonValidate
                iconColor: "white"
                background: true
                backgroundColor: "#222222"
                highlightMode: "color"

                visible: resizeWidget.editing
                source: "qrc:/assets/icons_material/baseline-done-24px.svg"
                onClicked: resizeWidget.editing = false
            }
        }

        ////////////////

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

            onPressed: (mouse) => {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: (mouse) => {
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

            onPressed: (mouse) => {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: (mouse) => {
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

            onPressed: (mouse) => {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: (mouse) => {
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

            onPressed: (mouse) => {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: (mouse) => {
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

            onPressed: (mouse) => {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: (mouse) => {
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

            onPressed: (mouse) => {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: (mouse) => {
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

            onPressed: (mouse) => {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: (mouse) => {
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

            onPressed: (mouse) => {
                isResizing = true
                gismo.initOriginals(mouse.x, mouse.y)
                gismo.originalMouseOffset = mapToItem(gismo, mouse.x, mouse.y)
            }
            onReleased: isResizing = false
            onPositionChanged: (mouse) => {
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
            //console.log("> resize() > " +
            //            "> up: " + up.toFixed(0) + " > left: "+ left.toFixed(0) +
            //            " > right: "+ right.toFixed(0) + " > down: "+ down.toFixed(0))

            // clamp single direction
            if (up && !left && !right && !down && gismo.originalY + up < 0) up = -gismo.originalY
            if (!up && left && !right && !down && gismo.originalX + left < 0) left = -gismo.originalX
            if (!up && !left && right && !down && gismo.originalX + gismo.originalWidth + right > resizeWidget.width) right = resizeWidget.width - gismo.originalX - gismo.originalWidth
            if (!up && !left && !right && down && gismo.originalY + gismo.originalHeight + down > resizeWidget.height) down = resizeWidget.height - gismo.originalY - gismo.originalHeight

            var changeUp = up
            var changeLeft = left
            var changeRight = right
            var changeDown = down

            if (up && modifier) changeDown = -up*2
            else if (up) changeDown = -up

            if (left && modifier) changeRight = -left*2
            else if (left) changeRight = -left

            if (right && modifier) { changeLeft = -right; changeRight += right; }
            if (down && modifier) { changeUp = -down; changeDown += down; }

            //console.log("> changeUp: " + changeUp.toFixed(0) + " > changeLeft: "+ changeLeft.toFixed(0) + " " +
            //            "> changeRight: "+ changeRight.toFixed(0) + " > changeDown: "+ changeDown.toFixed(0))

            var newx = gismo.originalX + changeLeft
            var newy = gismo.originalY + changeUp
            var newwidth = gismo.originalWidth + changeRight
            var newheight = gismo.originalHeight + changeDown

            if (!gismo.arLock) {

                if (modifier && (newwidth < minWidth || newheight < minHeight)) return

                if (newx < 0) { newwidth += newx; newx = 0; }
                if (newx + newwidth > resizeWidget.width) newwidth = resizeWidget.width - newx

                if (newy < 0) { newheight += newy; newy = 0; }
                if (newy + newheight > resizeWidget.height) newheight = resizeWidget.height - newy

            } else if (gismo.arLock) {

                if (up && right) { ////

                    newheight = Math.ceil(newwidth / gismo.arFloat)
                    newy = gismo.originalY + gismo.originalHeight - newheight

                    if (modifier) newy = gismo.originalY + ((gismo.originalHeight - newheight) / 2)

                    // clamp values
                    if (newy < 0) {
                        //console.log("clamp diag u/r (newy < 0)")
                        newheight += newy
                        newwidth = Math.ceil(newheight * gismo.arFloat)
                        newy = 0
                    }
                    // clamp values
                    if (newy + newheight > resizeWidget.height) {
                        //console.log("clamp diag u/r (newy + newheight > resizeWidget.height)")
                        newheight = resizeWidget.height - newy
                        newwidth = Math.ceil(newheight * gismo.arFloat)
                    }
                    // clamp values
                    if (newx + newwidth > resizeWidget.width) {
                        //console.log("clamp diag u/r (newx + newwidth > resizeWidget.width)")
                        newwidth = resizeWidget.width - newx
                        newheight = Math.ceil(newwidth / gismo.arFloat)
                        newy = gismo.originalY + gismo.originalHeight - newheight
                    }

                } else if (down && left) { ////

                    newheight = Math.ceil(newwidth / gismo.arFloat)

                    if (modifier) newy = gismo.originalY + ((gismo.originalHeight - newheight) / 2)

                    // clamp values
                    if (newx < 0) {
                        //console.log("clamp diag d/l (newx < 0)")
                        newwidth += newx
                        newheight = Math.ceil(newwidth / gismo.arFloat)
                        newx = 0
                    }
                    // clamp values
                    if (gismo.originalY + newheight > resizeWidget.height) {
                        //console.log("clamp diag d/l (gismo.originalY + newheight > resizeWidget.height)")
                        newheight = resizeWidget.height - newy
                        newwidth = Math.ceil(newheight * gismo.arFloat)
                        newx = gismo.originalX + originalWidth - newwidth
                    }

                } else if ((left || right) && !up) { ////

                    newheight = Math.ceil(newwidth / gismo.arFloat)
                    if (left) newy = gismo.originalY + gismo.originalHeight - newheight

                    if (modifier) newy = gismo.originalY + ((gismo.originalHeight - newheight) / 2)

                    // clamp values
                    if (left && newy < 0) {
                        //console.log("clamp l/r (left && newy < 0)")
                        newheight += newy
                        newwidth = Math.ceil(newheight * gismo.arFloat)
                        newx = gismo.originalX + gismo.originalWidth - newwidth
                        newy = 0
                    }
                    // clamp values
                    if (right && newx + newwidth > resizeWidget.width) {
                        //console.log("clamp l/r (right && newx + newwidth > resizeWidget.width)")
                        newwidth = resizeWidget.width - newx
                        newheight = Math.ceil(newwidth / gismo.arFloat)
                        newy = gismo.originalY
                    }
                    // clamp values
                    if (newy + newheight > resizeWidget.height) {
                        //console.log("clamp l/r (newy + newheight > resizeWidget.height)")
                        newheight = resizeWidget.height - newy
                        newwidth = Math.ceil(newheight * gismo.arFloat)
                        newx = gismo.originalX
                    }

                } else if (up || down) { //////

                    newwidth = Math.ceil(newheight * gismo.arFloat)
                    if (up) newx = gismo.originalX + gismo.originalWidth - newwidth

                    if (modifier) newx = gismo.originalX + ((gismo.originalWidth - newwidth) / 2)

                    // clamp values
                    if (up && newx < 0) {
                        //console.log("clamp u/p (up && newx < 0)")
                        newwidth += newx
                        newheight = (newwidth / gismo.arFloat)
                        newx = 0
                        newy = gismo.originalY + gismo.originalHeight - newheight
                    }
                    if (up && newy < 0) {
                        //console.log("clamp u/p (up && newy < 0)")
                        newheight += newy
                        newwidth = Math.ceil(newheight * gismo.arFloat)
                        newy = 0
                        newx = gismo.originalX + gismo.originalWidth - newwidth
                    }
                    // clamp values
                    if (down &&  gismo.originalX + newwidth > resizeWidget.width) {
                        //console.log("clamp u/p (!up && gismo.originalX + newwidth > resizeWidget.width)")
                        newwidth = resizeWidget.width - newx
                        newheight = (newwidth / gismo.arFloat)
                        newy = gismo.originalY
                    }
                }
            }

            gismo.x = newx
            gismo.y = newy
            gismo.width = newwidth
            gismo.height = newheight

            // Check minimum sizes
            if (gismo.arLock) {
                if (arFloat > 1) {
                    if (gismo.height < gismo.minHeight) resize_minHeight(up, left, right, down)
                    else if (gismo.width < gismo.minWidth) resize_minWidth(up, left, right, down)
                } else if (arFloat < 1) {
                    if (gismo.width < gismo.minWidth) resize_minWidth(up, left, right, down)
                    else if (gismo.height < gismo.minHeight) resize_minHeight(up, left, right, down)
                }
            } else {
                if (gismo.width < gismo.minWidth) resize_minWidth(up, left, right, down)
                if (gismo.height < gismo.minHeight)resize_minHeight(up, left, right, down)
            }

            resizeWidget.save()
        }

        function resize_minWidth(up, left, right, down) {
            //console.log("MIN WIDTH > " + gismo.width)

            gismo.width = gismo.minWidth
            if (gismo.arLock) gismo.height = Math.ceil(gismo.minWidth / gismo.arFloat)

            if (!(down && left) && (down || right)) gismo.x = gismo.originalX
            else gismo.x = gismo.originalX + gismo.originalWidth - gismo.minWidth

            if (!(up && right) && (down || right)) gismo.y = gismo.originalY
            else gismo.y = gismo.originalY + gismo.originalHeight - gismo.height
        }
        function resize_minHeight(up, left, right, down) {
            //console.log("MIN HEIGHT > " + gismo.height)

            gismo.height = gismo.minHeight
            if (gismo.arLock) gismo.width = Math.ceil(gismo.minHeight * gismo.arFloat)

            if (!(up && right) && (down || right)) gismo.y = gismo.originalY
            else gismo.y = gismo.originalY + gismo.originalHeight - gismo.minHeight

            if (!(down && left) && (down || right)) gismo.x = gismo.originalX
            else gismo.x = gismo.originalX + gismo.originalWidth - gismo.width
        }
    }
}
