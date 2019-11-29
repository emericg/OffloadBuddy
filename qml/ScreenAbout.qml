import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

import ThemeEngine 1.0

Item {
    width: 1280
    height: 720

    Rectangle {
        id: rectangleHeader
        height: 64
        z: 5

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

            text: qsTr("ABOUT") + "  /  OffloadBuddy"
            verticalAlignment: Text.AlignVCenter
            font.bold: true
            font.pixelSize: Theme.fontSizeHeaderTitle
            color: Theme.colorHeaderContent
        }

        Text {
            id: textVersion2
            anchors.left: textHeader.right
            anchors.leftMargin: 24
            anchors.bottom: textHeader.bottom
            anchors.bottomMargin: 6
            text: qsTr("v%1  /  built %2").arg(app.appVersion()).arg(app.appBuildDate())
            font.bold: true
            color: Theme.colorHeaderContent
        }
    }

    ////////////////////////////////////////////////////////////////////////////

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
            height: 160
            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20
            fillMode: Image.PreserveAspectCrop
            source: "qrc:/appicons/offloadbuddy.png"
        }
        Text {
            id: textVersion
            width: 112
            height: 16
            text: qsTr("Version %1 (%2)").arg(app.appVersion()).arg(app.appBuildDate())

            anchors.horizontalCenter: imageLogo.horizontalCenter
            anchors.top: imageLogo.bottom
            anchors.topMargin: 6
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeContentText
            color: Theme.colorText
        }

        TextArea {
            id: textArea
            anchors.top: parent.top
            anchors.topMargin: 24
            //anchors.bottom: imageGitHub.top
            //anchors.bottomMargin: 24
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.right: imageLogo.left

            readOnly: true
            wrapMode: Text.WordWrap
            font.pixelSize: 18
            color: Theme.colorText
            text: "OffloadBuddy is a multimedia offloading software with a few tricks up his sleeve!\nIt's designed to remove the hassle of handling and transferring the many videos and pictures file from your devices like action cameras, regular cameras and smartphones...\n\n✔ Import datas from SD cards, mass storage or MTP devices\n  - Copy, merge or reencode medias\n  - Consult and export shots metadatas\n  - Organize your media library\n✔ Create clips or extract photos from your videos\n✔ Assemble photo timelapses into videos\n✔ GoPro firmware updates"
            anchors.rightMargin: 24
        }

        ////////////////////////////////////////////////////////////////////////

        Item {
            id: rectangleOss
            anchors.top: textArea.bottom
            anchors.topMargin: 32
            anchors.left: parent.left
            anchors.leftMargin: 32
            anchors.right: parent.right
            anchors.rightMargin: 32

            Text {
                id: element
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.top: parent.top
                anchors.topMargin: 0
                anchors.left: parent.left
                anchors.leftMargin: 0

                color: Theme.colorText
                text: qsTr("OffloadBuddy is made possible thanks to a couple of third party open source projects:")
                wrapMode: Text.WordWrap
                font.pixelSize: 18
            }

            Column {
                anchors.top: element.bottom
                anchors.topMargin: 8
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.left: parent.left
                anchors.leftMargin: 16

                Row {
                    height: 32
                    spacing: 24

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⦁ Qt"
                        color: Theme.colorText
                        font.pixelSize: 16
                    }
                    ItemImageButton {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/icons_material/baseline-link-24px.svg"
                        onClicked: Qt.openUrlExternally("https://www.qt.io")
                    }
                    ItemBadge {
                        anchors.verticalCenter: parent.verticalCenter
                        legend: qsTr("license")
                        text: qsTr("LGPL 3")
                        onClicked: Qt.openUrlExternally("https://www.gnu.org/licenses/lgpl-3.0.html")
                    }
                }
                Row {
                    height: 32
                    spacing: 24

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⦁ ffmpeg"
                        color: Theme.colorText
                        font.pixelSize: 16
                    }
                    ItemImageButton {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/icons_material/baseline-link-24px.svg"
                        onClicked: Qt.openUrlExternally("https://www.ffmpeg.org")
                    }
                    ItemBadge {
                        anchors.verticalCenter: parent.verticalCenter
                        legend: qsTr("license")
                        text: qsTr("LGPL 2.1")
                        onClicked: Qt.openUrlExternally("https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html")
                    }
                }
                Row {
                    height: 32
                    spacing: 24

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⦁ minivideo"
                        color: Theme.colorText
                        font.pixelSize: 16
                    }
                    ItemImageButton {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/icons_material/baseline-link-24px.svg"
                        onClicked: Qt.openUrlExternally("https://github.com/emericg/MiniVideo")
                    }
                    ItemBadge {
                        anchors.verticalCenter: parent.verticalCenter
                        legend: qsTr("license")
                        text: qsTr("LGPL 3")
                        onClicked: Qt.openUrlExternally("https://www.gnu.org/licenses/lgpl-3.0.html")
                    }
                }
                Row {
                    height: 32
                    spacing: 24

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⦁ libexif"
                        color: Theme.colorText
                        font.pixelSize: 16
                    }
                    ItemImageButton {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/icons_material/baseline-link-24px.svg"
                        onClicked: Qt.openUrlExternally("https://libexif.github.io")
                    }
                    ItemBadge {
                        anchors.verticalCenter: parent.verticalCenter
                        legend: qsTr("license")
                        text: qsTr("LGPL 2.1")
                        onClicked: Qt.openUrlExternally("https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html")
                    }
                }
                Row {
                    height: 32
                    spacing: 24

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⦁ Google material icons"
                        color: Theme.colorText
                        font.pixelSize: 16
                    }
                    ItemImageButton {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/icons_material/baseline-link-24px.svg"
                        onClicked: Qt.openUrlExternally("https://material.io/tools/icons")
                    }
                    ItemBadge {
                        width: 140
                        anchors.verticalCenter: parent.verticalCenter
                        legend: qsTr("license")
                        text: qsTr("Apache 2.0")
                        onClicked: Qt.openUrlExternally("https://www.apache.org/licenses/LICENSE-2.0.txt")
                    }
                }
                Row {
                    height: 32
                    spacing: 24

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⦁ SingleApplication"
                        color: Theme.colorText
                        font.pixelSize: 16
                    }
                    ItemImageButton {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/icons_material/baseline-link-24px.svg"
                        onClicked: Qt.openUrlExternally("https://github.com/itay-grudev/SingleApplication/")
                    }
                    ItemBadge {
                        anchors.verticalCenter: parent.verticalCenter
                        legend: qsTr("license")
                        text: qsTr("MIT")
                        onClicked: Qt.openUrlExternally("https://github.com/itay-grudev/SingleApplication/blob/master/LICENSE")
                    }
                }
            }
        }

        ////////////////////////////////////////////////////////////////////////

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
        Text {
            id: textGitHub
            anchors.verticalCenter: imageGitHub.verticalCenter
            anchors.left: imageGitHub.right
            anchors.leftMargin: 8

            text: qsTr("Visit us on <html><style type=\"text/css\"></style><a href=\"https://github.com/emericg/OffloadBuddy\">GitHub</a></html>!")
            color: Theme.colorText
            font.pixelSize: 18
            onLinkActivated: Qt.openUrlExternally(link)

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
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
            onLinkActivated: Qt.openUrlExternally(link)

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }
}
