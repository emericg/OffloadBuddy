import QtQuick 2.10
import QtQuick.Controls 2.3
import QtGraphicalEffects 1.0

import com.offloadbuddy.style 1.0

Rectangle {
    width: 1280
    height: 720

    Rectangle {
        id: rectangleHeader
        height: 64
        color: ThemeEngine.colorHeaderBackground
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.topMargin: 0

        Text {
            id: textHeader
            y: 20
            height: 40
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("ABOUT")
            verticalAlignment: Text.AlignVCenter
            font.bold: true
            font.pixelSize: ThemeEngine.fontSizeHeaderTitle
            color: ThemeEngine.colorHeaderTitle
        }
    }

    Rectangle {
        id: rectangleContent
        color: ThemeEngine.colorContentBackground

        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        Rectangle {
            id: rectangleProject
            height: 320
            color: ThemeEngine.colorContentBox
            radius: 4
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.left: parent.left
            anchors.leftMargin: 16

            Image {
                id: imageLogo
                width: 220
                height: 180
                anchors.verticalCenterOffset: -10
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 8
                fillMode: Image.PreserveAspectCrop
                source: "qrc:/appicons/offloadbuddy.png"
            }

            Text {
                id: text_title
                anchors.left: parent.left
                anchors.leftMargin: 16
                text: "OffloadBuddy"
                anchors.top: parent.top
                anchors.topMargin: 12
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentTitle
                color: ThemeEngine.colorContentTitle
            }

            TextArea {
                id: textArea
                anchors.top: text_title.bottom
                anchors.topMargin: 8
                anchors.bottom: imageGitHub.top
                anchors.bottomMargin: 8
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: imageLogo.left

                readOnly: true
                wrapMode: Text.WordWrap
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
                text: "OffloadBuddy is a multimedia offloading software with a few tricks up his sleeve!\nIt's designed to remove the hassle of handling and transferring the many videos and pictures file from your devices like action cameras, regular cameras and smartphones...\n\n* Import datas from SD cards, mass storage or MTP devices\n  - Copy, merge or reencode medias\n  - Consult and export shots metadatas\n  - Organize your media library\n* Create clips or extract photos from your videos\n* Assemble photo timelapses into videos\n* GoPro firmware updates"
                anchors.rightMargin: 8
            }

            Text {
                id: text1
                width: 112
                height: 16
                text: qsTr("Version 0.1 (git)")
                anchors.horizontalCenter: imageLogo.horizontalCenter
                anchors.top: imageLogo.bottom
                anchors.topMargin: 6
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: ThemeEngine.fontSizeContentText
                color: ThemeEngine.colorContentText
            }

            Text {
                id: text2
                anchors.verticalCenter: imageGitHub.verticalCenter
                anchors.left: imageGitHub.right
                anchors.leftMargin: 8

                text: qsTr("Visit us on <html><style type=\"text/css\"></style><a href=\"https://github.com/emericg/OffloadBuddy\">GitHub</a></html>!")
                color: ThemeEngine.colorContentText
                font.pixelSize: ThemeEngine.fontSizeContentText
                onLinkActivated: Qt.openUrlExternally("https://github.com/emericg/OffloadBuddy")
            }

            Image {
                id: imageGitHub
                y: 224
                width: 32
                height: 32
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                sourceSize.height: 64
                sourceSize.width: 64
                source: "../resources/other/GitHub-Mark-64px.png"
            }
        }

        Rectangle {
            id: rectangleAuthors
            radius: 4
            anchors.bottom: parent.bottom
            anchors.top: rectangleProject.bottom
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.margins: 16
            color: ThemeEngine.colorContentBox

            Text {
                id: text_title1
                anchors.left: parent.left
                anchors.leftMargin: 16

                text: qsTr("Authors")
                anchors.top: parent.top
                anchors.topMargin: 12
                verticalAlignment: Text.AlignVCenter
                font.bold: true
                font.pixelSize: ThemeEngine.fontSizeContentTitle
                color: ThemeEngine.colorContentTitle
            }

            Rectangle {
                id: rectangleAuthor
                x: 16
                y: 64
                width: 512
                height: 128
                color: ThemeEngine.colorContentSubBox
                radius: 8

                Rectangle {
                    id: backImg
                    width: 100
                    height: 100
                    radius: 50
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        id: maskImg
                        width: 100
                        height: 100
                        radius: 50
                        visible: false
                        anchors.fill: parent
                        //source: "qrc:/authors/mask.png"
                    }
                    Image {
                        id: authorImg
                        anchors.fill: parent
                        sourceSize.height: 256
                        sourceSize.width: 256
                        fillMode: Image.PreserveAspectCrop
                        source: "qrc:/authors/emeric.jpg"
                        visible: false
                    }
                    OpacityMask {
                        id: whatever
                        source: authorImg
                        maskSource: maskImg
                        anchors.fill: parent
                        anchors.rightMargin: 5
                        anchors.leftMargin: 5
                        anchors.bottomMargin: 5
                        anchors.topMargin: 5
                    }
                }
                Text {
                    id: textName
                    height: 20
                    anchors.top: parent.top
                    anchors.topMargin: 24
                    anchors.left: backImg.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 8

                    text: "Emeric"
                    color: ThemeEngine.colorContentSubTitle
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    font.pixelSize: 20
                }
                TextArea {
                    id: textArea1
                    anchors.top: textName.bottom
                    anchors.topMargin: 4
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    anchors.left: backImg.right
                    anchors.leftMargin: 4
                    anchors.right: parent.right
                    anchors.rightMargin: 4

                    readOnly: true
                    text: qsTr("Main developer. Likes animals and flowers. Also, ponies. You know, the ones with horns and wings.")
                    font.pixelSize: ThemeEngine.fontSizeContentText
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignTop
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }
    }
}
