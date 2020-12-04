import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Item {
    id: screenAbout
    width: 1280
    height: 720

    Rectangle {
        id: rectangleHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        height: 64
        z: 5
        color: Theme.colorHeader

        DragHandler {
            // Drag on the sidebar to drag the whole window // Qt 5.15+
            // Also, prevent clicks below this area
            onActiveChanged: if (active) appWindow.startSystemMove();
            target: null
        }

        Text {
            id: textHeader
            height: 40
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("ABOUT") + "  OffloadBuddy"
            verticalAlignment: Text.AlignVCenter
            font.bold: true
            font.pixelSize: Theme.fontSizeHeader
            color: Theme.colorHeaderContent
        }

        Text {
            id: textVersion2
            anchors.left: textHeader.right
            anchors.leftMargin: 24
            anchors.bottom: textHeader.bottom
            anchors.bottomMargin: 6
            text: qsTr("v%1  /  built %2").arg(utilsApp.appVersion()).arg(utilsApp.appBuildDate())
            font.bold: true
            color: Theme.colorHeaderContent
        }

        CsdWindows {
            anchors.top: parent.top
            anchors.right: parent.right
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    ScrollView {
        id: scrollView
        contentWidth: -1

        anchors.top: rectangleHeader.bottom
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        Column {
            anchors.topMargin: 24
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.fill: parent
            spacing: 16

            ////////

            TextArea {
                id: textArea1
                anchors.topMargin: -8
                anchors.left: parent.left
                anchors.leftMargin: -8
                anchors.right: parent.right
                anchors.rightMargin: -8

                readOnly: true
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                color: Theme.colorText
                text: qsTr("OffloadBuddy is a multimedia offloading software with a few tricks up his sleeve!\n" +
                           "It's designed to remove the hassle of handling and transferring the many videos and pictures file from your devices like action cameras, regular cameras and smartphones...")
            }

            Item {
                id: buttonArea
                height: 40
                anchors.left: parent.left
                anchors.right: parent.right

                ButtonWireframeImage {
                    id: button1
                    width: 180
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter

                    primaryColor: "#5483EF"

                    text: qsTr("Website")
                    imgSize: 32
                    source: "qrc:/assets/icons_material/baseline-link-24px.svg"
                    onClicked: Qt.openUrlExternally("https://emeric.io/OffloadBuddy")
                }

                ButtonWireframeImage {
                    id: button2
                    width: 180
                    anchors.left: button1.right
                    anchors.leftMargin: 24
                    anchors.verticalCenter: button1.verticalCenter

                    primaryColor: "#5483EF"

                    text: qsTr("Issue tracker")
                    imgSize: 24
                    source: "qrc:/assets/logos/github.svg"
                    onClicked: Qt.openUrlExternally("https://www.github.com/emericg/OffloadBuddy")
                }
            }

            TextArea {
                id: textArea2
                anchors.left: parent.left
                anchors.leftMargin: -8
                anchors.right: parent.right
                anchors.rightMargin: -8

                readOnly: true
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                color: Theme.colorText
                text: qsTr("✔ Import data from SD cards, mass storage or MTP devices\n  - Copy, merge or reencode media\n  - Consult and export shots metadata\n  - Organize your media library\n" +
                           "✔ Create clips or extract photos from your videos\n" +
                           "✔ Assemble photo timelapses into videos\n" +
                           "✔ GoPro firmware updates")
            }

            Item { width: 16; height: 16; } // spacer

            Column {
                id: sectionOSS
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 4

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    color: Theme.colorText
                    text: qsTr("This application is made possible thanks to a couple of third party open source projects:")
                    wrapMode: Text.WordWrap
                    font.pixelSize: 18
                }

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
                        source: "qrc:/assets/icons_material/baseline-link-24px.svg"
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
                        source: "qrc:/assets/icons_material/baseline-link-24px.svg"
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
                        source: "qrc:/assets/icons_material/baseline-link-24px.svg"
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
                        source: "qrc:/assets/icons_material/baseline-link-24px.svg"
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
                        source: "qrc:/assets/icons_material/baseline-link-24px.svg"
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
                        source: "qrc:/assets/icons_material/baseline-link-24px.svg"
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
    }

    ////////////////////////////////////////////////////////////////////////////

    Item {
        height: 32
        anchors.left: parent.left
        anchors.leftMargin: 32
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24

        ImageSvg {
            id: imageGitHub
            width: 32
            height: 32
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            source: "qrc:/assets/logos/github.svg"
            color: Theme.colorIcon
        }
        Text {
            id: textGitHub
            anchors.left: imageGitHub.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter

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
            anchors.verticalCenter: parent.verticalCenter

            source: "qrc:/assets/icons_material/baseline-bug_report-24px.svg"
            color: Theme.colorIcon
        }
        Text {
            id: textIssues
            anchors.left: imageIssues.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter

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

    Image {
        id: imageLogo
        width: 220
        height: 160
        anchors.right: parent.right
        anchors.rightMargin: 32
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32

        fillMode: Image.PreserveAspectCrop
        source: "qrc:/appicons/offloadbuddy.png"
    }
}
