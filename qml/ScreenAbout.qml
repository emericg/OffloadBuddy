import QtQuick 2.15
import QtQuick.Controls 2.15

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
            font.pixelSize: Theme.fontSizeComponent
            color: Theme.colorSubText
        }

        ////////

        CsdWindows { }

        CsdLinux { }

        ////////

        Rectangle { // separator
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: 2
            opacity: 0.1
            color: Theme.colorHeaderContent
        }
    }
    Rectangle { // shadow
        anchors.top: rectangleHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        height: 8
        opacity: 0.66

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Theme.colorHeaderHighlight; }
            GradientStop { position: 1.0; color: Theme.colorBackground; }
        }
    }

    // CONTENT /////////////////////////////////////////////////////////////////

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
            anchors.leftMargin: 24
            anchors.right: parent.right
            anchors.rightMargin: 24

            topPadding: 24
            bottomPadding: 24
            spacing: 24

            ////////

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 24

                Image { // logo
                    width: 220
                    height: 160
                    sourceSize.width: 220
                    sourceSize.height: 160

                    fillMode: Image.PreserveAspectFit
                    source: "qrc:/appicons/offloadbuddy.svg"
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 220 - 24
                    spacing: 16

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
                        height: 40
                        spacing: 24

                        ButtonWireframeIconCentered {
                            width: 180
                            anchors.verticalCenter: parent.verticalCenter

                            fullColor: false
                            primaryColor: Theme.colorPrimary

                            text: qsTr("Website")
                            source: "qrc:/assets/icons_material/baseline-link-24px.svg"
                            sourceSize: 32

                            onClicked: Qt.openUrlExternally("https://emeric.io/OffloadBuddy")
                        }

                        ButtonWireframeIconCentered {
                            width: 180
                            anchors.verticalCenter: parent.verticalCenter

                            fullColor: false
                            primaryColor: Theme.colorPrimary

                            text: qsTr("Discussions")
                            source: "qrc:/assets/icons_material/duotone-question_answer-24px.svg"

                            onClicked: Qt.openUrlExternally("https://www.github.com/emericg/OffloadBuddy/discussions")
                        }

                        ButtonWireframeIconCentered {
                            width: 180
                            anchors.verticalCenter: parent.verticalCenter

                            fullColor: false
                            primaryColor: Theme.colorPrimary

                            text: qsTr("Bug report")
                            source: "qrc:/assets/icons_material/baseline-bug_report-24px.svg"

                            onClicked: Qt.openUrlExternally("https://www.github.com/emericg/OffloadBuddy/issues")
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
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeContentBig
                }

                Row {
                    height: 32
                    spacing: 24

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⦁ Qt"
                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentBig
                    }
                    RoundButtonIcon {
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
                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentBig
                    }
                    RoundButtonIcon {
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
                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentBig
                    }
                    RoundButtonIcon {
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
                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentBig
                    }
                    RoundButtonIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/assets/icons_material/baseline-link-24px.svg"
                        onClicked: Qt.openUrlExternally("https://github.com/libexif")
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
                        text: "⦁ libmtp"
                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentBig
                    }
                    RoundButtonIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/assets/icons_material/baseline-link-24px.svg"
                        onClicked: Qt.openUrlExternally("https://github.com/libmtp")
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
                        text: "⦁ miniz"
                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentBig
                    }
                    RoundButtonIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/assets/icons_material/baseline-link-24px.svg"
                        onClicked: Qt.openUrlExternally("https://github.com/richgel999/miniz/")
                    }
                    ItemBadge {
                        anchors.verticalCenter: parent.verticalCenter
                        legend: qsTr("license")
                        text: qsTr("MIT")
                        onClicked: Qt.openUrlExternally("https://github.com/richgel999/miniz/blob/master/LICENSE")
                    }
                }
                Row {
                    height: 32
                    spacing: 24

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⦁ SingleApplication"
                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentBig
                    }
                    RoundButtonIcon {
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
                Row {
                    height: 32
                    spacing: 24

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⦁ Google Material Icons"
                        textFormat: Text.PlainText
                        color: Theme.colorText
                        font.pixelSize: Theme.fontSizeContentBig
                    }
                    RoundButtonIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/assets/icons_material/baseline-link-24px.svg"
                        onClicked: Qt.openUrlExternally("https://material.io/tools/icons")
                    }
                    ItemBadge {
                        anchors.verticalCenter: parent.verticalCenter
                        legend: qsTr("license")
                        text: qsTr("Apache 2.0")
                        onClicked: Qt.openUrlExternally("https://www.apache.org/licenses/LICENSE-2.0.txt")
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
