import QtQuick 2.9
import QtQuick.Controls 2.2

import com.offloadbuddy.theme 1.0
import "UtilsString.js" as UtilsString

Rectangle {
    id: banner
    z: 1
    height: 56
    color: Theme.colorInfoBanner

    anchors.top: parent.top
    anchors.topMargin: 0
    anchors.left: parent.left
    anchors.leftMargin: 0
    anchors.right: parent.right
    anchors.rightMargin: 0

    Component.onCompleted: {
        banner.close()
    }

    function openMessage(message) {
        banner.visible = true
        banner.height = 56
        bannerText.text = message
    }

    function close() {
        banner.visible = false
        banner.height = 0
    }

    Text {
        id: bannerText
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: "banner text"
        color: Theme.colorInfoBannerText
        font.pixelSize: Theme.fontSizeBannerText
    }

    ImageSvg {
        id: image
        width: 40
        height: 40
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        fillMode: Image.PreserveAspectFit

        source: "qrc:/icons_material/baseline-close-24px.svg"
        color: Theme.colorInfoBannerText

        MouseArea {
            anchors.fill: parent
            onClicked: banner.close()
        }
    }
}
