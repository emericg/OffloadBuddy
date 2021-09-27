import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Item {
    id: screenAbout
    width: 1280
    height: 720

    // HEADER //////////////////////////////////////////////////////////////////

    Rectangle {
        id: rectangleHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        z: 1
        height: 64
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
            font.bold: true
            font.pixelSize: Theme.fontSizeHeader
            color: Theme.colorHeaderContent
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            id: textVersion
            anchors.left: textHeader.right
            anchors.leftMargin: 24
            anchors.bottom: textHeader.bottom
            anchors.bottomMargin: 6

            text: qsTr("version %1  /  %2  /  built on %3").arg(utilsApp.appVersion()).arg(utilsApp.appBuildMode()).arg(utilsApp.appBuildDate())
            textFormat: Text.PlainText
            font.bold: true
            font.pixelSize: Theme.fontSizeContentSmall
            color: Theme.colorHeaderContent
        }

        ////////

        CsdWindows { }

        ////////

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: 2
            opacity: 0.1
            color: Theme.colorHeaderContent
        }
        SimpleShadow {
            anchors.top: parent.bottom
            anchors.topMargin: -height
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            opacity: 0.7
            color: Theme.colorHeaderContent
        }
    }

    // CONTENT /////////////////////////////////////////////////////////////////

    ScrollView {
        id: scrollView
        contentWidth: -1

        anchors.top: rectangleHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Column {
            anchors.fill: parent
            anchors.topMargin: 24
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            spacing: 24

            ////////

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 24

                Image {
                    //id: imageLogo
                    width: 220
                    height: 160

                    fillMode: Image.PreserveAspectCrop
                    source: "qrc:/appicons/offloadbuddy.svg"
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 220 - 24
                    spacing: 16

                    TextArea {
                        width: parent.width
                        //anchors.margins: -8
                        leftPadding: 0

                        readOnly: true
                        wrapMode: Text.WordWrap
                        font.pixelSize: Theme.fontSizeContentBig
                        color: Theme.colorText
                        text: qsTr("OffloadBuddy is a multimedia offloading software with a few tricks up his sleeve!\n" +
                                   "It's designed to remove the hassle of handling and transferring the many videos and pictures file from your devices like action cameras, regular cameras and smartphones...")
                    }

                    Row {
                        id: buttonArea
                        height: 40
                        spacing: 24

                        ButtonWireframeImage {
                            width: 180
                            anchors.verticalCenter: parent.verticalCenter

                            fullColor: false
                            primaryColor: Theme.colorPrimary

                            text: qsTr("Website")
                            imgSize: 32
                            source: "qrc:/assets/icons_material/baseline-link-24px.svg"
                            onClicked: Qt.openUrlExternally("https://emeric.io/OffloadBuddy")
                        }

                        ButtonWireframeImage {
                            width: 180
                            anchors.verticalCenter: parent.verticalCenter

                            fullColor: false
                            primaryColor: Theme.colorPrimary

                            text: qsTr("Bug report")
                            source: "qrc:/assets/icons_material/baseline-bug_report-24px.svg"
                            onClicked: Qt.openUrlExternally("https://www.github.com/emericg/OffloadBuddy/issues")
                        }

                        ButtonWireframeImage {
                            width: 180
                            anchors.verticalCenter: parent.verticalCenter

                            fullColor: false
                            primaryColor: Theme.colorPrimary

                            text: qsTr("Discussions")
                            source: "qrc:/assets/icons_material/duotone-question_answer-24px.svg"
                            onClicked: Qt.openUrlExternally("https://www.github.com/emericg/OffloadBuddy/discussions")
                        }
                    }
                }
            }

            ////////

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: -24
                anchors.right: parent.right
                anchors.rightMargin: -24
                height: 2
                opacity: 0.33
                color: Theme.colorSeparator
            }

            ////////

            TextArea {
                anchors.left: parent.left
                anchors.leftMargin: -8
                anchors.right: parent.right
                anchors.rightMargin: -8

                readOnly: true
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeContentBig
                color: Theme.colorText
                text: qsTr("✔ Import data from SD cards, mass storage or MTP devices\n  - Copy, merge or reencode media\n  - Consult and export shots metadata\n  - Organize your media library\n" +
                           "✔ Create clips or extract photos from your videos\n" +
                           "✔ Assemble photo timelapses into videos\n" +
                           "✔ GoPro firmware updates")
            }

            ////////

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: -24
                anchors.right: parent.right
                anchors.rightMargin: -24
                height: 2
                opacity: 0.33
                color: Theme.colorSeparator
            }

            ////////

            Column {
                id: sectionOSS
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 4

                Text {
                    height: 32
                    anchors.left: parent.left
                    anchors.right: parent.right

                    color: Theme.colorText
                    text: qsTr("This application is made possible thanks to a couple of third party open source projects:")
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeContentBig
                }

                Row {
                    height: 32
                    spacing: 24

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⦁ Qt"
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentBig
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
                        font.pixelSize: Theme.fontSizeContentBig
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
                        font.pixelSize: Theme.fontSizeContentBig
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
                        font.pixelSize: Theme.fontSizeContentBig
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
                        font.pixelSize: Theme.fontSizeContentBig
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
                        font.pixelSize: Theme.fontSizeContentBig
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

            ////////

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: -24
                anchors.right: parent.right
                anchors.rightMargin: -24
                height: 2
                opacity: 0.33
                color: Theme.colorSeparator
            }

            ////////
        }
    }
}
