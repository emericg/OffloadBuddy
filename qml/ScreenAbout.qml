import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

import com.offloadbuddy.theme 1.0

Item {
    width: 1280
    height: 720

    Rectangle {
        id: rectangleHeader
        height: 64
        color: Theme.colorHeader
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        Text {
            id: textHeader
            height: 40
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("ABOUT")
            verticalAlignment: Text.AlignVCenter
            font.bold: true
            font.pixelSize: Theme.fontSizeHeaderTitle
            color: Theme.colorHeaderContent
        }
    }

    Item {
        id: rectangleContent

        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        Image {
            id: imageLogo
            width: 220
            height: 180
            anchors.top: parent.top
            anchors.topMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24
            fillMode: Image.PreserveAspectCrop
            source: "qrc:/appicons/offloadbuddy.png"
        }

        TextArea {
            id: textArea
            anchors.top: parent.top
            anchors.topMargin: 24
            anchors.bottom: imageGitHub.top
            anchors.bottomMargin: 24
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: imageLogo.left

            readOnly: true
            wrapMode: Text.WordWrap
            font.pixelSize: 18
            color: Theme.colorText
            text: "OffloadBuddy is a multimedia offloading software with a few tricks up his sleeve!\nIt's designed to remove the hassle of handling and transferring the many videos and pictures file from your devices like action cameras, regular cameras and smartphones...\n\n* Import datas from SD cards, mass storage or MTP devices\n  - Copy, merge or reencode medias\n  - Consult and export shots metadatas\n  - Organize your media library\n* Create clips or extract photos from your videos\n* Assemble photo timelapses into videos\n* GoPro firmware updates"
            anchors.rightMargin: 24
        }

        Text {
            id: textVersion
            width: 112
            height: 16
            text: qsTr("Version 0.2 (git)")
            anchors.horizontalCenter: imageLogo.horizontalCenter
            anchors.top: imageLogo.bottom
            anchors.topMargin: 6
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeContentText
            color: Theme.colorText
        }

        Text {
            id: textGitHub
            anchors.verticalCenter: imageGitHub.verticalCenter
            anchors.left: imageGitHub.right
            anchors.leftMargin: 8

            text: qsTr("Visit us on <html><style type=\"text/css\"></style><a href=\"https://github.com/emericg/OffloadBuddy\">GitHub</a></html>!")
            color: Theme.colorText
            font.pixelSize: 18
            onLinkActivated: Qt.openUrlExternally("https://github.com/emericg/OffloadBuddy")
        }

        ImageSvg {
            id: imageGitHub
            width: 32
            height: 32
            anchors.left: parent.left
            anchors.leftMargin: 32
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 32

            source: "qrc:/logos/github.svg"
            color: Theme.colorIcon
        }

        ImageSvg {
            id: imageIssues
            width: 32
            height: 32
            anchors.left: textGitHub.right
            anchors.leftMargin: 32
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 32

            source: "qrc:/icons_material/baseline-bug_report-24px.svg"
            color: Theme.colorIcon
        }

        Text {
            id: textIssues
            anchors.left: imageIssues.right
            anchors.verticalCenter: imageIssues.verticalCenter
            anchors.leftMargin: 8

            text: qsTr("Report bugs or post feature request on our <html><style type=\"text/css\"></style><a href=\"https://github.com/emericg/OffloadBuddy/issues\">issue tracker</a></html>!")
            color: Theme.colorText
            font.pixelSize: 18
            onLinkActivated: Qt.openUrlExternally("https://github.com/emericg/OffloadBuddy/issues")
        }
    }
}
