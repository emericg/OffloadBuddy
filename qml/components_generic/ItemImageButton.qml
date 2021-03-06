import QtQuick 2.12

import ThemeEngine 1.0
import "qrc:/js/UtilsNumber.js" as UtilsNumber

Item {
    id: itemImageButton
    implicitWidth: 40
    implicitHeight: 40

    // states
    signal clicked()
    signal longClicked()
    property bool highlighted: false
    property bool selected: false

    // settings
    property int btnSize: height
    property int imgSize: UtilsNumber.alignTo(height * 0.666, 2)

    property bool background: false
    property bool border: false

    property string highlightMode: "circle" // circle / color / both / off

    property string iconColor: Theme.colorIcon
    property string highlightColor: Theme.colorPrimary
    property string backgroundColor: Theme.colorComponent
    property string borderColor: Theme.colorComponentBorder

    property url source: ""

    ////////////////////////////////////////////////////////////////////////////

    MouseArea {
        anchors.fill: bgRect
        onClicked: itemImageButton.clicked()
        onPressAndHold: itemImageButton.longClicked()

        hoverEnabled: true
        onEntered: {
            itemImageButton.highlighted = true
            bgRect.opacity = (highlightMode === "circle" || highlightMode === "both" || itemImageButton.background) ? 1 : 0.75
        }
        onExited: {
            itemImageButton.highlighted = false
            bgRect.opacity = itemImageButton.background ? 0.75 : 0
        }
    }

    Rectangle {
        id: bgRect
        width: btnSize
        height: btnSize
        radius: btnSize
        anchors.verticalCenter: itemImageButton.verticalCenter

        visible: (highlightMode === "circle" || highlightMode === "both" || itemImageButton.background)
        color: itemImageButton.backgroundColor

        border.width: itemImageButton.border ? Theme.componentBorderWidth : 0
        border.color: itemImageButton.borderColor

        opacity: itemImageButton.background ? 0.75 : 0
        Behavior on opacity { NumberAnimation { duration: 333 } }
    }

    ImageSvg {
        id: contentImage
        width: imgSize
        height: imgSize
        anchors.centerIn: bgRect

        source: itemImageButton.source
        opacity: itemImageButton.enabled ? 1.0 : 0.33
        color: {
            if (selected === true) {
                itemImageButton.highlightColor
            } else if (highlightMode === "color" || highlightMode === "both") {
                itemImageButton.highlighted ? itemImageButton.highlightColor : itemImageButton.iconColor
            } else {
                itemImageButton.iconColor
            }
        }
    }
}
