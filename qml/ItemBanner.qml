import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

import com.offloadbuddy.style 1.0
import "StringUtils.js" as StringUtils

Rectangle {
    id: banner
    z: 1
    height: 56
    color: ThemeEngine.colorInfoBanner

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
        color: ThemeEngine.colorInfoBannerText
        font.pixelSize: ThemeEngine.fontSizeBannerText
    }
    
    Image {
        id: image
        width: 40
        height: 40
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        fillMode: Image.PreserveAspectFit
        
        source: "qrc:/icons_material/baseline-close-24px.svg"
        sourceSize.width: 40
        sourceSize.height: 40
        
        ColorOverlay {
            anchors.fill: parent
            source: parent
            color: ThemeEngine.colorInfoBannerText
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: banner.close()
        }
    }
}
