import QtQuick
import QtQuick.Controls

import ThemeEngine

Loader {
    id: screenAbout
    anchors.fill: parent

    function loadScreen() {
        // load screen
        screenAbout.active = true

        // change screen
        appContent.state = "about"
    }

    function backAction() {
        if (screenAbout.status === Loader.Ready)
            screenAbout.item.backAction()
    }

    active: false
    asynchronous: false

    sourceComponent: Item {
        anchors.fill: parent

        // HEADER //////////////////////////////////////////////////////////////

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
                anchors.leftMargin: Theme.componentMarginXL
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
                anchors.leftMargin: Theme.componentMarginXL
                anchors.bottom: textHeader.bottom
                anchors.bottomMargin: 6

                text: qsTr("version %1  /  %2  /  built on %3").arg(utilsApp.appVersion()).arg(utilsApp.appBuildMode()).arg(utilsApp.appBuildDate())
                textFormat: Text.PlainText
                font.bold: true
                font.pixelSize: Theme.componentFontSize
                color: Theme.colorSubText
            }

            ////////

            CsdWindows { }

            CsdLinux { }

            ////////

            HeaderSeparator { }
        }

        HeaderShadow {anchors.top: rectangleHeader.bottom; }

        // CONTENT /////////////////////////////////////////////////////////////

        Flickable {
            anchors.top: rectangleHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            contentWidth: -1
            contentHeight: columnAbout.height

            boundsBehavior: Flickable.OvershootBounds
            ScrollBar.vertical: ScrollBar { }

            Column {
                id: columnAbout
                anchors.left: parent.left
                anchors.leftMargin: Theme.componentMarginXL
                anchors.right: parent.right
                anchors.rightMargin: Theme.componentMarginXL

                topPadding: Theme.componentMarginXL
                bottomPadding: Theme.componentMarginXL
                spacing: Theme.componentMarginXL

                ////////

                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Theme.componentMarginXL

                    Image { // logo
                        width: 220
                        height: 160
                        sourceSize.width: 220
                        sourceSize.height: 160

                        fillMode: Image.PreserveAspectFit
                        source: "qrc:/gfx/offloadbuddy.svg"
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 220 - Theme.componentMarginXL
                        spacing: Theme.componentMargin

                        Text {
                            width: parent.width

                            wrapMode: Text.WordWrap
                            font.pixelSize: Theme.fontSizeContentBig
                            color: Theme.colorText
                            text: qsTr("OffloadBuddy is a multimedia offloading software with a few tricks up his sleeve!\n" +
                                       "It's designed to remove the hassle of handling and transferring the many videos and pictures file from your devices like action cameras, regular cameras and smartphones...")
                            textFormat: Text.PlainText
                        }

                        Row {
                            spacing: Theme.componentMarginXL

                            ButtonSolid {
                                width: 180
                                height: 40

                                text: qsTr("Website")
                                source: "qrc:/assets/icons/material-symbols/link.svg"

                                onClicked: Qt.openUrlExternally("https://emeric.io/OffloadBuddy")
                            }

                            ButtonSolid {
                                width: 180
                                height: 40

                                text: qsTr("Discussions")
                                source: "qrc:/assets/icons/material-icons/duotone/question_answer.svg"

                                onClicked: Qt.openUrlExternally("https://www.github.com/emericg/OffloadBuddy/discussions")
                            }

                            ButtonSolid {
                                width: 180
                                height: 40

                                text: qsTr("Bug report")
                                source: "qrc:/assets/icons/material-symbols/bug_report.svg"

                                onClicked: Qt.openUrlExternally("https://www.github.com/emericg/OffloadBuddy/issues")
                            }
                        }
                    }
                }

                ////////

                Separator { }

                ////////

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right

                    text: qsTr("✔ Import data from SD cards, mass storage or MTP devices\n  - Copy, merge or reencode media\n  - Consult and export shots metadata\n  - Organize your media library\n" +
                               "✔ Create clips or extract photos from your videos\n" +
                               "✔ Assemble photo timelapses into videos\n" +
                               "✔ GoPro firmware updates")
                    textFormat: Text.PlainText
                    font.pixelSize: Theme.fontSizeContentBig
                    wrapMode: Text.WordWrap
                    color: Theme.colorText
                }

                ////////

                Separator { }

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
                        textFormat: Text.PlainText
                        wrapMode: Text.WordWrap
                        font.pixelSize: Theme.fontSizeContentBig
                    }

                    Row {
                        height: 32
                        spacing: Theme.componentMarginXL

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "⦁ Qt"
                            textFormat: Text.PlainText
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContentBig
                        }
                        RoundButtonSunken {
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/assets/icons/material-symbols/link.svg"
                            onClicked: Qt.openUrlExternally("https://www.qt.io")
                        }
                        ItemLicenseBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            legend: qsTr("license")
                            text: qsTr("LGPL 3")
                            onClicked: Qt.openUrlExternally("https://www.gnu.org/licenses/lgpl-3.0.html")
                        }
                    }
                    Row {
                        height: 32
                        spacing: Theme.componentMarginXL

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "⦁ ffmpeg"
                            textFormat: Text.PlainText
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContentBig
                        }
                        RoundButtonSunken {
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/assets/icons/material-symbols/link.svg"
                            onClicked: Qt.openUrlExternally("https://www.ffmpeg.org")
                        }
                        ItemLicenseBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            legend: qsTr("license")
                            text: qsTr("LGPL 2.1")
                            onClicked: Qt.openUrlExternally("https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html")
                        }
                    }
                    Row {
                        height: 32
                        spacing: Theme.componentMarginXL

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "⦁ minivideo"
                            textFormat: Text.PlainText
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContentBig
                        }
                        RoundButtonSunken {
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/assets/icons/material-symbols/link.svg"
                            onClicked: Qt.openUrlExternally("https://github.com/emericg/MiniVideo")
                        }
                        ItemLicenseBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            legend: qsTr("license")
                            text: qsTr("LGPL 3")
                            onClicked: Qt.openUrlExternally("https://www.gnu.org/licenses/lgpl-3.0.html")
                        }
                    }
                    Row {
                        height: 32
                        spacing: Theme.componentMarginXL

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "⦁ libexif"
                            textFormat: Text.PlainText
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContentBig
                        }
                        RoundButtonSunken {
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/assets/icons/material-symbols/link.svg"
                            onClicked: Qt.openUrlExternally("https://github.com/libexif")
                        }
                        ItemLicenseBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            legend: qsTr("license")
                            text: qsTr("LGPL 2.1")
                            onClicked: Qt.openUrlExternally("https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html")
                        }
                    }
                    Row {
                        height: 32
                        spacing: Theme.componentMarginXL

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "⦁ libmtp"
                            textFormat: Text.PlainText
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContentBig
                        }
                        RoundButtonSunken {
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/assets/icons/material-symbols/link.svg"
                            onClicked: Qt.openUrlExternally("https://github.com/libmtp")
                        }
                        ItemLicenseBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            legend: qsTr("license")
                            text: qsTr("LGPL 2.1")
                            onClicked: Qt.openUrlExternally("https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html")
                        }
                    }
                    Row {
                        height: 32
                        spacing: Theme.componentMarginXL

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "⦁ miniz"
                            textFormat: Text.PlainText
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContentBig
                        }
                        RoundButtonSunken {
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/assets/icons/material-symbols/link.svg"
                            onClicked: Qt.openUrlExternally("https://github.com/richgel999/miniz/")
                        }
                        ItemLicenseBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            legend: qsTr("license")
                            text: qsTr("MIT")
                            onClicked: Qt.openUrlExternally("https://github.com/richgel999/miniz/blob/master/LICENSE")
                        }
                    }
                    Row {
                        height: 32
                        spacing: Theme.componentMarginXL

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "⦁ SingleApplication"
                            textFormat: Text.PlainText
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContentBig
                        }
                        RoundButtonSunken {
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/assets/icons/material-symbols/link.svg"
                            onClicked: Qt.openUrlExternally("https://github.com/itay-grudev/SingleApplication/")
                        }
                        ItemLicenseBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            legend: qsTr("license")
                            text: qsTr("MIT")
                            onClicked: Qt.openUrlExternally("https://github.com/itay-grudev/SingleApplication/blob/master/LICENSE")
                        }
                    }
                    Row {
                        height: 32
                        spacing: Theme.componentMarginXL

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "⦁ Google Material Icons"
                            textFormat: Text.PlainText
                            color: Theme.colorText
                            font.pixelSize: Theme.fontSizeContentBig
                        }
                        RoundButtonSunken {
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/assets/icons/material-symbols/link.svg"
                            onClicked: Qt.openUrlExternally("https://material.io/tools/icons")
                        }
                        ItemLicenseBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            legend: qsTr("license")
                            text: qsTr("Apache 2.0")
                            onClicked: Qt.openUrlExternally("https://www.apache.org/licenses/LICENSE-2.0.txt")
                        }
                    }
                }

                ////////

                Separator { }

                ////////
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////
}
