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
            width: 512
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
            height: 256
            color: ThemeEngine.colorContentBox
            radius: 16
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
                y: 10
                width: 300
                height: 40
                anchors.left: parent.left
                anchors.leftMargin: 16
                text: "OffloadBuddy"
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
                anchors.right: parent.right
                anchors.rightMargin: 300

                readOnly: true
                font.pixelSize: ThemeEngine.fontSizeContentText
                text: qsTr("OffloadBuddy remove the hassle of handling and transfering the many videos and pictures file from your actioncams, cameras or phones.

It also helps with many other convenient things like:
- merging chaptered files
- extracting many metadatas
- video cliping and reencoding")
                wrapMode: Text.WordWrap
            }

            Text {
                id: text1
                x: 1068
                width: 112
                height: 15
                text: qsTr("Version 0.1 (git)")
                anchors.horizontalCenter: imageLogo.horizontalCenter
                anchors.top: imageLogo.bottom
                anchors.topMargin: 6
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 15
            }

            Text {
                id: text2
                y: 239
                width: 166
                height: 32
                text: qsTr("Visit us on <html><style type=\"text/css\"></style><a href=\"https://github.com/emericg/OffloadBuddy\">GitHub</a></html>!")
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                anchors.left: imageGitHub.right
                anchors.leftMargin: 8
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                font.pixelSize: 16
                onLinkActivated: Qt.openUrlExternally("https://github.com/emericg/OffloadBuddy")
            }

            Image {
                id: imageGitHub
                y: 224
                width: 32
                height: 32
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                sourceSize.height: 64
                sourceSize.width: 64
                source: "../resources/other/GitHub-Mark-64px.png"
            }
        }

        Rectangle {
            id: rectangleAuthors
            radius: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.topMargin: 16
            anchors.leftMargin: 16
            anchors.top: rectangleProject.bottom
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.left: parent.left
            color: ThemeEngine.colorContentBox

            Text {
                id: text_title1
                y: 10
                width: 300
                height: 40
                anchors.left: parent.left
                anchors.leftMargin: 16

                text: qsTr("Authors")
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
                color: ThemeEngine.colorHeaderBackground
                radius: 8

                Rectangle {
                    id: backImg
                    y: 24
                    width: 100
                    height: 100
                    radius: 50
                    anchors.left: parent.left
                    anchors.leftMargin: 8
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
                    height: 24
                    anchors.top: parent.top
                    anchors.topMargin: 24
                    anchors.left: backImg.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 8

                    text: qsTr("Emeric")
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
                    text: qsTr("Main developer. Likes animals and flowers. Also, ponies. Yes I needed two lines here...")
                    font.pixelSize: ThemeEngine.fontSizeContentText
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignTop
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }
    }
}
