import QtQuick 2.12

import ThemeEngine 1.0

Item {
    id: badge
    implicitWidth: 128
    implicitHeight: 22

    property string legend: "legend"
    property string text: "text"

    signal clicked()

    Rectangle {
        id: leftRect
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: leftText.right
        anchors.rightMargin: -6
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        color: "#555555"
    }

    Rectangle {
        id: rightRect
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.left: leftRect.right
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        color: "#97ca00"
    }

    Text {
        id: leftText
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter

        color: "white"
        text: badge.legend
        textFormat: Text.PlainText
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 12
    }

    Text {
        id: rightText
        anchors.left: rightRect.left
        anchors.leftMargin: 6
        anchors.right: rightRect.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter

        color: "white"
        text: badge.text
        textFormat: Text.PlainText
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 12
        font.bold: true
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: badge.clicked()
    }
}
