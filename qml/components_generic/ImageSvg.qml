import QtQuick 2.12
import QtGraphicalEffects 1.12 // Qt5
//import Qt5Compat.GraphicalEffects // Qt6

Item {
    implicitWidth: 32
    implicitHeight: 32

    property alias source: sourceImg.source
    property string color

    property alias smooth: sourceImg.smooth
    property alias fillMode: sourceImg.fillMode
    property alias asynchronous: sourceImg.asynchronous

    Image {
        id: sourceImg
        anchors.fill: parent
        visible: parent.color ? false : true

        sourceSize: Qt.size(width, height)

        smooth: false
        fillMode: Image.PreserveAspectFit
        asynchronous: false
    }

    ColorOverlay {
        source: sourceImg
        anchors.fill: sourceImg
        visible: parent.color ? true : false

        cached: true
        color: parent.color
    }
}
